"""
T Macrina
151111

Functions to improve the CalBlitz Python alignments using Julia
"""

using ImageRegistration
using Images
using ImageView
using FixedPointNumbers
using HDF5

fn = "demoMovie.tif"

function load_movie(fn)
	if fn[end-2:end] == "h5"
		return h5read(fn, "mov")
	else
		return reinterpret(UInt16, data(Images.load(fn)))
	end
end

function load_movie_slice(fn, slice)
	return h5read(fn, "mov", slice)
end

function normalize(mov)
	m = reinterpret(UFixed16, mov)
	return reinterpret(UInt16, m/maximum(m))
end

function view_movie(mov)
	opts = Dict(:pixelspacing => [1,1], :xy => ["y","x"])
	img = Image(1-convert(Array{UFixed16}, mov), timedim=3)
	return view(img; opts...)
end

function save_movie(fn, mov)
  assert(typeof(mov) == Array{UInt16,3})
  f = h5open(fn, "w")
  @time f["mov", "chunk", (32,32,1)] = mov
  close(f)
end