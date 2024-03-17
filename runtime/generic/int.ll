define ptr @int_new(i64 %val) alwaysinline {
    %int_bytes = call i64 @int_bytes()
    %i = call ptr @object_new(i64 %int_bytes)

    %val_ptr = getelementptr %int, ptr %i, i64 0, i32 1
    store i64 %val, ptr %val_ptr

    ret ptr %i
}

define void @int_release(ptr %i) alwaysinline {
    %int_bytes = call i64 @int_bytes()
    call void @ref_release(ptr %i, i64 %int_bytes)

    ret void
}

define i64 @int_bytes() alwaysinline {
    %int_bytes_ptr = getelementptr %int, ptr null, i64 1
    %int_bytes = ptrtoint ptr %int_bytes_ptr to i64
    ret i64 %int_bytes
}

define i64 @int_val(ptr %i) alwaysinline {
    %val_ptr = getelementptr %int, ptr %i, i64 0, i32 1
    %val = load i64, ptr %val_ptr
    ret i64 %val
}
