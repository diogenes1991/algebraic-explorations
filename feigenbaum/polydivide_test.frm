#-
#include- ../src/frm/algexp.hrm
#include- polydivide.hrm

Off Statistics;
Symbol z, c;
Local dummy = 1;

*===========================================================================
*   Test suite for experimental quotient routines.
*
*   Computes Q/p for bifurcation polynomials of g_c(z) = z^2 + c,
*   comparing the no-div_ coefficient descent against FORM's div_ at low order.
*
*   Usage: cd feigenbaum && form polydivide_test.frm
*===========================================================================

#procedure CQ(DOLLAR,SYMB)
    $CQtmp = replace_(`SYMB',`SYMB'^2+c)*(`DOLLAR');
    .sort
    `DOLLAR' = $CQtmp;
    .sort
#endprocedure

*===========================================================================
*   Test 1: g^2(z)-z / g(z)-z  — deg(B)=2, deg(p)=2  (borderline)
*===========================================================================

$gz = z;
.sort
#call CQ($gz,z)
$p1 = $gz - z;
.sort
#call CQ($gz,z)
$Q1 = $gz - z;
.sort

$Bdiv1 = div_($Q1,$p1);
.sort
*#call PolyDivide($Q1,$p1,z,$Bpd1)
#call PolyDivideDescent($Q1,$p1,z,$Bdesc1)

*$diff1 = $Bdiv1 - $Bpd1;
$ddiff1 = $Bdiv1 - $Bdesc1;
$rem1 = $Q1 - ($Bdesc1)*($p1);
.sort
#message === Test 1: g^2-z / g-z (deg B=2, deg p=2) ===
#message div_:      `$Bdiv1'
*#message PolyDiv:   `$Bpd1'
#message Descent:   `$Bdesc1'
*#message P-adic diff: `$diff1'
#message Descent diff: `$ddiff1'
#message Descent rem:  `$rem1'

*===========================================================================
*   Test 2: g^3(z)-z / g(z)-z  — deg(B)=6, deg(p)=2
*===========================================================================

$gz = z;
.sort
#call CQ($gz,z)
$p2 = $gz - z;
.sort
#call CQ($gz,z)
#call CQ($gz,z)
$Q2 = $gz - z;
.sort

$Bdiv2 = div_($Q2,$p2);
.sort
*#call PolyDivide($Q2,$p2,z,$Bpd2)
#call PolyDivideDescent($Q2,$p2,z,$Bdesc2)

*$diff2 = $Bdiv2 - $Bpd2;
$ddiff2 = $Bdiv2 - $Bdesc2;
$rem2 = $Q2 - ($Bdesc2)*($p2);
.sort
#message === Test 2: g^3-z / g-z (deg B=6, deg p=2) ===
*#message P-adic diff: `$diff2'
#message Descent diff: `$ddiff2'
#message Descent rem:  `$rem2'

*===========================================================================
*   Test 3: g^4(z)-z / g^2(z)-z  — deg(B)=12, deg(p)=4
*===========================================================================

$gz = z;
.sort
#call CQ($gz,z)
#call CQ($gz,z)
$p3 = $gz - z;
.sort
#call CQ($gz,z)
#call CQ($gz,z)
$Q3 = $gz - z;
.sort

#message === Test 3: g^4-z / g^2-z (deg B=12, deg p=4) ===

#message Starting div_ (`TIME_'s)
$Bdiv3 = div_($Q3,$p3);
.sort
#message div_ done (`TIME_'s)

*#message Starting PolyDivide (`TIME_'s)
*#call PolyDivide($Q3,$p3,z,$Bpd3)
*#message PolyDivide done (`TIME_'s)

#message Starting PolyDivideDescent (`TIME_'s)
#call PolyDivideDescent($Q3,$p3,z,$Bdesc3)
#message PolyDivideDescent done (`TIME_'s)

*$diff3 = $Bdiv3 - $Bpd3;
$ddiff3 = $Bdiv3 - $Bdesc3;
$rem3 = $Q3 - ($Bdesc3)*($p3);
.sort
*#message P-adic diff: `$diff3'
#message Descent diff: `$ddiff3'
#message Descent rem:  `$rem3'

*===========================================================================
*   Test 4: g^5(z)-z / g(z)-z  -- deg(B)=30, deg(p)=2
*   Prime-period stress test: remove fixed points from g^5(z)-z.
*===========================================================================

$gz = z;
.sort
#call CQ($gz,z)
$p4 = $gz - z;
.sort
#call CQ($gz,z)
#call CQ($gz,z)
#call CQ($gz,z)
#call CQ($gz,z)
$Q4 = $gz - z;
.sort

#message === Test 4: g^5-z / g-z (deg B=30, deg p=2) ===
#message Building done (`TIME_'s)

*   div_ is intentionally not run here; this is a descent-only stress test.

*#message Starting PolyDivide (`TIME_'s)
*#call PolyDivide($Q4,$p4,z,$Bpd4)
*#message PolyDivide done (`TIME_'s)

#message Starting PolyDivideDescent (`TIME_'s)
#call PolyDivideDescent($Q4,$p4,z,$Bdesc4)
#message PolyDivideDescent done (`TIME_'s)

$rem4 = $Q4 - ($Bdesc4)*($p4);
.sort
#message Descent rem:  `$rem4'

.sort
.end
