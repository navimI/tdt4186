#include "kernel/types.h"
#include "user/user.h"

void
hello(int n, char *user)
{
    if(n == 0)
    {
        printf("Hello World\n");
    }
    else
    {
        printf("Hello %s, nice to meet you!\n", user);
    }


    
}

int
main(int argc, char *argv[])
{

    if(argc < 2){
        hello(0,"");
    }
    else{
        hello(1,argv[1]);
    } 
    exit(0);
}