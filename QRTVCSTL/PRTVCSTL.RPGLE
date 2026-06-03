**free
//=====================================================================*
//  Author  :  Thomas Raddatz                                          *
//  Date    :  21.06.2003                                              *
//  E-mail  :  thomas.raddatz@tools400.de                              *
//  Homepage:  www.tools400.de                                         *
//=====================================================================*
//  Prorotypes and Reference Fields of Service Program RTVCSTL         *
//=====================================================================*

//  Reference fields
dcl-s cstLst_handle_t pointer template;

//  Open List of Database File Constraints
dcl-pr f_opnCstLst ind opdesc extproc('RTVCSTLR1_f_opnCstLst');
  i_file    char(10) const;
  i_lib     char(10) const;
  i_orderBy char(10) value;
  o_handle  like(cstLst_handle_t);
  o_msg     char(32767) options(*nopass: *varsize);
end-pr;

//  Close List Of Database File Constraints
dcl-pr f_cloCstLst ind extproc('RTVCSTLR1_f_cloCstLst');
  io_handle pointer;
end-pr;

//  Get First Constraint
dcl-pr f_getFirstCst ind opdesc extproc('RTVCSTLR1_f_getFirstCst');
  i_handle like(cstLst_handle_t) value;
  o_data   char(32767) options(*varsize);
end-pr;

//  Get Next Constraint
dcl-pr f_getNextCst ind opdesc extproc('RTVCSTLR1_f_getNextCst');
  i_handle like(cstLst_handle_t) value;
  o_data   char(32767) options(*varsize);
end-pr;

//===============================================================*
//  Get Number of Constraints available
//===============================================================*

dcl-pr f_getNumCstAvl int(10) extproc('RTVCSTLR1_f_getNumCstAvl');
  i_handle like(cstLst_handle_t) value;
end-pr;

