# Euler products → ratios of zeta values

Take a multiplicative arithmetic function `a(n)` and the Dirichlet series
`Σ a(n)/n^s`. Multiplicativity turns it into an Euler product over primes, and when
the local factor is a rational function of `p^{-s}` it can be peeled apart, one order
at a time, into pieces that are each a Riemann zeta value. The output is the series
rewritten as a (finite or infinite) product/ratio of `ζ`'s — for example
`φ(n)/n^s ↦ ζ(s-1)/ζ(s)`.

This directory collects the write-up, the algorithm, and several independent
implementations, worked around the running example `Σ 1/(nφ(n))` and the harder
target `1/φ(n)²`.

## Read this first

- **`tex/main.tex`** — the notes: the identity, the greedy peeling algorithm, when it
  terminates (and when it doesn't), an efficient log-space variant, and the worked
  examples. Start here.

## What's here

- Extractors implementing the algorithm in **FORM**, **Haskell**, **Python**, and
  **Mathematica**, cross-validated against each other and against R. J. Mathar's
  survey (arXiv:1106.4038), which sets up the same construction.

See `CLAUDE.md` for the file-by-file layout and how to run things.
