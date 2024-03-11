define void @_start() {
	call void @thread_tls_init()

	call void @sys_exit_group(i64 0)
	unreachable
}
