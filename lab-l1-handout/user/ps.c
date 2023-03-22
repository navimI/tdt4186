#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    if(argc < 2)
    {
        scps();
        exit(0);
    }
    else
    {
        printf("no arguments allowed\n");
        printf("Usage: %s", argv[0]);
        exit(1);
    }
}
