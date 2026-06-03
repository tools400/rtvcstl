**free
//=====================================================================*
//  Author  :  Thomas Raddatz                                          *
//  Date    :  21.06.2003                                              *
//  E-mail  :  thomas.raddatz@tools400.de                              *
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
//  History:                                                           *
//                                                                     *
//  Datum       Name          nderung                                 *
//  ----------  ------------  ---------------------------------------  *
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
//     >>CMD<<     CRTPGM       PGM(&LI/&OB) +                         *
//                              MODULE(*PGM) +                         *
//                              BNDSRVPGM(*LIBL/RTVCSTL) +             *
//                              ACTGRP(*NEW) +                         *
//                              DETAIL(*BASIC);                        *
//   >>END-PRE-COMPILER<<                                              *
//=====================================================================*
ctl-opt extbinint(*yes);
ctl-opt datfmt(*iso) timfmt(*iso) debug(*yes);
//=====================================================================*
dcl-f QSYSPRT printer(132) usage(*output) oflind(*in70) infds(printer) usropn;

dcl-ds printer qualified;
  odpType char(2) pos(81);
  file    char(10);
  library char(10);
  splF    char(10);
  splFLib char(10);
  splFNbr int(5);
end-ds;

/copy QRTVCSTL,PRTVCSTL

//  Reference fields
/copy QRTVCSTL,FDCSTL0100
/copy QRTVCSTL,FDERRCODE
/copy QRTVCSTL,FDMSG
/copy QRTVCSTL,FDQOBJ

//  *ENTRY parameter list
dcl-pr RTVCSTL_T1 extpgm('RTVCSTL_T1');
  gi_file char(10) const;
  gi_lib  char(10) const;
end-pr;

//  Internal prototypes
dcl-pr main;
  i_file char(10) const;
  i_lib  char(10) const;
end-pr;

dcl-pr printLine;
  i_line char(128) value;
end-pr;

dcl-pr printCstHeader;
  i_header   varchar(50) const;
  i_cstl0100 likeds(cstl0100_t) const;
end-pr;

dcl-pr printRefCst;
  i_cstl0100 likeds(cstl0100_t) const;
end-pr;

dcl-pr printPriKeyCst;
  i_cstl0100 likeds(cstl0100_t) const;
end-pr;

dcl-pr printUnqCst;
  i_cstl0100 likeds(cstl0100_t) const;
end-pr;

dcl-pr printChkCst;
  i_cstl0100 likeds(cstl0100_t) const;
end-pr;

dcl-pr getDltRule varchar(10);
  i_cstl0100 likeds(cstl0100_t) const;
end-pr;

dcl-pr getUpdRule varchar(10);
  i_cstl0100 likeds(cstl0100_t) const;
end-pr;

dcl-pr sndInfoMsg;
  i_msgText char(128) value;
end-pr;

//  Global constants
dcl-c cTrue *on;
dcl-c cFalse *off;

//*******************************************************************
//  PROGRAM ENTRY POINT
//*******************************************************************
dcl-pi RTVCSTL_T1;
  gi_file char(10) const;
  gi_lib  char(10) const;
end-pi;

main(gi_file: gi_lib);

*inlr = *on;


//==================================================================*
//  Main Procedure
//==================================================================*
dcl-proc main export;
  dcl-pi *n;
    i_file char(10) const;
    i_lib  char(10) const;
  end-pi;

  //  Local helper fields
  dcl-s hasNext ind inz;
  dcl-s handle like(cstLst_handle_t) inz;
  dcl-s msg like(msg_t) inz;
  dcl-s cstType char(10) inz;
  dcl-ds cstl0100 likeds(cstl0100_t) inz;

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

end-proc;

//==================================================================*
//  Print referential constraint
//==================================================================*
dcl-proc printRefCst;
  dcl-pi *n;
    i_cstl0100 likeds(cstl0100_t) const;
  end-pi;

  printCstHeader('Referential constraint': i_cstl0100);

  printLine('  #Keys      : ' + %char(i_cstl0100.numKeys));
  printLine('  Length     : ' + %char(i_cstl0100.keyLen));

  printLine('  Parent     : ' + %trim(i_cstl0100.parLib) + '/'
                               + %trim(i_cstl0100.parFile));
  printLine('    key      : ' + i_cstl0100.parKey);
  printLine('  Foreign key: ' + i_cstl0100.fgnKey);
  printLine('  Delete rule: ' + getDltRule(i_cstl0100));
  printLine('  Update rule: ' + getUpdRule(i_cstl0100));

end-proc;

//==================================================================*
//  Returns the delete rule
//==================================================================*
dcl-proc getDltRule;
  dcl-pi *n varchar(10);
    i_cstl0100 likeds(cstl0100_t) const;
  end-pi;

  dcl-s dltRule varchar(10);

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

end-proc;

