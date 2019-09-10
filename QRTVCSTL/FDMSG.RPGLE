      /if not defined(msg_t     )
      /define msg_t
      * ============================================================= *
      *   Message structure                                           *
      * ============================================================= *
      *
     d msg_t           ds                  qualified           based(pDummy)
     d  ID                                 likeds(msgID_t)
     d  data                        512A
     d  type                         10a
     d  file                         10a
     d  lib                          10a
      *
     d msgID_t         ds                  qualified           based(pDummy)
     d  prefix                        3a
     d  nbr                           4S 0
      *
      /endif
