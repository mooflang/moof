define void @_start() {
	call void @init()

	call void @test_blob()

	call void @sys_exit_group(i64 0)
	unreachable
}

define void @test_blob() alwaysinline {
	%i = call ptr @int_new(i64 10)
	%b = call ptr @blob_new(ptr %i)
	call void @int_release(ptr %i)
	call void @blob_release(ptr %b)
	ret void
}
