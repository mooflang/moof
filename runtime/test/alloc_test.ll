target triple = "x86_64-pc-linux-gnu"

declare void @abort_if_not_equal(i64 %val1, i64 %val2)
declare ptr @alloc_acquire(i64)
declare i64 @alloc_block_bytes(i64)
declare ptr @alloc_release(ptr, i64)
declare i64 @alloc_slot(i64)
declare void @sys_exit_group(i64)
declare void @thread_tls_init()

define void @_start() {
	call void @thread_tls_init()

	call void @test_alloc_block_bytes()
	call void @test_alloc_slot()
	call void @test_alloc_acquire()

	call void @sys_exit_group(i64 0)
	unreachable
}

define private void @test_alloc_block_bytes() alwaysinline {
	%bytes1 = call i64 @alloc_block_bytes(i64 14)
	call void @abort_if_not_equal(i64 %bytes1, i64 16)

	%bytes2 = call i64 @alloc_block_bytes(i64 2)
	call void @abort_if_not_equal(i64 %bytes2, i64 8)

	ret void
}

define private void @test_alloc_slot() alwaysinline {
	%slot1 = call i64 @alloc_slot(i64 8)
	call void @abort_if_not_equal(i64 %slot1, i64 0)

	ret void
}

; Array size must match @testlib_alloc_size and should not be a multiple of 3
@test_alloc_sizes = global [5 x i64] [i64 14, i64 2, i64 64, i64 262144, i64 262145]

define private i64 @testlib_alloc_size(i64 %counter, i64 %offset) alwaysinline {
	%with_offset = add i64 %counter, %offset
	%index = urem i64 %with_offset, 5
	%ptr = getelementptr i64, ptr @test_alloc_sizes, i64 %index
	%val = load i64, ptr %ptr
	ret i64 %val
}

define private void @test_alloc_acquire() alwaysinline {
entry:
	br label %loop

loop:
	%counter = phi i64 [ 0, %entry ], [ %next_counter, %loop ]

	%s1 = call i64 @testlib_alloc_size(i64 %counter, i64 0)
	%ptr1 = call ptr @alloc_acquire(i64 %s1)
	store i64 %s1, ptr %ptr1

	%s2 = call i64 @testlib_alloc_size(i64 %counter, i64 1)
	%ptr2 = call ptr @alloc_acquire(i64 %s2)
	store i64 %s2, ptr %ptr2

	%s3 = call i64 @testlib_alloc_size(i64 %counter, i64 2)
	%ptr3 = call ptr @alloc_acquire(i64 %s3)
	store i64 %s3, ptr %ptr3

	%v1 = load i64, ptr %ptr1
	call void @abort_if_not_equal(i64 %v1, i64 %s1)

	%v2 = load i64, ptr %ptr2
	call void @abort_if_not_equal(i64 %v2, i64 %s2)

	%v3 = load i64, ptr %ptr3
	call void @abort_if_not_equal(i64 %v3, i64 %s3)

	call void @alloc_release(ptr %ptr2, i64 %s2)

	%next_counter = add i64 %counter, 1
	%continue = icmp ult i64 %next_counter, 100
	br i1 %continue, label %loop, label %afterloop

afterloop:
	ret void
}