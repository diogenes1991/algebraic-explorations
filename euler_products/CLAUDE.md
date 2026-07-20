# euler_products

Exploration: turning an Euler product into a ratio of Riemann ζ values. Start from a
multiplicative arithmetic function `a(n)`, factor `Σ a(n)/n^s = ∏_p B_p` over primes,
and greedily peel the local (Bell) factor `B_p` order by order into admissible
binomials `(1 ∓ q^{us-l})^γ`, each of which becomes a `ζ` via Euler's product. The
authoritative writeup is `tex/main.tex` (identity, greedy algorithm, termination
criterion, log-stream computation, targets); it is not auto-loaded, so read it when
working here.

## Notation conventions (for `tex/` and any math prose)

- Use `q = p^{-1}` everywhere (never `x = p^{-s}`), so `s` stays explicit in the
  exponents (`q^s`, `q^{s-1}`, `q^{us-l}`) — the exponent on `q` is the ζ-argument.
- Show the input as the full summand with `s` visible (`φ(n)/n^s ↦ ζ(s-1)/ζ(s)`),
  never hiding `s` (not `φ(n) ↦ …`).

## The two moves

Every factor introduced is read off through Euler's product (with `q^s = p^{-s}`):
`∏_p (1 - q^a)^γ = ζ(a)^{-γ}` and `∏_p (1 + q^a)^γ = (ζ(a)/ζ(2a))^γ`. So `1-` peels a
`ζ(a)`, and the `1+` branch doubles the argument. Numerator shift → upper bound of the
sum, denominator shift → lower bound (the two "bands").

## Layout

```
tex/main.tex              authoritative writeup (build: pdflatex, twice for TOC/refs)
euler_product_extractor.frm   FORM driver (naive dense; hangs ~order 50)
log_expand.frm                FORM demo of the log-stream integrality
extractor_fast.hs             efficient truncated-stream extractor
extractor_monkey.hs           naive reference extractor
extractor_backend.hs          stdin backend for the TeX generator
extract_validate.py           Python reference / cross-validator
tex_reduction.py              LaTeX-reduction generator (python|haskell backends)
Euler_Phi_Product_Extractor.nb   Mathematica extractor
HANDOFF.md                    running narrative / prior context
quora_post.md                 blog draft (gitignored: quora_*.md)
```

FORM helpers used by the drivers (`LowestPower`, `HighestPower`, `CoeffAt`,
`LogExpand`) live in the shared library `../src/frm/algexp.hrm` (see the repo root
`CLAUDE.md` for the FORM include convention).

## Non-obvious facts

- The extractor is cross-validated three ways (FORM / Haskell / Python) and they
  agree. An early FORM/Haskell "discrepancy" was a red herring: `Zeta` had been
  declared a non-commuting `Function` — use `CFunction`.
- Termination is a numerator property: it halts iff both `NUM_p` and `DEN_p` factor
  into admissible binomials (cyclotomics, in the `p`-free case). Denominators come
  from geometric sums and are automatically admissible; the numerator is where it
  breaks.
- The naive dense FORM driver balloons in degree and chokes around order 50; the
  log-stream method (multiply → add sparse logs) produces ~50 factors in a blink.

## Targets

- Running example: `Σ 1/(nφ(n))` — non-terminating (numerator `1-q+q^3` has a zero
  off the unit circle), used only for the truncated approximation `≈ 2.2039`.
- Calibration: Mathar's `φ²(n)` (arXiv:1106.4038, §3.13.1), 16 published exponents —
  an independent check before trusting the code on anything new.
- Actual target: `1/φ(n)²/n^s` — non-terminating (numerator coefficient
  `(2p-1)/((p-1)²p²)` is not a monomial in `p`). Plan: run to enough orders, conjecture
  the exponent sequence, cross-check against OEIS, then commit to a statement.

## Running (this exploration)

- FORM: `cd euler_products && form euler_product_extractor.frm`.
- Python validator: `python3 extract_validate.py`. TeX generator:
  `python3 tex_reduction.py --shifts 9 --backend python|haskell --compile`.
- Notes: `tex/main.tex` cites Mathar as prior art (same identity, same ordering
  convention); §"Mathar got here first" and the worked `φ²` check calibrate the code.
