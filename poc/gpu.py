#!python 
import pycuda.driver as cuda
import pycuda.autoinit
from pycuda import gpuarray
import numpy as np


mandel_mod = pycuda.driver.module_from_file('./kernel.ptx')
check_log = mandel_mod.get_function('check_log')

a=np.loadtxt('/content/pre.log', delimiter=' ', dtype=np.string_,converters={0:lambda v:v+b'\0'})


na=np.delete(a,0)
NUM_ROW=479
NUM_COL=2383
'''
na=a
NUM_ROW=2
NUM_COL=40
'''

na.reshape((NUM_ROW,NUM_COL))
print('shape:',na.shape,na.size,na.dtype)
print(na,na.data)

na_gpu = gpuarray.to_gpu(na)
out_gpu = gpuarray.empty_like(na_gpu)
check_log(na_gpu,out_gpu,block=(NUM_ROW,1,1),grid=(1,1,1))

#import sys
#np.set_printoptions(threshold=sys.maxsize)
#print('out_gpu:',out_gpu.get())