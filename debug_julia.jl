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
frame = mov[p:end-p,p:end-p,k]
blockmatches, max_r, xc = get_max_xc_vector(frame, template)