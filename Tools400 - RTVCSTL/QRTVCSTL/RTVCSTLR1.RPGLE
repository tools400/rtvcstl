      *=====================================================================*
      *  Author  :  Thomas Raddatz                                          *
      *  Date    :  21.06.2003                                              *
      *  E-mail  :  thomas.raddatz@Tools400.de                              *
      *  Homepage:  www.tools400.de                                         *
      *=====================================================================*
      *                                                                     *
      *  This software is free software, you can redistribute it and/or     *
      *  modify it under the terms of the GNU General Public License (GPL)  *
      *  as published by the Free Software Foundation.                      *
      *                                                                     *
      *  See GNU General Public License for details.                        *
      *          http://www.opensource.org                                  *
      *          http://www.opensource.org/licenses/gpl-license.html        *
      *                                                                     *
      *=====================================================================*
      *  The RTVCSTL service program retrieves the list of constraints      *
      *  that are defined for a database file.                              *
      *  The RTVCSTL service program runs on V5R1 and higher.               *
      *=====================================================================*
      *  History:                                                           *
      *                                                                     *
      *  Datum       Name          Änderung                                 *
      *  ----------  ------------  ---------------------------------------  *
      *  12.08.2003  Th.Raddatz    Added cstl0100.crtTmStmp.                *
      *  12.08.2003  Th.Raddatz    Fixed error in getEntry() when           *
      *                            computing pQdb_Qdbf_Constraint for the   *
      *                            next constraint.                         *
      *                                                                     *
      *=====================================================================*
      *   >>PRE-COMPILER<<                                                  *
      *     >>CRTCMD<<  CRTRPGMOD    MODULE(&LI/&OB) +                      *
      *                              SRCFILE(&SL/&SF) SRCMBR(&SM);          *
      *     >>IMPORTANT<<                                                   *
      *       >>PARM<< TRUNCNBR(*NO);                                       *
      *       >>PARM<< DBGVIEW(*LIST);                                      *
      *       >>PARM<< OPTION(*EVENTF);                                     *
      *     >>END-IMPORTANT<<                                               *
      *     >>EXECUTE<<                                                     *
      *   >>END-PRE-COMPILER<<                                              *
      *=====================================================================*
     H NOMAIN
     H EXTBININT(*YES) BNDDIR('QC2LE')
     H DATFMT(*ISO) TIMFMT(*ISO) DEBUG(*YES)
      /COPY QRTVCSTL,COPYRIGHT
      *=====================================================================*
      *
      *  Exported functions
      /COPY QRTVCSTL,PRTVCSTL
      *
      *  Reference fields
      /COPY QRTVCSTL,FDCSTL0100
      /COPY QRTVCSTL,FDERRCODE
      /COPY QRTVCSTL,FDMSG
      /COPY QRTVCSTL,FDQOBJ
      /COPY QRTVCSTL,QDBRTVFD
      *
      *  Handle
     D handle_t        DS                  qualified            based(pDummy)
     D  pFD                            *
     D  curEntry                     10I 0
     D  file                         10A
     D  lib                          10A
     D  reserved                     16A
      *
      *  Internal used prototypes
     D f_getEntry...
     D                 PR              N
     D  io_handle                                 likeds(handle_t  )
     D  o_data                    32767A          options(*varsize)
     D  i_length                     10I 0 value
      *
     D f_rtvKeyFlds...
     D                 PR                  like(cstl0100_t.parKey)
     D  i_pQdb_Qdbf_Keyn...
     D                                 *   const
      *
     D f_cvtDltRule...
     D                 PR                  like(cstl0100_t.dltRule)
     D  i_dltRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcdr)
      *
     D f_cvtUpdRule...
     D                 PR                  like(cstl0100_t.updRule)
     D  i_updRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcur)
      *
     D f_isApiError...
     D                 PR              N
     D  i_errCode                   272A   const
      *
     D f_newApiErrCode...
     D                 PR           272A
     D  i_monmsg                       N   const
      *
     D f_cvtApiErrCodeToMsg...
     D                 PR                         like(msg_t     )
     D  i_errCode                   272A   const
      *
      *  Prototypes of CEE APIs
     D ceegsi          PR                  extproc('CEEGSI')
     D  i_posN                       10I 0 const
     D  o_dataType                   10I 0
     D  o_currLen                    10I 0
     D  o_maxLen                     10I 0
     D  o_fc                         12A          options(*omit)
      *
      *  Global constants
     D cTrue           C                   const(*on )
     D cFalse          C                   const(*off)
      *
      *==================================================================*
      *  Open List Of Database File Members
      *==================================================================*
      *
     P f_opnCstLst...
     P                 B                   export
     D                 PI              N   opdesc
     D  i_file                       10A   const
     D  i_lib                        10A   const
     D  i_orderBy                    10A   value
     D  o_handle                                  like(cstLst_handle_t)
     D  o_msg                     32767A          options(*nopass :
     D                                                    *varsize)
      *
      *  Return value
     D o_isDone        S               N   inz(cFalse)
      *
      *  Parameter positions
     D p_msg           C                   const(5)
      *
      *  Optional parameter fields
     D msg             DS                  likeds(msg_t)  inz
      *
      *  QDBRTVFD API fields
     D qFile           DS                  likeds(qObj_t) inz
     D qRetFile        DS                  likeds(qObj_t) inz
      *
     D memSize         DS                  qualified            inz
     D  returned               1      4I 0
     D  needed                 5      8I 0
      *
      *  File Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t)
     D                                     based(pQdb_Qdbfh)
      *
      *  API Error code
     D errCode         DS                  likeds(errCode_t) inz
      *
      *  Handle
     D handle          DS                  likeds(handle_t)  based(pHandle)
      *
      *  Handle size
     D hSize           S             10I 0 inz
      *
      *  CEEGSI API
     D o_msgType       S             10I 0 inz
     D o_msgCurrLen    S             10I 0 inz
     D o_msgMaxLen     S             10I 0 inz
      *-------------------------------------------------------------------
      *
      *  Determine size of memory needed ...
     C                   Eval      pQdb_Qdbfh = *null
      *
     C                   Eval      qFile.name  = i_file
     C                   Eval      qFile.lib   = i_lib
     C                   Eval      errCode     = f_newApiErrCode(cTrue)
      *
     C                   Callp     QDBRTVFD(memSize         :
     C                                      %size(memSize)  :
     C                                      qRetFile        :
     C                                      'FILD0100'      :
     C                                      qFile           :
     C                                      '*FIRST'        :
     C                                      '0'             :
     C                                      '*LCL'          :
     C                                      '*EXT'          :
     C                                      errCode         )
      *
      *  If there is an error ...
     C                   If        f_isApiError(errCode)
      *  ... then
      *      signal error
     C                   Eval      o_isDone = cFalse
     C                   Else
      *  ... else
      *      allocate memory
     C                   Alloc     memSize.neededpQdb_Qdbfh
      *
     C                   Dou       Qdb_Qdbfh.Qdbfyavl = Qdb_Qdbfh.Qdbfyret
      *      Retrieve file definition
     C                   Callp     QDBRTVFD(Qdb_Qdbfh      :
     C                                      memSize.needed :
     C                                      qRetFile       :
     C                                      'FILD0100'     :
     C                                      qFile          :
     C                                      '*FIRST'       :
     C                                      '0'            :
     C                                      '*LCL'         :
     C                                      '*EXT'         :
     C                                      errCode        )
      *
     C                   If        f_isApiError(errCode)
     C                   Leave
     C                   Endif
      *
     C                   If        Qdb_Qdbfh.Qdbfyret < Qdb_Qdbfh.Qdbfyavl
     C                   Eval      memSize.needed = Qdb_Qdbfh.Qdbfyavl
     C                   Realloc   memSize.neededpQdb_Qdbfh
     C                   Endif
     C                   Enddo
      *
      *      If there is an error ...
     C                   If        f_isApiError(errCode)
      *      ... then
      *          signal error
     C                   Eval      o_isDone = cFalse
     C                   Else
      *      ... else
      *          signal OK
     C                   Eval      o_isDone = cTrue
     C                   Endif
     C                   Endif
      *
      *  Create error message from API error code
     C                   Eval      msg = f_cvtApiErrCodeToMsg(errCode)
      *
      *  Produce handle
     C                   If        o_isDone
     C                   Eval      hSize = %size(handle)
     C                   Alloc     hSize         pHandle
     C                   Eval      handle.pFD  = pQdb_Qdbfh
     C                   Eval      handle.file = qRetFile.name
     C                   Eval      handle.lib  = qRetFile.lib
     C                   Eval      o_handle   = pHandle
     C                   Else
     C                   If        pQdb_Qdbfh <> *NULL
     C                   Dealloc                 pQdb_Qdbfh
     C                   Endif
     C                   Eval      o_handle   = *NULL
     C                   Endif
      *
     C                   If        %parms >= p_msg
     C                   Callp     ceegsi(p_msg: o_msgType: o_msgCurrLen
     C                                    : o_msgMaxLen: *omit)
     C                   Eval      %subst(o_msg: 1: o_msgCurrLen) = msg
     C                   Endif
      *
     C                   Return    o_isDone
      *
     P                 E
      *
      *==================================================================*
      *  Close List Of Database File Members
      *==================================================================*
      *
     P f_cloCstLst...
     P                 B                   export
      *
     D f_cloCstLst...
     D                 PI              N
     D  io_handle                                 like(cstLst_handle_t)
      *
      *  Return value
     D o_isDone        S               N   inz(cFalse)
      *
      *  Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)
      *
      *  Format Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t )
     D                                     based(pQdb_Qdbfh  )
      *-------------------------------------------------------------------
      *
     C                   Eval      pHandle = io_handle
      *
      *  Free memory
     C                   Eval      pQdb_Qdbfh = handle.pFD
     C                   Dealloc                 pQdb_Qdbfh
      *
      *  Delete handle
     C                   Dealloc                 io_handle
     C                   Eval      io_handle = *NULL
      *
      *  Set return value
     C                   Eval      o_isDone  = cTrue
      *
     C                   Return    o_isDone
      *
     P f_cloCstLst...
     P                 E
      *
      *==================================================================*
      *  Get First Constraint
      *==================================================================*
      *
     P f_getFirstCst...
     P                 B                   export
     D                 PI              N          opdesc
     D  i_handle                           value  like(cstLst_handle_t)
     D  o_data                    32767A          options(*varsize)
      *
      *  Return value
     D o_isDone        S               N   inz(cFalse)
      *
      *  Parameter positions
     D p_data          C                   const(2)
      *
      *  Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)
      *
      *  CEEGSI API
     D o_dataType      S             10I 0 inz
     D o_dataCurrLen   S             10I 0 inz
     D o_dataMaxLen    S             10I 0 inz
      *-------------------------------------------------------------------
      *
     C                   Eval      pHandle = i_handle
      *
      *  Get length of o_data
     C                   Callp     ceegsi(p_data: o_dataType: o_dataCurrLen
     C                                    : o_dataMaxLen  : *omit)
      *
      *  Get first entry
     C                   Eval      handle.curEntry = 0
      *
      *  Retrieve entry data
     C                   Eval      o_isDone = f_getEntry(handle        :
     C                                                   o_data        :
     C                                                   o_dataCurrLen )
      *
     C                   Return    o_isDone
      *
     P                 E
      *
      *==================================================================*
      *  Get Next Constraint
      *==================================================================*
      *
     P f_getNextCst...
     P                 B                   export
     D                 PI              N          opdesc
     D  i_handle                           value  like(cstLst_handle_t)
     D  o_data                    32767A          options(*varsize)
      *
      *  Return value
     D o_isDone        S               N   inz(cFalse)
      *
      *  Parameter positions
     D p_data          C                   const(2)
      *
      *  Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)
      *
      *  CEEGSI API
     D o_dataType      S             10I 0 inz
     D o_dataCurrLen   S             10I 0 inz
     D o_dataMaxLen    S             10I 0 inz
      *-------------------------------------------------------------------
      *
     C                   Eval      pHandle = i_handle
      *
      *  Get length of o_data
     C                   Callp     ceegsi(p_data: o_dataType: o_dataCurrLen
     C                                    : o_dataMaxLen  : *omit)
      *
      *  Retrieve entry data
     C                   Eval      o_isDone = f_getEntry(handle        :
     C                                                   o_data        :
     C                                                   o_dataCurrLen )
      *
     C                   Return    o_isDone
      *
     P                 E
      *
      *==================================================================*
      *  Get Number of Constratints available
      *==================================================================*
      *
     P f_getNumCstAvl...
     P                 B                   export
     D                 PI            10I 0
     D  i_handle                           value  like(cstLst_handle_t)
      *
      *  Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)
      *
      *  QDBRTVFD API ...
      *  ... File Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t    )
     D                                     based(pQdb_Qdbfh   )
      *  ... Physical File Specific Attributes (Qdb_Qdbfphys)
     D Qdb_Qdbfphys    DS                  likeds(Qdb_Qdbfphys_t )
     D                                     based(pQdb_Qdbfphys)
      *-------------------------------------------------------------------
      *
     C                   Eval      pHandle = i_handle
      *
      *  Get access to File Definition Header (Qdb_Qdbfh)
     C                   Eval      pQdb_Qdbfh = handle.pFD
      *
      *  Get access to Physical File Specific Attributes (Qdb_Qdbfphys)
     C                   Eval      pQdb_Qdbfphys = pQdb_Qdbfh +
     C                                             Qdb_Qdbfh.Qdbpfof
      *
     C                   Return    Qdb_Qdbfphys.Qdbfcstn
      *
     P                 E
      *
      *==================================================================*
      *  Get Entry
      *==================================================================*
      *
     P f_getEntry...
     P                 B
     D                 PI              N
     D  io_handle                                 likeds(handle_t  )
     D  o_data                    32767A          options(*varsize)
     D  i_length                     10I 0 value
      *
      *  Return value
     D o_isDone        S               N   inz(cFalse)
      *
      *  QDBRTVFD API ...
      *  ... File Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t    )
     D                                     based(pQdb_Qdbfh   )
      *  ... Physical File Specific Attributes (Qdb_Qdbfphys)
     D Qdb_Qdbfphys    DS                  likeds(Qdb_Qdbfphys_t )
     D                                     based(pQdb_Qdbfphys)
      *  ... Constraint Definition Header (Qdb_Qdbf_Constraint)
     D Qdb_Qdbf_Constraint...
     D                 DS                  likeds(Qdb_Qdbf_Constraint_t)
     D                                     based(pQdb_Qdbf_Constraint)
      *  ... Constraint Keys (Qdb_Qdbf_Keyn)
     D Qdb_Qdbf_Keyn   DS                  likeds(Qdb_Qdbf_Keyn_t      )
     D                                     based(pQdb_Qdbf_Keyn      )
      *  ... Referential Constraint Definition (Qdb_Qdbf_Riafk_Afkd)
     D Qdb_Qdbf_Riafk_Afkd...
     D                 DS                  likeds(Qdb_Qdbf_Riafk_Afkd_t)
     D                                     based(pQdb_Qdbf_Riafk_Afkd)
      *  ... Check Constraint (Qdb_Qdbf_Chk_Cst)
     D Qdb_Qdbf_Chk_Cst...
     D                 DS                  likeds(Qdb_Qdbf_Chk_Cst_t   )
     D                                     based(pQdb_Qdbf_Chk_Cst   )
      *
      *  Return data
     D cstl0100        DS                  likeds(cstl0100_t) inz
      *
      *  Helper fields
     D crtTmStmp       DS                  qualified
     D  date                          7A   inz
     D  time                          6A   inz
      *
     D pFirstConstraint...
     D                 S               *   inz
     D x               S             10I 0 inz
      *-------------------------------------------------------------------
      *
     C                   Clear                   cstl0100
      *
      *  Get access to File Definition Header (Qdb_Qdbfh)
     C                   Eval      pQdb_Qdbfh = io_handle.pFD
      *
      *  Get access to Physical File Specific Attributes (Qdb_Qdbfphys)
     C                   Eval      pQdb_Qdbfphys = pQdb_Qdbfh +
     C                                             Qdb_Qdbfh.Qdbpfof
      *
      *  If the file has constraints ...
     C                   If        Qdb_Qdbfphys.Qdbfcstn > 0
      *  ... then
      *      remember the starting point of the first constraint
     C                   Eval      pFirstConstraint = pQdb_Qdbfh +
     C                                                Qdb_Qdbfphys.Qdbfofcs
      *
     C                   For       x = 0 to Qdb_Qdbfphys.Qdbfcstn - 1
     C                   If        x = 0
      *      access first constraint
     C                   Eval      pQdb_Qdbf_Constraint = pFirstConstraint
     C                   Else
      *      access next constraint
     C                   Eval      pQdb_Qdbf_Constraint = pQdb_Qdbf_Constraint +
     C                                             Qdb_Qdbf_Constraint.Qdbf_csto
     C                   Endif
      *      if we are at the entry we are searching for ...
     C                   If        x = io_handle.curEntry
      *      ... then
      *          produce return value ...
      *          ... file & library
     C                   Eval      cstl0100.file    = io_handle.file
     C                   Eval      cstl0100.lib     = io_handle.lib
      *          ... creation timestamp
     C                   Eval      crtTmStmp = Qdb_Qdbf_Constraint.Qdbf_add_ts
     C                   Eval      cstl0100.crtTmStmp =
     C                                      %date(crtTmStmp.date: *CYMD0) +
     C                                      %time(crtTmStmp.time: *HMS0 )
      *          ... constraint name
     C                   Eval      cstl0100.cstname = %subst(
     C                                       Qdb_Qdbf_Constraint.Qdbf_cst_name :
     C                                       1                                 :
     C                                       Qdb_Qdbf_Constraint.Qdbf_cst_lp2  )
      *          ... constraint library
     C                   Eval      cstl0100.cstlib  =
     C                                       Qdb_Qdbf_Constraint.Qdbf_cst_lin
      *          ... constraint type
     C                   If        Qdb_Qdbf_Constraint.Qdbf_type = 'F'
     C                   Eval      cstl0100.csttype = 'R'
     C                   Else
     C                   Eval      cstl0100.csttype =
     C                                       Qdb_Qdbf_Constraint.Qdbf_type
     C                   Endif
      *          ... check pending status (referential & check constraint)
     C                   If        (Qdb_Qdbf_Constraint.Qdbf_type = 'R')   or
     C                             (Qdb_Qdbf_Constraint.Qdbf_type = 'C')
     C                   Eval      cstl0100.chkpnd  =
     C                                       Qdb_Qdbf_Constraint.Qdbf_chkpd
     C                   Else
     C                   Eval      cstl0100.chkpnd  = ''
     C                   Endif
      *          ... status               (referential & check constraint)
     C                   If        (Qdb_Qdbf_Constraint.Qdbf_type = 'R')   or
     C                             (Qdb_Qdbf_Constraint.Qdbf_type = 'C')
     C                   Eval      cstl0100.cststs  =
     C                                       Qdb_Qdbf_Constraint.Qdbf_state +
     C                                       Qdb_Qdbf_Constraint.Qdbf_abled
     C                   Else
     C                   Eval      cstl0100.cststs  = ''
     C                   Endif
      *
      *          ... retrieve constraint specific information of ...
      *              ... referential constraint
     C                   If        Qdb_Qdbf_Constraint.Qdbf_type = 'F'
      *                  ... access constraint keys
     C                   Eval      pQdb_Qdbf_Keyn = pQdb_Qdbf_Constraint +
     C                                             Qdb_Qdbf_Constraint.Qdbf_Hlen
     C                   Eval      cstl0100.numKeys = Qdb_Qdbf_Keyn.Qdbf_nokys
     C                   Eval      cstl0100.keyLen  = Qdb_Qdbf_Keyn.Qdbf_klen
     C                   Eval      cstl0100.fgnKey  =
     C                                              f_rtvKeyFlds(pQdb_Qdbf_Keyn)
      *                  ... access constraint keys of parent file
     C                   Eval      pQdb_Qdbf_Keyn = pQdb_Qdbf_Keyn +
     C                                              Qdb_Qdbf_keyn.Qdbf_Kslen
     C                   Eval      cstl0100.parKey  =
     C                                              f_rtvKeyFlds(pQdb_Qdbf_Keyn)
      *                  ... referential constraint definition
     C                   Eval      pQdb_Qdbf_Riafk_Afkd =
     C                                              pQdb_Qdbf_Keyn +
     C                                              Qdb_Qdbf_keyn.Qdbf_Kslen
     C                   Eval      cstl0100.parFile =
     C                                     Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_pkfn
     C                   Eval      cstl0100.parLib  =
     C                                     Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_pkln
     C                   Eval      cstl0100.dltRule = f_cvtDltRule(
     C                                     Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_fkcdr)
     C                   Eval      cstl0100.updRule = f_cvtUpdRule(
     C                                     Qdb_Qdbf_Riafk_Afkd.Qdbf_riafk_fkcur)
     C                   Endif
      *
      *              ... unique constraint / primary unique constraint
     C                   If        (Qdb_Qdbf_Constraint.Qdbf_type = 'U')   or
     C                             (Qdb_Qdbf_Constraint.Qdbf_type = 'P')
      *                  ... access constraint keys
     C                   Eval      pQdb_Qdbf_Keyn = pQdb_Qdbf_Constraint +
     C                                             Qdb_Qdbf_Constraint.Qdbf_Hlen
     C                   Eval      cstl0100.numKeys = Qdb_Qdbf_Keyn.Qdbf_nokys
     C                   Eval      cstl0100.keyLen  = Qdb_Qdbf_Keyn.Qdbf_klen
     C                   Eval      cstl0100.parKey  =
     C                                              f_rtvKeyFlds(pQdb_Qdbf_Keyn)
     C                   Endif
      *
      *              ... check constraint
     C                   If        Qdb_Qdbf_Constraint.Qdbf_type = 'C'
      *                  ... check constraint expression
     C                   Eval      pQdb_Qdbf_Chk_Cst = pQdb_Qdbf_Constraint +
     C                                             Qdb_Qdbf_Constraint.Qdbf_Hlen
     C                   If        Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr_len <=
     C                                                  %len(cstl0100.chkCstExp)
     C                   Eval      cstl0100.exptrunc = 'N'
     C                   Eval      cstl0100.chkCstExp =
     C                                    %subst(Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr :
     C                                        1                                :
     C                                        Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr_len)
     C                   Else
     C                   Eval      cstl0100.exptrunc = 'Y'
     C                   Eval      cstl0100.chkCstExp =
     C                                    %subst(Qdb_Qdbf_Chk_Cst.Qdbf_chkexpr :
     C                                        1                                :
     C                                        %len(cstl0100.chkCstExp)         )
     C                   Endif
     C                   Endif
      *
     C                   Eval      io_handle.curEntry = io_handle.curEntry + 1
     C                   Eval      o_isDone = cTrue
     C                   Leave
     C                   Endif
      *
     C                   Endfor
     C                   Endif
      *
     C                   Eval      %subst(o_data: 1: i_length) = cstl0100
      *
     C                   Return    o_isDone
      *
     P                 E
      *
      *==================================================================*
      *  Retrieve key fields
      *==================================================================*
      *
     P f_rtvKeyFlds...
     P                 B
     D                 PI                  like(cstl0100_t.parKey)
     D  i_pQdb_Qdbf_Keyn...
     D                                 *   const
      *
      *  Return value
     D o_keyFlds       S                   like(cstl0100_t.parKey)
      *
      *  QDBRTVFD API ...
      *  ... Constraint Keys (Qdb_Qdbf_Keyn)
     D Qdb_Qdbf_Keyn   DS                  likeds(Qdb_Qdbf_Keyn_t      )
     D                                     based(pQdb_Qdbf_Keyn      )
      *  ... Key Name Array (Qdb_Qdbf_Narray)
     D Qdb_Qdbf_Narray...
     D                 DS                  likeds(Qdb_Qdbf_Narray_t    )
     D                                     based(pQdb_Qdbf_Narray    )
      *
      *  Helper fields
     D x               S             10I 0 inz
     D keyNameLen      S             10I 0 inz
      *-------------------------------------------------------------------
      *
     C                   Eval      pQdb_Qdbf_Keyn = i_pQdb_Qdbf_Keyn
      *
     C                   For       x = 1 to Qdb_Qdbf_Keyn.Qdbf_nokys
     C                   If        x = 1
      *              access first key fields
     C                   Eval      pQdb_Qdbf_Narray =
     C                                          %addr(Qdb_Qdbf_Keyn.Qdbf_narray)
     C                   Else
      *              access next key field
     C                   Eval      pQdb_Qdbf_Narray = pQdb_Qdbf_Narray +
     C                                                %size(Qdb_Qdbf_Narray)
     C                   Endif
      *
     C                   Eval      keyNameLen = %len(Qdb_Qdbf_Narray.Qdbf_kname)
     C                   Eval      %subst(o_keyFlds                        :
     C                                    (x * keyNameLen) - keyNameLen + 1:
     C                                    keyNameLen                       ) =
     C                                    Qdb_Qdbf_Narray.Qdbf_kname
     C                   Endfor
      *
     C                   Return    o_keyFlds
      *
     P                 E
      *
      *==================================================================*
      *  Convert Delete Rule
      *==================================================================*
      *
     P f_cvtDltRule...
     P                 B
     D                 PI                  like(cstl0100_t.dltRule)
     D  i_dltRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcdr)
      *
      *  Return value
     D o_dltRule       S                   like(cstl0100_t.dltRule)
      *-------------------------------------------------------------------
      *
      *  Convert delete rule ...
     C                   Select
      *  ... *CASCADE
     C                   When      i_dltRule = 'C'
     C                   Eval      o_dltRule = 'CC'
      *  ... *SETDFT
     C                   When      i_dltRule = 'D'
     C                   Eval      o_dltRule = 'SD'
      *  ... *SETNULL
     C                   When      i_dltRule = 'L'
     C                   Eval      o_dltRule = 'SN'
      *  ... *NOACTION
     C                   When      i_dltRule = 'N'
     C                   Eval      o_dltRule = 'NA'
      *  ... *RESTRICT
     C                   When      i_dltRule = 'R'
     C                   Eval      o_dltRule = 'RS'
      *  ... unknown delete rule
     C                   Other
     C                   Eval      o_dltRule = '??'
     C                   Endsl
      *
     C                   Return    o_dltRule
      *
     P                 E
      *
      *==================================================================*
      *  Convert Update Rule
      *==================================================================*
      *
     P f_cvtUpdRule...
     P                 B
     D                 PI                  like(cstl0100_t.updRule)
     D  i_updRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcur)
      *
      *  Return value
     D o_updRule       S                   like(cstl0100_t.updRule)
      *-------------------------------------------------------------------
      *
      *  Convert update rule ...
     C                   Select
      *  ... *NOACTION
     C                   When      i_updRule = 'N'
     C                   Eval      o_updRule = 'NA'
      *  ... *RESTRICT
     C                   When      i_updRule = 'R'
     C                   Eval      o_updRule = 'RS'
      *  ... unknown update rule
     C                   Other
     C                   Eval      o_updRule = '??'
     C                   Endsl
      *
     C                   Return    o_updRule
      *
     P                 E
      *
      *==================================================================*
      *  Is API Error?
      * -----------------------------------------------------------------
      *    cTrue  - error
      *    cFalse - no error
      *==================================================================*
      *
     P f_isApiError...
     P                 B
     D                 PI              N
     D  i_errCode                   272A   const
      *
      *  Return value
     D o_isError       S               N   inz(cFalse)
      *
      *  API error code
     D errCode         DS                  likeds(errCode_t) inz
      *-------------------------------------------------------------------
      *
     C                   Eval      errCode = i_errCode
      *
     C                   If        errCode.bytAvl = 0
     C                   Eval      o_isError = cFalse
     C                   Else
     C                   Eval      o_isError = cTrue
     C                   Endif
      *
     C                   Return    o_isError
      *
     P                 E
      *
      *==================================================================*
      *  Create API error code
      *==================================================================*
      *
     P f_newApiErrCode...
     P                 B
     D                 PI           272A
     D  i_monmsg                       N   const
      *
      *  Return value
     D errCode         DS                  likeds(errCode_t) inz
      *-------------------------------------------------------------------
      *
     C                   Clear                   errCode
      *
     C                   If        i_monMsg = cTrue
     C                   Eval      errCode.bytPrv = %size(errCode)
     C                   Else
     C                   Eval      errCode.bytPrv = 0
     C                   Endif
      *
     C                   Return    errCode
      *
     P                 E
      *
      *==================================================================*
      *  Convert API error code to message
      *==================================================================*
      *
     P f_cvtApiErrCodeToMsg...
     P                 B
     D                 PI                         like(msg_t)
     D  i_errCode                   272A   const
      *
      *  Return value
     D o_msg           DS                  likeds(msg_t) inz
      *
      *  API Error code
     D errCode         DS                  likeds(errCode_t) inz
      *-------------------------------------------------------------------
      *
     C                   Eval      errCode = i_errCode
      *
     C                   If        errCode.bytAvl = 0
     C                   Clear                   o_msg
     C                   Else
     C                   Clear                   o_msg
     C                   Eval      o_msg.ID   = errCode.excID
     C                   Eval      o_msg.data = errCode.excDta
     C                   Eval      o_msg.type = '*ESCAPE'
     C                   Eval      o_msg.file = 'QCPFMSG'
     C                   Eval      o_msg.lib  = 'QSYS'
     C                   Endif
      *
     C                   Return    o_msg
      *
     P                 E
      *
