"""
Time CalBlitz alignment in Python
"""

import h5py
import calblitz as cb
import time
import pylab as pl
import numpy as np
from time import time

#%%
filename = 'demoMovie.tif'
max_shift_h = 10;
max_shift_w = 10;
frames_to_skip = 4;
frameRate=15.62;
start_time=0;
#%% load and motion correct movie (see other Demo for more details)
m=cb.load(filename, fr=frameRate,start_time=start_time);

print 'motion correcting...'
t1 = time()
m,shifts, xcorrs, template = m.motion_correct(max_shift_w=max_shift_w,
											max_shift_h=max_shift_h, 
											num_frames_template=300, 
											template=None,
											method='opencv')
max_h, max_w = np.max(shifts,axis=0)
min_h, min_w = np.min(shifts,axis=0)
t2 = time()
print('python motion_correct:  %0.3fs' % (t2 - t1))
m = m.crop(crop_top=max_h,crop_bottom=-min_h+1,crop_left=max_w,crop_right=-min_w,crop_begin=0,crop_end=0)

print 'saving motion corrected movie...'
m.save('demoTiff_mc.tif')
t3 = time()
print('python saving time:  %0.3fs' % (t3 - t2))