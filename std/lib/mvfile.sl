ineed ("copyfile");

define mvfile (source, dest, opts)
{
  variable
    backup,
    retval,
    backuptext = "",
    st_dest = stat_file (dest);

%TODO CHMOD
  if (NULL != st_dest && opts.backup)
    {
    backup = strcat (dest, opts.suffix);
    retval = copyfile (dest, backup);
    if (-1 == retval)
      {
      (@print_err) (sprintf ("%s: backup failed", backup));
      return -1;
      }

    backuptext = sprintf (" (backup: %s)", backup);
    }

  retval = rename (source, dest);

  if (-1 == retval)
    {
    if ("Cross-device link" == errno_string (errno))
      {
      retval = copyfile (source, dest);
      if (-1 == retval)
        {
        (@print_err) (sprintf
          ("%s: failed to mv to %s, Couldn't bypass the Cross-device link", source, dest));
        return -1;
        }

      if (-1 == remove (source))
        {
        () = remove (dest);
        (@print_err) (sprintf
          ("%s: failed to mv to %s, ERRNO: %s", source, dest, errno_string (errno)));
        return -1;
        }
      }
    else
      {
      (@print_err) (sprintf (
        "Failed to move %s to %s, ERRNO: %s", source, dest, errno_string (errno)));
      return -1;
      }
    }

  (@print_out) (sprintf ("`%s' -> `%s'%s", source, dest, backuptext));
  return 0;
}
