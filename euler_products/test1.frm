Symbol q;
Auto Symbol xCI;

#procedure HighestPower(DOLLAR,SYMB,POW)
    .sort
    Local loc = replace_(`SYMB',xCI)*(`DOLLAR');
    $xmax = -1;
    .sort

    if ( count(xCI,1) > $xmax ) $xmax = count_(xCI,1);
    .sort

    `POW' = `$xmax';

    .sort
    Local loc = 0;
#endprocedure


$den = 1 - q^2;
$denPow = -1;
$xmax = -1;
.sort
*$num = 1 - q^2 - q^3;

#call HighestPower(`den`,q,`denPow`);

#message $denPow;
.end
