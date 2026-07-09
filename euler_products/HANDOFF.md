# Handoff: Euler-Product → Zeta-Value Extraction Project

Status as of this session. Written for a fresh agent (or future me) to pick up
without re-deriving anything below from scratch.

## 1. What this project is

Diógenes is formalizing and implementing an algorithm that takes a
multiplicative arithmetic function $a(n)$, writes its Dirichlet series as an
Euler product $\zD(s) = \prod_p B_p(p^{-s})$, and tries to factor each local
Bell series $B_p(x)$ (a rational function of $x=p^{-s}$) into a product/ratio
of Riemann zeta values, order by order in $x$. Originally prototyped in
Mathematica (`Extractor`/`GetCharsTerm2`/`Handler`). Framed as a discretized
relative of Selberg–Delange (goes further: tries to represent $G(s)$ itself as
a product, not just its value/derivatives at $s=1$) and structurally similar
to the plethystic exponential/logarithm technique from physics.

Working style: graduate-level peer register, exact rational/integer
arithmetic throughout, Haskell preferred for real implementation, LaTeX for
writeup, push back on unverified claims rather than smoothing over them.

## 2. Prior art: Mathar, arXiv:1106.4038v2

Uploaded as a project file (`/mnt/project/1106_4038v2.pdf` — note: this file
is actually a zip archive of per-page `.jpeg`/`.txt` pairs, not a real PDF;
unzip it and concatenate the `.txt` files in numeric order to read it, `view`
chokes on it directly).

**Confirmed finding: Mathar's framework is the same construction as ours.**
His eqs. (1.5)–(1.7) are exactly our master factorization identity
$$B_p(x) = \prod_i (1-S_i p^{l_i-u_is})^{\gamma_i}, \quad S_i=\pm1,$$
ordered by increasing $u_i$ then decreasing $l_i$ — same ordering convention
we'd independently arrived at. His eq. (1.7) is our Euler identity mapping
each factor to a $\zeta$-ratio. He doesn't frame it via Selberg–Delange or
plethystics, and it's a table-of-results survey, not a reusable algorithm —
so citing as prior art, not treating as redundant.

