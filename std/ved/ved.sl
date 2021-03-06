typedef struct
  {
  _fname,
  _sockaddr,
  _fd,
  _state,
  _exists,
  _func,
  _count,
  _drawonly,
  _issudo,
  p_,
  } Ved_Type;

private variable ved_;
private variable funcs = Assoc_Type[Ref_Type];

private variable
  CONNECTED = 0x1,
  IDLED = 0x2,
  JUST_DRAW = 0x064,
  GOTO_EXIT = 0x0C8,
  SEND_COLS = 0x0190,
  % 0x01F4,
  % 0x012C,
  SEND_FILE = 0x0258,
  SEND_ROWS = 0x02BC,
  %0x0320,
  SEND_INFOCLRFG = 0x0384,
  SEND_INFOCLRBG = 0x0385,
  SEND_PROMPTCOLOR = 0x03E8,
  SEND_MSGROW = 0x044C,
  SEND_FUNC = 0x04b0,
  SEND_LINES = 0x0514;

private define ved_exit ()
{
  variable status = waitpid (ved_.p_.pid, 0);
  ved_.p_.atexit ();

  () = close (ved_._fd);
  __uninitialize (&ved_);
}

private define send_bufkey (sock)
{
  sock->send_str (sock, ved_._me);
}

private define send_lines (sock)
{
  sock->send_int (sock, LINES);
}

private define send_func (sock)
{
  sock->send_int (sock, NULL == ved_._func ? 0 : ved_._func);

  ifnot (NULL == ved_._func)
    {
    () = sock->get_int (sock);
    sock->send_int (sock, NULL == ved_._count ? 0 : 1);

    ifnot (NULL == ved_._count)
      {
      () = sock->get_int (sock);
      sock->send_int (sock, ved_._count);
      }
    }
}

private define just_draw (sock)
{
  sock->send_int (sock, ved_._drawonly);
}

private define send_rows (sock)
{
  variable
    frame = CW.cur.frame,
    rows = [CW.dim[frame].rowfirst:CW.dim[frame].rowlast + 1];

  sock->send_int_ar (sock, rows);
}

private define send_file (sock)
{
  sock->send_str (sock, ved_._fname);
}

private define send_el_chr (sock)
{
  getchar_lang = &input->el_getch;
  sock->send_int (sock, (@getch));
  getchar_lang = &input->en_getch;
}

private define send_chr (sock)
{
  sock->send_int (sock, (@getch));
}

private define send_cols (sock)
{
  sock->send_int (sock, COLUMNS);
}

private define send_msgrow (sock)
{
  sock->send_int (sock, MSGROW);
}

private define send_infoclrfg (sock)
{
  sock->send_int (sock, COLOR.activeframe);
}

private define send_infoclrbg (sock)
{
  sock->send_int (sock, COLOR.info);
}

private define send_promptcolor (sock)
{
  sock->send_int (sock, COLOR.prompt);
}

private define addflags (p)
{
  p.stdout.file = CW.buffers[CW.cur.frame].fname,
  p.stdout.wr_flags = ">>";
  p.stderr.file = CW.msgbuf;
  p.stderr.wr_flags = ">>";
}

private define broken_sudoproc_broken ()
{
  variable passwd = root.lib.getpasswd ();

  ifnot (strlen (passwd))
    {
    srv->send_msg ("Password is an empty string. Aborting ...", -1);
    return NULL;
    }

  variable retval = root.lib.validate_passwd (passwd);

  if (NULL == retval)
    {
    srv->send_msg ("This is not a valid password", -1);
    return NULL;
    }

  variable p = proc->init (1, 1, 1);

  p.stdin.in = passwd;
  return p;
}

private define getargvenv ()
{
  variable
    argv = [PROC_EXEC, sprintf ("%s/proc", path_dirname (__FILE__)), ved_._fname],
    env = [
      sprintf ("VED_SOCKADDR=%s", ved_._sockaddr),
      sprintf ("IMPORT_PATH=%s", get_import_module_path ()),
      sprintf ("LOAD_PATH=%s", get_slang_load_path ()),
      sprintf ("TERM=%s", getenv ("TERM")),
      sprintf ("LANG=%s", getenv ("LANG")),
      sprintf ("STDNS=%s", STDNS),
      sprintf ("SRV_SOCKADDR=%s", SRV_SOCKADDR),
      sprintf ("SRV_FILENO=%d", _fileno (SRV_SOCKET)),
      sprintf ("DISPLAY=%S", getenv ("DISPLAY")),
      sprintf ("PATH=%s", getenv ("PATH")),
      ];

  if (ved_._issudo)
    argv = [SUDO_EXEC, "-S", "-E",  "-C", sprintf ("%d", _fileno (SRV_SOCKET)+ 1), argv];

  return argv, env;
}

