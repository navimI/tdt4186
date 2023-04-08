// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"


uint64 MAX_PAGES = 0;
uint64 FREE_PAGES = 0;

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
    struct run *next;
};

struct
{
    struct spinlock lock;
    struct run *freelist;
} kmem;

char shared_mem[(PHYSTOP-KERNBASE)/PGSIZE]; // counter for the processes pages


// We initialize the copy on write shared memory table to 0
void
shared_mem_init(void)
{
  for(int i = 0; i < (PHYSTOP-KERNBASE)/PGSIZE; i++)
    shared_mem[i] = 0;
}

// Return the number of shared pages

uint64
getsharedmem(void *pa)
{
    return shared_mem[SHARED((uint64)pa)];

}


// Increase the shared memory counter
void
increasesharedmem(void *pa)
{
  shared_mem[SHARED((uint64)pa)]++;
}

// Decrease the shared memory counter
// If the counter is 0 call the free function
void
decreasesharedmem(void *pa)
{
  if (getsharedmem(pa) > 0)
  {
    shared_mem[SHARED((uint64)pa)]--;
  }
  freesharedmem(pa);
  
}

//Check if the page is no longer shared
//If it is not shared, free the page

void
freesharedmem(void *pa)
{
  if (getsharedmem(pa) == 0)
  {

      // Fill with junk to catch dangling refs.
      memset(pa, 1, PGSIZE);

      struct run *r = (struct run *) (pa);

      acquire(&kmem.lock);
      r->next = kmem.freelist;
      kmem.freelist = r;
      FREE_PAGES++;
      release(&kmem.lock);
    }
}

void kinit()
{
    initlock(&kmem.lock, "kmem");
    freerange(end, (void *)PHYSTOP);
    // Initialize the shared memory table
    shared_mem_init();
    MAX_PAGES = FREE_PAGES;
}

void freerange(void *pa_start, void *pa_end)
{
    char *p;
    p = (char *)PGROUNDUP((uint64)pa_start);
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    {
        kfree(p);
    }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    if (MAX_PAGES != 0)
        assert(FREE_PAGES < MAX_PAGES);
    //struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
        panic("kfree");

    // decrease the shared memory counter
    // If the counter is 0, free the page
    
    decreasesharedmem(pa);

   
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    assert(FREE_PAGES > 0);
    struct run *r;

    acquire(&kmem.lock);
    r = kmem.freelist;
    if (r)
        kmem.freelist = r->next;
    release(&kmem.lock);

    if (r){
        memset((char *)r, 5, PGSIZE); // fill with junk
        increasesharedmem((void *)r);
        FREE_PAGES--;
        }
    return (void *)r;
}
