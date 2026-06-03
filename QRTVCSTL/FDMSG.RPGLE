**free
/if not defined(msg_t)
/define msg_t
// ============================================================= *
//   Message structure                                           *
// ============================================================= *

dcl-ds msg_t qualified template;
  ID   likeds(msgID_t);
  data char(512);
  type char(10);
  file char(10);
  lib  char(10);
end-ds;

dcl-ds msgID_t qualified template;
  prefix char(3);
  nbr    zoned(4);
end-ds;

/endif
