function create_params(mesh_dist, block_size, search_r, min_r)
  return Dict(  "mesh_dist" => mesh_dist, 
                "block_size" => block_size, 
                "search_r" => search_r, 
                "min_r" => min_r)
end

# function generate_random_template(mov, n=4)
#   indices = randperm(size(mov,3))[1:n]
#   sample = mov[:,:,indices]
#   sample_template = median3d(sample)
#   params = create_params(16, 8, 8, 0)
#   template, offsets, matches = align_stack(sample, sample_template, params)
#   return template[:,:,1]
# end

function remove_border{T}(a::Array{T}, border)
  di, dj = border
  return a[di:end-di, dj:end-dj]
end

function generate_template(mov, max_disp=[10,10], num_frames_in_template=300)
  n = max(1, round(Int64, size(mov)[3] / num_frames_in_template))
  sample = mov[:,:,1:n:end]
  template_sample = median3d(sample)
  template_sample = remove_border(template_sample, max_disp)
  sample_warped, sample_offsets, sample_disps = align_movie(sample, template_sample)
  template_warped = median3d(sample_warped)
  template_warped = remove_border(template_warped, max_disp)
  mov_warped, mov_offsets, mov_disps = align_movie(mov, template_warped)
  return median3d(mov_warped), sample_disps, mov_disps
end

function match_template{T}(mov::Array{T}, template)
  displacements = []
  for k in 1:size(mov, 3)
    # mesh, blockmatches = blockmatch(mov[:,:,k], template, params=params)
    # tform = calculate_translation(blockmatches)
    displacement, max_r, xc = get_max_xc_vector(template, mov[:,:,k])
    push!(displacements, -displacement)
  end
  return displacements
end

function get_max_frame_dimensions(frames)
  return maximum(hcat(map(collect, map(size, frames))...), 2)
end

function get_max_offest(offsets)
  return minimum(hcat(offsets...), 2)
end

function apply_displacements{T}(mov::Array{T}, displacements)
  assert(size(mov, 3) == length(displacements))
  frames = []
  offsets = []
  for k in 1:size(mov, 3)
    displacement = displacements[k]
    tform = eye(3)
    tform[3,1:2] = displacement
    frame, offset = imwarp(mov[:,:,k], tform)
    push!(frames, frame)
    push!(offsets, offset)
  end

  maxn, maxm = get_max_frame_dimensions(frames)
  mini, minj = get_max_offest(offsets)
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

  return new_mov, offsets
end

function align_movie{T}(mov::Array{T}, template)
  displacements = match_template(mov, template)
  new_mov, offsets = apply_displacements(mov, displacements)
  return new_mov, offsets, displacements
end