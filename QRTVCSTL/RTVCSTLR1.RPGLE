**free
//=====================================================================*
//  Author  :  Thomas Raddatz                                          *
//  Date    :  21.06.2003                                              *
//  E-mail  :  thomas.raddatz@Tools400.de                              *
//  Homepage:  www.tools400.de                                         *
//=====================================================================*
//                                                                     *
//  This software is free software, you can redistribute it and/or     *
//  modify it under the terms of the GNU General Public License (GPL)  *
//  as published by the Free Software Foundation.                      *
//                                                                     *
//  See GNU General Public License for details.                        *
//          http://www.opensource.org                                  *
//          http://www.opensource.org/licenses/gpl-license.html        *
//                                                                     *
//=====================================================================*
//  The RTVCSTL service program retrieves the list of constraints      *
//  that are defined for a database file.                              *
//  The RTVCSTL service program runs on V5R1 and higher.               *
//=====================================================================*
//  History:                                                           *
//                                                                     *
//  Datum       Name          Änderung                                 *
//  ----------  ------------  ---------------------------------------  *
//  12.08.2003  Th.Raddatz    Added cstl0100.crtTmStmp.                *
//  12.08.2003  Th.Raddatz    Fixed error in getEntry() when           *
//                            computing pQdb_Qdbf_Constraint for the   *
//                            next constraint.                         *
//                                                                     *
//=====================================================================*
//   >>PRE-COMPILER<<                                                  *
//     >>CRTCMD<<  CRTRPGMOD    MODULE(&LI/&OB) +                      *
//                              SRCFILE(&SL/&SF) SRCMBR(&SM);          *
//     >>IMPORTANT<<                                                   *
//       >>PARM<< TRUNCNBR(*NO);                                       *
//       >>PARM<< DBGVIEW(*LIST);                                      *
//       >>PARM<< OPTION(*EVENTF);                                     *
//     >>END-IMPORTANT<<                                               *
//     >>EXECUTE<<                                                     *
//   >>END-PRE-COMPILER<<                                              *
//=====================================================================*
ctl-opt nomain;
ctl-opt extbinint(*yes) bnddir('QC2LE');
ctl-opt datfmt(*iso) timfmt(*iso) debug(*yes);
/copy QRTVCSTL,COPYRIGHT
//=====================================================================*

//  Exported functions
/copy QRTVCSTL,PRTVCSTL

//  Reference fields
/copy QRTVCSTL,FDCSTL0100
/copy QRTVCSTL,FDERRCODE
/copy QRTVCSTL,FDMSG
/copy QRTVCSTL,FDQOBJ
/copy QRTVCSTL,QDBRTVFD

//  Handle
dcl-ds handle_t qualified template;
  pFD      pointer;
  curEntry int(10);
  file     char(10);
  lib      char(10);
  reserved char(16);
end-ds;

//  Internal used prototypes
dcl-pr getEntry ind;
  io_handle likeds(handle_t);
  o_data    char(32767) options(*varsize);
  i_length  int(10) value;
end-pr;

dcl-pr rtvKeyFlds like(cstl0100_t.parKey);
  i_pQdb_Qdbf_Keyn pointer const;
end-pr;

dcl-pr cvtDltRule like(cstl0100_t.dltRule);
  i_dltRule like(Qdb_Qdbf_Riafk_Afkd_t.Qdbf_riafk_fkcdr) const;
end-pr;

dcl-pr cvtUpdRule like(cstl0100_t.updRule);
  i_updRule like(Qdb_Qdbf_Riafk_Afkd_t.Qdbf_riafk_fkcur) const;
end-pr;

dcl-pr isApiError ind;
  i_errCode char(272) const;
end-pr;

dcl-pr newApiErrCode char(272);
  i_monmsg ind const;
end-pr;

dcl-pr cvtApiErrCodeToMsg like(msg_t);
  i_errCode char(272) const;
end-pr;

//  Prototypes of CEE APIs
dcl-pr ceegsi extproc('CEEGSI');
  i_posN     int(10) const;
  o_dataType int(10);
  o_currLen  int(10);
  o_maxLen   int(10);
  o_fc       char(12) options(*omit);
end-pr;

//  Global constants
dcl-c cTrue *on;
dcl-c cFalse *off;

