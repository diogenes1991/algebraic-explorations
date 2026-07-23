#-
#include- ../src/frm/algexp.hrm

Off Statistics;

auto s x;
auto s r,q;
Symbol xSR;

Table PBifurcation(1);
Table NBifurcation(1);
Table PLadder(1);
Table NLadder(1);
Table RSolution(1);

*===========================================================================
#procedure CompoundLogistic(DOLLAR,SYMB)
*   One logistic composition: DOLLAR -> r * DOLLAR * (1 - DOLLAR)
    $CLtmp = replace_(`SYMB',(r)*`SYMB'*(1-`SYMB'))*(`DOLLAR');
    .sort
    `DOLLAR' = `$CLtmp';
    .sort
#endprocedure

*===========================================================================
#procedure LogisticBifurcations(B,N)
*
*   Derive the bifurcation polynomial for the period B*2^{N-1} -> B*2^N
*   doubling of the logistic map f_r(x) = r*x*(1-x).
*
*   The result is stored in [RSolution(M)] where M = B*2^{N-1}.

    $M = {`B'*2^{`N'}/2};
    .sort

    g [NBifurcation(`$M')] = 0;
    g [PBifurcation(`$M')] = 0;

    #message -----------------------------------------------------
    #message Finding the defining equations for
    #message the {`B'*2^{`N'}/2} --> {`B'*{2^`N'}} Bifurcation

    $Base = x;
    $NDefinition = x;
    $PDefinition = x;
    $Constraint = x;
    $Redundant  = x;
    .sort

*   --- Phase 1: build iterates and snapshot bifurcation conditions ---

    #do i=1,{`B'*2^`N'}
        #message Now on step `i'/{`B'*2^`N'} of building (`TIME_'s)
        #call CompoundLogistic($Base,x)
    #if ( `i' == {`B'*2^{`N'}/2} )
        $NDefinition = `$Base'+x;
        $Constraint = `$Base'-x;
        .sort
    #endif
    #if (`N'>=1)
    #if ((`i'=={2^{`N'}*`B'/4}))
        $Redundant = `$Base';
        .sort
    #endif
    #endif
    #enddo

    $PDefinition = `$Base'-x;
    $Redundant = `$Redundant'-x;
    .sort

    #message Base definition built (`TIME_')

*   --- Phase 2: differentiate ---

    #message Deriving 1/2
    #call Derivative($PDefinition,x)
    #message (`TIME_'s)
    #message Deriving 2/2
    #call Derivative($NDefinition,x)
    #message (`TIME_'s)
    .sort

    #message Definitions and constraint built (`TIME_'s)

*   --- Phase 3: remove lower-period solutions ---

    #if(`N'>=1)
        $TOID = div_(`$Constraint',`$Redundant');
    #else
        $TOID = `$Constraint';
    #endif
    .sort

    $LHSID = 0;
    $RHSID = 0;
    $POW = 0;
    $NUM = 0;
    .sort

*   --- Phase 4: reduce P and N definitions modulo constraint ---

    #call PolyLeadRule($TOID,x,$LHSID,$RHSID,$POW,$NUM)
    #call PolyReduce($NDefinition,x,$LHSID,$RHSID,$POW,$NUM)
    #call PolyReduce($PDefinition,x,$LHSID,$RHSID,$POW,$NUM)

    g [NBifurcation(`$M')] = `$NDefinition';
    g [PBifurcation(`$M')] = `$PDefinition';
    .sort

    #message Building of defining equations done (`TIME_'s)
    #message -----------------------------------------------------

*   --- Phase 5: ladder reduction (cross-reduce P and N) ---

    #message Reducing positive definition

    g [PLadder(`$M')] = 0;
    $TOID = [NBifurcation(`$M')];
    .sort

    #call HighestPower($TOID,x,$POW)

    #do i=1,{`$POW'-{`B'*2^{`N'}/2}}
        $EXPR = [PBifurcation(`$M')];
        .sort
        #call HighestPower($TOID,x,$POW)
        #if( `$POW' <= {`B'*2^{`N'}/2} )
            #message Reduction of positive definition done (`TIME_'s)
            #message ------------------------------------------------
            #breakdo
        #else
            #call PolyLeadRule($TOID,x,$LHSID,$RHSID,$POW,$NUM)
            #call PolyReduce($EXPR,x,$LHSID,$RHSID,$POW,$NUM)
            $VALUE = -2;
            #call DivideOutRoot($EXPR,r,$VALUE)
            $VALUE = 2;
            #call DivideOutRoot($EXPR,r,$VALUE)
            $VALUE = 4;
            #call DivideOutRoot($EXPR,r,$VALUE)
            $TOID = $EXPR;
            .sort
        #endif
    #enddo

    g [PLadder(`$M')] = `$TOID';
    .sort

    #message Reducing negative definition

    g [NLadder(`$M')] = 0;
    $TOID = [PBifurcation(`$M')];
    .sort

    #call HighestPower($TOID,x,$POW)

    #do i=1,{`$POW'-{`B'*2^{`N'}/2}}
        $EXPR = [NBifurcation(`$M')];
        .sort
        #call HighestPower($TOID,x,$POW)
        #if( `$POW' <= {`B'*2^{`N'}/2} )
            #message Reduction of negative definition done (`TIME_'s)
            #message ------------------------------------------------
            #breakdo
        #else
            #call PolyLeadRule($TOID,x,$LHSID,$RHSID,$POW,$NUM)
            #call PolyReduce($EXPR,x,$LHSID,$RHSID,$POW,$NUM)
            $VALUE = -2;
            #call DivideOutRoot($EXPR,r,$VALUE)
            $VALUE = 2;
            #call DivideOutRoot($EXPR,r,$VALUE)
            $VALUE = 4;
            #call DivideOutRoot($EXPR,r,$VALUE)
            $TOID = $EXPR;
            .sort
        #endif
    #enddo

    g [NLadder(`$M')] = `$TOID';
    .sort

*   --- Phase 6: eliminate x (resultant via cross-products + GCD) ---

    $PDefinition = replace_(x,xSR)*[PLadder(`$M')];
    $NDefinition = replace_(x,xSR)*[NLadder(`$M')];
    .sort

    #call HighestPower($PDefinition,xSR,$POW)

    #do i=0,`$POW'
        .sort
        l CP`i' = `$PDefinition';
        l CN`i' = `$NDefinition';
        .sort
        id xSR^{`$POW'-`i'+1} = 1;
        id xSR = 0;
        .sort
    #enddo

    #if (`$POW'>0)
    #do i=0,{`$POW'-1}
        .sort
        l CR`i' = (CP`i')*(CN`$POW') - (CN`i')*(CP`$POW');
        .sort
        #if(`i'>0)
        g [RSolution(`$M')] = gcd_([RSolution(`$M')],CR`i');
        #else
        g [RSolution(`$M')] = CR`i';
        #endif
        .sort
    #enddo
    #else
        g [RSolution(`$M')] = gcd_([PLadder(`$M')],[NLadder(`$M')]);
    #endif

    $EXPR = [RSolution(`$M')];
    #call PrimitivePart($EXPR)
    $VALUE = 2;
    #call DivideOutRoot($EXPR,r,$VALUE)
    $VALUE = 4;
    #call DivideOutRoot($EXPR,r,$VALUE)
    $VALUE = -2;
    #call DivideOutRoot($EXPR,r,$VALUE)
    g [RSolution(`$M')] = `$EXPR';
    .sort

    #message Solution to the {`B'*2^{`N'-1}} --> {`B'*2^`N'} Bifurcation done
    #message All the r that produce this are roots of [RSolution(`$M')] = 0
    #message -------------------------------------------------------------

#endprocedure

*===========================================================================

Local dummy = 1;
.sort

$order = 1;
$base = 3;
.sort

#call LogisticBifurcations(`$base',`$order')

.sort
print [RSolution({`$base'*2^{`$order'}/2})];
.end
