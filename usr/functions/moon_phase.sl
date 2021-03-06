ineed ("isleap");
ineed ("checktmfmt");
ineed ("strtoint");

define main ()
{
  variable
    mp,
    tf,
    err,
    tim,
    tok,
    index,
    retval,
    gotopager = 0,
    file = SCRATCHBUF,
    repeats = NULL,
    args = __pop_list (_NARGS - 1);
 
  args = list_to_array (args, String_Type);

  index = proc->is_arg ("--pager", args);
  ifnot (NULL == index)
    {
    gotopager = 1;
    args[index] = NULL;
    args = args[wherenot (_isnull (args))];
    }

  ifnot (length (args))
    tim = localtime (_time ());

  if (1 == length (args))
    {
    tim = args[0];
    if (strlen (tim) < 4)
      {
      srv->send_msg ("please use one of the --tf= or --for= switches", -1);
      throw GotoPrompt;
      }
    else
      {
      if ("--for=" == tim[[0:5]])
        {
        repeats = strchop (tim, '=', 0)[1];
        tim = localtime (_time);
        }
      else if ("--tf=" != tim[[0:4]])
        {
        srv->send_msg ("please use one of the --tf= or --for= switches", -1);
        throw GotoPrompt;
        }
      }
    }

  if (2 == length (args))
    {
    repeats = args[1];
    tim = args[0];

    if (strlen (tim) < 4 && strlen (repeats) < 4)
      {
      srv->send_msg ("please use one of the --tf= or --for= switches", -1);
      throw GotoPrompt;
      }

    repeats = strchop (repeats, '=', 0);

    if ("--for" == repeats[0])
      repeats = repeats[1];
    else if ("--tf" == repeats[0])
      {
      repeats[0] = tim;
      tim = "--tf=" + repeats[1];
      repeats = strchop (repeats[0], '=', 0)[1];
      }
    else
      {
      srv->send_msg ("please use one of the --tf= or --for= switches", -1);
      throw GotoPrompt;
      }
    }

 ifnot (NULL == repeats)
   {
    repeats = strtoint (repeats);
    if (NULL == repeats)
      {
      srv->send_msg ("please give an integer as argument to the --for= switch", -1);
      throw GotoPrompt;
      }
   }

  if (1 == _NARGS || (2 == _NARGS && 0 == length (args))
      || (1 == length (args) && NULL != repeats))
    tim.tm_year += 1900;
  else
    {
    tim = strchop (tim, '=', 0);

    ifnot (2 == length (tim))
      {
      srv->send_msg ("wrong time format", -1);
      throw GotoPrompt;
      }

    tim = tim[1];
    tok = strchop (tim, ':', 0);

    ifnot (6 == length (tok))
      {
      srv->send_msg ("wrong time format", -1);
      throw GotoPrompt;
      }

    tok = array_map (Integer_Type, &atoi, tok);
    tim = localtime (_time);
    set_struct_fields (tim, tok[0], tok[1], tok[2], tok[3], tok[4] - 1, tok[5]);

    retval = checktmfmt (tim);
 
    if (NULL == retval)
      {
      err = ();
      srv->send_msg (err, -1);
      throw GotoPrompt;
      }
    }

  tf = sprintf ("%d:%d:%d:%d:%d:%d", tim.tm_sec, tim.tm_min, tim.tm_hour,
      tim.tm_mday, tim.tm_mon, tim.tm_year);
 
  writefile (["MOON PHASE", repeat ("_", COLUMNS)], file);

  if (NULL == repeats)
    retval = proc->call (["moonphase", "--nocl",
        sprintf ("--tf=%s", tf),
        sprintf ("--execdir=%s/scripts", path_dirname (__FILE__)),
        sprintf ("--msgfname=%s", CW.msgbuf),
        sprintf ("--mainfname=%s", file)]);
  else
    retval = proc->call (["moonphase", "--nocl",
        sprintf ("--tf=%s", tf),
        sprintf ("--for=%d", repeats),
        sprintf ("--execdir=%s/scripts", path_dirname (__FILE__)),
        sprintf ("--msgfname=%s", CW.msgbuf),
        sprintf ("--mainfname=%s", file)]);
 
  ifnot (retval)
    {
    ifnot (gotopager)
      ved (file;drawonly);
    else
      ved (file;drawwind);
    }

  throw GotoPrompt;
}
