target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare void @alloc_release(ptr, i64)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

%data = type {
    i64, ; bytes
    [ 0 x i8 ] ; data
}

define ptr @data_new(i64 %bytes) alwaysinline {
    %data_bytes_ptr = getelementptr %data, ptr null, i64 0, i32 1, i64 %bytes
    %data_bytes = ptrtoint ptr %data_bytes_ptr to i64

    %d = call ptr @alloc_acquire(i64 %data_bytes)

    %bytes_ptr = getelementptr %data, ptr %d, i64 0, i32 0
    store i64 %bytes, ptr %bytes_ptr

    ret ptr %d
}