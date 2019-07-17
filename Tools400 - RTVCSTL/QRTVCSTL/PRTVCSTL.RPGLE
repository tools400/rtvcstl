      *=====================================================================*
      *  Author  :  Thomas Raddatz                                          *
      *  Date    :  21.06.2003                                              *
      *  E-mail  :  thomas.raddatz@tools400.de                              *
      *  Homepage:  www.tools400.de                                         *
      *=====================================================================*
      *  Prorotypes and Reference Fields of Service Program RTVCSTL         *
      *=====================================================================*
      *
      *  Reference fields
     D cstLst_handle_t...
     D                 S               *   based(pDummy)
      *
      *  Open List of Database File Constraints
     D f_opnCstLst...
     D                 PR              N   opdesc
     D                                     EXTPROC('RTVCSTLR1+
     D                                     _f_opnCstLst+
     D                                     ')
     D  i_file                       10A   const
     D  i_lib                        10A   const
     D  i_orderBy                    10A   value
     D  o_handle                                  like(cstLst_handle_t)
     D  o_msg                     32767A          options(*nopass: *varsize)
      *
      *  Close List Of Database File Constraints
     D f_cloCstLst...
     D                 PR              N
     D                                     EXTPROC('RTVCSTLR1+
     D                                     _f_cloCstLst+
     D                                     ')
     D  io_handle                      *
      *
      *  Get First Constraint
     D f_getFirstCst...
     D                 PR              N   opdesc
     D                                     extproc('RTVCSTLR1+
     D                                     _f_getFirstCst+
     D                                     ')
     D  i_handle                           value  like(cstLst_handle_t)
     D  o_data                    32767A   options(*varsize)
      *
      *  Get Next Constraint
     D f_getNextCst...
     D                 PR              N   opdesc
     D                                     extproc('RTVCSTLR1+
     D                                     _f_getNextCst+
     D                                     ')
     D  i_handle                           value  like(cstLst_handle_t)
     D  o_data                    32767A   options(*varsize)
      *
      *===============================================================*
      *  Get Number of Constraints available
      *===============================================================*
      *
     D f_getNumCstAvl...
     D                 PR            10I 0
     D                                     extproc('RTVCSTLR1+
     D                                     _f_getNumCstAvl+
     D                                     ')
     D  i_handle                           value  like(cstLst_handle_t)
      *
