() = evalfile ("parents");
() = evalfile ("rmdir");

define main ()
{
  variable
    i,
    st,
    root,
    dirs,
    retval,
    exit_code = 0,
    parents = NULL,
    interactive = NULL,
    path_arr = String_Type[0],
    c = cmdopt_new (&_usage);

  c.add ("parents", &parents);
  c.add ("interactive", &interactive);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    (@print_err) (sprintf ("%s: argument is required", __argv[0]));
    return 1;
    }

  dirs = __argv[[i:]];
  dirs = dirs[where (strncmp (dirs, "--", 2))];

  ifnot (NULL == parents)
    _for i (0, length (dirs) - 1)
      path_arr = [path_arr, dir_parents (dirs[i])];
  else
    path_arr = dirs;

  path_arr = path_arr[array_sort (path_arr)];

  _for i (length (path_arr) - 1, 0, -1)
    {
    st = stat_file (path_arr[i]);

    if (NULL== st)
      {
      (@print_err) (sprintf ("failed to remove `%s': Not such directory", path_arr[i]));
      exit_code = 1;
      continue;
      }

    retval = removedir (path_arr[i], interactive);
 
    if (-1 == retval)
      exit_code = 1;
    }
 
  return exit_code;
}
