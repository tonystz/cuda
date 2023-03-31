#!python 
import pycuda.driver as cuda
import pycuda.autoinit
from pycuda import gpuarray
import numpy as np


mandel_mod = pycuda.driver.module_from_file('./kernel.ptx')
check_log = mandel_mod.get_function('check_log')

a=np.loadtxt('/content/pre.log', delimiter=' ', dtype=np.string_,converters={0:lambda v:v+b'\0'})


na=np.delete(a,0)
NUM_ROW=2383
NUM_COL=479
'''
na=a
NUM_ROW=2
NUM_COL=40
'''

print(cuda.Context.get_limit(cuda.limit.MALLOC_HEAP_SIZE))
cuda.Context.set_limit(cuda.limit.MALLOC_HEAP_SIZE, 60*1024*1024)
print(cuda.Context.get_limit(cuda.limit.MALLOC_HEAP_SIZE))

na.reshape((NUM_ROW,NUM_COL))
print('shape:',na.shape,na.size,na.dtype)
print(na,na.data)

na_gpu = gpuarray.to_gpu(na)
out_gpu = gpuarray.empty_like(na_gpu)
check_log(na_gpu,out_gpu,block=(1024,1,1),grid=(3,1,1))

#import sys
#np.set_printoptions(threshold=sys.maxsize)
#print('out_gpu:',out_gpu.get())

def filter(array):
  r={}
  for i in array:
    if len(i) == 0 : continue
    ip,c=i.decode().split('#')
    if ip in r:
        r[ip] += int(c)
    else:
        r[ip] = int(c)
  return [i for i,c in r.items() if c>500]
print(filter(out_gpu.get()))