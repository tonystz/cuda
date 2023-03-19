#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void findIPPortFromRaw(char *in_gpu){
    char dup[521];
    char white[]={' ','\t','\n','\v','\f','\r'};
    char ipaddr[16]={0};
    char port[4]={0};
    int fip=0;
    int fport=0;
    
    for(int i=0;in_gpu[i] != '\0';i++){
    if (fip ==0 && (in_gpu[i] == white[0] || in_gpu[i]== white[1])){
        dup[i]='\0';
        fip=1;
    }
    if(fip == 0){
        ipaddr[i]=in_gpu[i];
    }

    if(fport ==0 && i>16 && in_gpu[i-2]=='"'&& (in_gpu[i-1] == white[0] || in_gpu[i-1]== white[1])){
        port[0]= in_gpu[i];
        port[1]=in_gpu[i+1];
        port[2]=in_gpu[i+2];
        fport=1;
        // printf("test:%s %s\n",dup,port);
    }
     dup[i]=in_gpu[i];
    }
    // printf("dup:%s\n",dup);
    printf("ipaddr:[%s] port:[%s]\n",ipaddr,port);
}

int find404AddressFromPre(char*in_gpu, char out_addr[]){
     int find=0;
     for(int i=0;in_gpu[i] !=0;i++){
        if (in_gpu[i]=='-' && in_gpu[i+1]=='4' && in_gpu[i+2] == '0' && in_gpu[i+3] == '4'){
            out_addr[i]=0;
            find=1;
            break;
        }
        out_addr[i] = in_gpu[i];
     }
     if (!find){
        out_addr[0]=0;
     }

     return find;
}


#define LOG_LEN 44
#define ROW_NUM 479
#define COL_NUM 2383
typedef struct{
      char ipAddr[LOG_LEN];
      short cnt;
}ST_IPAddr;

char* nploadtxt(char *fpath){
    char *nparray=(char*)malloc(ROW_NUM*COL_NUM*LOG_LEN);
    char *lineBuff=NULL;
    size_t  lineLen=0;
    char *pos;
    
    int rowStartIndex=0;
    int colStartIndex=0;
    FILE* fp = fopen(fpath, "r");
    int readline_size=0;

        for(int r=0;r<ROW_NUM;r++){
            rowStartIndex=r*COL_NUM;
            for(int c=0;c<COL_NUM;c++){
                colStartIndex=c*COL_NUM+rowStartIndex;
                if((readline_size = getline(&lineBuff, &lineLen, fp)) != -1){
                     //printf("%s\n",lineBuff);
                     //trim newline
                     if ((pos=strchr(lineBuff, '\n')) != NULL){
                        *pos = '\0';
                     }
                     strcpy(nparray+colStartIndex,lineBuff);
                }else{
                    printf("enf of file\n");
                }
               
            }
        }
    if(lineBuff)free(lineBuff);
    if(fp)fclose(fp);
    return nparray;
}
void npShowArray(char*array, int rindex){
    int rowStartIndex=0;
    int colStartIndex=0;

    for(int r=0;r<ROW_NUM;r++){
        rowStartIndex=r*COL_NUM;
        for(int c=0;c<COL_NUM;c++){
            colStartIndex=c*COL_NUM+rowStartIndex;
            printf("%s ",array+colStartIndex);
        }
        if(r== rindex){
            printf("\n");
            break;
        }
    }
}

void kernel(char *in_gpu, char*out_gpu){

    int rowStartIndex=0;
    int colStartIndex=0;
    char ipaddr[LOG_LEN];
    //ST_IPAddr res[ROW_NUM][COL_NUM];

    int last_find_iadd_in_row=0;
    int all_find_iadd_in_row=0;
    for(int r=0;r<ROW_NUM;r++){
        rowStartIndex=r*COL_NUM;
        last_find_iadd_in_row=0;
        for(int c=0;c<COL_NUM;c++){
            colStartIndex=c*COL_NUM+rowStartIndex;
            //printf("%s ",in_gpu+colStartIndex);
            if(find404AddressFromPre(in_gpu+colStartIndex,ipaddr)){
                strcpy(out_gpu+rowStartIndex+last_find_iadd_in_row*LOG_LEN,ipaddr);
                //strcpy(res[r][c].ipAddr,ipaddr);
                //res[r][c].cnt =0;
                //printf("r[%d]%s, find=%d\n",r,out_gpu+rowStartIndex,last_find_iadd_in_row);
                last_find_iadd_in_row++;
            }
        }
        all_find_iadd_in_row +=last_find_iadd_in_row;
    }
    printf("total find:%d\n",all_find_iadd_in_row);

    for(int r=0;r<ROW_NUM;r++){
        for(int c=0;c<COL_NUM;c++){
        //printf("thread[%d][%d] addr:%s = %d\\n",r,c,res[r][c].ipAddr,res[r][c].cnt);
        }
    }
}
int main(){

    /*char *in_gpu="183.212.185.121 - - [12/Feb/2022:16:22:42 +0800] \"GET / HTTP/1.1\" 200 4534";
    char *in_gpu="::1 - - [12/Feb/2022:16:17:16 +0800] \"GET / HTTP/1.1\" 200 14";
    char *filepath="access.log";
    */
    // ST_IPAddr res[ROW_NUM][COL_NUM];
    printf("sie %u %ld\n", COL_NUM*ROW_NUM/1024,sizeof(ST_IPAddr));
    printf("sie %lu\n", COL_NUM*ROW_NUM*sizeof(ST_IPAddr)/1024/1024);
    //ST_IPAddr res[COL_NUM];

//     //for(int r=0;r<ROW_NUM;r++){
//         for(int c=0;c<COL_NUM;c++){
//             strcpy(res[0][c].ipAddr,"hello");
//         }
//     //}
//    // for(int r=0;r<ROW_NUM;r++){
//         for(int c=0;c<COL_NUM;c++){
//             printf("%s\n",res[0][c].ipAddr);
//         }
//     //}
   
    exit(0);
    char *in_gpu="183.212.185.121-2";
    char *filepath="preaccess.log";
    
    char *npa=nploadtxt(filepath);
   

    char *npOut=(char*)malloc(ROW_NUM*COL_NUM*LOG_LEN);
    kernel(npa,npOut);
    npShowArray(npOut,1);
    if(npa)free(npa);
    if(npOut)free(npOut);



    // FILE* fp=0;
    // int bufferLength = 255;
    // char buffer[bufferLength]; /* not ISO 90 compatible */

    // char ipaddr[LOG_LEN];
    // fp = fopen(filepath, "r");
    // while(fgets(buffer, bufferLength, fp)) {
    //     // printf("%s", buffer);
    //     // findIPPortFromRaw(buffer);
    //     if(find404AddressFromPre(buffer,ipaddr)){
    //         printf("404 ipaddr:[%s]\n",ipaddr);
    //     }
    // }

    // if(fp)fclose(fp);
    
    
    return 0;
}
