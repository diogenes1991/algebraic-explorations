#-
#include ../src/frm/algexp.hrm

Off Statistics;

Symbol q;
CFunction Zeta;

* We work with lots of dollar variables,
* so we need to have a (dummy) active expression
Local dummy = 1;

* Numerator and denominator of for
* the sample function 1 / (n*phi(n))
* (where phi is the Euler totient function)
$Num = 1 - q + q^3;
$Den = 1 - q - q^2 + q^3;
$Acc = 1;
.sort

*   Parenthesis here are necessary, otherwise the
*   operators only hit the closest term
*   ($-sign replacements are resolved as text replacements)
#do i=1,9
    $Diff`i' = `$Num' - (`$Den');
    .sort

    #call LowestPower($Diff`i',q,$Pow)
    #call CoeffAt($Diff`i',q,$Pow,$Coeff)

    #if (`$Coeff' > 0)
        $Num = (`$Num') * (1 - q^`$Pow')^`$Coeff';
        $Acc = (`$Acc') * Zeta(`$Pow')^`$Coeff';
        .sort
    #else
        $Num = (`$Num') * (1 + q^`$Pow')^{-`$Coeff'};
        $Acc = (`$Acc') * (Zeta({2*`$Pow'})/Zeta(`$Pow'))^{-`$Coeff'};
        .sort
    #endif

#enddo

Local Accumulator = `$Acc';
print;

.sort
.end
