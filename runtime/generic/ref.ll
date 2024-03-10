target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare void @alloc_release(ptr, i64)

%ref_wrapper = type { i64, i8 }

define ptr @ref_new(i64 %bytes) alwaysinline {
    %wrap_bytes = add i64 %bytes, 8
    %wrap = call ptr @alloc_acquire(i64 %wrap_bytes)

    %cnt_ptr = getelementptr %ref_wrapper, ptr %wrap, i32 0
    store i64 0, ptr %cnt_ptr

    %base_ptr = getelementptr %ref_wrapper, ptr %wrap, i32 1

    ret ptr %base_ptr
}

define void @ref_acquire(ptr %base_ptr) alwaysinline {
    %wrap = call ptr @ref_get_wrap(ptr %base_ptr)

    %cnt_ptr = getelementptr %ref_wrapper, ptr %wrap, i32 0
    atomicrmw add ptr %cnt_ptr, i64 1 monotonic

    ret void
}

define void @ref_release(ptr %base_ptr, i64 %bytes) alwaysinline {
    %wrap = call ptr @ref_get_wrap(ptr %base_ptr)

    %cnt_ptr = getelementptr %ref_wrapper, ptr %wrap, i32 0
    %old_cnt = atomicrmw sub ptr %cnt_ptr, i64 1 monotonic

    %should_release = icmp eq i64 %old_cnt, 0
    br i1 %should_release, label %release, label %done

release:
    %wrap_bytes = add i64 %bytes, 8
    call void @alloc_release(ptr %wrap, i64 %wrap_bytes)
    br label %done

done:
    ret void
}

define ptr @ref_get_wrap(ptr %base_ptr) alwaysinline {
    %wrap = getelementptr i64, ptr %base_ptr, i64 -1
    ret ptr %wrap
}