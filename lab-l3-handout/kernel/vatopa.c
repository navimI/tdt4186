#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if ( argc <= 1 )
    {
        printf("Usage: vatopa virtual_address [pid]");
        exit(1);
    }
    
    int addr = atoi(argv[1]);
    int pid = -1;
    if ( argc >= 3 )
    {
        pid = atoi(argv[2]);
    }
    int pa = va2pa( addr, pid );
    printf( "0x%x\n", pa );
    
    exit(0);
}
