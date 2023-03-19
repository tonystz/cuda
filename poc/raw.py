import time
import os

g_file='/content/drive/MyDrive/access.log'
if os.path.exists(g_file):
    print("use google drive raw log")
else:
    g_file="../cuda/poc/access.log"
    print("use sample raw log")
g_file_pred='pre.log'
def step_1_pre_process():
    skip_line=0
    total_line=0
    with open(g_file,'r') as fr,open(g_file_pred,'w') as fw:
        for line in fr:
            total_line +=1
            t=line.split(' ')
            if len(t) !=10:
                skip_line+=1
                continue
            fw.write(f'{t[0]}-{t[8]}\n')
    return total_line,skip_line

s=time.time()
total_line,skip_line=step_1_pre_process()
print(f'[step0]preprocess raw log: total={total_line} skip={skip_line}',time.time()-s)