//==================================================================*
//  Open List Of Database File Members
//==================================================================*
dcl-proc f_opnCstLst export;
  dcl-pi *n ind opdesc;
    i_file    char(10) const;
    i_lib     char(10) const;
    i_orderBy char(10) value;
    o_handle  like(cstLst_handle_t);
    o_msg     char(32767) options(*nopass: *varsize);
  end-pi;

  // Return value
  dcl-s o_isDone ind inz(cFalse);

  // Parameter positions
  dcl-c p_msg 5;

  // Optional parameter fields
  dcl-ds msg likeds(msg_t) inz;

  // QDBRTVFD API fields
  dcl-ds qFile likeds(qObj_t) inz;
  dcl-ds qRetFile likeds(qObj_t) inz;

  dcl-ds memSize qualified inz;
    returned int(10);
    needed   int(10);
  end-ds;

  // File Definition Header (Qdb_Qdbfh)
  dcl-ds Qdb_Qdbfh likeds(Qdb_Qdbfh_t) based(pQdb_Qdbfh);

  // API Error code
  dcl-ds errCode likeds(errCode_t) inz;

  // Handle
  dcl-ds handle likeds(handle_t) based(pHandle);

  // Handle size
  dcl-s hSize int(10) inz;

  // CEEGSI API
  dcl-s o_msgType int(10) inz;
  dcl-s o_msgCurrLen int(10) inz;
  dcl-s o_msgMaxLen int(10) inz;
  //-------------------------------------------------------------------

  // Determine size of memory needed ...
  pQdb_Qdbfh = *null;

  qFile.name  = i_file;
  qFile.lib   = i_lib;
  errCode     = newApiErrCode(cTrue);

  QDBRTVFD(memSize: %size(memSize): qRetFile: 'FILD0100': qFile
           : '*FIRST': '0': '*LCL': '*EXT': errCode);

  // if there is an error ...
  if (isApiError(errCode));
    // ... then signal an error
    o_isDone = cFalse;
  else;
    // ... allocate memory
    pQdb_Qdbfh = %ALLOC(memSize.needed);

    dou (Qdb_Qdbfh.Qdbfyavl = Qdb_Qdbfh.Qdbfyret);

      // retrieve file definition using API
      QDBRTVFD(Qdb_Qdbfh: memSize.needed: qRetFile: 'FILD0100': qFile
               : '*FIRST': '0': '*LCL': '*EXT': errCode);

      if (isApiError(errCode));
        leave;
      endif;

      if (Qdb_Qdbfh.Qdbfyret < Qdb_Qdbfh.Qdbfyavl);
        memSize.needed = Qdb_Qdbfh.Qdbfyavl;
        pQdb_Qdbfh = %REALLOC(pQdb_Qdbfh:memSize.needed);
      endif;
    enddo;

    // if there is an error ...
    if (isApiError(errCode));
      // ... then signal an error
      o_isDone = cFalse;
    else;
      o_isDone = cTrue;
    endif;
  endif;

  // create error message from the API error code
  msg = cvtApiErrCodeToMsg(errCode);

  // produce handle
  if (o_isDone);
    hSize = %size(handle);
    pHandle = %ALLOC(hSize);
    handle.pFD  = pQdb_Qdbfh;
    handle.file = qRetFile.name;
    handle.lib  = qRetFile.lib;
    o_handle   = pHandle;
  else;
    if (pQdb_Qdbfh <> *NULL);
      Dealloc pQdb_Qdbfh;
    endif;
    o_handle   = *NULL;
  endif;

  if (%parms >= p_msg);
    ceegsi(p_msg: o_msgType: o_msgCurrLen
          : o_msgMaxLen: *omit);
    %subst(o_msg: 1: o_msgCurrLen) = msg;
  endif;

  return o_isDone;

end-proc;

//==================================================================*
//  Close List Of Database File Members
//==================================================================*
dcl-proc f_cloCstLst export;
  dcl-pi *n ind;
    io_handle like(cstLst_handle_t);
  end-pi;

  // Return value
  dcl-s o_isDone ind inz(cFalse);

  // Handle
  dcl-ds handle likeds(handle_t) based(pHandle);

  // Format Definition Header (Qdb_Qdbfh)
  dcl-ds Qdb_Qdbfh likeds(Qdb_Qdbfh_t) based(pQdb_Qdbfh);
  //-------------------------------------------------------------------

  pHandle = io_handle;

  // free memory of data pointer
  pQdb_Qdbfh = handle.pFD;
  Dealloc pQdb_Qdbfh;

  // delete handle
  Dealloc io_handle;
  io_handle = *NULL;

  // set return value
  o_isDone  = cTrue;

  return o_isDone;

