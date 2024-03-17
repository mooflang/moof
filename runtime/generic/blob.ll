define ptr @blob_new(ptr %int.bytes) alwaysinline {
    %bytes = call i64 @int_val(ptr %int.bytes)

    %blob_bytes = call i64 @blob_bytes(i64 %bytes)
    %b = call ptr @object_new(i64 %blob_bytes)

    %bytes_ptr = getelementptr %blob, ptr %b, i64 0, i32 1
    store i64 %bytes, ptr %bytes_ptr

    ret ptr %b
}

define void @blob_release(ptr %b) alwaysinline {
    %bytes_ptr = getelementptr %blob, ptr %b, i64 0, i32 1
    %bytes = load i64, ptr %bytes_ptr

    %blob_bytes = call i64 @blob_bytes(i64 %bytes)
    call void @ref_release(ptr %b, i64 %blob_bytes)

    ret void
}

define i64 @blob_bytes(i64 %bytes) alwaysinline {
    %blob_bytes_ptr = getelementptr %blob, ptr null, i64 0, i32 2, i64 %bytes
    %blob_bytes = ptrtoint ptr %blob_bytes_ptr to i64
    ret i64 %blob_bytes
}
