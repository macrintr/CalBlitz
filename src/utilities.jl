"""
Normalize 3D matrix values on range [0,1]
"""
function normalize(mov)
	mov = mov .- minimum(mov)
	return mov ./ maximum(mov)
end

"""
Calculate median along 3rd dimension (result is 2D array of medians)
"""
function median3d{T}(v::AbstractArray{T})
  m = zeros(T, size(v)[1:2]...)
  for i=1:size(v,1), j=1:size(v,2)
    m[i,j] = round(T, median(v[i,j,:]))
  end
  return m
end

"""
Concatenate movies along ith dimension for frame by frame viewing
"""
function stack_movies(movA, movB)
  nA, mA, lA = size(movA)
  nB, mB, lB = size(movB)
  assert(lA == lB)
  n, m = min([nA, mA], [nB, mB])
  border = ones(n, 10, lA)
  return cat(2, movA[1:n,1:m,:], border, movB[1:n,1:m,:])
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