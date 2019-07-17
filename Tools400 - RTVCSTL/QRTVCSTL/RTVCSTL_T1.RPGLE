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
     FQSYSPRT   O    F  132        PRINTER oflind(*in70)
     F                                     infds(printer)
     F                                     usropn
      *
     D printer         DS                  qualified
     D  odpType               81     82A
     D  file                  83     92A
     D  library               93    102A
     D  splF                 103    112A
     D  splFLib              113    122A
     D  splFNbr              123    124I 0
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
     D RTVCSTL_T1...
     D                 PR                  extpgm('RTVCSTL_T1')
     D  gi_file                      10A   const
     D  gi_lib                       10A   const
      *
      *  Internal prototypes
     D main...
     D                 PR
     D  i_file                       10A   const
     D  i_lib                        10A   const
      *
     D printLine...
     D                 PR
     D  i_line                      128A   value
      *
     D printCstHeader...
     D                 PR
     D  i_header                     50a   const varying
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D printRefCst...
     D                 PR
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D printPriKeyCst...
     D                 PR
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D printUnqCst...
     D                 PR
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D printChkCst...
     D                 PR
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D getDltRule...
     D                 PR            10A   varying
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D getUpdRule...
     D                 PR            10A   varying
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D sndInfoMsg...
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
     D RTVCSTL_T1...
     D                 PI
     D  gi_file                      10A   const
     D  gi_lib                       10A   const
      /free

         main(gi_file: gi_lib);

         *inlr = *on;

      /end-free
      *
      *==================================================================*
      *  Main Procedure
      *==================================================================*
     P main...
     P                 B                   export
     D                 PI
     D  i_file                       10A   const
     D  i_lib                        10A   const
      *
      *  Local helper fields
     D hasNext         S               N   inz
     D handle          S                   like(cstLst_handle_t) inz
     D msg             S                   like(msg_t) inz
     D cstType         S             10A    inz
     D cstl0100        DS                  likeds(cstl0100_t) inz
      /free

         // Open List of Databse File Constraints
         if (f_opnCstLst(i_file: i_lib: '*NONE': handle: msg));

           open QSYSPRT;

           // Read 1. Constraint
           hasNext = f_getFirstCst(handle: cstl0100);

           dow hasNext;
             // Show entry
             if (hasNext);
               select;
               when (cstl0100.cstType = 'R');
                 cstType = '*REFCST';
                 printRefCst(cstl0100);
               when (cstl0100.cstType = 'P');
                 cstType = '*PRIKEY';
                 printPriKeyCst(cstl0100);
               when (cstl0100.cstType = 'U');
                 cstType = '*UNQCST';
                 printUnqCst(cstl0100);
               when (cstl0100.cstType = 'C');
                 cstType = '*CHKCST';
                 printChkCst(cstl0100);
               endsl;

               sndInfoMsg(%trim(cstl0100.file) + '/'  +
                            %trim(cstl0100.file) + ': ' +
                            %trim(cstType) + '; ' +
                            cstl0100.cstName);
             endif;

             // Read next entry
             hasNext = f_getNextCst(handle: cstl0100);
           enddo;

           // Close List of Databse File Constraints
           f_cloCstLst(handle);

           if (%open(QSYSPRT));
             close QSYSPRT;
           endif;

         endif;

         return;

      /end-free
     P                 E
      *
      *==================================================================*
      *  Print referential constraint
      *==================================================================*
     P printRefCst...
     P                 B
     D                 PI
     D  i_cstl0100                         const likeds(cstl0100_t)
      /free

       printCstHeader('Referential constraint': i_cstl0100);

       printLine('  #Keys      : ' + %char(i_cstl0100.numKeys));
       printLine('  Length     : ' + %char(i_cstl0100.keyLen));

       printLine('  Parent     : ' + %trim(i_cstl0100.parLib) + '/'
                                    + %trim(i_cstl0100.parFile));
       printLine('    key      : ' + i_cstl0100.parKey);
       printLine('  Foreign key: ' + i_cstl0100.fgnKey);
       printLine('  Delete rule: ' + getDltRule(i_cstl0100));
       printLine('  Update rule: ' + getUpdRule(i_cstl0100));

      /end-free
     P                 E
      *
      *==================================================================*
      *  Returns the delete rule
      *==================================================================*
     P getDltRule...
     P                 B
     D                 PI            10A   varying
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D dltRule         S             10A   varying
      /free

       select;
       when (i_cstl0100.dltRule = 'RS');
         dltRule = '*RESTRICTED';
       when (i_cstl0100.dltRule = 'NA');
         dltRule = '*NOACTION';
       when (i_cstl0100.dltRule = 'CC');
         dltRule = '*CASCADE';
       when (i_cstl0100.dltRule = 'SN');
         dltRule = '*SETNULL';
       when (i_cstl0100.dltRule = 'SD');
         dltRule = '*SETDFT';
       other;
         dltRule = '*N';
       endsl;

       return dltRule;

      /end-free
     P                 E
      *
      *==================================================================*
      *  Returns the update rule
      *==================================================================*
     P getUpdRule...
     P                 B
     D                 PI            10A   varying
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D updRule         S             10A   varying
      /free

       select;
       when (i_cstl0100.updRule = 'NA');
         updRule = '*NOACTION';
       when (i_cstl0100.updRule = 'RS');
         updRule = '*RESTRICTED';
       other;
         updRule = '*N';
       endsl;

       return updRule;

      /end-free
     P                 E
      *
      *==================================================================*
      *  Print primary key constraint
      *==================================================================*
     P printPriKeyCst...
     P                 B
     D                 PI
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D i               S             10I 0
     D pos             S             10I 0
      /free

       printCstHeader('Primary key': i_cstl0100);

       printLine('  #Keys      : ' + %char(i_cstl0100.numKeys));
       printLine('  Length     : ' + %char(i_cstl0100.keyLen));
       printLine('  Fields     :');

       pos = 1;
       for i = 1 to i_cstl0100.numKeys;
         printLine('    ' + %subst(i_cstl0100.parKey: pos: 10));
         pos += 10;
       endfor;

      /end-free
     P                 E
      *
      *==================================================================*
      *  Print unique key constraint
      *==================================================================*
     P printUnqCst...
     P                 B
     D                 PI
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D i               S             10I 0
     D pos             S             10I 0
      /free

       printCstHeader('Unique key': i_cstl0100);

       printLine('  #Keys      : ' + %char(i_cstl0100.numKeys));
       printLine('  Length     : ' + %char(i_cstl0100.keyLen));
       printLine('  Fields     :');

       pos = 1;
       for i = 1 to i_cstl0100.numKeys;
         printLine('    ' + %subst(i_cstl0100.parKey: pos: 10));
         pos += 10;
       endfor;

      /end-free
     P                 E
      *
      *==================================================================*
      *  Print check constraint
      *==================================================================*
     P printChkCst...
     P                 B
     D                 PI
     D  i_cstl0100                         const likeds(cstl0100_t)
      *
     D i               S             10I 0
     D pos             S             10I 0
      /free

       printCstHeader('Check constraint': i_cstl0100);

       if (i_cstl0100.expTrunc = 'Y');
         printLine('  Truncated  : ' + 'YES');
       else;
         printLine('  Truncated  : ' + 'NO');
       endif;

       printLine('  Expression : ' + i_cstl0100.chkCstExp);

      /end-free
     P                 E
      *
      *==================================================================*
      *  Print constraint header
      *==================================================================*
     P printCstHeader...
     P                 B
     D                 PI
     D  i_header                     50a   const varying
     D  i_cstl0100                         const likeds(cstl0100_t)
      /free

       printLine('');
       printLine(i_header + ':');
       printLine('  Name       : ' + i_cstl0100.cstName);
       printLine('  Library    : ' + i_cstl0100.lib);
       printLine('  Created    : ' + %char(i_cstl0100.crtTmStmp));
       printLine('  Type       : ' + i_cstl0100.cstType);

      /end-free
     P                 E
      *
      *==================================================================*
      *  Appends a line to the log
      *==================================================================*
     P printLine...
     P                 B
     D                 PI
     D  i_line                      128A   value
      *
     D lineOutput      DS           132
      /free

       lineOutput = i_line;

       write QSYSPRT lineOutput;

      /end-free
     P printLine...
     P                 E
      *
      *==================================================================*
      *  Send *INFO message
      *==================================================================*
     P sndInfoMsg...
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
      /free

       clear qMsgF;
       qMsgF.name = 'QCPFMSG';
       qMsgF.lib = '*LIBL';

       clear errCode;
       errCode.bytPrv = %size(errCode);

       qmhsndpm('CPF9897': qMsgF: i_msgText: %len(%trimr(i_msgText))
                : '*INFO': '*CTLBDY': 1: msgKey: errCode);

      /end-free
     P                 E

