define void @_start() {
	call void @init()

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

; Array size must match @testlib_alloc_size urem value
@test_alloc_sizes = private global [8 x i64] [i64 14, i64 2, i64 64, i64 63, i64 129, i64 262144, i64 262145, i64 100000]

define private i64 @testlib_alloc_size(i64 %counter, i64 %offset) alwaysinline {
	%with_offset = add i64 %counter, %offset
	%index = urem i64 %with_offset, 8
	%ptr = getelementptr i64, ptr @test_alloc_sizes, i64 %index
	%val = load i64, ptr %ptr
	ret i64 %val
}

%check = type { ptr, i64 }

define private void @testlib_append_check(ptr %to_check, ptr %to_check_i, ptr %loc, i64 %val) alwaysinline {
	store i64 %val, ptr %loc

	%i = load i64, ptr %to_check_i

	%slot_loc = getelementptr %check, ptr %to_check, i64 %i, i32 0
	store ptr %loc, ptr %slot_loc

	%slot_val = getelementptr %check, ptr %to_check, i64 %i, i32 1
	store i64 %val, ptr %slot_val

	%next_i = add i64 %i, 1
	store i64 %next_i, ptr %to_check_i

	ret void
}

define private void @testlib_check(ptr %to_check, ptr %to_check_i) alwaysinline {
entry:
	br label %loop

loop:
	%prev_i = load i64, ptr %to_check_i
	%i = sub i64 %prev_i, 1
	store i64 %i, ptr %to_check_i

	%slot_loc = getelementptr %check, ptr %to_check, i64 %i, i32 0
	%loc = load ptr, ptr %slot_loc
	%val = load i64, ptr %loc

	%slot_val_expected = getelementptr %check, ptr %to_check, i64 %i, i32 1
	%val_expected = load i64, ptr %slot_val_expected

	call void @abort_if_not_equal(i64 %val_expected, i64 %val)

	%done = icmp eq i64 %i, 0
	br i1 %done, label %afterloop, label %loop

afterloop:
	ret void
}

define private ptr @testlib_end(ptr %start, i64 %bytes) alwaysinline {
	%bytes2 = call i64 @llvm.umax(i64 %bytes, i64 8)
	%1 = ptrtoint ptr %start to i64
	%2 = add i64 %1, %bytes2
	%3 = sub i64 %2, 8
	%4 = and i64 %3, u0xfffffffffffffff8
	%5 = inttoptr i64 %4 to ptr
	ret ptr %5
}

define private void @test_alloc_acquire() alwaysinline {
entry:
	%to_check = alloca %check, i64 4000
	%to_check_i = alloca i64
	store i64 0, ptr %to_check_i

	br label %loop

loop:
	%counter = phi i64 [ 0, %entry ], [ %next_counter, %loop ]

	%s1 = call i64 @testlib_alloc_size(i64 %counter, i64 0)
	%ptr1 = call ptr @alloc_acquire(i64 %s1)
	call void @testlib_append_check(ptr %to_check, ptr %to_check_i, ptr %ptr1, i64 %counter)
	%ptr1e = call ptr @testlib_end(ptr %ptr1, i64 %s1)
	call void @testlib_append_check(ptr %to_check, ptr %to_check_i, ptr %ptr1e, i64 %counter)

	%s2 = call i64 @testlib_alloc_size(i64 %counter, i64 1)
	%ptr2 = call ptr @alloc_acquire(i64 %s2)

	%s3 = call i64 @testlib_alloc_size(i64 %counter, i64 2)
	%ptr3 = call ptr @alloc_acquire(i64 %s3)
	call void @testlib_append_check(ptr %to_check, ptr %to_check_i, ptr %ptr3, i64 %counter)
	%ptr3e = call ptr @testlib_end(ptr %ptr3, i64 %s3)
	call void @testlib_append_check(ptr %to_check, ptr %to_check_i, ptr %ptr3e, i64 %counter)

	call void @alloc_release(ptr %ptr2, i64 %s2)

	%next_counter = add i64 %counter, 1
	%continue = icmp ult i64 %next_counter, 1000
	br i1 %continue, label %loop, label %afterloop

afterloop:
	call void @testlib_check(ptr %to_check, ptr %to_check_i)

	ret void
}