end-proc;

//==================================================================*
//  Get First Constraint
//==================================================================*
dcl-proc f_getFirstCst export;
  dcl-pi *n ind opdesc;
    i_handle like(cstLst_handle_t) value;
    o_data   char(32767) options(*varsize);
  end-pi;

  // Return value
  dcl-s o_isDone ind inz(cFalse);

  // Parameter positions
  dcl-c p_data 2;

  // Handle
  dcl-ds handle likeds(handle_t) based(pHandle);

  // CEEGSI API
  dcl-s o_dataType int(10) inz;
  dcl-s o_dataCurrLen int(10) inz;
  dcl-s o_dataMaxLen int(10) inz;
  //-------------------------------------------------------------------

  pHandle = i_handle;

  // get length of o_data
  ceegsi(p_data: o_dataType: o_dataCurrLen: o_dataMaxLen  : *omit);

  // get first entry
  handle.curEntry = 0;

  // retrieve entry data
  o_isDone = getEntry(handle: o_data: o_dataCurrLen );

  return o_isDone;

end-proc;

//==================================================================*
//  Get Next Constraint
//==================================================================*
dcl-proc f_getNextCst export;
  dcl-pi *n ind opdesc;
    i_handle like(cstLst_handle_t) value;
    o_data   char(32767) options(*varsize);
  end-pi;

  // Return value
  dcl-s o_isDone ind inz(cFalse);

  // Parameter positions
  dcl-c p_data 2;

  // Handle
  dcl-ds handle likeds(handle_t) based(pHandle);

  // CEEGSI API
  dcl-s o_dataType int(10) inz;
  dcl-s o_dataCurrLen int(10) inz;
  dcl-s o_dataMaxLen int(10) inz;
  //-------------------------------------------------------------------

  pHandle = i_handle;

  //  Get length of o_data
  ceegsi(p_data: o_dataType: o_dataCurrLen: o_dataMaxLen  : *omit);

  //  Retrieve entry data
  o_isDone = getEntry(handle: o_data: o_dataCurrLen);

  return o_isDone;

end-proc;

//==================================================================*
//  Get Number of Constratints available
//==================================================================*
dcl-proc f_getNumCstAvl export;
  dcl-pi *n int(10);
    i_handle like(cstLst_handle_t) value;
  end-pi;

  // Handle
  dcl-ds handle likeds(handle_t) based(pHandle);

  // QDBRTVFD API ...
  // ... File Definition Header (Qdb_Qdbfh)
  dcl-ds Qdb_Qdbfh likeds(Qdb_Qdbfh_t) based(pQdb_Qdbfh);
  // ... Physical File Specific Attributes (Qdb_Qdbfphys)
  dcl-ds Qdb_Qdbfphys likeds(Qdb_Qdbfphys_t) based(pQdb_Qdbfphys);
  //-------------------------------------------------------------------

  pHandle = i_handle;

  // get access to File Definition Header (Qdb_Qdbfh)
  pQdb_Qdbfh = handle.pFD;

  // get access to Physical File Specific Attributes (Qdb_Qdbfphys)
  pQdb_Qdbfphys = pQdb_Qdbfh + Qdb_Qdbfh.Qdbpfof;

  return Qdb_Qdbfphys.Qdbfcstn;

end-proc;

