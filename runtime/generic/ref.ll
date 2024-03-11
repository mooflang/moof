target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare void @alloc_release(ptr, i64)

%ref = type {
    i64, ; reference count
    [0 x i8] ; caller data
}

; Allocate a reference-counted object with 1 reference
define ptr @ref_new(i64 %bytes) alwaysinline {
    %ref_bytes = call i64 @ref_bytes(i64 %bytes)
    %r = call ptr @alloc_acquire(i64 %ref_bytes)

    %cnt_ptr = getelementptr %ref, ptr %r, i64 0, i32 0
    store i64 0, ptr %cnt_ptr

    %base = call ptr @ref_ref_to_base(ptr %r)
    ret ptr %base
}

; Increase the reference count of an object by 1
define void @ref_acquire(ptr %base) alwaysinline {
    %r = call ptr @ref_base_to_ref(ptr %base)

    %cnt_ptr = getelementptr %ref, ptr %r, i64 0, i32 0
    atomicrmw add ptr %cnt_ptr, i64 1 monotonic

    ret void
}

; Decrease the reference count of an object by 1 and deallocate it if this is the last reference
define void @ref_release(ptr %base, i64 %bytes) alwaysinline {
    %r = call ptr @ref_base_to_ref(ptr %base)

    %cnt_ptr = getelementptr %ref, ptr %r, i64 0, i32 0
    %old_cnt = atomicrmw sub ptr %r, i64 1 monotonic

    %should_release = icmp eq i64 %old_cnt, 0
    br i1 %should_release, label %release, label %done

release:
    %ref_bytes = call i64 @ref_bytes(i64 %bytes)
    call void @alloc_release(ptr %r, i64 %ref_bytes)
    br label %done

done:
    ret void
}

; Constant calculation of %ref start to caller data start
define private i64 @ref_ref_to_base_offset() alwaysinline {
    %offset_ptr = getelementptr %ref, ptr null, i64 0, i32 1
    %offset = ptrtoint ptr %offset_ptr to i64
    ret i64 %offset
}

; Constant calculation of caller data start to %ref start (negative value)
define private i64 @ref_base_to_ref_offset() alwaysinline {
    %wtb = call i64 @ref_ref_to_base_offset()
    %btw = sub i64 0, %wtb
    ret i64 %btw
}

; Calculate number of bytes to allocate for caller data plus %ref
define private i64 @ref_bytes(i64 %bytes) alwaysinline {
    %total_bytes_ptr = getelementptr %ref, ptr null, i64 0, i32 1, i64 %bytes
    %total_bytes = ptrtoint ptr %total_bytes_ptr to i64
    ret i64 %total_bytes
}

; Calculate caller data start from %ref start
define private ptr @ref_ref_to_base(ptr %r) alwaysinline {
    %base = getelementptr %ref, ptr %r, i64 0, i32 1
    ret ptr %base
}

; Calculate %ref start from caller data start
define private ptr @ref_base_to_ref(ptr %base) alwaysinline {
    %offset = call i64 @ref_base_to_ref_offset()
    %r = getelementptr i8, ptr %base, i64 %offset
    ret ptr %r
}