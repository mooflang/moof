target triple = "x86_64-pc-linux-gnu"

declare void @sys_exit_group(i64)
declare void @thread_tls_init()

define void @_start() {
	call void @thread_tls_init()

	call void @sys_exit_group(i64 0)
	unreachable
}