**Key validation benchmark: §3.13.1, $\varphi^2(n)$ (Hadamard square of
Euler's totient).** Master eq. $a(p^e)=(p-1)^2p^{2e-2}$; Bell series
(his eq. 3.78) $B_p(x) = \dfrac{1-(2p-1)x}{1-p^2x}$. This does **not**
terminate in finitely many factors; his eq. (3.79) gives an explicit 16-term
infinite product with exponent sequence
$2,1,1,2,2,4,2,3,8,5,2,6,16,16,8,2,\dots$ using a mixed $S=\pm1$ sign
convention (both $(1-p^{l-us})$ and $(1+p^{l-us})$ type factors) to keep
exponents small. This is the reference case used to validate the PoC
extractors (see §4).

Full extracted text of the paper is not saved anywhere persistent — if needed
again, re-run: unzip `1106_4038v2.pdf`, `cat` the numbered `.txt` files in
order.

## 3. LaTeX writeup (started, not finished)

**File: `euler_zeta_extraction.tex`** (in outputs, in this project's
`/mnt/user-data/outputs/`). Contains:
- §1: formal statement of the target identity + Euler's formula
  (eqs. \eqref{eq:euler-minus}/\eqref{eq:euler-plus}) + informal algorithm
  statement + relation to Selberg–Delange and plethystic log.
- §2: Mathar's framework quoted precisely as prior art, his $\varphi^2(n)$
  worked example reproduced (his eq. 3.79) as the validation benchmark.
- §3: **Proposition** (proved): Bell series of $1/\varphi(n)^2$ is
  $$B_p(x) = \frac{(p-1)^2p^2+(2p-1)x}{(p-1)^2(p^2-x)}.$$
  Followed by a flagged remark (written honestly as "needs checking," not
  asserted) about the $(p-1)^{-2}$-type prefactor not fitting the monomial
  template — **this remark is now partially superseded by §5 below and
  should be revised when the writeup is next touched.**
- §4: next-steps list (now partly stale, see §6 here for the live version).

**Not yet done:** incorporating the PoC findings (§4–5 below) into the tex,
including the empirical confirmation of the `DEN(0)≠1` obstruction and the
corrected understanding of why non-monomial residuals are *not* actually a
problem in general (§5).

## 4. Proof-of-concept implementations: Haskell + C++ (done, cross-validated)

**Location:** `/mnt/user-data/outputs/poc/extractor.hs`,
`/mnt/user-data/outputs/poc/extractor.cpp` (also live at
`/home/claude/poc/` in the sandbox this session, compiled binaries
`extractor_hs`, `extractor_cpp` sitting there too if the same container
persists — don't count on it persisting across sessions).

### Algorithm implemented (identical in both languages)

Given $\mathrm{NUM}_p(x), \mathrm{DEN}_p(x) \in \mathbb{Z}[p][x]$:
1. Represent a "p-polynomial" as a sparse map `power-of-p -> integer`
   (exact, arbitrary precision: Haskell native `Integer`, C++ `mpz_class`
   via GMP).
2. Represent a series in $x$ as a list/vector of p-polynomials, one per
   order, truncated at working order $N$.
3. **Invert $\mathrm{DEN}$** via the standard recurrence assuming constant
   term is exactly the polynomial $1$: $\mathrm{Inv}_0=1$,
   $\mathrm{Inv}_n = -\sum_{i=1}^n \mathrm{DEN}_i \cdot \mathrm{Inv}_{n-i}$.
   **If $\mathrm{DEN}_0 \neq 1$ exactly (as a polynomial in $\mathbb{Z}[p]$),
   this step fails and the program reports it explicitly** — this is the
   real, sharp obstruction criterion (see §5).
4. $R = \mathrm{NUM}\cdot\mathrm{DEN}^{-1}$ (series multiplication).
5. **Extraction loop:** at each order $u=1,2,\dots$, the residual's
   coefficient (an integer polynomial in $p$) is decomposed into its
   monomials $c(p) = \sum_l c_l p^l$ — **importantly, this is always
   possible** (any integer polynomial trivially decomposes into monomials);
   an earlier version of the code wrongly required a *single* monomial and
   flagged "non-monomial" as a stop condition — that was a bug, fixed. For
   each nonzero $(l,c_l)$: extract factor $(1-p^lx^u)^{\gamma}$ with
   $\gamma=-c_l$ (fixed sign convention $S=+1$ throughout — see caveat
   below), divide it out via multiplying by
   $(1-p^lx^u)^{c_l}$ (computed via the exact integer generalized binomial
   series, no rationals needed since $\binom{\gamma}{k}\in\mathbb{Z}$ for
   integer $\gamma$), continue to next order.
6. Report the extracted $(u,l,\gamma)$ list.

**Sign-convention caveat (important, unresolved elegance issue, not a
correctness issue):** the PoC only ever extracts $S=+1$ ("$-$"-type) factors.
Mathar's published $\varphi^2(n)$ product mixes $S=+1$ and $S=-1$ factors to
keep exponents small (his max exponent is 32). Our $S=+1$-only convention is
**mathematically valid but combinatorially much worse** — see benchmark
numbers below. This is expected: the infinite-product representation is
non-uniform/non-unique, confirmed empirically. Getting the compact
alternating-sign version would need a lookahead/greedy sign-disambiguation
step, not yet implemented.

### Validated results

Both languages produce **identical output** (cross-check passed):

- **$\varphi^2(n)$ test case, order $N=60$:** 1833 factors extracted, largest
  $|\gamma|$ has 26 decimal digits, terminates cleanly (as expected — Mathar's
  case is the "infinite but always-monomial-decomposable" Mode 1, see §5).
  At $N=24$ the first several extracted exponents were spot-checked by hand
  against the Bell-series algebra and are self-consistent.
- **$1/\varphi(n)^2$ (our actual target), order $N=60$:** **fails immediately**
  at the DEN-inversion step: `DEN(0) != 1 in Z[p]: cannot invert termwise in
  the polynomial ring.` This is because
  $\mathrm{DEN}_0 = (p-1)^2p^2 = p^4-2p^3+p^2 \neq 1$. Confirms empirically
  (not just by hand-argument) that this function sits outside what the
  $\mathbb{Z}[p]$-based extraction algorithm can even start on — see §5 for
  what this does and doesn't mean.

### Timing/size benchmark ($N=60$, both cases run, wall clock via `bash -c "time ..."`)

| | Haskell | C++ (GMP) |
|---|---|---|
| Source lines | 124 | 168 |
| Wall time | ~1.57s | ~1.09s |
| CPU time (self-reported) | 1.49s | included above |
| Binary size | 14 MB (static GHC RTS) | 50 KB |
| Bignum | native `Integer` | explicit GMP `mpz_class` |

C++ modestly faster, Haskell modestly shorter/simpler to write (no manual
memory/type ceremony for the bignum polynomial maps); both "nothing crazily
optimized" — dense-ish `std::map`/`Data.Map.Strict` sparse polynomials,
no memoization, no parallelism.

## 5. Key conceptual finding this session (resolves/refines earlier over-claim)

Diógenes correctly pushed back on an earlier claim that isolated $(p-1)$-type
prefactors (e.g. in $1/\varphi(n)$, $1/\varphi(n)^2$) represent a hard
analytic obstruction. Corrected understanding, now confirmed both
analytically and empirically:

- **Not an obstruction:** a residual coefficient polynomial in $p$ having
  *multiple* monomial terms (e.g. $(p-1)^2 = p^2-2p+1$) is totally fine —
  each term just yields its own factor at that order. This is exactly
  Mathar's Mode 1 ($\varphi^2(n)$): infinite product, well-posed, just
  doesn't terminate. The PoC bug (§4) had this backwards initially.
- **The real, sharp obstruction:** when $\mathrm{DEN}_p(0) \neq 1$ as an
  element of $\mathbb{Z}[p]$ — i.e. the constant term of the denominator
  isn't the multiplicative identity — the series-inversion recurrence simply
  cannot run in the polynomial ring $\mathbb{Z}[p][[x]]$; you'd need to work
  in the field of fractions $\mathbb{Q}(p)[[x]]$ instead. This is exactly
  what happens for $1/\varphi(n)^2$ (and $1/\varphi(n)$, checked by hand,
  not yet in the PoC): $\mathrm{DEN}_0=(p-1)^2p^2$.
- **Connection to divergence (Diógenes's observation, correct):** the
  isolated $(p-1)^{-1}$ piece is literally $(1-p^{-1})^{-1}$ evaluated at the
  single frozen point "$s=1$" rather than as a function of $s$ — i.e. it's
  $\zeta(1)$ (divergent) trying to masquerade as a per-prime constant. This
  is *why* $u=0$ is structurally excluded from the building-block set, not
  an arbitrary restriction.
- **What "factoring it out" actually buys you:** the full $B_p(x)$ and
  $\zD(s)$ are perfectly convergent/well-defined for $\Re(s)$ large enough —
  nothing is analytically broken. What's genuinely open is *representability*:
  whether the residual, non-$(p-1)$ piece can be written as a zeta-ratio
  product. Classical results (e.g. Landau: $\sum_{n\le x} n/\varphi(n)\sim Ax$,
  $A=\zeta(2)\zeta(3)/\zeta(6)$) only pin down the Selberg–Delange constant
  $G(1)$, a *number* — not $G(s)$ as a function, which is what this project
  actually wants. So the open question stands, just correctly scoped now:
  not "does it diverge" but "is $G(s)$ representable in zeta-ratio vocabulary
  at all, given $\mathrm{DEN}_0 \neq 1$ blocks the direct algorithm."
- **Not yet done:** actually working the $1/\varphi(n)^2$ extraction over
  $\mathbb{Q}(p)$ (rational functions in $p$, not just polynomials) to see
  whether *that* version terminates/behaves well. This is the natural next
  computational step and would settle the representability question
  empirically rather than by further hand-argument.

## 6. FORM implementation: not done, in progress

**File: `/mnt/user-data/outputs/poc/test1.frm`** — this is only a **syntax
scratch test**, not the real algorithm. It checks two FORM idioms needed for
the real port:
1. Truncating a power series by degree in `x`: `if (count(x,1) > N) discard;`
2. Isolating a single term/monomial and reading off its numeric coefficient
   (via `id p=1; id x=1;` after isolating one $(u,l)$ slice).

**Status: written but not yet run/debugged in this session** — the sandbox
session ended before executing `test1.frm` through the `form` binary to
confirm the syntax works as intended. This is the immediate next action.

**Design sketch for the real FORM port** (not yet written):
- Represent NUM, DEN as `Local` polynomial expressions in symbols `p,x`.
- Invert DEN mod $x^{N+1}$ via Newton iteration (quadratic convergence,
  $\lceil\log_2 N\rceil$ steps): `Inv_new = Inv*(2 - DEN*Inv)`, truncate via
  `if (count(x,1) > N) discard;` after each step.
- $R = \mathrm{NUM}\cdot\mathrm{Inv}$, truncate.
- Extraction loop: FORM has no native "iterate over nonzero terms of an
  unknown polynomial," so this needs a `#do`-unrolled double loop over
  $u=1..N$ and candidate $l=0..(\text{max degree})$, isolating each
  $(u,l)$ slice via `if (count(x,1)!=u) discard;` /
  `if (count(p,1)!=l) discard;`, reading the coefficient into a `$`-dollar
  variable, and if nonzero, building and multiplying in the corresponding
  factor. For $N=60$ this is on the order of $60\times120$ module iterations
  — plan to first get correctness at a smaller order (e.g. $N=16$, matching
  Mathar's published term count) before attempting the $N=60$ benchmark scale
  used for Haskell/C++, and note honestly in the final comparison if FORM was
  benchmarked at a different (smaller) order for engineering-time reasons.

## 7. Immediate next actions (in priority order)

1. Finish debugging `test1.frm` syntax, then write the real
   `extractor.frm` per the design sketch above; get it correct at $N=16$
   against the known Haskell/C++ output at $N=16$ (cross-validate all three
   before trusting FORM's numbers); then decide whether to push FORM to
   $N=60$ for a fair size/time comparison or report at reduced scale.
2. Complete the three-way size/time comparison table (currently only
   Haskell vs. C++ — see §4) and write it up.
3. Extend the Haskell/C++ PoC (or a variant) to work over $\mathbb{Q}(p)$
   rather than $\mathbb{Z}[p]$, and actually run the $1/\varphi(n)^2$
   extraction to see what happens — this is the real open question from §5,
   and it's now computationally tractable to just check rather than keep
   arguing about analytically.
4. Fold the §5 findings (corrected understanding of the obstruction,
   empirical confirmation) into `euler_zeta_extraction.tex`, replacing the
   too-tentative "flagged remark" in current §3 with the sharper
   $\mathrm{DEN}(0)\neq1$ criterion and the divergence/$\zeta(1)$
   connection.
5. Only after (3) resolves representability one way or the other, write the
   closed-form or infinite-product theorem for $1/\varphi(n)^2$ properly.

## 8. File index

| File | Location | Status |
|---|---|---|
| `euler_zeta_extraction.tex` | `/mnt/user-data/outputs/` | Draft, §1–2 solid, §3 remark now stale (see §3/§6 above) |
| `extractor.hs` | `/mnt/user-data/outputs/poc/` | Working, validated, benchmarked |
| `extractor.cpp` | `/mnt/user-data/outputs/poc/` | Working, validated, benchmarked, output matches Haskell exactly |
| `test1.frm` | `/mnt/user-data/outputs/poc/` | Syntax scratch only, unrun |
| Mathar PDF (project file) | `/mnt/project/1106_4038v2.pdf` | Read this session; remember it's a zip-of-jpeg/txt, not a real PDF |
