#include "kernel/types.h"
#include "user.h"
#define LIB_PREFIX "[UTHREAD]: "
#define ulog() printf("%s%s\n", LIB_PREFIX, __FUNCTION__)
#define PGSIZE 4096 // bytes per page

uint32 thread_count;
struct thread *threads[MAXTHREAD];
struct lock thread_lock;
struct thread *current_thread;

void
thread_init(void)
{
    thread_count = 0;
    for (int i = 0; i < MAXTHREAD; i++)
    {
        threads[i] = 0;
    }
    initlock(&thread_lock, "thread lock");
}

void tsched()
{
    // TODO: Implement a userspace round robin scheduler that switches to the next thread
    

}

uint8 tidalloc()
{
    acquire(&thread_lock);
    uint8 tid = thread_count;
    thread_count++;
    release(&thread_lock);
    return tid;
}


void tcreate(struct thread **thread, struct thread_attr *attr, void *(*func)(void *arg), void *arg)
{
    // TODO: Create a new thread and add it as runnable, such that it starts running
    // once the scheduler schedules it the next time
    uint32 stacksize = PGSIZE;
    uint32 res_size = 0;
    uint64 stack;

    *thread = (struct thread *)malloc(sizeof(struct thread));

    if (attr != 0)
    {
        if (attr->stacksize != 0)
        {
            stacksize = attr->stacksize;
        }
        if (attr->res_size != 0)
        {
            res_size = attr->res_size;
        }
    }

    // Set up the new thread
    (*thread)->state = RUNNABLE;
    (*thread)->func = func;
    (*thread)->arg = arg;
    (*thread)->tid = tidalloc();
    (*thread)->tcontext.ra = (uint64)func;

    // Allocate memory for the thread's stack and store the highest address in context.sp
    stack = (uint64)malloc(stacksize);
    (*thread)->tcontext.sp = stack + stacksize;

    // Allocate memory for the thread's result
    (*thread)->result = malloc(res_size);

    // Add the thread to the threads array
    threads[thread_count] = *thread;

    // Increment the thread count
    thread_count++;

}


/*Based on the information you provided about the `tsched` function and its requirements, here's an example implementation of the `tsched` function that uses a round-robin scheduling algorithm to select the next thread to run:

```c
// Global variable to keep track of the currently running thread
int current_thread = -1;

void tsched()
{
    // Find the next runnable thread using a round-robin scheduling algorithm
    int next_thread = (current_thread + 1) % MAXTHREAD;
    while (threads[next_thread] == NULL || threads[next_thread]->state != RUNNABLE)
    {
        next_thread = (next_thread + 1) % MAXTHREAD;
        if (next_thread == current_thread)
        {
            // No runnable threads found
            return;
        }
    }

    // Switch to the next thread
    if (current_thread != -1)
    {
        tswtch(&threads[current_thread]->tcontext, &threads[next_thread]->tcontext);
    }
    current_thread = next_thread;
}
```

This implementation of `tsched` uses a global variable `current_thread` to keep track of the currently running thread. The `tsched` function starts by finding the next runnable thread using a round-robin scheduling algorithm. It does this by starting from the thread after the currently running thread (`current_thread + 1`) and iterating through all threads in the `threads` array until it finds a thread that is not `NULL` and has a state of `RUNNABLE`.

Once a runnable thread is found, the `tsched` function uses the `tswtch` function to switch to this thread. The `current_thread` variable is then updated to reflect the index of the newly selected thread.

Note that this implementation assumes that the `threads` array and the `tswtch` function are defined and implemented elsewhere in your code. You would need to provide these definitions and implementations for this version of `tsched` to work correctly.

Is this what you were looking for? 😊*/

int tjoin(int tid, void *status, uint size)
{
    // TODO: Wait for the thread with TID to finish. If status and size are non-zero,
    // copy the result of the thread to the memory, status points to. Copy size bytes.
    return 0;
}

void tyield()
{
    // TODO: Implement the yielding behaviour of the thread
}

uint8 twhoami()
{
    // TODO: Returns the thread id of the current thread
    return 0;
}
