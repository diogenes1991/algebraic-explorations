#procedure HighestPower(EXPR,SYMB,POW)
*
*   Highest power of `SYMB' occurring in `EXPR', written into the $-variable `POW'.
*
*   Arguments (all passed by name, FORM-style):
*       EXPR  - a $-variable holding the expression to inspect, e.g. $poly
*       SYMB  - the symbol whose degree you want, e.g. x
*       POW   - the $-variable that receives the result, e.g. $deg
*
*   Usage:
*       Symbols x, ... ;
*       Local dummy = 1;           * keep one active expression around
*       .sort
*       $poly = 1 + x^2 + x^7;
*       .sort
*       #call HighestPower($poly,x,$deg)
*       #message degree = `$deg'
*
*   Notes:
*       - Returns -1 for the zero polynomial (no powers found).
*       - Uses the internal symbol xHPtmp so other symbols in EXPR cannot
*         inflate the count; declared once via a guard so repeated #calls
*         don't re-declare it.

    #ifndef `HIGHESTPOWERINIT'
        #define HIGHESTPOWERINIT "1"
        Symbol xHPtmp;
    #endif

    .sort
    Local HPLOCAL = replace_(`SYMB',xHPtmp)*(`EXPR');
    $HPmax = -1;
    .sort

    if ( count(xHPtmp,1) > $HPmax ) $HPmax = count_(xHPtmp,1);
    .sort

    `POW' = `$HPmax';
    .sort

    Drop HPLOCAL;
    .sort
#endprocedure
