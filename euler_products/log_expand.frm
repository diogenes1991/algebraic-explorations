#-
#include ../src/frm/algexp.hrm

* The "seed" of the log-space extractor is the only genuinely-Taylor step:
* L = log(Num) - log(Den).  Every factor peeled afterwards is a (1 -+ q^k),
* whose log is the sparse Mercator series.
*
* CAUTION: the raw L = log(Num/Den) does NOT have integer coefficients
* (e.g. 3/2 q^4).  Integrality holds only at the LOWEST not-yet-cancelled order
* during the sweep.  This driver shows both facts:
*   (a) log(Num), log(Den), L all carry fractions;
*   (b) after peeling the factors at orders 2 and 3 (subtracting their sparse
*       logs), the residual's order-4 coefficient turns from 3/2 into the
*       integer 1 -- the "readable coefficient is an integer" lemma in action.

Off Statistics;

Symbol q;
Local dummy = 1;
.sort

#define NORD "12"

$Num = 1 - q + q^3;
$Den = 1 - q - q^2 + q^3;
.sort

#call LogExpand($Num,q,`NORD',$LNum)
#call LogExpand($Den,q,`NORD',$LDen)
$L = $LNum - $LDen;
.sort

* Sparse logs of the first two peeled factors, (1 - q^2) and (1 - q^3).
$f2 = 1 - q^2;
$f3 = 1 - q^3;
.sort
#call LogExpand($f2,q,`NORD',$Lf2)
#call LogExpand($f3,q,`NORD',$Lf3)

* Residual after peeling orders 2 and 3:  R = L + log(1-q^2) + log(1-q^3).
$R = $L + $Lf2 + $Lf3;
.sort

Local LogNum   = $LNum;    * fractions (1/2, 1/3, ...)
Local LogDen   = $LDen;    * fractions
Local L        = $L;       * log(Num/Den): STILL fractional (3/2 q^4, ...)
Local Residual = $R;       * after peeling orders 2,3: order-4 coeff is now integer 1
Print LogNum LogDen L Residual;
.sort

.end