private define doproc ()
{
  variable p, argv, env;

  ifnot (ved_._issudo)
    {
    if (p = proc->init (0, 1, 1), p == NULL)
      return NULL;

    addflags (p);
    }
  else
    {
    if (p = broken_sudoproc_broken (), p == NULL)
      return NULL;

    addflags (p);
    }

  (argv, env) = getargvenv ();

  if (NULL == p.execve (argv, env, 1))
    return NULL;

  return p;
}

private define is_file (fn)
{
  ifnot (stat_is ("reg", stat_file (fn).st_mode))
    {
    srv->send_msg_and_refresh (sprintf ("%s: is not a regular file", fn), -1);
    return -1;
    }

  return 0;
}

private define is_file_readable (fn, issudo)
{
  if (-1 == access (fn, R_OK) && 0 == issudo)
    {
    srv->send_msg_and_refresh (sprintf ("%s: is not readable", fn), -1);
    return -1;
    }

  return 0;
}

private define check_file (fn, issudo)
{
  ifnot (access (fn, F_OK))
    {
    if (-1 == is_file (fn))
      return -1;
 
    if (-1 == is_file_readable (fn, issudo))
      return -1;

    return 1;
    }

  return 0;
}

private define parse_args ()
{
  variable issudo = ();
  variable fname = ();

  ifnot (_NARGS - 2)
    @fname = CW.buffers[CW.cur.frame].fname;
  else
    @fname = ();
 
  variable exists = check_file (@fname, issudo);

  if (-1 == exists)
    return -1;

  return exists;
}

private define connect_to_child ()
{
  ved_._fd = ved_.p_.connect (ved_._sockaddr);

  if (NULL == ved_._fd)
    {
    ved_.p_.atexit ();
    () = kill (ved_.p_.pid, SIGKILL);
    return;
    }
 
  ved_._state = ved_._state | CONNECTED;

  variable retval;

  forever
    {
    retval = sock->get_int (ved_._fd);
 
    ifnot (Integer_Type == typeof (retval))
      break;

    if (retval == GOTO_EXIT)
      {
      ved_._state = ved_._state & ~CONNECTED;
      break;
      }
 
    (@funcs[string (retval)]) (ved_._fd);
    }
}

private define init_ved (fn, exists)
{
  ved_ = @Ved_Type;
  ved_._fname = fn;
  ved_._state = 0;
  ved_._exists = exists;
  ved_._count = qualifier ("count");
  ved_._func = qualifier ("func");
  ved_._drawonly = qualifier_exists ("drawonly");
}

private define init_sockaddr (fn)
{
  return sprintf ("%s/_ved/ved_%s_%d.sock", TEMPDIR,
    path_basename_sans_extname (fn), _time);
}

private define _ved_ ()
{
  variable issudo = ();
  variable file;
  variable args = __pop_list (_NARGS - 1);
  variable exists = parse_args (__push_list (args), &file, issudo;;__qualifiers ());

  if (-1 == exists)
    return;

  init_ved (file, exists;;__qualifiers ());

  ved_._issudo = issudo;
  
  ved_._sockaddr = init_sockaddr (file);

  ved_.p_ = doproc ();
  
  if (NULL == ved_.p_)
    return;

  connect_to_child ();

  ved_exit ();
}

define ved ()
{
  variable args = __pop_list (_NARGS);
  _ved_ (__push_list (args), 0;;__qualifiers ());

  if (qualifier_exists ("drawwind"))
    CW.drawwind ();
}

define vedsudo ()
{
  variable args = __pop_list (_NARGS);
  _ved_ (__push_list (args), 1;;__qualifiers ());
}

funcs[string (JUST_DRAW)] = &just_draw;
funcs[string (SEND_COLS)] = &send_cols;
funcs[string (SEND_FILE)] = &send_file;
funcs[string (SEND_ROWS)] = &send_rows;
funcs[string (SEND_INFOCLRBG)] = &send_infoclrbg;
funcs[string (SEND_INFOCLRFG)] = &send_infoclrfg;
funcs[string (SEND_PROMPTCOLOR)] = &send_promptcolor;
funcs[string (SEND_MSGROW)] = &send_msgrow;
funcs[string (SEND_FUNC)] = &send_func;
funcs[string (SEND_LINES)] = &send_lines;
