target triple = "x86_64-pc-linux-gnu"

declare i64 @sys_getpid()
declare i64 @sys_kill(i64, i64)

define void @abort() alwaysinline {
	%pid = call i64 @sys_getpid()
	call void @sys_kill(i64 %pid, i64 6) ; SIGABRT
	unreachable
}

define void @abort_if_nonzero(i64 %val) alwaysinline {
	%is_zero = icmp eq i64 %val, 0
	br i1 %is_zero, label %zero, label %nonzero

zero:
	ret void

nonzero:
	call void @abort()
	unreachable
}

define void @abort_if_not_equal(i64 %val1, i64 %val2) alwaysinline {
	%is_equal = icmp eq i64 %val1, %val2
	br i1 %is_equal, label %equal, label %notequal

equal:
	ret void

notequal:
	call void @abort()
	unreachable
}


define void @abort_if_null(ptr %val) alwaysinline {
	%is_null = icmp eq ptr %val, null
	br i1 %is_null, label %null, label %notnull

null:
	call void @abort()
	unreachable

notnull:
	ret void
}