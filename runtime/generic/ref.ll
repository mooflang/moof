target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare void @alloc_release(ptr, i64)

define ptr @ref_new(i64 %bytes) alwaysinline {
    %wrap_bytes = call i64 @ref_wrap_bytes(i64 %bytes)
    %wrap = call ptr @alloc_acquire(i64 %wrap_bytes)

    store i64 0, ptr %wrap

    %base = call ptr @ref_wrap_to_base(ptr %wrap)
    ret ptr %base
}

define void @ref_acquire(ptr %base) alwaysinline {
    %wrap = call ptr @ref_base_to_wrap(ptr %base)
    atomicrmw add ptr %wrap, i64 1 monotonic

    ret void
}

define void @ref_release(ptr %base, i64 %bytes) alwaysinline {
    %wrap = call ptr @ref_base_to_wrap(ptr %base)
    %old_cnt = atomicrmw sub ptr %wrap, i64 1 monotonic

    %should_release = icmp eq i64 %old_cnt, 0
    br i1 %should_release, label %release, label %done

release:
    %wrap_bytes = call i64 @ref_wrap_bytes(i64 %bytes)
    call void @alloc_release(ptr %wrap, i64 %wrap_bytes)
    br label %done

done:
    ret void
}

define i64 @ref_wrap_bytes(i64 %bytes) alwaysinline {
    %wrap_bytes = add i64 %bytes, 8
    ret i64 %wrap_bytes
}

define ptr @ref_wrap_to_base(ptr %wrap) alwaysinline {
    %base = getelementptr i8, ptr %wrap, i64 8
    ret ptr %base
}

define ptr @ref_base_to_wrap(ptr %base) alwaysinline {
    %wrap = getelementptr i8, ptr %base, i64 -8
    ret ptr %wrap
}