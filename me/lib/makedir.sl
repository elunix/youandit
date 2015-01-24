define makedir (dir, mode)
{
  ifnot (access (dir, F_OK))
    {
    (@print_err) (sprintf ("cannot create directory `%s': File exists", dir));
    return -1;
    }

  ifnot (NULL == mode)
    {
    if (-1 == mkdir (dir, mode))
      {
      (@print_err) (sprintf
        ("cannot create directory `%s': %s", dir, errno_string (errno)));
      return -1;
      }
    }
  else
    if (-1 == mkdir (dir))
      {
      (@print_err) (sprintf
        ("cannot create directory `%s': %s", dir, errno_string (errno)));
      return -1;
      }

  (@print_norm) (sprintf ("created directory `%s' with access: %s", dir,
    stat_mode_to_string (stat_file (dir).st_mode)));

  return 0;
}
