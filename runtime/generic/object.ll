; Allocate and initialize a new object
define ptr @object_new(i64 %bytes) alwaysinline {
    %o = call ptr @alloc_acquire(i64 %bytes)
    call void @ref_init(ptr %o)
    ret ptr %o
}
