extern "C" {

 #include <stdlib.h>

 const int COL_NUM=2383;
 const int ROW_NUM=479;
 const int LOG_LEN=44;
 const int THRESHOLD=500;
 
 /* for test
 const int COL_NUM=40;
 const int ROW_NUM=2;
 const int LOG_LEN=20;*/
    typedef struct{
      char ipAddr[LOG_LEN];
      int cnt;
    }ST_IPAddr;
    __device__ void mystrcpy(char *out,char *in){
      int i=0;
      for(i=0;in[i]!=0;i++){
        out[i] = in[i];
      }
      out[i]=0;
    }
__device__ char* myitoa(int i, char b[]){
    char const digit[] = "0123456789";
    char* p = b;
    if(i<0){
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    }while(shifter);
    *p = '\0';
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
        i = i/10;
    }while(i);
    return b;
}

__device__ int myAtoi(char* str)
{
    // Initialize result
    int res = 0;
 
    for (int i = 0; str[i] != '\0'; ++i)
        res = res * 10 + str[i] - '0';
 
    // return result.
    return res;
}

 __device__ int splitStrInt(char *s, char addr[]){
    int i=0;
    while(s[i] !=0){
        if(s[i]=='#')break;
        addr[i]=s[i];
        i++;
    }
    addr[i]=0;
    return myAtoi(s+i+1);
 }
 __device__ char* mergStrInt(char*s, int n, char a[]){
    int i=0;
    while(s[i]!=0){
        a[i]=s[i];
        i++;
    }
    a[i]='#';
    i++;
    char buff[512];
    myitoa(n,buff);
    int j=0;
    while(buff[j] !=0){
        a[i+j]=buff[j];
        j++;
    }
    a[i+j]=0;
    return a;
 }
    __device__  int find_404_ipaddr(char*in_gpu,char outAddr[],int rowStartIndex ,int strStartIndex){
        int index=0;
        for(int i = 0; i<LOG_LEN; i++){
            index = strStartIndex+i+rowStartIndex;
            if (in_gpu[index]=='-'){
              if (in_gpu[index+1] == '4' && in_gpu[index+2] == '0' && in_gpu[index+3] == '4'){
                 outAddr[i]=0;
                 return 1;
              }
            }
            outAddr[i]=in_gpu[index];
        }
        return 0;
    }
   
    __device__ int strEqua(char *s1,char *s2){
      if((*s1==0)&&(*s2 !=0)|| (*s1 !=0 && *s2==0))return 0;
      for(int i=0;s1[i]!=0 && s2[i] !=0;i++){
        if (s1[i] != s2[i]){
          return 0;
        }
      }
      return 1;
    }
    __device__ void pushDedup(ST_IPAddr*dedup,char *ipAddr,int*dedup_cnt){
      int c=0;
      for(;c<COL_NUM;c++){
        if(strEqua(dedup[c].ipAddr,ipAddr)){
          dedup[c].cnt ++;
          break;
        }else{
          if(dedup[c].ipAddr[0] == 0){
            mystrcpy(dedup[c].ipAddr,ipAddr);
            dedup[c].cnt = 1;
            (*dedup_cnt)++;
            break;
          }
        }
      }
    }

    __device__  ST_IPAddr *getHeapMem(){
      /*
      https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html?highlight=dynamic#heap-memory-allocation
      need set the limit, so hear for ROW_NUM=40
      */ 
      int mem_size=ROW_NUM*COL_NUM*sizeof(ST_IPAddr);
      ST_IPAddr *heap = (ST_IPAddr *)malloc(mem_size);

      memset(heap, 0, mem_size);
      printf("Thread %d got pointer: %p heapsize=%d\n", threadIdx.x, heap,mem_size);
      //free(heap);
      return heap;
    }

    __device__ void showHeap(ST_IPAddr *heap,int dedup_cnt){
      //print heap memory
      printf("Thread:%d Total:%d\n", threadIdx.x, dedup_cnt);
      for(int i=0;i<dedup_cnt;i++){
        if(heap[i].cnt>THRESHOLD){
            printf("[showHeap]Thread %d addr: %s=%d\n", threadIdx.x, heap[i].ipAddr,heap[i].cnt);
        }
        
      }
    }

    __device__ void pushDedupSummary(ST_IPAddr*dedup, ST_IPAddr *st,int*dedup_cnt){
      int c=0;
      for(;c<COL_NUM;c++){
        if(strEqua(dedup[c].ipAddr,st->ipAddr)){
          dedup[c].cnt += st->cnt;
          break;
        }else{
          if(dedup[c].ipAddr[0] == 0){
            mystrcpy(dedup[c].ipAddr,st->ipAddr);
            dedup[c].cnt = st->cnt;
            (*dedup_cnt)++;
            break;
          }
        }
      }
    }

    __device__ void summary(char*out_gpu, ST_IPAddr *heap){
      //int idx = threadIdx.x + blockIdx.x * blockDim.x;
      int rowOffset=COL_NUM*LOG_LEN;
      char tmpBuff[LOG_LEN];
      int heap_dedup_cnt=0;
       for(int r=0;r<ROW_NUM;r++){
         for(int c=0;c<COL_NUM;c++){
           if(out_gpu[r*rowOffset+c*LOG_LEN]!=0){
              //printf("thread[%d]offset=%d r=%d,c=%d  find:%s\n",idx,r*rowOffset+c*LOG_LEN,r,c,out_gpu+r*rowOffset+c*LOG_LEN);
              
              //de-dedup global
              
              ST_IPAddr st;
              st.cnt=splitStrInt(out_gpu+r*rowOffset+c*LOG_LEN,tmpBuff);
              mystrcpy(st.ipAddr,tmpBuff);
              pushDedupSummary(heap,&st,&heap_dedup_cnt);
           }
         }
       }

       showHeap(heap,heap_dedup_cnt);

    }

    __global__ void check_log(char*in_gpu,char* out_gpu)
    { 
      ST_IPAddr dedup[COL_NUM];
      int dedup_cnt=0;    
      
      int idx = threadIdx.x + blockIdx.x * blockDim.x;
      // printf("ST_IPAddr size: %lu\n",sizeof(ST_IPAddr));
      //printf("index: threadIdx.x=%d blockIdx.x=%d  blockDim.x=%d \n",threadIdx.x,blockIdx.x,blockDim.x);
      //printf("thread id: [%d]  get str:%s  strlen=%d \n",idx,in_gpu+LOG_LEN+1, LOG_LEN);

      // string len is 6
      char sub[LOG_LEN+1];
      int strStartIndex=0;//string start locaion
      int rowOffset=COL_NUM*LOG_LEN;
      if(idx > ROW_NUM){
        printf("[ERROR]idx=%d, rowCnt=%d, we want one thread process all one rows'data .please tune",idx,ROW_NUM);
      }
      
      int rowStartIndex=rowOffset*idx;
      out_gpu[rowStartIndex]=0;
      //int all_find_iadd_in_row=0;
      for(int c=0;c<COL_NUM;c++){
        strStartIndex=c*LOG_LEN;
        if (find_404_ipaddr(in_gpu,sub,rowStartIndex,strStartIndex)){
          //printf("thread[%d] rowStartIndex=%d, substring:%s strStartIndex %d\n",idx,rowStartIndex,sub,strStartIndex);
          
          //copy 404 to out_gpu
          //mystrcpy(out_gpu+rowStartIndex+dedup_cnt*LOG_LEN,sub);
          //mystrcpy(dedup[c].ipAddr,sub);
          pushDedup(dedup,sub,&dedup_cnt);
          //printf("rowStartIndex=%d,c=%d  sub=%s add=%d dedup_cnt=%d \n",rowStartIndex,c,sub,dedup[c].cnt,dedup_cnt);
          
        }
      }

      //int rowOffsetForInt=COL_NUM*4;
      __syncthreads();
      char tmpBuff[LOG_LEN*2];
      for(int c=0;c<dedup_cnt;c++){
         mergStrInt(dedup[c].ipAddr,dedup[c].cnt,tmpBuff);
         mystrcpy(out_gpu+rowStartIndex+LOG_LEN*c,tmpBuff);
         //memcpy(out_int_gpu+idx*rowOffsetForInt+c*4, &dedup[c], sizeof(ST_IPAddr));
         //out_int_gpu[idx*rowOffsetForInt+c*4]=dedup[c].cnt;
         //printf("thread[%d] rowStartIndex[%d][%d] addr:%s = %d\n",idx,rowStartIndex,c,dedup[c].ipAddr,dedup[c].cnt);
      }
      //printf("thread[%d] addrCnt:%d\n",idx,dedup_cnt);
      __syncthreads();

      if(idx ==0 ){
        // in global mem to dedup
        ST_IPAddr *heap=getHeapMem();
        summary(out_gpu,heap);
        if(heap)free(heap);
      }
    }
    
}
