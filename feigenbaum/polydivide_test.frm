#-
#include- ../src/frm/algexp.hrm
#include- polydivide.hrm

Off Statistics;
Symbol z, c;
Local dummy = 1;

*===========================================================================
*   Test suite for PolyDivide (base-(p-1) division).
*
*   Computes Q/p for bifurcation polynomials of g_c(z) = z^2 + c,
*   comparing PolyDivide against FORM's div_ for correctness.
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
#call PolyDivide($Q1,$p1,z,$Bpd1)

$diff1 = $Bdiv1 - $Bpd1;
.sort
#message === Test 1: g^2-z / g-z (deg B=2, deg p=2) ===
#message div_:      `$Bdiv1'
#message PolyDiv:   `$Bpd1'
#message Diff:      `$diff1'

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
#call PolyDivide($Q2,$p2,z,$Bpd2)

$diff2 = $Bdiv2 - $Bpd2;
.sort
#message === Test 2: g^3-z / g-z (deg B=6, deg p=2) ===
#message Diff:      `$diff2'

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

#message Starting PolyDivide (`TIME_'s)
#call PolyDivide($Q3,$p3,z,$Bpd3)
#message PolyDivide done (`TIME_'s)

$diff3 = $Bdiv3 - $Bpd3;
.sort
#message Diff:      `$diff3'

*===========================================================================
*   Test 4: g^5(z)-z / g^2(z)-z  — deg(B)=28, deg(p)=4
*   This is the 5->10 case where div_ was the bottleneck.
*===========================================================================

$gz = z;
.sort
#call CQ($gz,z)
#call CQ($gz,z)
$p4 = $gz - z;
.sort
#call CQ($gz,z)
#call CQ($gz,z)
#call CQ($gz,z)
$Q4 = $gz - z;
.sort

#message === Test 4: g^5-z / g^2-z (deg B=28, deg p=4) ===
#message Building done (`TIME_'s)

*   Uncomment ONE of the following to benchmark:

*#message Starting div_ (`TIME_'s)
*$Bdiv4 = div_($Q4,$p4);
*.sort
*#message div_ done (`TIME_'s)

#message Starting PolyDivide (`TIME_'s)
#call PolyDivide($Q4,$p4,z,$Bpd4)
#message PolyDivide done (`TIME_'s)

.sort
.end
