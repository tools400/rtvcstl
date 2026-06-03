/* -------------------------------------------------------------------------- */
/* RTVCSTL    - SCRIPT MEMBER                                                 */
/* Use commands  xmlgenINC (generate text for install pgm)                    */
/*               xmlgenMBR (to define source members                          */
/*               xmlgenCMD (execute qcmdexc at run time                       */
/* Put &TOLIB where you want user selected lib at run time.                   */
   DCL &TOLIB *CHAR 10
/* -------------------------------------------------------------------------- */
/* >>PRE-COMPILER<<                                                           */
/*   >>CRTCMD<<  XMLGEN  XMLSCRIPT(&SM) SCRIPTSRCF(&SL/&SF);                  */
/*   >>IMPORTANT<<                                                            */
/*     >>PARM<<  SRCTOFILE(&LI/QXML);                                         */
/*     >>PARM<<  XMLMBR(*SCRIPT);                                             */
/*     >>PARM<<  ENCODING('ISO-8859-1');                                      */
/*     >>PARM<<  AUTHOR('Thomas Raddatz');                                    */
/*   >>END-IMPORTANT<<                                                        */
/*   >>EXECUTE<<                                                              */
/* >>END-PRE-COMPILER<<                                                       */
/* -------------------------------------------------------------------------- */
             XMLGENINC  XINCLUDE(*YES)

             XMLGENVRS XSRCFILE(QRTVCSTL) XSRCLIB(RTVCSTLD) XSRCMBR(COPYRIGHT)

             XMLGENCND  XMSG('Create sample programs? (YES, NO)') +
                          XVALUES(YES NO) XVAR(&CRTTSTPGM)

             XMLGENSET  XVAR(&SRCFILE) XVALUE(QRTVCSTL)

/* ---------------------------------- */
/*  Deploy source member              */
/* ---------------------------------- */
             XMLGENMBR  XMBR(A_INSTALL ) XMBRATR(CLLE ) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(A_README  ) XMBRATR(TXT) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(COPYRIGHT ) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(FDCSTL0100) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(FDERRCODE ) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(FDMSG     ) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(FDQOBJ    ) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(PRTVCSTL  ) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(QDBRTVFD  ) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(RTVCSTL_T1) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(RTVCSTL   ) XMBRATR(BND  ) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

             XMLGENMBR  XMBR(RTVCSTLR1 ) XMBRATR(RPGLE) +
                          XFROMSRCF(QRTVCSTL  ) XFROMSRCL(RTVCSTLD) +
                          XTOSRCF(QRTVCSTL  ) XOBJTYPE(*PGM   ) +
                          XGENCRT(*NO ) XPARAM(*BLANK)

/* ---------------------------------- */
/*  Create objects                    */
/* ---------------------------------- */
             XMLGENCMD  XCMD(CRTBNDCL PGM(&TOLIB/A_INSTALL) +
                          SRCFILE(&TOLIB/QRTVCSTL) SRCMBR(*PGM) +
                          DFTACTGRP(*NO) ACTGRP(*NEW) +
                          DBGVIEW(*LIST)) XDLTSPLF(A_INSTALL)

             XMLGENCMD  XCMD(CALL PGM(&TOLIB/A_INSTALL) +
                             PARM('&TGTRLS' '&SRCFILE' '&TOLIB' '&CRTTSTPGM'))
             XMLGENCMD  XCMD(DLTPGM PGM(&TOLIB/A_INSTALL))

