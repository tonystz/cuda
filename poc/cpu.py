import numpy as np
import time

s=time.time()
a=np.loadtxt(g_file_pred, delimiter=' ', dtype=np.string_,converters=lambda v:v+b'\0')
print('[step1]reload data:',time.time()-s,a.shape,a.dtype,a.size,a)

s=time.time()
filter_404=[i for i in a if i.decode().split('-')[1]=='404']
print('[step2]404 data filter:',time.time()-s,len(filter_404))

def step3_check(filter_404,threshhold=500):
    r={}
    for i in filter_404:
        t=i.decode().split('-')
        if t[0] in r:
            r[t[0]] +=1
        else:
            r[t[0]] = 1
    return [i for i,c in r.items() if c>threshhold]
s=time.time()
r=step3_check(filter_404)
print('[step3]check result:',time.time()-s,r)
