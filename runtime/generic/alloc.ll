target triple = "x86_64-pc-linux-gnu"

; TODO: alloc_thread_data(), alloc_thread_adopt()

declare i64 @llvm.ctlz(i64, i1)
declare i64 @llvm.cttz(i64, i1)
declare i64 @llvm.umax(i64, i64)

declare void @abort_if_nonzero(i64)

declare i64 @sys_arch_prctl(i64, ptr)
declare i64 @sys_getpid()
declare i64 @sys_kill(i64, i64)
declare i64 @sys_mmap2(ptr, i64, i64, i64, i64, i64)
declare i64 @sys_munmap(ptr, i64)
declare i64 @sys_write(i64, ptr, i64)

@alloc_heads = private thread_local(localexec) global [16 x ptr] zeroinitializer

@alloc_max_block_bytes = private constant i64 u0x00040000
@alloc_pool_bytes =      private constant i64 u0x00200000

; Allocate via pool or directly based on requested bytes
define ptr @alloc_acquire(i64 %bytes) alwaysinline {
	; Split large allocations that call mmap() directly from small ones that use pools
	%max_block_bytes = load i64, ptr @alloc_max_block_bytes
	%is_large = icmp ugt i64 %bytes, %max_block_bytes
	br i1 %is_large, label %direct, label %pool

direct:
	%direct_ptr = call ptr @alloc_acquire_direct(i64 %bytes)
	ret ptr %direct_ptr

pool:
	%block_bytes = call i64 @alloc_block_bytes(i64 %bytes)
	%slot = call i64 @alloc_slot(i64 %block_bytes)
	%pool_ptr = call ptr @alloc_acquire_pool(i64 %block_bytes, i64 %slot)
	ret ptr %pool_ptr
}

; Free via pool or directly based on bytes
define void @alloc_release(ptr %ptr, i64 %bytes) alwaysinline {
	%max_block_bytes = load i64, ptr @alloc_max_block_bytes
	%is_large = icmp ugt i64 %bytes, %max_block_bytes
	br i1 %is_large, label %direct, label %pool

direct:
	call void @alloc_release_direct(ptr %ptr, i64 %bytes)
	ret void

pool:
	%block_bytes = call i64 @alloc_block_bytes(i64 %bytes)
	%slot = call i64 @alloc_slot(i64 %block_bytes)
	call void @alloc_release_pool(ptr %ptr, i64 %slot)
	ret void
}

; Acquire directly with mmap() (not from a pool)
define ptr @alloc_acquire_direct(i64 %bytes) alwaysinline {
	; PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS
	%p = call ptr @sys_mmap2(ptr null, i64 %bytes, i64 u0x03, i64 u0x22, i64 -1, i64 0)
	ret ptr %p
}

; Acquire from a bulk pool
define ptr @alloc_acquire_pool(i64 %block_bytes, i64 %slot) alwaysinline {
	%head_ptr = getelementptr ptr, ptr @alloc_heads, i64 %slot

	call void @alloc_maybe_expand_pool(i64 %block_bytes, ptr %head_ptr)

	; Remove and return the first free block
	%head = load ptr, ptr %head_ptr
	; After @alloc_maybe_expand_pool(), %head is guaranteed to be non-null
	%next = load ptr, ptr %head
	; %next may be null, but that's the next alloc's problem
	store ptr %next, ptr %head_ptr

	ret ptr %head
}

; Release directly with munmap()
define void @alloc_release_direct(ptr %ptr, i64 %bytes) alwaysinline {
	%munmap_ret = call i64 @sys_munmap(ptr %ptr, i64 %bytes)
	call void @abort_if_nonzero(i64 %munmap_ret)

	ret void
}

; Release into a bulk pool
define void @alloc_release_pool(ptr %ptr, i64 %slot) alwaysinline {
	; Splice the returned block into the free list at head
	%head_ptr = getelementptr ptr, ptr @alloc_heads, i64 %slot
	%head = load ptr, ptr %head_ptr
	store ptr %head, ptr %ptr
	store ptr %ptr, ptr %head_ptr
	ret void
}

; Determine allocation block size
define i64 @alloc_block_bytes(i64 %bytes) alwaysinline {
	%usable_bytes = call i64 @llvm.umax(i64 %bytes, i64 8)
	%block_bytes = call i64 @alloc_ceil_pow2(i64 %usable_bytes)
	ret i64 %block_bytes
}

; Determine slot in pool table for allocation size
define i64 @alloc_slot(i64 %block_bytes) alwaysinline {
	%trailing_zeros = call i64 @llvm.cttz(i64 %block_bytes, i1 1)
	%slot = sub i64 %trailing_zeros, 3
	ret i64 %slot
}

; Round up to next power of 2
define private i64 @alloc_ceil_pow2(i64 %val) alwaysinline {
	%1 = sub i64 %val, 1
	%2 = call i64 @llvm.ctlz(i64 %1, i1 0)
	%3 = sub i64 64, %2
	%4 = shl i64 1, %3
	ret i64 %4
}

; Expand the pool with more system allocation if necessary
define private void @alloc_maybe_expand_pool(i64 %block_bytes, ptr %head_ptr) alwaysinline {
	%head = load ptr, ptr %head_ptr
	%is_null = icmp eq ptr %head, null
	br i1 %is_null, label %needsalloc, label %alreadyalloc

needsalloc:
	call void @alloc_expand_pool(i64 %block_bytes, ptr %head_ptr)
	ret void

alreadyalloc:
	ret void
}

; Expand the pool with more system allocation
define private void @alloc_expand_pool(i64 %block_bytes, ptr %head_ptr) alwaysinline {
entry:
	%pool_bytes = load i64, ptr @alloc_pool_bytes
	; PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS
	%alloc_ptr = call ptr @sys_mmap2(ptr null, i64 %pool_bytes, i64 u0x03, i64 u0x22, i64 -1, i64 0)

	br label %loop

loop:
	%offset_bytes = phi i64 [ 0, %entry ], [ %next_offset_bytes, %loop ]

	%from_ptr = phi ptr [ %head_ptr, %entry ], [ %to_ptr, %loop ]
	%to_ptr = getelementptr i8, ptr %alloc_ptr, i64 %offset_bytes
	store ptr %to_ptr, ptr %from_ptr
	; Last block will always point to null

	%next_offset_bytes = add i64 %offset_bytes, %block_bytes

	%continue = icmp ult i64 %next_offset_bytes, %pool_bytes
	br i1 %continue, label %loop, label %afterloop

afterloop:
	ret void
}