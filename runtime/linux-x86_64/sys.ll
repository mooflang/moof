define i64 @sys_arch_prctl(i64 %code, ptr %addr) alwaysinline {
	%1 = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi}"(i64 158, i64 %code, ptr %addr)
	ret i64 %1
}

define void @sys_exit_group(i64 %val) alwaysinline {
	call void asm sideeffect "syscall", "{rax},{rdi}"(i64 231, i64 0)
	unreachable
}

define i64 @sys_getpid() alwaysinline {
	%1 = call i64 asm sideeffect "syscall", "={rax},{rax}"(i64 39)
	ret i64 %1
}

define i64 @sys_kill(i64 %pid, i64 %sig) alwaysinline {
	%1 = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi}"(i64 62, i64 %pid, i64 %sig)
	ret i64 %1
}

define ptr @sys_mmap2(ptr %addr, i64 %len, i64 %prot, i64 %flags, i64 %fd, i64 %pgoffset) alwaysinline {
	%1 = call ptr asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9}"(i64 9, ptr %addr, i64 %len, i64 %prot, i64 %flags, i64 %fd, i64 %pgoffset)
	ret ptr %1
}

define i64 @sys_munmap(ptr %addr, i64 %len) alwaysinline {
	%1 = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi}"(i64 11, ptr %addr, i64 %len)
	ret i64 %1
}

define i64 @sys_write(i64 %fd, ptr %buf, i64 %len) alwaysinline {
	%1 = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx}"(i64 1, i64 %fd, ptr %buf, i64 %len)
	ret i64 %1
}
