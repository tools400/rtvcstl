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
     H NOMAIN
     H EXTBININT(*YES) BNDDIR('QC2LE')
     H DATFMT(*ISO) TIMFMT(*ISO) DEBUG(*YES)
      /COPY QRTVCSTL,COPYRIGHT
       //=====================================================================*

       //  Exported functions
      /COPY QRTVCSTL,PRTVCSTL

       //  Reference fields
      /COPY QRTVCSTL,FDCSTL0100
      /COPY QRTVCSTL,FDERRCODE
      /COPY QRTVCSTL,FDMSG
      /COPY QRTVCSTL,FDQOBJ
      /COPY QRTVCSTL,QDBRTVFD

       //  Handle
     D handle_t        DS                  qualified            based(pDummy)
     D  pFD                            *
     D  curEntry                     10I 0
     D  file                         10A
     D  lib                          10A
     D  reserved                     16A

       //  Internal used prototypes
     D getEntry...
     D                 PR              N
     D  io_handle                                 likeds(handle_t  )
     D  o_data                    32767A          options(*varsize)
     D  i_length                     10I 0 value

     D rtvKeyFlds...
     D                 PR                  like(cstl0100_t.parKey)
     D  i_pQdb_Qdbf_Keyn...
     D                                 *   const

     D cvtDltRule...
     D                 PR                  like(cstl0100_t.dltRule)
     D  i_dltRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcdr)

     D cvtUpdRule...
     D                 PR                  like(cstl0100_t.updRule)
     D  i_updRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcur)

     D isApiError...
     D                 PR              N
     D  i_errCode                   272A   const

     D newApiErrCode...
     D                 PR           272A
     D  i_monmsg                       N   const

     D cvtApiErrCodeToMsg...
     D                 PR                         like(msg_t)
     D  i_errCode                   272A   const

       //  Prototypes of CEE APIs
     D ceegsi          PR                  extproc('CEEGSI')
     D  i_posN                       10I 0 const
     D  o_dataType                   10I 0
     D  o_currLen                    10I 0
     D  o_maxLen                     10I 0
     D  o_fc                         12A          options(*omit)

       //  Global constants
     D cTrue           C                   const(*on )
     D cFalse          C                   const(*off)

       //==================================================================*
       //  Open List Of Database File Members
       //==================================================================*
     P f_opnCstLst...
     P                 B                   export
     D                 PI              N   opdesc
     D  i_file                       10A   const
     D  i_lib                        10A   const
     D  i_orderBy                    10A   value
     D  o_handle                                  like(cstLst_handle_t)
     D  o_msg                     32767A          options(*nopass: *varsize)

       // Return value
     D o_isDone        S               N   inz(cFalse)

       // Parameter positions
     D p_msg           C                   const(5)

       // Optional parameter fields
     D msg             DS                  likeds(msg_t)  inz

       // QDBRTVFD API fields
     D qFile           DS                  likeds(qObj_t) inz
     D qRetFile        DS                  likeds(qObj_t) inz

     D memSize         DS                  qualified            inz
     D returned                      10I 0
     D needed                        10I 0

       // File Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t)
     D                                     based(pQdb_Qdbfh)

       // API Error code
     D errCode         DS                  likeds(errCode_t) inz

       // Handle
     D handle          DS                  likeds(handle_t)  based(pHandle)

       // Handle size
     D hSize           S             10I 0 inz

       // CEEGSI API
     D o_msgType       S             10I 0 inz
     D o_msgCurrLen    S             10I 0 inz
     D o_msgMaxLen     S             10I 0 inz
       //-------------------------------------------------------------------
      /FREE

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

      /END-FREE
     P                 E

       //==================================================================*
       //  Close List Of Database File Members
       //==================================================================*
     P f_cloCstLst...
     P                 B                   export
     D                 PI              N
     D  io_handle                                 like(cstLst_handle_t)

       // Return value
     D o_isDone        S               N   inz(cFalse)

       // Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)

       // Format Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t )
     D                                     based(pQdb_Qdbfh  )
       //-------------------------------------------------------------------
      /FREE

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

      /END-FREE
     P                 E

       //==================================================================*
       //  Get First Constraint
       //==================================================================*
     P f_getFirstCst...
     P                 B                   export
     D                 PI              N          opdesc
     D  i_handle                           value  like(cstLst_handle_t)
     D  o_data                    32767A          options(*varsize)

       // Return value
     D o_isDone        S               N   inz(cFalse)

       // Parameter positions
     D p_data          C                   const(2)

       // Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)

       // CEEGSI API
     D o_dataType      S             10I 0 inz
     D o_dataCurrLen   S             10I 0 inz
     D o_dataMaxLen    S             10I 0 inz
       //-------------------------------------------------------------------
      /FREE

       pHandle = i_handle;

       // get length of o_data
       ceegsi(p_data: o_dataType: o_dataCurrLen: o_dataMaxLen  : *omit);

       // get first entry
       handle.curEntry = 0;

       // retrieve entry data
       o_isDone = getEntry(handle: o_data: o_dataCurrLen );

       return o_isDone;

      /END-FREE
     P                 E

       //==================================================================*
       //  Get Next Constraint
       //==================================================================*
     P f_getNextCst...
     P                 B                   export
     D                 PI              N          opdesc
     D  i_handle                           value  like(cstLst_handle_t)
     D  o_data                    32767A          options(*varsize)

       // Return value
     D o_isDone        S               N   inz(cFalse)

       // Parameter positions
     D p_data          C                   const(2)

       // Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)

       // CEEGSI API
     D o_dataType      S             10I 0 inz
     D o_dataCurrLen   S             10I 0 inz
     D o_dataMaxLen    S             10I 0 inz
       //-------------------------------------------------------------------
      /FREE

       pHandle = i_handle;

       //  Get length of o_data
       ceegsi(p_data: o_dataType: o_dataCurrLen: o_dataMaxLen  : *omit);

       //  Retrieve entry data
       o_isDone = getEntry(handle: o_data: o_dataCurrLen);

       return o_isDone;

      /END-FREE
     P                 E

       //==================================================================*
       //  Get Number of Constratints available
       //==================================================================*
     P f_getNumCstAvl...
     P                 B                   export
     D                 PI            10I 0
     D  i_handle                           value  like(cstLst_handle_t)

       // Handle
     D handle          DS                  likeds(handle_t   )  based(pHandle)

       // QDBRTVFD API ...
       // ... File Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t    )
     D                                     based(pQdb_Qdbfh   )
       // ... Physical File Specific Attributes (Qdb_Qdbfphys)
     D Qdb_Qdbfphys    DS                  likeds(Qdb_Qdbfphys_t )
     D                                     based(pQdb_Qdbfphys)
       //-------------------------------------------------------------------
      /FREE

       pHandle = i_handle;

       // get access to File Definition Header (Qdb_Qdbfh)
       pQdb_Qdbfh = handle.pFD;

       // get access to Physical File Specific Attributes (Qdb_Qdbfphys)
       pQdb_Qdbfphys = pQdb_Qdbfh + Qdb_Qdbfh.Qdbpfof;

       return Qdb_Qdbfphys.Qdbfcstn;

      /END-FREE
     P                 E

       //==================================================================*
       //  Get Entry
       //==================================================================*
     P getEntry...
     P                 B
     D                 PI              N
     D  io_handle                                 likeds(handle_t  )
     D  o_data                    32767A          options(*varsize)
     D  i_length                     10I 0 value

       // Return value
     D o_isDone        S               N   inz(cFalse)

       // QDBRTVFD API ...
       // ... File Definition Header (Qdb_Qdbfh)
     D Qdb_Qdbfh       DS                  likeds(Qdb_Qdbfh_t    )
     D                                     based(pQdb_Qdbfh   )
       // ... Physical File Specific Attributes (Qdb_Qdbfphys)
     D Qdb_Qdbfphys    DS                  likeds(Qdb_Qdbfphys_t )
     D                                     based(pQdb_Qdbfphys)
       // ... Constraint Definition Header (Qdb_Qdbf_Constraint)
     D Qdb_Qdbf_Constraint...
     D                 DS                  likeds(Qdb_Qdbf_Constraint_t)
     D                                     based(pQdb_Qdbf_Constraint)
       // ... Constraint Keys (Qdb_Qdbf_Keyn)
     D Qdb_Qdbf_Keyn   DS                  likeds(Qdb_Qdbf_Keyn_t      )
     D                                     based(pQdb_Qdbf_Keyn      )
       // ... Referential Constraint Definition (Qdb_Qdbf_Riafk_Afkd)
     D Qdb_Qdbf_Riafk_Afkd...
     D                 DS                  likeds(Qdb_Qdbf_Riafk_Afkd_t)
     D                                     based(pQdb_Qdbf_Riafk_Afkd)
       // ... Check Constraint (Qdb_Qdbf_Chk_Cst)
     D Qdb_Qdbf_Chk_Cst...
     D                 DS                  likeds(Qdb_Qdbf_Chk_Cst_t   )
     D                                     based(pQdb_Qdbf_Chk_Cst   )

       // Return value
     D cstl0100        DS                  likeds(cstl0100_t) inz

       // Helper fields
     D crtTmStmp       DS                  qualified
     D  date                          7A   inz
     D  time                          6A   inz

     D pFirstConstraint...
     D                 S               *   inz
     D x               S             10I 0 inz
       //-------------------------------------------------------------------
      /FREE

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

      /END-FREE
     P                 E

       //==================================================================*
       //  Retrieve key fields
       //==================================================================*
     P rtvKeyFlds...
     P                 B
     D                 PI                  like(cstl0100_t.parKey)
     D  i_pQdb_Qdbf_Keyn...
     D                                 *   const

       //  Return value
     D o_keyFlds       S                   like(cstl0100_t.parKey)

       //  QDBRTVFD API ...
       //  ... Constraint Keys (Qdb_Qdbf_Keyn)
     D Qdb_Qdbf_Keyn   DS                  likeds(Qdb_Qdbf_Keyn_t      )
     D                                     based(pQdb_Qdbf_Keyn      )
       //  ... Key Name Array (Qdb_Qdbf_Narray)
     D Qdb_Qdbf_Narray...
     D                 DS                  likeds(Qdb_Qdbf_Narray_t    )
     D                                     based(pQdb_Qdbf_Narray    )

       //  Helper fields
     D x               S             10I 0 inz
     D keyNameLen      S             10I 0 inz
       //-------------------------------------------------------------------
      /FREE

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

      /END-FREE
     P                 E

       //==================================================================*
       //  Convert Delete Rule
       //==================================================================*
     P cvtDltRule...
     P                 B
     D                 PI                  like(cstl0100_t.dltRule)
     D  i_dltRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcdr)

       //  Return value
     D o_dltRule       S                   like(cstl0100_t.dltRule)
       //-------------------------------------------------------------------
      /FREE

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

      /END-FREE
     P                 E

       //==================================================================*
       //  Convert Update Rule
       //==================================================================*
     P cvtUpdRule...
     P                 B
     D                 PI                  like(cstl0100_t.updRule)
     D  i_updRule                          const  like(Qdb_Qdbf_...
     D                                                 Riafk_Afkd_t.Qdbf_...
     D                                                 riafk_fkcur)

       //  Return value
     D o_updRule       S                   like(cstl0100_t.updRule)
       //-------------------------------------------------------------------
      /FREE

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

      /END-FREE
     P                 E

       //==================================================================*
       //  Is API Error?
       // -----------------------------------------------------------------
       //    cTrue  - error
       //    cFalse - no error
       //==================================================================*
     P isApiError...
     P                 B
     D                 PI              N
     D  i_errCode                   272A   const

       //  Return value
     D o_isError       S               N   inz(cFalse)

       //  API error code
     D errCode         DS                  likeds(errCode_t) inz
       //-------------------------------------------------------------------
      /FREE

       errCode = i_errCode;

       if (errCode.bytAvl = 0);
         o_isError = cFalse;
       else;
         o_isError = cTrue;
       endif;

       return o_isError;

      /END-FREE
     P                 E

       //==================================================================*
       //  Create API error code
       //==================================================================*
     P newApiErrCode...
     P                 B
     D                 PI           272A
     D  i_monmsg                       N   const

       //  Return value
     D errCode         DS                  likeds(errCode_t) inz
       //-------------------------------------------------------------------
      /FREE

       Clear errCode;

       if (i_monMsg = cTrue);
         errCode.bytPrv = %size(errCode);
       else;
         errCode.bytPrv = 0;
       endif;

       return errCode;

      /END-FREE
     P                 E

       //==================================================================*
       //  Convert API error code to message
       //==================================================================*
     P cvtApiErrCodeToMsg...
     P                 B
     D                 PI                         like(msg_t)
     D  i_errCode                   272A   const

       //  Return value
     D o_msg           DS                  likeds(msg_t) inz

       //  API Error code
     D errCode         DS                  likeds(errCode_t) inz
       //-------------------------------------------------------------------
      /FREE

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

      /END-FREE
     P                 E

