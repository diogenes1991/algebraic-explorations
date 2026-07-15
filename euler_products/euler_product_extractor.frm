#-
#include ../src/frm/algexp.hrm

#procedure CoeffAt(EXPR,SYMB,POW,COEF)

    .sort
    #ifndef `COAT'
        #define COAT "1"
        Symbol xCOAT,xCOATH;
    #endif

    Local COATLOCAL = replace_(`SYMB',xCOAT)*`EXPR';
    id,only, xCOAT^`POW' = xCOATH^`POW';
    id xCOAT = 0;
    id xCOATH = 1;
    .sort

    `COEF' = COATLOCAL;
    .sort

    Drop COATLOCAL;
    .sort

#endprocedure

Off Statistics;

Symbol q;
Symbol qH;

Local dummy = 1;

$Num1 = 1 - q + q^3;
$Den1 = 1 - q - q^2 + q^3 + 4*q^5;
$Diff1 = $Num1 - $Den1;
.sort

#call LowestPower($Diff1,q,$LPow1)
#call HighestPower($Diff1,q,$HPow1)

#message Diff1 lowest power is `$LPow1'
#message Diff1 highest power is `$HPow1'
.sort

#call CoeffAt($Diff1,q,$LPow1,$Coef1)
#call CoeffAt($Diff1,q,$HPow1,$Coef2)
#message Coefficient at lowest power is `$Coef1'
#message Coefficient at highest power is `$Coef2'

.sort

.sort
.end
