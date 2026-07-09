#-
* highest_power.frm
* Driver demonstrating the reusable HighestPower procedure.

* Global FORM helpers live in src/frm; pull them in by relative path.
* (Run this file from euler_products/ so the relative path resolves,
*  or invoke form with  -p ../src/frm  and drop the #include line.)
#include ../src/frm/HighestPower.prc

Off Statistics;

Symbols x,y,n;

* Keep one active expression so the $-variable assignments below have a home.
Local dummy = 1;
.sort

* Two different polynomials, to show the procedure is reused in many places.
$P = 1 + 3*x + 5*x^2*y + 7*x^5 + y^9;
$Q = y + y^4 + x*y^12;
.sort

#call HighestPower($P,x,$degPx)
#call HighestPower($P,y,$degPy)
#call HighestPower($Q,y,$degQy)

#message Highest power of x in P is `$degPx'
#message Highest power of y in P is `$degPy'
#message Highest power of y in Q is `$degQy'

.end
