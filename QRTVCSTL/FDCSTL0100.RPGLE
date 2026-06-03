**free
/if not defined(cstl0100_t)
/define cstl0100_t

// RTVCSTL API - Format CSTL0100
dcl-ds cstl0100_t qualified template;
  file      char(10); // File name
  lib       char(10); // Library name
  cstName   char(258); // Constraint name
  cstLib    char(10); // Constraint librar
  crtTmStmp timestamp; // Creation timestam
  cstType   char(1); // Type: P=*PRIMARY
  //    U=*UNIQUE
  //    R=*REFCST
  //    C=*CHKCST
  chkPnd    char(1); // Check Pending: Y/
  cstSts    char(2); // DD=dfn/dis,DE=dfn
  // ED=est/dis,EE=est/en
  numKeys   zoned(3); // Number of Keys
  keyLen    zoned(5); // Total Key Length
  parFile   char(10); // Parent File Name
  parLib    char(10); // Parent Library Na
  parKey    char(1200); // Parent Key Inform
  fgnKey    char(1200); // Foreign Key Infor
  dltRule   char(2); // Dlt Rule:
  //    RS=Restricted
  //    NA=No Action
  //    CC=Cascade
  //    SN=Set Null
  //    SD=Set Default
  updRule   char(2); // Upd Rule:
  //    NA=Noaction
  //    RS=Restrict
  expTrunc  char(1); // Expr. Truncated:
  chkCstExp char(2000); // Check Cst Express
end-ds;

/endif
