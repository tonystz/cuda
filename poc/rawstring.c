#include <stdio.h>

void findIPPort(char *out_gpu){
    char dup[521];
    char white[]={' ','\t','\n','\v','\f','\r'};
    char ipaddr[16]={0};
    char port[4]={0};
    int fip=0;
    int fport=0;
    
    for(int i=0;out_gpu[i] != '\0';i++){
    if (fip ==0 && (out_gpu[i] == white[0] || out_gpu[i]== white[1])){
        dup[i]='\0';
        fip=1;
    }
    if(fip == 0){
        ipaddr[i]=out_gpu[i];
    }

    if(fport ==0 && i>16 && out_gpu[i-2]=='"'&& (out_gpu[i-1] == white[0] || out_gpu[i-1]== white[1])){
        port[0]= out_gpu[i];
        port[1]=out_gpu[i+1];
        port[2]=out_gpu[i+2];
        fport=1;
        // printf("test:%s %s\n",dup,port);
    }
     dup[i]=out_gpu[i];
    }
    // printf("dup:%s\n",dup);
    printf("ipaddr:[%s] port:[%s]\n",ipaddr,port);
}

int main(){

    //char *out_gpu="183.212.185.121 - - [12/Feb/2022:16:22:42 +0800] \"GET / HTTP/1.1\" 200 4534";
    char *out_gpu="::1 - - [12/Feb/2022:16:17:16 +0800] \"GET / HTTP/1.1\" 200 14";
    FILE* filePointer;
    int bufferLength = 255;
    char buffer[bufferLength]; /* not ISO 90 compatible */

    filePointer = fopen("access.log", "r");

    while(fgets(buffer, bufferLength, filePointer)) {
        // printf("%s", buffer);
        findIPPort(buffer);
    }

    fclose(filePointer);
    
    
    return 0;
}
