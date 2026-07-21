#-
#include- ../src/frm/algexp.hrm

Off Statistics;

Symbol z, c, xSR, y;

Table PBifurcation(1);
Table NBifurcation(1);
Table PLadder(1);
Table NLadder(1);
Table CSolution(1);

*===========================================================================
#procedure CompoundQuadratic(DOLLAR,SYMB)
*   One quadratic composition: DOLLAR -> DOLLAR^2 + c
    $CQtmp = replace_(`SYMB',`SYMB'^2+c)*(``DOLLAR'');
    .sort
    `DOLLAR' = `$CQtmp';
    .sort
#endprocedure

*===========================================================================
#procedure MandelbrotBifurcations(B,N)
*
*   Derive the bifurcation polynomial in c for the period B*2^{N-1} -> B*2^N
*   doubling of the standard quadratic g_c(z) = z^2 + c.
*
*   The result is stored in [CSolution(M)] where M = B*2^{N-1}.

    $M = {`B'*2^{`N'}/2};
    .sort

    g [NBifurcation(`$M')] = 0;
    g [PBifurcation(`$M')] = 0;

    #message =====================================================
    #message [Mandelbrot] Finding the defining equations for
    #message the {`B'*2^{`N'}/2} --> {`B'*{2^`N'}} Bifurcation

    $Base = z;
    $NDefinition = z;
    $PDefinition = z;
    $Constraint = z;
    $Redundant  = z;
    .sort

*   --- Phase 1: build iterates and snapshot bifurcation conditions ---

    #do i=1,{`B'*2^`N'}
        #message Now on step `i'/{`B'*2^`N'} of building (`TIME_'s)
        #call CompoundQuadratic($Base,z)
    #if ( `i' == {`B'*2^{`N'}/2} )
        $NDefinition = `$Base'+z;
        $Constraint = `$Base'-z;
        .sort
    #endif
    #if (`N'>=1)
    #if ((`i'=={2^{`N'}*`B'/4}))
        $Redundant = `$Base';
        .sort
    #endif
    #endif
    #enddo

    $PDefinition = `$Base'-z;
    $Redundant = `$Redundant'-z;
    .sort

    #message Base definition built (`TIME_')

*   --- Phase 2: differentiate ---

    #message Deriving 1/2
    #call Derivative($PDefinition,z)
    #message (`TIME_'s)
    #message Deriving 2/2
    #call Derivative($NDefinition,z)
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

    #call PolyLeadRule($TOID,z,$LHSID,$RHSID,$POW,$NUM)
    #call PolyReduce($NDefinition,z,$LHSID,$RHSID,$POW,$NUM)
    #call PolyReduce($PDefinition,z,$LHSID,$RHSID,$POW,$NUM)

    g [NBifurcation(`$M')] = `$NDefinition';
    g [PBifurcation(`$M')] = `$PDefinition';
    .sort

    #message Building of defining equations done (`TIME_'s)
    #message =====================================================

*   Check if either definition is already z-free (common for the quadratic
*   map, whose simpler coefficient structure lets the reduction complete
*   in Phase 4).  If so, it is already the bifurcation polynomial in c.

    #call HighestPower($NDefinition,z,$NDEG)
    #call HighestPower($PDefinition,z,$PDEG)

    #if ( `$NDEG' <= 0 )
        #message N definition is z-free; short-circuiting to c-polynomial
        g [CSolution(`$M')] = `$NDefinition';
        .sort
    #elseif ( `$PDEG' <= 0 )
        #message P definition is z-free; short-circuiting to c-polynomial
        g [CSolution(`$M')] = `$PDefinition';
        .sort
    #else

*   --- Phase 5: ladder reduction (cross-reduce P and N) ---

    #message Reducing positive definition

    g [PLadder(`$M')] = 0;
    $TOID = [NBifurcation(`$M')];
    .sort

    #call HighestPower($TOID,z,$POW)

    #do i=1,{`$POW'-{`B'*2^{`N'}/2}}
        $EXPR = [PBifurcation(`$M')];
        .sort
        #call HighestPower($TOID,z,$POW)
        #if( `$POW' <= {`B'*2^{`N'}/2} )
            #message Reduction of positive definition done (`TIME_'s)
            #message ------------------------------------------------
            #breakdo
        #else
            #call PolyLeadRule($TOID,z,$LHSID,$RHSID,$POW,$NUM)
            #call PolyReduce($EXPR,z,$LHSID,$RHSID,$POW,$NUM)
            $VALUE = 0;
            #call DivideOutRoot($EXPR,c,$VALUE)
            $VALUE = -2;
            #call DivideOutRoot($EXPR,c,$VALUE)
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

    #call HighestPower($TOID,z,$POW)

    #do i=1,{`$POW'-{`B'*2^{`N'}/2}}
        $EXPR = [NBifurcation(`$M')];
        .sort
        #call HighestPower($TOID,z,$POW)
        #if( `$POW' <= {`B'*2^{`N'}/2} )
            #message Reduction of negative definition done (`TIME_'s)
            #message ------------------------------------------------
            #breakdo
        #else
            #call PolyLeadRule($TOID,z,$LHSID,$RHSID,$POW,$NUM)
            #call PolyReduce($EXPR,z,$LHSID,$RHSID,$POW,$NUM)
            $VALUE = 0;
            #call DivideOutRoot($EXPR,c,$VALUE)
            $VALUE = -2;
            #call DivideOutRoot($EXPR,c,$VALUE)
            $TOID = $EXPR;
            .sort
        #endif
    #enddo

    g [NLadder(`$M')] = `$TOID';
    .sort

*   --- Phase 6: eliminate z (resultant via cross-products + GCD) ---

    $PDefinition = replace_(z,xSR)*[PLadder(`$M')];
    $NDefinition = replace_(z,xSR)*[NLadder(`$M')];
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
        g [CSolution(`$M')] = gcd_([CSolution(`$M')],CR`i');
        #else
        g [CSolution(`$M')] = CR`i';
        #endif
        .sort
    #enddo
    #else
        g [CSolution(`$M')] = gcd_([PLadder(`$M')],[NLadder(`$M')]);
    #endif

    #endif

    $EXPR = [CSolution(`$M')];
    #call PrimitivePart($EXPR)
    $VALUE = 0;
    #call DivideOutRoot($EXPR,c,$VALUE)
    $VALUE = -2;
    #call DivideOutRoot($EXPR,c,$VALUE)
    g [CSolution(`$M')] = `$EXPR';
    .sort

    #message Solution to the {`B'*2^{`N'-1}} --> {`B'*2^`N'} Bifurcation done
    #message All the c that produce this are roots of [CSolution(`$M')] = 0
    #message =====================================================

#endprocedure

*===========================================================================

Local dummy = 1;
.sort

$order = 1;
$base = 3;
.sort

#call MandelbrotBifurcations(`$base',`$order')
.sort

id c = (1-y)/4;

.sort
print [CSolution({`$base'*2^{`$order'}/2})];
.end
