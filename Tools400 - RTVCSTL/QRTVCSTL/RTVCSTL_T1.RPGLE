      *=====================================================================*
      *  Author  :  Thomas Raddatz                                          *
      *  Date    :  21.06.2003                                              *
      *  E-mail  :  thomas.raddatz@tools400.de                              *
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
      *  History:                                                           *
      *                                                                     *
      *  Datum       Name          Änderung                                 *
      *  ----------  ------------  ---------------------------------------  *
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
      *     >>CMD<<     CRTPGM       PGM(&LI/&OB) +                         *
      *                              MODULE(*PGM) +                         *
      *                              BNDSRVPGM(&LI/RTVCSTL) +               *
      *                              ACTGRP(*NEW) +                         *
      *                              DETAIL(*BASIC);                        *
      *   >>END-PRE-COMPILER<<                                              *
      *=====================================================================*
     H EXTBININT(*YES)
     H DATFMT(*ISO) TIMFMT(*ISO) DEBUG(*YES)
      *=====================================================================*
      *
      /COPY QRTVCSTL,PRTVCSTL
      *
      *  Reference fields
      /COPY QRTVCSTL,FDCSTL0100
      /COPY QRTVCSTL,FDERRCODE
      /COPY QRTVCSTL,FDMSG
      /COPY QRTVCSTL,FDQOBJ
      *
      *  *ENTRY parameter list
     D RTVCSTL_T...
     D                 PR                  extpgm('RTVCSTL_T')
     D  gi_file                      10A   const
     D  gi_lib                       10A   const
      *
      *  Internal prototypes
     D p_main...
     D                 PR
     D  i_file                       10A   const
     D  i_lib                        10A   const
      *
     D p_sndInfoMsg...
     D                 PR
     D  i_msgText                   128A   value
      *
      *  Global constants
     D cTrue           C                   const(*on )
     D cFalse          C                   const(*off)
      *
      ********************************************************************
      *  PROGRAM ENTRY POINT
      ********************************************************************
      *
     D RTVCSTL_T...
     D                 PI
     D  gi_file                      10A   const
     D  gi_lib                       10A   const
      *
     C                   Callp     p_main(gi_file: gi_lib)
      *
     C                   Eval      *inlr = *on
      *
      *==================================================================*
      *  Main Procedure
      *==================================================================*
      *
     P p_main...
     P                 B                   export
     D                 PI
     D  i_file                       10A   const
     D  i_lib                        10A   const
      *
      *  Local helper fields
     D isDone          S               N   inz
     D handle          S                   like(cstLst_handle_t) inz
     D data            S                   like(cstl0100) inz
     D msg             S                   like(msg_t) inz
     D cstType         S             10A    inz
      *
     D cstl0100        DS                  likeds(cstl0100_t) inz
      *-------------------------------------------------------------------
      *
      *  Open List of Databse File Constraints
     C                   Eval      isDone = f_opnCstLst(i_file   :
     C                                                  i_lib    :
     C                                                  '*NONE'  :
     C                                                  handle   :
     C                                                  msg      )
      *
      *  Read 1. Constraint
     C                   Eval      isDone = f_getFirstCst(handle :                          RA
     C                                                    data   )
      *
     C                   Dow       isDone
      *  Show entry
     C                   If        isDone
     C                   Eval      cstl0100 = data
     C                   Select
     C                   When      cstl0100.cstType = 'R'
     C                   Eval      cstType = '*REFCST'
     C                   When      cstl0100.cstType = 'P'
     C                   Eval      cstType = '*PRIKEY'
     C                   When      cstl0100.cstType = 'U'
     C                   Eval      cstType = '*UNQCST'
     C                   When      cstl0100.cstType = 'C'
     C                   Eval      cstType = '*CHKCST'
     C                   Endsl
     C                   Callp     p_sndInfoMsg(%trim(cstl0100.file) + '/'  +
     C                                          %trim(cstl0100.file) + ': ' +
     C                                          %trim(cstType) + '; ' +
     C                                          cstl0100.cstName         )
     C                   Endif
      *
      *  Read next entry
     C                   Eval      isDone = f_getNextCst(handle :
     C                                                   data   )
     C                   Enddo
      *
      *  Close List of Databse File Constraints
     C                   Eval      isDone = f_cloCstLst(handle)
      *
     C                   Return
      *
     P                 E
      *
      *==================================================================*
      *  Send *INFO message
      *==================================================================*
      *
     P p_sndInfoMsg...
     P                 B
     D                 PI
     D  i_msgText                   128A   value
      *
      *  Local helper fields
     D qMsgF           DS                  likeds(qObj_t) inz
     D msgKey          S              4A   inz
     D errCode         DS                  likeds(errcode_t) inz
      *
      *  Send Program Message (QMHSNDPM) API
     D qmhsndpm        PR                  ExtPgm('QMHSNDPM')
     D  i_msgID                       7A   const                                msgID
     D  i_qMsgF                      20A   const                                msgF + lib
     D  i_msgText                 32767A   const  options(*varsize)             msg data
     D  i_lenMsgText                 10I 0 const                                length
     D  i_msgType                    10A   const                                msg type
     D  i_callStackE                 10A   const                                stack entry
     D  i_callStackC                 10I 0 const                                stack counter
     D  i_msgKey                      4A   const                                msg key
     D  io_errCode                32767A          options(*varsize)             error code
     D  i_lenCalStckE                10I 0        options(*nopass )             opt. group 1
     D  i_calStckEQ                  20A          options(*nopass )             |
     D  i_waitTime                   10I 0        options(*nopass )             |
     D  i_calStckEDTp                10A          options(*nopass )             opt. group 2
     D  i_ccsid                      10I 0        options(*nopass )             |
      *-------------------------------------------------------------------
      *
     C                   Clear                   qMsgF
     C                   Eval      qMsgF.name = 'QCPFMSG'
     C                   Eval      qMsgF.lib  = '*LIBL'
      *
     C                   Clear                   errCode
     C                   Eval      errCode.bytPrv = %size(errCode)
      *
     C                   Callp     qmhsndpm('CPF9897': qMsgF: i_msgText
     C                                      : %len(%trimr(i_msgText))
     C                                      : '*INFO': '*CTLBDY': 1
     C                                      : msgKey: errCode)
      *
     P                 E
      *
