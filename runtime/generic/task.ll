target triple = "x86_64-pc-linux-gnu"

declare ptr @alloc_acquire(i64)
declare void @alloc_release(ptr, i64)

%task = type {
    i64, ; task bytes
    ptr, ; next task
    ptr, ; task function
    [0 x ptr] ; task arguments
}

@task_head = private global ptr zeroinitializer

; Donate this thread as a task runner
define void @task_loop() alwaysinline {
entry:
    br label %loop

loop:
    ; pop task from queue
    %t = load ptr, ptr @task_head
    %next_task_ptr = getelementptr %task, ptr %t, i64 0, i32 1
    %next_task = load ptr, ptr %next_task_ptr
    store ptr %next_task, ptr @task_head

    ; run task
    %t_func_ptr = getelementptr %task, ptr %t, i64 0, i32 2
    %t_func = load ptr, ptr %t_func_ptr
    %t_args_ptr = getelementptr %task, ptr %t, i64 0, i32 3
    call void %t_func(ptr %t_args_ptr)

    %t_bytes_ptr = getelementptr %task, ptr %t, i64 0, i32 0
    %t_bytes = load i64, ptr %t_bytes_ptr
    call void @alloc_release(ptr %t, i64 %t_bytes)

    br label %loop
    unreachable
}

; Add task to queue (LIFO)
define void @task_add(ptr %t) alwaysinline {
    %next_task_ptr = getelementptr %task, ptr %t, i64 0, i32 1
    %prev_task_head = load ptr, ptr @task_head
    store ptr %prev_task_head, ptr %next_task_ptr
    store ptr %t, ptr @task_head
    ret void
}

; Allocate a new task
define ptr @task_new(ptr %func, i64 %num_args) alwaysinline {
    ; pointer to one element after the correct number of args, giving us the size
    %task_bytes_ptr = getelementptr %task, ptr null, i64 0, i32 3, i64 %num_args
    %task_bytes = ptrtoint ptr %task_bytes_ptr to i64

    %t = call ptr @alloc_acquire(i64 %task_bytes)

    %t_bytes_ptr = getelementptr %task, ptr %t, i64 0, i32 0
    store i64 %task_bytes, ptr %t_bytes_ptr

    %t_func_ptr = getelementptr %task, ptr %t, i64 0, i32 2
    store ptr %func, ptr %t_func_ptr

    ret ptr %t
}

; Set a task argument
define void @task_set_arg(ptr %t, i64 %i, ptr %arg) alwaysinline {
    %arg_ptr = getelementptr %task, ptr %t, i64 0, i32 3, i64 %i
    store ptr %arg, ptr %arg_ptr
    ret void
}

; Fetch an arg from the arg list
define ptr @task_get_arg(ptr %args, i64 %i) alwaysinline {
    %arg_ptr = getelementptr ptr, ptr %args, i64 %i
    %arg = load ptr, ptr %arg_ptr
    ret ptr %arg
}