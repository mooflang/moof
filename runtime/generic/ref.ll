; Initialize a reference-counted object with 1 reference
define void @ref_init(ptr %o) alwaysinline {
    %cnt_ptr = getelementptr %object, ptr %o, i64 0, i32 0
    store i64 0, ptr %cnt_ptr
    ret void
}

; Increase the reference count of an object by 1
define void @ref_acquire(ptr %o) alwaysinline {
    %cnt_ptr = getelementptr %object, ptr %o, i64 0, i32 0
    atomicrmw add ptr %cnt_ptr, i64 1 monotonic
    ret void
}

; Decrease the reference count of an object by 1 and deallocate it if this is the last reference
define void @ref_release(ptr %o, i64 %bytes) alwaysinline {
    %cnt_ptr = getelementptr %object, ptr %o, i64 0, i32 0
    %old_cnt = atomicrmw sub ptr %cnt_ptr, i64 1 monotonic

    %should_release = icmp eq i64 %old_cnt, 0
    br i1 %should_release, label %release, label %done

release:
    call void @alloc_release(ptr %o, i64 %bytes)
    br label %done

done:
    ret void
}
