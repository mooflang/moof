define void @_start() {
	call void @thread_tls_init()

	call void @test_blob()

	call void @sys_exit_group(i64 0)
	unreachable
}

define void @test_blob() alwaysinline {
	%b = call ptr @blob_new(i64 10)
	call void @blob_release(ptr %b)
	ret void
}
