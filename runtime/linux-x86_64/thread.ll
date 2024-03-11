; TODO: thread_tls_deinit()

@thread_tls_bytes = private constant i64 u0x00001000

; Initialize thread-local storage for this thread
define void @thread_tls_init() alwaysinline {
	%tls_bytes = load i64, ptr @thread_tls_bytes
	; PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS
	%ptr = call ptr @sys_mmap2(ptr null, i64 %tls_bytes, i64 u0x03, i64 u0x22, i64 -1, i64 0)

	; Set %fs near the end of the allocated block, since %fs offsets are negative by convention
	%tls_offset = sub i64 %tls_bytes, 8
	%base = getelementptr i8, ptr %ptr, i64 %tls_offset

	; Store a pointer to itself at %fs:0
	store ptr %base, ptr %base

	%arch_prctl_ret = call i64 @sys_arch_prctl(i64 u0x1002, ptr %base) ; ARCH_SET_FS
	call void @abort_if_nonzero(i64 %arch_prctl_ret)

	ret void
}
