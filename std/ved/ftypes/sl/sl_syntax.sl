private variable colors = [
%functions
  14,
%conditional
  13,
%type
  12,
%errors
  17,
];

private variable regexps = [
%functions
  pcre_compile ("\
((evalfile(?=\s))\
|(?<!\w)(import(?=\s))\
|(?<!\w)(sigprocmask(?=\s))\
|(?<!\w)(\(\)(?=\s))\
|(?<!\w)(ineed(?=\s))\
|(?<!\w)(fork(?=\s))\
|(?<!\w)(pipe(?=\s))\
|(?<!\w)(execv(?=\s))\
|(?<!\w)(execve(?=\s))\
|(?<!\w)(socket(?=\s))\
|(?<!\w)(bind(?=\s))\
|(?<!\w)(listen(?=\s))\
|(?<!\w)(connect(?=\s))\
|(?<!\w)(getlinestr(?=\s))\
|(?<!\w)(waddlineat(?=\s))\
|(?<!\w)(waddlineat_dr(?=\s))\
|(?<!\w)(waddlinear_dr(?=\s))\
|(?<!\w)(waddlinear(?=\s))\
|(?<!\w)(waddline(?=\s))\
|(?<!\w)(waddline_dr(?=\s)))+"R),
%conditional
  pcre_compile ("\
(((?<!\w)if(?=\s))\
|((?<!\w)ifnot(?=\s))\
|((?<!\w)else if(?=\s))\
|((?<!\w)else$)\
|((?<!\w)\{$)\
|((?<!\{)(?<!\w)\}(?=;))\
|((?<!\w)\}$)\
|((?<!\w)while(?=\s))\
|((?<!\w)loop$)\
|((?<!\w)switch(?=\s))\
|((?<!\w)case(?=\s))\
|((?<!\w)_for(?=\s))\
|((?<!\w)for(?=\s))\
|((?<!\w)foreach(?=\s))\
|((?<!\w)forever$)\
|((?<!\w)do$)\
|((?<!\w)then$)\
|((?<=\w)--(?=;))\
|((?<=\w)\+\+(?=;))\
|((?<=\s)\?(?=\s))\
|((?<=\s):(?=\s))\
|((?<=\s)\+(?=\s))\
|((?<=\s)-(?=\s))\
|((?<=\s)\*(?=\s))\
|((?<=\s)/(?=\s))\
|((?<=\s)mod(?=\s))\
|((?<=\s)\+=(?=\s))\
|((?<=\s)!=(?=\s))\
|((?<=\s)>=(?=\s))\
|((?<=\s)<=(?=\s))\
|((?<=\s)<(?=\s))\
|((?<=\s)>(?=\s))\
|((?<=\s)==(?=\s)))+"R),
%type
  pcre_compile ("\
(((?<!\w)define(?=\s))\
|(^\{$)\
|(^\}$)\
|((?<!\w)variable(?=[\s]*))\
|((?<!\w)private(?=\s))\
|((?<!\w)public(?=\s))\
|((?<!\w)static(?=\s))\
|((?<!\w)typedef struct$)\
|((?<!\w)struct(?=[\s]*))\
|((?<!\w)try(?=[\s]*))\
|((?<!\w)catch(?=\s))\
|((?<!\w)throw(?=\s))\
|((?<!\w)finally(?=\s))\
|((?<!\w)return(?=[\s;]))\
|((?<!\w)break(?=;))\
|((?<!\w)continue(?=;))\
|(NULL)\
|((?<!\w)stderr(?=[,\)\.]))\
|((?<!\w)stdin(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<=\s|\||\()S_IRGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IROTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXG(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXO(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXU(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISUID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISGID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISVTX(?=[,\|;\)]+))\
|((?<=\s|\|)O_APPEND(?=[,\|;\)]+))\
|((?<=\s|\|)O_BINARY(?=[,\|;\)]+))\
|((?<=\s|\|)O_NOCTTY(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_WRONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_CREAT(?=[,\|;\)]+))\
|((?<=\s|\|)O_EXCL(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDWR(?=[,\|;\)]+))\
|((?<=\s|\|)O_TEXT(?=[,\|;\)]+))\
|((?<=\s|\|)O_TRUNC(?=[,\|;\)]+))\
|((?<=\s|\|)O_NONBLOCK(?=[,\|;\)]+))\
|((?<=[\s|@])[\w]+_Type(?=[\[;\]]))\
|((?<=\()[\w]+_Type(?=,))\
|((?<!\w)[\w]+Error(?=:)))+"R),
%errors
  pcre_compile ("\
((?<=\w)(\s{1,}$))+"R),
];

private define sl_hl_groups (lines, vlines)
{
  variable
    i,
    ii,
    col,
    subs,
    match,
    color,
    regexp,
    context;
 
  _for i (0, length (lines) - 1)
    {
    _for ii (0, length (regexps) - 1)
      {
      color = colors[ii];
      regexp = regexps[ii];
      col = 0;

      while (subs = pcre_exec (regexp, lines[i], col), subs > 1)
        {
        match = pcre_nth_match (regexp, 1);
        col = match[0];
        context = match[1] - col;
        srv->set_color_in_region (color, vlines[i], col, 1, context);
        col += context;
        }
      }
    }
}

define sl_lexicalhl (lines, vlines)
{
  sl_hl_groups (lines, vlines);
}
