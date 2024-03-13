define ptr @blob_new(i64 %bytes) alwaysinline {
    %blob_bytes_ptr = getelementptr %blob, ptr null, i64 0, i32 2, i64 %bytes
    %blob_bytes = ptrtoint ptr %blob_bytes_ptr to i64

    %b = call ptr @alloc_acquire(i64 %blob_bytes)

    %bytes_ptr = getelementptr %blob, ptr %b, i64 0, i32 1
    store i64 %bytes, ptr %bytes_ptr

    ret ptr %b
}
