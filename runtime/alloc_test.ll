target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare ptr @alloc_acquire_pool(i64, i64)
declare ptr @alloc_release(ptr, i64)
declare void @alloc_release_pool(ptr, i64)
declare void @sys_exit_group(i64)
declare void @thread_tls_init()

define void @_start() {
	call void @thread_tls_init()

	call void @alloc_test()

	call void @sys_exit_group(i64 0)
	unreachable
}

define private void @alloc_test() alwaysinline {
entry:
	br label %loop

loop:
	%counter = phi i64 [ 0, %entry ], [ %next_counter, %loop ]

	; Using runtime method/size/slot selection
;	%ptr1 = call ptr @alloc_acquire(i64 14)
;	%ptr2 = call ptr @alloc_acquire(i64 14)
;	%ptr3 = call ptr @alloc_acquire(i64 14)
;	call void @alloc_release(ptr %ptr2, i64 14)

	; Using compile-time method/size/slot selection
	%ptr1 = call ptr @alloc_acquire_pool(i64 16, i64 1)
	%ptr2 = call ptr @alloc_acquire_pool(i64 16, i64 1)
	%ptr3 = call ptr @alloc_acquire_pool(i64 16, i64 1)
	call void @alloc_release_pool(ptr %ptr2, i64 1)

	%next_counter = add i64 %counter, 1
	%continue = icmp ult i64 %next_counter, 100000000
	br i1 %continue, label %loop, label %afterloop

afterloop:
	ret void
}