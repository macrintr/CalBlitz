# """
# T Macrina
# 160106

# IO functions for calcium image movies
# """

function get_filepaths(path="images")
  filenames = readdir(path)
  return [joinpath(path, fn) for fn in filenames]
end

function gray16_to_int16(a)
  return round(Int16, convert(Array{Float64}, data(a))*2^16)
end

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

function save_movie(fn, mov)
  # assert(typeof(mov) == Array{Float64,3})
  f = h5open(fn, "w")
  @time f["mov", "chunk", (32,32,1)] = mov
  close(f)
end