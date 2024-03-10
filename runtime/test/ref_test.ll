target triple = "x86_64-pc-linux-gnu"

declare void @ref_acquire(ptr)
declare ptr @ref_new(i64)
declare void @ref_release(ptr, i64)
declare void @sys_exit_group(i64)
declare void @thread_tls_init()

define void @_start() {
	call void @thread_tls_init()

    call void @test_ref_large()

	call void @sys_exit_group(i64 0)
	unreachable
}

define void @test_ref_large() alwaysinline {
    %ptr = call ptr @ref_new(i64 262153) ; refs=1
    call void @ref_acquire(ptr %ptr) ; refs=2
    call void @ref_release(ptr %ptr, i64 262153) ; refs=1
    call void @ref_release(ptr %ptr, i64 262153) ; refs=0

    ret void
}