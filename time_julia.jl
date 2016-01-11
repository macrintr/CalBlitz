#
# Time CalBlitz alignment in Julia
#

using CalBlitz

fn = "images/demoMovie.h5"
max_disps = [10,10]
num_frames_in_template = 300
mov = load_movie(fn)

print("generate_template: ")
@time template, template_offsets, template_disps = generate_template(mov, max_disps, num_frames_in_template);
print("align_stack: ")
template = remove_border(template, max_disps);
@time new_mov, offsets, disps = align_movie(mov, template);

using PyPlot