//==================================================================*
//  Get Entry
//==================================================================*
dcl-proc getEntry;
  dcl-pi *n ind;
    io_handle likeds(handle_t);
    o_data    char(32767) options(*varsize);
    i_length  int(10) value;
  end-pi;

  // Return value
  dcl-s o_isDone ind inz(cFalse);

  // QDBRTVFD API ...
  // ... File Definition Header (Qdb_Qdbfh)
  dcl-ds Qdb_Qdbfh likeds(Qdb_Qdbfh_t) based(pQdb_Qdbfh);
  // ... Physical File Specific Attributes (Qdb_Qdbfphys)
  dcl-ds Qdb_Qdbfphys likeds(Qdb_Qdbfphys_t) based(pQdb_Qdbfphys);
  // ... Constraint Definition Header (Qdb_Qdbf_Constraint)
  dcl-ds Qdb_Qdbf_Constraint likeds(Qdb_Qdbf_Constraint_t) based(pQdb_Qdbf_Constraint);
  // ... Constraint Keys (Qdb_Qdbf_Keyn)
  dcl-ds Qdb_Qdbf_Keyn likeds(Qdb_Qdbf_Keyn_t) based(pQdb_Qdbf_Keyn);
  // ... Referential Constraint Definition (Qdb_Qdbf_Riafk_Afkd)
  dcl-ds Qdb_Qdbf_Riafk_Afkd likeds(Qdb_Qdbf_Riafk_Afkd_t) based(pQdb_Qdbf_Riafk_Afkd);
  // ... Check Constraint (Qdb_Qdbf_Chk_Cst)
  dcl-ds Qdb_Qdbf_Chk_Cst likeds(Qdb_Qdbf_Chk_Cst_t) based(pQdb_Qdbf_Chk_Cst);

  // Return value
  dcl-ds cstl0100 likeds(cstl0100_t) inz;

  // Helper fields
  dcl-ds crtTmStmp qualified;
    date char(7) inz;
    time char(6) inz;
  end-ds;

  dcl-s pFirstConstraint pointer inz;
  dcl-s x int(10) inz;
  //-------------------------------------------------------------------

  Clear cstl0100;

  // get access to File Definition Header (Qdb_Qdbfh)
  pQdb_Qdbfh = io_handle.pFD;

  // get access to Physical File Specific Attributes (Qdb_Qdbfphys)
  pQdb_Qdbfphys = pQdb_Qdbfh +
                 Qdb_Qdbfh.Qdbpfof;

  // if the file has constraints ...
  if (Qdb_Qdbfphys.Qdbfcstn > 0);
    //  ... then remember the starting point of the first constraint
    pFirstConstraint = pQdb_Qdbfh + Qdb_Qdbfphys.Qdbfofcs;

    For x = 0 to Qdb_Qdbfphys.Qdbfcstn - 1;
      if (x = 0);
        // access first constraint
        pQdb_Qdbf_Constraint = pFirstConstraint;
      else;
        // access next constraint
        pQdb_Qdbf_Constraint = pQdb_Qdbf_Constraint +
                               Qdb_Qdbf_Constraint.Qdbf_csto;
      endif;
      // if we are at the entry we are searching for ...
      if (x = io_handle.curEntry);
        // ... then produce return value:
        // file & library
        cstl0100.file    = io_handle.file;
        cstl0100.lib     = io_handle.lib;
        // creation timestamp
        crtTmStmp = Qdb_Qdbf_Constraint.Qdbf_add_ts;
        cstl0100.crtTmStmp = %date(crtTmStmp.date: *CYMD0) +
                             %time(crtTmStmp.time: *HMS0 );
        // constraint name
        cstl0100.cstname = %subst(
                 Qdb_Qdbf_Constraint.Qdbf_cst_name :
                 1                                 :
                 Qdb_Qdbf_Constraint.Qdbf_cst_lp2  );
        // constraint library
        cstl0100.cstlib  = Qdb_Qdbf_Constraint.Qdbf_cst_lin;
        // constraint type
        if (Qdb_Qdbf_Constraint.Qdbf_type = 'F');
          cstl0100.csttype = 'R';
        else;
          cstl0100.csttype = Qdb_Qdbf_Constraint.Qdbf_type;
        endif;
        // check pending status (referential & check constraint)
        if ((Qdb_Qdbf_Constraint.Qdbf_type = 'R')   or
           (Qdb_Qdbf_Constraint.Qdbf_type = 'C'));
          cstl0100.chkpnd = Qdb_Qdbf_Constraint.Qdbf_chkpd;
        else;
          cstl0100.chkpnd = '';
        endif;
        // status (referential & check constraint)
        if (Qdb_Qdbf_Constraint.Qdbf_type = 'R'   or
            Qdb_Qdbf_Constraint.Qdbf_type = 'C');
          cstl0100.cststs  = Qdb_Qdbf_Constraint.Qdbf_state +
                             Qdb_Qdbf_Constraint.Qdbf_abled;
        else;
          cstl0100.cststs  = '';
        endif;

        // retrieve constraint specific information of:
        // referential constraint
        if (Qdb_Qdbf_Constraint.Qdbf_type = 'F');
          // access constraint keys
          pQdb_Qdbf_Keyn = pQdb_Qdbf_Constraint +
                           Qdb_Qdbf_Constraint.Qdbf_Hlen;
          cstl0100.numKeys = Qdb_Qdbf_Keyn.Qdbf_nokys;
          cstl0100.keyLen = Qdb_Qdbf_Keyn.Qdbf_klen;
          cstl0100.fgnKey = rtvKeyFlds(pQdb_Qdbf_Keyn);
          // access constraint keys of parent file
          pQdb_Qdbf_Keyn = pQdb_Qdbf_Keyn + Qdb_Qdbf_keyn.Qdbf_Kslen;
          cstl0100.parKey  = rtvKeyFlds(pQdb_Qdbf_Keyn);
          // referential constraint definition
          pQdb_Qdbf_Riafk_Afkd = pQdb_Qdbf_Keyn +
                                 Qdb_Qdbf_keyn.Qdbf_Kslen;
          cstl0100.parFile = Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_pkfn;
          cstl0100.parLib = Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_pkln;
          cstl0100.dltRule = cvtDltRule(
                               Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_fkcdr);
          cstl0100.updRule = cvtUpdRule(
                               Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_fkcur);
        endif;

        // unique constraint / primary unique constraint
        if ((Qdb_Qdbf_Constraint.Qdbf_type = 'U')   or
           (Qdb_Qdbf_Constraint.Qdbf_type = 'P'));
          //                  ... access constraint keys
          pQdb_Qdbf_Keyn = pQdb_Qdbf_Constraint +
                           Qdb_Qdbf_Constraint.Qdbf_Hlen;
          cstl0100.numKeys = Qdb_Qdbf_Keyn.Qdbf_nokys;
          cstl0100.keyLen = Qdb_Qdbf_Keyn.Qdbf_klen;
          cstl0100.parKey = rtvKeyFlds(pQdb_Qdbf_Keyn);
        endif;

        // check constraint
        if (Qdb_Qdbf_Constraint.Qdbf_type = 'C');
          // check constraint expression
          pQdb_Qdbf_Chk_Cst = pQdb_Qdbf_Constraint +
                              Qdb_Qdbf_Constraint.Qdbf_Hlen;
          if (Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr_len <=
              %len(cstl0100.chkCstExp));
            cstl0100.exptrunc = 'N';
            cstl0100.chkCstExp = %subst(
                      Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr :
                      1                             :
                      Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr_len);
          else;
            cstl0100.exptrunc = 'Y';
            cstl0100.chkCstExp = %subst(
                      Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr :
                      1                             :
                      %len(cstl0100.chkCstExp));
          endif;
        endif;

        io_handle.curEntry = io_handle.curEntry + 1;
        o_isDone = cTrue;
        leave;
      endif;

    Endfor;
  endif;

  %subst(o_data: 1: i_length) = cstl0100;

  return o_isDone;

