# feigenbaum

Exploration: symbolic computation of the exact bifurcation polynomials of the
logistic map $f_r(x) = rx(1-x)$.  Given a period-doubling transition (period $m
\to 2m$), the program derives the polynomial in $r$ whose roots are the
parameter values at which the bifurcation occurs --- entirely symbolically, no
numerical root-finding.  The ratios of successive bifurcation intervals converge
to the Feigenbaum constant $\delta \approx 4.669$.

## The idea in one paragraph

At a period-doubling bifurcation from period $m$ to $2m$, two conditions hold:
the period-$m$ cycle exists ($f^m(x) = x$) and its multiplier equals $-1$
($(f^m)'(x) = -1$).  These are two polynomial equations in $x$ and $r$; the code
eliminates $x$ by iterated polynomial reduction (long division in $x$), strips
known trivial roots ($r = \pm 2, 4$), and outputs the minimal polynomial in $r$
whose roots are the new bifurcation values.

## Layout

```
feigenbaum.frm              FORM driver (uses library from ../src/frm/algexp.hrm)
tex/main.tex                pedagogical writeup of the method
CLAUDE.md                   this file
```

## Running

```
cd feigenbaum && form feigenbaum.frm
```

The active invocation is `LogisticBifurcations(2,1)` which computes the 2 -> 4
bifurcation (producing `r^2 - 2r - 5 = 0`, i.e. `r = 1 + sqrt(6)`).  Edit the
call at the bottom of the file to target other transitions.  Higher bifurcations
are expensive --- the symbolic expressions grow as $O(2^{2m})$ in degree.

## Procedures

**From library (`src/frm/algexp.hrm`):**

- `Derivative(EXPR,SYMB)` --- symbolic differentiation.
- `PrimitivePart(EXPR)` --- remove numerical GCD prefactor.
- `DivideOutRoot(EXPR,SYMB,ROOT)` --- divide out a known linear root.
- `HighestPower(EXPR,SYMB,POW)` --- highest power of a symbol.
- `PolyLeadRule` / `PolyReduce` --- polynomial reduction modulo an identity
  (extract leading-power substitution rule, apply it to lower degree).

**Local to this driver:**

- `CompoundLogistic(DOLLAR,SYMB)` --- one composition $\$ \to r\$(1-\$)$.
- `LogisticBifurcations(B,N)` --- the main driver: builds iterates, sets up
  bifurcation conditions, eliminates $x$, outputs the bifurcation polynomial.

## Non-obvious facts

- The two bifurcation conditions used are: $(f^m)'(x) + 1 = 0$ (the
  "negative" definition, $N$: multiplier of the $m$-cycle equals $-1$) and
  $(f^{2m})'(x) - 1 = 0$ (the "positive" definition, $P$: multiplier of the
  nascent $2m$-cycle equals $+1$).  Both describe the same bifurcation event;
  the code cross-reduces them to eliminate $x$.
- The "ladder" phase alternates: use $N$ to reduce $P$, then the result to
  reduce $N$, etc. --- essentially the Euclidean algorithm in $x$ over
  $\mathbb{Z}[r]$.
- Trivial roots $r = \pm 2, 4$ are stripped at each reduction step.  These
  correspond to degenerate/superstable cases that appear generically.
