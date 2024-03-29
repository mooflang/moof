define void @init() {
    call void @thread_tls_init()
    ret void
}