end-proc;

//==================================================================*
//  Retrieve key fields
//==================================================================*
dcl-proc rtvKeyFlds;
  dcl-pi *n like(cstl0100_t.parKey);
    i_pQdb_Qdbf_Keyn pointer const;
  end-pi;

  //  Return value
  dcl-s o_keyFlds like(cstl0100_t.parKey);

  //  QDBRTVFD API ...
  //  ... Constraint Keys (Qdb_Qdbf_Keyn)
  dcl-ds Qdb_Qdbf_Keyn likeds(Qdb_Qdbf_Keyn_t) based(pQdb_Qdbf_Keyn);
  //  ... Key Name Array (Qdb_Qdbf_Narray)
  dcl-ds Qdb_Qdbf_Narray likeds(Qdb_Qdbf_Narray_t) based(pQdb_Qdbf_Narray);

  //  Helper fields
  dcl-s x int(10) inz;
  dcl-s keyNameLen int(10) inz;
  //-------------------------------------------------------------------

  pQdb_Qdbf_Keyn = i_pQdb_Qdbf_Keyn;

  for x = 1 to Qdb_Qdbf_Keyn.Qdbf_nokys;
    if (x = 1);
      // access first key fields
      pQdb_Qdbf_Narray = %addr(Qdb_Qdbf_Keyn.Qdbf_narray);
    else;
      // access next key field
      pQdb_Qdbf_Narray = pQdb_Qdbf_Narray + %size(Qdb_Qdbf_Narray);
    endif;

    keyNameLen = %len(Qdb_Qdbf_Narray.Qdbf_kname);
    %subst(o_keyFlds                        :
          (x * keyNameLen) - keyNameLen + 1:
          keyNameLen                       ) =
          Qdb_Qdbf_Narray.Qdbf_kname;
  endfor;

  return o_keyFlds;

