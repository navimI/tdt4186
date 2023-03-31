#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int addr,pid,va;
    if (argc < 2)
    {
        printf("Usage: %s virtual_address [pid]\n", argv[0]);
        exit(1);
    }

    addr = atoi(argv[1]);
    pid = -1;

    if (argc > 2)
    {
        pid = atoi(argv[2]);
    }

    va = va2pa(addr, pid);

    printf("0x%x\n", va);

    exit(0);

    
}