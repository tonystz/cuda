import time

g_file='/content/drive/MyDrive/access.log'
g_file_pred='pre'+g_file
def step_1_pre_process():
    skipline=0
    with open(g_file,'r') as fr,open(g_file_pred,'w') as fw:
        for line in fr:
            t=line.split(' ')
            if len(t) !=10:
                skipline+=1
                continue
            fw.write(f'{t[0]}-{t[8]}\n')
    print('skipline',skipline)

s=time.time()
step_1_pre_process()
print('[step0]preprocess raw log:',time.time()-s)