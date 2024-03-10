target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare void @alloc_release(ptr, i64)

%ref_wrap = type { i64, i8 }

; Allocate a reference-counted object with 1 reference
define ptr @ref_new(i64 %bytes) alwaysinline {
    %wrap_bytes = call i64 @ref_wrap_bytes(i64 %bytes)
    %wrap = call ptr @alloc_acquire(i64 %wrap_bytes)

    %cnt_ptr = getelementptr %ref_wrap, ptr %wrap, i64 0, i32 0
    store i64 0, ptr %cnt_ptr

    %base = call ptr @ref_wrap_to_base(ptr %wrap)
    ret ptr %base
}

; Increase the reference count of an object by 1
define void @ref_acquire(ptr %base) alwaysinline {
    %wrap = call ptr @ref_base_to_wrap(ptr %base)

    %cnt_ptr = getelementptr %ref_wrap, ptr %wrap, i64 0, i32 0
    atomicrmw add ptr %cnt_ptr, i64 1 monotonic

    ret void
}

; Decrease the reference count of an object by 1 and deallocate it if this is the last reference
define void @ref_release(ptr %base, i64 %bytes) alwaysinline {
    %wrap = call ptr @ref_base_to_wrap(ptr %base)

    %cnt_ptr = getelementptr %ref_wrap, ptr %wrap, i64 0, i32 0
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

; Constant calculation of %ref_wrap start to caller base location
define private i64 @ref_wrap_to_base_offset() alwaysinline {
    %wtb_ptr = getelementptr %ref_wrap, ptr null, i64 0, i32 1
    %wtb = ptrtoint ptr %wtb_ptr to i64
    ret i64 %wtb
}

; Constant calculation of %ref_wrap caller base location to start (negative value)
define private i64 @ref_base_to_wrap_offset() alwaysinline {
    %wtb = call i64 @ref_wrap_to_base_offset()
    %btw = sub i64 0, %wtb
    ret i64 %btw
}

; Calculate number of bytes to allocate for caller request plus wrapper
define private i64 @ref_wrap_bytes(i64 %bytes) alwaysinline {
    %wtb = call i64 @ref_wrap_to_base_offset()
    %wrap_bytes = add i64 %bytes, %wtb
    ret i64 %wrap_bytes
}

; Calculate caller base location from %ref_wrap start
define private ptr @ref_wrap_to_base(ptr %wrap) alwaysinline {
    %base = getelementptr %ref_wrap, ptr %wrap, i64 0, i32 1
    ret ptr %base
}

; Calculate %ref_wrap start from caller base location
define private ptr @ref_base_to_wrap(ptr %base) alwaysinline {
    %btw = call i64 @ref_base_to_wrap_offset()
    %wrap = getelementptr i8, ptr %base, i64 %btw
    ret ptr %wrap
}