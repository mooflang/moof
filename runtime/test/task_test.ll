define void @_start() {
	call void @init()

    call void @test_task()
    unreachable
}

define void @test_task() {
    %t = call ptr @task_new(ptr @test_task_chain_0, i64 0)
    call void @task_add(ptr %t)
    call void @task_loop()
    unreachable
}

@test_task_val = private constant i64 u0x12345678

define void @test_task_chain_0(ptr %args) {
    %t = call ptr @task_new(ptr @test_task_chain_1, i64 1)
    call void @task_set_arg(ptr %t, i64 0, ptr @test_task_val)
    call void @task_add(ptr %t)

    ret void
}

define void @test_task_chain_1(ptr %args) {
    %arg0 = call ptr @task_get_arg(ptr %args, i64 0)
    call void @abort_if_not_equal(ptr %arg0, ptr @test_task_val)

    %t = call ptr @task_new(ptr @test_task_exit, i64 0)
    call void @task_add(ptr %t)

    ret void
}

define void @test_task_exit(ptr %args) {
	call void @sys_exit_group(i64 0)
	unreachable
}
