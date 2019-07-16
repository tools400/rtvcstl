      /if not defined(cstl0100_t)
      /define cstl0100_t
      *
      * RTVCSTL API - Format CSTL0100
     d cstl0100_t      ds                  qualified based(pDummy)
     d  file                         10a                                        File name
     d  lib                          10a                                        Library name
     d  cstName                     258a                                        Constraint name
     d  cstLib                       10a                                        Constraint library
     d  crtTmStmp                      z                                        Creation timestamp
     d  cstType                       1a                                        Type: P=*PRIMARY
     d                                                                                U=*UNIQUE
     d                                                                                R=*REFCST
     d                                                                                C=*CHKCST
     d  chkPnd                        1a                                        Check Pending: Y/N
     d  cstSts                        2a                                        DD=dfn/dis,DE=dfn/en
     d                                                                          ED=est/dis,EE=est/en
     d  numKeys                       3S 0                                      Number of Keys
     d  keyLen                        5S 0                                      Total Key Length
     d  parFile                      10a                                        Parent File Name
     d  parLib                       10a                                        Parent Library Name
     d  parKey                     1200a                                        Parent Key Inform.
     d  fgnKey                     1200a                                        Foreign Key Inform.
     d  dltRule                       2a                                        Dlt Rule:
     d                                                                              RS=Restricted
     d                                                                              NA=No Action
     d                                                                              CC=Cascade
     d                                                                              SN=Set Null
     d                                                                              SD=Set Default
     d  updRule                       2a                                        Upd Rule:
     d                                                                              NA=Noaction
     d                                                                              RS=Restrict
     d  expTrunc                      1a                                        Expr. Truncated: Y/N
     d  chkCstExp                  2000a                                        Check Cst Expression
      *
      /endif
