target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare void @alloc_release(ptr, i64)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

%blob = type {
    i64, ; bytes
    [ 0 x i8 ] ; data
}

define ptr @blob_new(i64 %bytes) alwaysinline {
    %blob_bytes_ptr = getelementptr %blob, ptr null, i64 0, i32 1, i64 %bytes
    %blob_bytes = ptrtoint ptr %blob_bytes_ptr to i64

    %b = call ptr @alloc_acquire(i64 %blob_bytes)

    %bytes_ptr = getelementptr %blob, ptr %b, i64 0, i32 0
    store i64 %bytes, ptr %bytes_ptr

    ret ptr %b
}