//==================================================================*
//  Returns the update rule
//==================================================================*
dcl-proc getUpdRule;
  dcl-pi *n varchar(10);
    i_cstl0100 likeds(cstl0100_t) const;
  end-pi;

  dcl-s updRule varchar(10);

  select;
  when (i_cstl0100.updRule = 'NA');
    updRule = '*NOACTION';
  when (i_cstl0100.updRule = 'RS');
    updRule = '*RESTRICTED';
  other;
    updRule = '*N';
  endsl;

  return updRule;

end-proc;

//==================================================================*
//  Print primary key constraint
//==================================================================*
dcl-proc printPriKeyCst;
  dcl-pi *n;
    i_cstl0100 likeds(cstl0100_t) const;
  end-pi;

  dcl-s i int(10);
  dcl-s pos int(10);

  printCstHeader('Primary key': i_cstl0100);

  printLine('  #Keys      : ' + %char(i_cstl0100.numKeys));
  printLine('  Length     : ' + %char(i_cstl0100.keyLen));
  printLine('  Fields     :');

  pos = 1;
  for i = 1 to i_cstl0100.numKeys;
    printLine('    ' + %subst(i_cstl0100.parKey: pos: 10));
    pos += 10;
  endfor;

end-proc;

//==================================================================*
//  Print unique key constraint
//==================================================================*
dcl-proc printUnqCst;
  dcl-pi *n;
    i_cstl0100 likeds(cstl0100_t) const;
  end-pi;

  dcl-s i int(10);
  dcl-s pos int(10);

  printCstHeader('Unique key': i_cstl0100);

  printLine('  #Keys      : ' + %char(i_cstl0100.numKeys));
  printLine('  Length     : ' + %char(i_cstl0100.keyLen));
  printLine('  Fields     :');

  pos = 1;
  for i = 1 to i_cstl0100.numKeys;
    printLine('    ' + %subst(i_cstl0100.parKey: pos: 10));
    pos += 10;
  endfor;

end-proc;

//==================================================================*
//  Print check constraint
//==================================================================*
dcl-proc printChkCst;
  dcl-pi *n;
    i_cstl0100 likeds(cstl0100_t) const;
  end-pi;

  dcl-s i int(10);
  dcl-s pos int(10);

  printCstHeader('Check constraint': i_cstl0100);

  if (i_cstl0100.expTrunc = 'Y');
    printLine('  Truncated  : ' + 'YES');
  else;
    printLine('  Truncated  : ' + 'NO');
  endif;

  printLine('  Expression : ' + i_cstl0100.chkCstExp);

end-proc;

//==================================================================*
//  Print constraint header
//==================================================================*
dcl-proc printCstHeader;
  dcl-pi *n;
    i_header   varchar(50) const;
    i_cstl0100 likeds(cstl0100_t) const;
  end-pi;

  printLine('');
  printLine(i_header + ':');
  printLine('  Name       : ' + i_cstl0100.cstName);
  printLine('  Library    : ' + i_cstl0100.lib);
  printLine('  Created    : ' + %char(i_cstl0100.crtTmStmp));
  printLine('  Type       : ' + i_cstl0100.cstType);

end-proc;

//==================================================================*
//  Appends a line to the log
//==================================================================*
dcl-proc printLine;
  dcl-pi *n;
    i_line char(128) value;
  end-pi;

  dcl-ds lineOutput len(132);
  end-ds;

  lineOutput = i_line;

  write QSYSPRT lineOutput;

end-proc;

//==================================================================*
//  Send *INFO message
//==================================================================*
dcl-proc sndInfoMsg;
  dcl-pi *n;
    i_msgText char(128) value;
  end-pi;

  //  Local helper fields
  dcl-ds qMsgF likeds(qObj_t) inz;
  dcl-s msgKey char(4) inz;
  dcl-ds errCode likeds(errcode_t) inz;

  //  Send Program Message (QMHSNDPM) API
  dcl-pr qmhsndpm extpgm('QMHSNDPM');
    i_msgID       char(7) const; // msgID
    i_qMsgF       char(20) const; // msgF + lib
    i_msgText     char(32767) options(*varsize) const; // msg data
    i_lenMsgText  int(10) const; // length
    i_msgType     char(10) const; // msg type
    i_callStackE  char(10) const; // stack entry
    i_callStackC  int(10) const; // stack counter
    i_msgKey      char(4) const; // msg key
    io_errCode    char(32767) options(*varsize); // error code
    i_lenCalStckE int(10) options(*nopass); // opt. group 1
    i_calStckEQ   char(20) options(*nopass); // |
    i_waitTime    int(10) options(*nopass); // |
    i_calStckEDTp char(10) options(*nopass); // opt. group 2
    i_ccsid       int(10) options(*nopass); // |
  end-pr;

  clear qMsgF;
  qMsgF.name = 'QCPFMSG';
  qMsgF.lib = '*LIBL';

  clear errCode;
  errCode.bytPrv = %size(errCode);

  qmhsndpm('CPF9897': qMsgF: i_msgText: %len(%trimr(i_msgText))
           : '*INFO': '*CTLBDY': 1: msgKey: errCode);

end-proc;

