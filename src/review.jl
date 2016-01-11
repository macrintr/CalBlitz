"""
View two movies side-by-side
"""
function compare_movies(movA, movB)
  movC = stack_movies(movA, movB)
  return view_movie(movC)
end

"""
Create viewer with key controls to log errors
"""
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