end-proc;

//==================================================================*
//  Convert Delete Rule
//==================================================================*
dcl-proc cvtDltRule;
  dcl-pi *n like(cstl0100_t.dltRule);
    i_dltRule like(Qdb_Qdbf_Riafk_Afkd_t.Qdbf_riafk_fkcdr) const;
  end-pi;

  //  Return value
  dcl-s o_dltRule like(cstl0100_t.dltRule);
  //-------------------------------------------------------------------

  // Convert delete rule ...
  select;
  // ... *CASCADE
  when (i_dltRule = 'C');
    o_dltRule = 'CC';
  // ... *SETDFT
  when (i_dltRule = 'D');
    o_dltRule = 'SD';
  // ... *SETNULL
  when (i_dltRule = 'L');
    o_dltRule = 'SN';
  // ... *NOACTION
  when (i_dltRule = 'N');
    o_dltRule = 'NA';
  // ... *RESTRICT
  when (i_dltRule = 'R');
    o_dltRule = 'RS';
  // ... unknown delete rule
  Other;
    o_dltRule = '??';
  endsl;

  return o_dltRule;

end-proc;

//==================================================================*
//  Convert Update Rule
//==================================================================*
dcl-proc cvtUpdRule;
  dcl-pi *n like(cstl0100_t.updRule);
    i_updRule like(Qdb_Qdbf_Riafk_Afkd_t.Qdbf_riafk_fkcur) const;
  end-pi;

  //  Return value
  dcl-s o_updRule like(cstl0100_t.updRule);
  //-------------------------------------------------------------------

  // Convert update rule ...
  select;
  // ... *NOACTION
  when (i_updRule = 'N');
    o_updRule = 'NA';
  // ... *RESTRICT
  when (i_updRule = 'R');
    o_updRule = 'RS';
  // ... unknown update rule
  Other;
    o_updRule = '??';
  endsl;

  return o_updRule;

end-proc;

//==================================================================*
//  Is API Error?
// -----------------------------------------------------------------
//    cTrue  - error
//    cFalse - no error
//==================================================================*
dcl-proc isApiError;
  dcl-pi *n ind;
    i_errCode char(272) const;
  end-pi;

  //  Return value
  dcl-s o_isError ind inz(cFalse);

  //  API error code
  dcl-ds errCode likeds(errCode_t) inz;
  //-------------------------------------------------------------------

  errCode = i_errCode;

  if (errCode.bytAvl = 0);
    o_isError = cFalse;
  else;
    o_isError = cTrue;
  endif;

  return o_isError;

end-proc;

//==================================================================*
//  Create API error code
//==================================================================*
dcl-proc newApiErrCode;
  dcl-pi *n char(272);
    i_monmsg ind const;
  end-pi;

  //  Return value
  dcl-ds errCode likeds(errCode_t) inz;
  //-------------------------------------------------------------------

  Clear errCode;

  if (i_monMsg = cTrue);
    errCode.bytPrv = %size(errCode);
  else;
    errCode.bytPrv = 0;
  endif;

  return errCode;

end-proc;

//==================================================================*
//  Convert API error code to message
//==================================================================*
dcl-proc cvtApiErrCodeToMsg;
  dcl-pi *n like(msg_t);
    i_errCode char(272) const;
  end-pi;

  //  Return value
  dcl-ds o_msg likeds(msg_t) inz;

  //  API Error code
  dcl-ds errCode likeds(errCode_t) inz;
  //-------------------------------------------------------------------

  errCode = i_errCode;

  if ((errCode.bytAvl = 0));
    clear o_msg;
  else;
    clear o_msg;
    o_msg.ID   = errCode.excID;
    o_msg.data = errCode.excDta;
    o_msg.type = '*ESCAPE';
    o_msg.file = 'QCPFMSG';
    o_msg.lib  = 'QSYS';
  endif;

  return o_msg;

end-proc;

