"""
Debug Julia scripts
"""

include("sandbox.jl")
fn = "images/demoMovie.h5"
mov = load_movie(fn)
# generate template
n = 4
sample = mov[:,:,1:n:end]
template = median3d(sample)

p = 10
k = 1
temp = template[p+1:end-p,p+1:end-p,k]
frame = mov[:,:,k]
blockmatches, max_r, xc = ImageRegistration.get_max_xc_vector(temp, frame)