#include "kernel/types.h"
#include "user.h"
#define LIB_PREFIX "[UTHREAD]: "
#define ulog() printf("%s%s\n", LIB_PREFIX, __FUNCTION__)
#define PGSIZE 4096 // bytes per page

struct thread threads[MAXTHREAD];

//struct lock threads_lock;
struct thread *current_thread;
uint32 thread_count;

void
threadinit()
{
    struct thread *t;

    thread_count = 0;

    //initlock(&threads_lock, "threads_lock");

    for (t = threads; t < &threads[MAXTHREAD]; t++)
    {
        //initlock(&t->tlock, "thread");
        t->state = UNUSED;
    }
}

void
tsave(struct thread *thread)
{
    struct thread *t;
    for (t = threads; t < &threads[MAXTHREAD]; t++)
    {
        //acquire(&t->tlock);
        if (t->state == UNUSED)
        {
            t->tid = tidalloc();
            //printf("tsave t->tid = %d\n", t->tid);
            t->state = RUNNING;
            thread = t;
            //printf("thread dir = %d\n", thread);
            current_thread = t;
            break;
        }
        
       
    }
}

void tsched(void)
{
    // TODO: Implement a userspace round robin scheduler that switches to the next thread
    struct thread *t;
    //printf("tsched entered\n");
    for(t=threads; t<&threads[MAXTHREAD]; t++)
    {
        //acquire(&threads_lock);
        //twhoami();
        //printf("tsched t->state = %d\n", t->state);
        if(t->state == RUNNABLE){
            //printf("tsched t->state = %d\n", current_thread->state);
            t->state = RUNNING;
            current_thread->state = RUNNABLE;
            tswtch(&current_thread->tcontext, &t->tcontext);
            current_thread = t;
            //twhoami();
        }
        //release(&threads_lock);
        
    }

}

uint8 tidalloc()
{
    uint8 tid;
    //acquire(&threads_lock);
    tid = thread_count;
    thread_count++;
    //release(&threads_lock);
    return tid;
}


void tcreate(struct thread **thread, struct thread_attr *attr, void *(*func)(void *arg), void *arg)
{
    // TODO: Create a new thread and add it as runnable, such that it starts running
    // once the scheduler schedules it the next time
    uint32 stacksize = 4096;
    uint32 res_size = 0;
    uint64 stack;

    struct thread *t;
    /* printf("\n---------\n\n");
    printf("tcreate entered\n");
    printf("thread count = %d\n", thread_count); */
    for (t = threads; t < &threads[MAXTHREAD]; t++)
    {
        //acquire(&t->tlock);
        /* printf("thread id = %d\n", t->tid);
        printf("tcreate t->state = %d\n", t->state); */
        if (t->state == UNUSED)
        {
            goto found;
        }
     
    }

found:

    //*thread = (struct thread *)malloc(sizeof(struct thread));


    // Set the thread attributes
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

    /* printf("stacksize = %d\n", stacksize);
    printf("res_size = %d\n", res_size); */

    // Set up the new thread
    t->state = RUNNABLE;
    t->func = func;
    t->arg = arg;
    t->tid = tidalloc();
    t->tcontext.ra = (uint64)func;

    /* printf("tcreate t->state = %d\n", t->state);
    printf("tcreate t->tid = %d\n", t->tid); */

    // Allocate memory for the thread's stack and store the highest address in context.sp
    stack = (uint64)malloc(stacksize);
    t->tcontext.sp = stack + stacksize;

    // Allocate memory for the thread's result
    if(res_size != 0)
        t->result = malloc(res_size);
    else
        t->result = 0;

    // Add the thread to the threads array
    *thread = t;

    /* printf("tcreate &t dir = %d\n", &t);
    printf("tcreate t dir = %d\n", t);
    printf("tcreate *thread = %d\n", *thread); */
    struct thread *aux = threads;
    aux++;
    /* printf("tcreate thread  = %d\n", aux->tid);
    printf("\n----------\n"); */
}

int tjoin(int tid, void *status, uint size)
{
    // TODO: Wait for the thread with TID to finish. If status and size are non-zero,
    // copy the result of the thread to the memory, status points to. Copy size bytes.
    return 0;
}

void tyield()
{
    //printf("tyield called\n");
    // TODO: Implement the yielding behaviour of the thread
    //current_thread->state = RUNNABLE; 
    tsched();
}

uint8 twhoami()
{
    // TODO: Returns the thread id of the current thread
    printf("current running id = %d/n",current_thread->tid);
    return current_thread->tid;
    return 0;
}
