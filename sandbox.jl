# """
# T Macrina
# 151111

# Functions to improve the CalBlitz Python alignments using Julia
# """

using ImageRegistration
using Images
using ImageView
using FixedPointNumbers
using HDF5

include("moviecontrols.jl")

fn = "images/k26_v1_176um_target_pursuit_002_013.h5"
fn = "images/M_FLUO.h5"
fn = "images/demoMovie.h5"
fn = "demoMovie_mc.h5"

function load_movie(fn, signed=false)
  println(fn)
	if fn[end-1:end] == "h5"
		return h5read(fn, "mov")
	else
    return convert(Array{Float64}, data(Images.load(fn)))
	end
end

function load_movie_slice(fn, slice)
	return h5read(fn, "mov", slice)
end

function normalize(mov)
	mov = mov .+ minimum(mov)
	return mov ./ maximum(mov)
end

function view_movie(mov)
	opts = Dict(:pixelspacing => [1,1], :xy => ["y","x"])
	img = Image(mov, timedim=3)
	return view(img; opts...)
end

function save_movie(fn, mov)
  assert(typeof(mov) == Array{Float64,3})
  f = h5open(fn, "w")
  @time f["mov", "chunk", (32,32,1)] = mov
  close(f)
end

function median3d{T}(v::AbstractArray{T})
  m = zeros(T, size(v)[1:2]...)
  for i=1:size(v,1), j=1:size(v,2)
    m[i,j] = median(v[i,j,:])
  end
  return m
end

function create_params(mesh_dist, block_size, search_r, min_r)
  return Dict(  "mesh_dist" => mesh_dist, 
                "block_size" => block_size, 
                "search_r" => search_r, 
                "min_r" => min_r)
end

function align(mov)
  template = generate_template(mov, 10)
  params = create_params(16, 8, 8, 0)
  return align_stack(mov, template, params)
end

function generate_template(mov, n=20)
  indices = randperm(size(mov,3))[1:n]
  sample = mov[:,:,indices]
  sample_template = median3d(sample)
  params = create_params(16, 8, 8, 0)
  template, offsets, matches = align_stack(sample, sample_template, params)
  return template[:,:,1]
end

function align_stack{T}(mov::Array{T}, template, params)
  p = 3
  matches = []
  frames = []
  offsets = []
  for k in 1:size(mov, 3)
    # mesh, blockmatches = blockmatch(mov[:,:,k], template, params=params)
    # tform = calculate_translation(blockmatches)
    blockmatches, max_r, xc = get_max_xc_vector(mov[p:end-p,p:end-p,k], template)
    tform = eye(3)
    tform[3,1:2] = blockmatches - [p p]
    frame, offset = imwarp(mov[:,:,k], tform)
    push!(frames, frame)
    push!(offsets, offset)
    push!(matches, blockmatches)
  end

  maxn, maxm = maximum(hcat(map(collect, map(size, frames))...), 2)
  mini, minj = minimum(hcat(offsets...), 2)
  # n, m = maxn-mini, maxm-minj
  n, m = size(mov[:,:,1])
  new_mov = zeros(T, maxn, maxm, length(frames))
  # println((maxn, maxm))
  # println((mini, minj))
  # println((n, m))
  # println((i,j))
  bb = BoundingBox(0, 0, n-1, m-1)
  print(bb)
  for (k, (frame, offset)) in enumerate(zip(frames, offsets))
    new_mov[:,:,k] = rescopeimage(frame, offset, bb)
  end

  return new_mov, offsets, matches
end

"""
Determine maximum dimensions of list of dimensions with different sizes
"""
function find_largest_dimensions(dims)
  maxn, maxm = dims[1]
  for dim in dims
    n, m = dim
    if n > maxn; maxn = n; end
    if m > maxm; maxm = m; end
  end
  return maxn, maxm
end

"""
`RESCOPE` - Crop/pad an image to fill a bounding box
    
    new_img = rescope(img, offset, boundingbox)

Args:

* img: 2D or 3D array
* offset: 2-element array, specifying i & j offset from global origin
* bb: bounding box object in the global reference space

Returns:

* new_img: original img, cropped &/or extended with rows and columns of zeros
"""
function rescopeimage{T}(img::Array{T}, offset, bb)
  z = zeros(T, bb.h+1, bb.w+1)
  imgbb = BoundingBox(offset..., size(img,1)-1, size(img,2)-1)
  xbb = imgbb - bb
  if !isnan(xbb.i) & !isnan(xbb.j) & !isnan(xbb.h) & !isnan(xbb.h)
    crop_img = xbb.i-offset[1]+1 : xbb.i-offset[1]+1+xbb.h, 
                  xbb.j-offset[2]+1 : xbb.j-offset[2]+1+xbb.w
    crop_z = xbb.i-bb.i+1:xbb.i-bb.i+1+xbb.h, xbb.j-bb.j+1:xbb.j-bb.j+1+xbb.w
    z[crop_z...] = img[crop_img...]
  end
  return z
end

function compare_movies(movA, movB)
  movC = stack_movies(movA, movB)
  return view_movie(movC)
end

function stack_movies(movA, movB)
  nA, mA, lA = size(movA)
  nB, mB, lB = size(movB)
  assert(lA == lB)
  n, m = min([nA, mA], [nB, mB])
  border = ones(n, 10, lA)
  return cat(2, movA[1:n,1:m,:], border, movB[1:n,1:m,:])
end

function inspect_alignment(mov, fps=10)
  e = Condition()

  imgc, img2 = view_movie(mov[:,:,1:100])
  state = imgc.navigationstate
  set_fps!(state, fps)
  
  errors = 0

  c = canvas(imgc)
  win = Tk.toplevel(c)
  bind(win, "<KP_Enter>", path->count())
  bind(win, "<Delete>", path->reset())
  bind(win, "<Destroy>", path->end_count())

  function count()
    errors += 1
    println(errors)
  end

  function reset()
    errors = 0
    println(errors)
  end

  function end_count()
    notify(e)
    bind(win, "<KP_Enter>", path->path)
    bind(win, "<Delete>", path->path)
    bind(win, "<Destroy>", path->path)
  end
  
  wait(e)
  return errors
end