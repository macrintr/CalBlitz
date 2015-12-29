# -*- coding: utf-8 -*-
"""
Test Python & Julia alignment
"""

#%%
import h5py
import calblitz as cb
import time
import pylab as pl
import numpy as np
# import numpy.fft as fft
from skimage.feature import match_template
import cv2

# """
# Courtesy https://mail.scipy.org/pipermail/scipy-dev/2013-December/019498.html
# """
# # 2D convolution using the convolution's FFT property
# def conv2(a,b):
#     ma,na = a.shape
#     mb,nb = b.shape
#     return fft.ifft2(fft.fft2(a,[2*ma-1,2*na-1])*fft.fft2(b,[2*mb-1,2*nb-1]))

# # compute a normalized 2D cross correlation using convolutions
# # this will give the same output as matlab, albeit in row-major order
# def normxcorr2(b,a):
#     c = conv2(a,np.flipud(np.fliplr(b)))
#     a = conv2(a**2, ones(b.shape))
#     b = sum(b.flatten()**2)
#     c = c/sqrt(a*b)
#     return c

#%%
filename='demoMovie.tif'
frameRate=15.62;
start_time=0;

#%%
filename_py=filename[:-4]+'.npz'
filename_hdf5=filename[:-4]+'.hdf5'
filename_mc=filename[:-4]+'_mc.npz'

#%% load movie
print 'loading movie...'
m=cb.load(filename, fr=frameRate,start_time=start_time);

# Create template
min_val=np.min(np.mean(m,axis=0))
num_frames_template=10e7/(512*512)

# sometimes it is convenient to only consider a subset of the movie when computing the median
frames_to_skip=np.round(np.maximum(1,m.shape[0]/num_frames_template))
submov=m[::frames_to_skip,:]
# create template with portion of movie
template = np.nanmedian(submov,axis=0)

max_shift_h=10;
max_shift_w=10;
n_frames_,h_i, w_i = m.shape
ms_w = max_shift_w
ms_h = max_shift_h
temp = template[ms_h:h_i-ms_h,ms_w:w_i-ms_w].astype(np.float32)
h,w = temp.shape 

frame = np.asanyarray(m[0,:,:], dtype=np.float32)
# TM_CCORR_NORMED doesn't subtract the image means
# res = cv2.matchTemplate(frame,temp,cv2.TM_CCORR_NORMED)             
# top_left = cv2.minMaxLoc(res)[3]

# res = normxcorr2(frame, temp)
res = match_template(frame, temp)
top_left = cv2.minMaxLoc(res)[3]
# ij = np.unravel_index(np.argmax(res), res.shape)
# x, y = ij[::-1]


# shifts,xcorrs=submov.extract_shifts(max_shift_w=max_shift_w, max_shift_h=max_shift_h, template=templ, method=method)  #
# submov.apply_shifts(shifts,interpolation='cubic',method=method)
# template=(np.nanmedian(submov,axis=0))
# shifts,xcorrs=m.extract_shifts(max_shift_w=max_shift_w, max_shift_h=max_shift_h, template=template, method=method)  #
# m=m.apply_shifts(shifts,interpolation='cubic',method=method)
# template=(np.median(m,axis=0)) 