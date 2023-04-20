#include "kernel/types.h"
#include "user.h"
#define LIB_PREFIX "[UTHREAD]: "
#define ulog() printf("%s%s\n", LIB_PREFIX, __FUNCTION__)
#define PGSIZE 4096 // bytes per page

struct thread threads[MAXTHREAD];

struct lock threads_lock;
struct thread *current_thread;
uint32 thread_count;


void tentry (void){
    //wrapp thread function
    current_thread->result = current_thread->func(current_thread->arg);
    current_thread->state = ZOMBIE;
    //yield thread function
    tyield();
    
}

void
threadinit()
{
    struct thread *t;
    //initialize thread counter
    thread_count = 0;
    //initialize threads and set the state to UNUSED
    for (t = threads; t < &threads[MAXTHREAD]; t++)
    {
        t->state = UNUSED;
    }
}

void
tsave(struct thread *thread)
{
    struct thread *t;
    //find the first unused thread and set it to RUNNING
    for (t = threads; t < &threads[MAXTHREAD]; t++)
    {

        if (t->state == UNUSED)
        {
            // Set up the new thread
            t->tid = tidalloc();
            t->state = RUNNING;
            t -> stacksize = PGSIZE;
            // set the thread dir of the thread table to the current thread dir
            thread = t;

            // set the new thread to the current thread
            current_thread = t;
            
            break;
        }
        
       
    }
}

void tsched(void)
{
    struct context *old, *new;
    old = 0;
    new = 0;
    int id = 0;

    // Look for a runnable thread in a round-robin schedule
    
    for(int i = 0; i < MAXTHREAD; i++)
    {
        // Take the thread with the next tid in the threads array
        id = 0;

        struct thread *t = threads + ((current_thread->tid + i) % MAXTHREAD);
    
        printf("");
 
        if(t->state == RUNNABLE && t->tid != current_thread->tid){
            // Set the state of the thread to RUNNING and setup the context
            t->state = RUNNING;
            id = 1;
            old = &current_thread->tcontext;

            new = &t->tcontext;

            current_thread = t;
            break;
            
        }
    
        
        
    }
    // If the is exited successfully, switch to the new thread
        if (id && (old != 0 && new != 0)) tswtch(old, new);

}

uint8 tidalloc()
{
    // Generate a new id for a thread
    uint8 tid;
    tid = thread_count;
    thread_count++;
    return tid;
}


void tcreate(struct thread **thread, struct thread_attr *attr, void *(*func)(void *arg), void *arg)
{
    uint32 stacksize = 4096;
    uint32 res_size = 0;
    uint64 stack;

    struct thread *t;
    // Find the first unused thread in the threads array
    for (t = threads; t < &threads[MAXTHREAD]; t++)
    {
        if (t->state == UNUSED)
        {
            goto found;
        }
     
    }
    

found:

   // If attr is non-zero, set the stacksize and res_size to the values in attr
   // Otherwise, use the default values
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
    t->state = RUNNABLE;
    t->func = func;
    t->arg = arg;
    t->tid = tidalloc();
    t->tcontext.ra = (uint64)tentry;
    t->stacksize = stacksize;


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


   
}



int tjoin(int tid, void *status, uint size)
{
    // Find the thread with the given tid
    struct thread *t;
    for (t = threads; t < &threads[MAXTHREAD]; t++)
    {

        if (t->tid == tid)
        {
            break;
        }
     
    }
    if (t->tid != tid) {
        return -1; // Thread not found
    }

    // Wait for the thread to finish
    while (t->state != ZOMBIE) {
        tyield();
    }

    // If status and size are non-zero, copy the result of the thread to the memory that status points to
    if (status != 0 && size > 0) {
        memcpy(status, t->result, size);
    }

    // Free the resources used by the thread
    tfree(t, size);

    return 0;
}

void tfree(struct thread *t, uint size)
{
     // Free the memory used by the thread's stack
    uint64 stack = t->tcontext.sp - t->stacksize;
    free((void *)stack);

    // Free the memory used by the thread's result
    if (t->result != 0) {
        free(t->result);
    }

    // Set the thread's state to UNUSED
    t->state = UNUSED;
}

void tyield()
{
    // If the thread isn't yield due to it's finished, set the thread to runnable
    if (current_thread->state != ZOMBIE) {
    current_thread->state = RUNNABLE;}
    
    // Switch to another thread
    tsched();
    
}

uint8 twhoami()
{
    // Return the current thread id
    return current_thread->tid;
    
}
