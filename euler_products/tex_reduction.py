#!/usr/bin/env python3
"""
TeX generator for the Euler-product -> zeta reduction.

Entry point (for now): the numerator and denominator of the local Bell factor
B(q) = Num(q)/Den(q).  A backend computes the numerator-shift factorization; this
script maps the shifts to zeta values and emits a compilable LaTeX write-up of the
reduction, plus a numeric value.

    python3 tex_reduction.py --shifts 9 --backend python --out tex/reduction.tex

Later the entry point becomes the summand a(n); we'll derive Num/Den from it and
feed the same pipeline.  The backend is pluggable so the same LaTeX comes out
whether the algebra was done in Python, Haskell, or (eventually) FORM.
"""

import argparse
import re
import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------------------
# Input parsing: "power:coeff power:coeff ..."  ->  [(power, coeff), ...]
# ---------------------------------------------------------------------------
def parse_pairs(s):
    out = []
    for tok in s.split():
        p, c = tok.split(":")
        out.append((int(p), int(c)))
    return out

def pairs_to_str(pairs):
    return " ".join(f"{p}:{c}" for p, c in pairs)

# ---------------------------------------------------------------------------
# Backends: each returns the ordered list of shifts [(power, coeff), ...],
# truncated to q-order `order`.
# ---------------------------------------------------------------------------
def series_from(pairs, n):
    s = [0] * (n + 1)
    for p, c in pairs:
        if p <= n:
            s[p] += c
    return s

def _mul_binom(p, c, s):                 # s * (1 + c q^p), truncated to len(s)
    n = len(s)
    return [s[k] + (c * s[k - p] if k - p >= 0 else 0) for k in range(n)]

def _mul_binom_pow(p, c, e, s):
    for _ in range(e):
        s = _mul_binom(p, c, s)
    return s

def extract_python(num_pairs, den_pairs, order):
    """Built-in reference backend (matches extractor_fast.hs / .frm)."""
    num = series_from(num_pairs, order)
    den = series_from(den_pairs, order)
    shifts = []
    k = 1
    while k <= order:
        cf = num[k] - den[k]
        if cf != 0:
            c, e = (-1, cf) if cf > 0 else (1, -cf)   # (1-q^k)^cf vs (1+q^k)^-cf
            num = _mul_binom_pow(k, c, e, num)
            shifts.append((k, cf))
        k += 1
    return shifts

def extract_haskell(num_pairs, den_pairs, order):
    """Shell out to extractor_backend.hs via ghci; parse 'SHIFT k c' lines."""
    ghc_dir = os.path.expanduser("~/.ghcup/bin")
    env = dict(os.environ, PATH=ghc_dir + os.pathsep + os.environ.get("PATH", ""))
    stdin = f"{order}\n{pairs_to_str(num_pairs)}\n{pairs_to_str(den_pairs)}\n"
    proc = subprocess.run(
        ["ghci", "-v0", os.path.join(HERE, "extractor_backend.hs"), "-e", "main"],
        input=stdin, capture_output=True, text=True, env=env,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"haskell backend failed:\n{proc.stderr}")
    shifts = []
    for line in proc.stdout.splitlines():
        m = re.match(r"SHIFT\s+(-?\d+)\s+(-?\d+)", line)
        if m:
            shifts.append((int(m.group(1)), int(m.group(2))))
    return shifts

def extract_form(num_pairs, den_pairs, order):
    raise NotImplementedError(
        "FORM backend not wired up yet; use --backend python or haskell."
    )

BACKENDS = {"python": extract_python, "haskell": extract_haskell, "form": extract_form}

def compute_shifts(num_pairs, den_pairs, nshifts, backend):
    """Grow the q-truncation until we have `nshifts` factors, then take the first N.

    (q-order = max power tracked; the Nth shift sits at an unknown, higher power,
    so we enlarge the window until enough factors appear or the product terminates.)
    """
    fn = BACKENDS[backend]
    order = max(2 * nshifts, 8)
    for _ in range(12):                      # generous cap on doublings
        shifts = fn(num_pairs, den_pairs, order)
        if len(shifts) >= nshifts:
            return shifts[:nshifts]
        prev = len(shifts)
        order *= 2
        # if enlarging stopped adding shifts, the product terminated (finite form)
        if fn(num_pairs, den_pairs, order)[prev:] == []:
            return shifts
    return shifts[:nshifts]

# ---------------------------------------------------------------------------
# Shift -> zeta bookkeeping.  Single-q toy: zeta(k) <-> 1/(1-q^k), 1+q^k = z(k)/z(2k).
#   cf > 0: factor (1-q^k)^cf   -> zeta(k)^cf
#   cf < 0: factor (1+q^k)^-cf  -> zeta(k)^cf * zeta(2k)^-cf
# Net exponents per argument (later shifts can cancel earlier zetas).
# ---------------------------------------------------------------------------
def shifts_to_zetas(shifts):
    z = {}
    for k, cf in shifts:
        z[k] = z.get(k, 0) + cf
        if cf < 0:
            z[2 * k] = z.get(2 * k, 0) - cf
    return {a: e for a, e in z.items() if e != 0}

def zeta(n, M=16):
    """Riemann zeta(n) for n>=2 via Euler-Maclaurin (~1e-9)."""
    s = sum(1.0 / k ** n for k in range(1, M))
    s += M ** (1 - n) / (n - 1) + 0.5 * M ** (-n)
    s += n * M ** (-n - 1) / 12.0
    s -= n * (n + 1) * (n + 2) * M ** (-n - 3) / 720.0
    return s

def zetas_value(z):
    v = 1.0
    for a, e in z.items():
        v *= zeta(a) ** e
    return v

# ---------------------------------------------------------------------------
# LaTeX rendering
# ---------------------------------------------------------------------------
def poly_latex(pairs, var="q"):
    terms = sorted((p, c) for p, c in pairs if c != 0)
    out = ""
    for i, (p, c) in enumerate(terms):
        mag = abs(c)
        sign = "-" if c < 0 else "+"
        if p == 0:
            body = f"{mag}"
        else:
            qp = var if p == 1 else f"{var}^{{{p}}}"
            body = qp if mag == 1 else f"{mag}{qp}"
        if i == 0:
            out += ("-" if c < 0 else "") + body
        else:
            out += f" {sign} {body}"
    return out or "0"

def factors_latex(shifts, var="q"):
    parts = []
    for k, cf in shifts:
        base = f"(1-{var}^{{{k}}})" if cf > 0 else f"(1+{var}^{{{k}}})"
        e = cf if cf > 0 else -cf
        parts.append(base if e == 1 else f"{base}^{{{e}}}")
    return "".join(parts) if parts else "1"

def zetas_latex(z, per_line=None):
    """Render the zeta ratio.  If per_line is set, stack numerator/denominator
    every `per_line` factors (via `gathered`) so long products wrap instead of
    overflowing the margin."""
    def piece(items):
        if not items:
            return "1"
        toks = [f"\\zeta({a})" if e == 1 else f"\\zeta({a})^{{{e}}}"
                for a, e in sorted(items)]
        if per_line is None or len(toks) <= per_line:
            return "".join(toks)
        lines = ["".join(toks[i:i + per_line]) for i in range(0, len(toks), per_line)]
        return "\\begin{gathered}\n" + " \\\\\n".join(lines) + "\n\\end{gathered}"
    num = [(a, e) for a, e in z.items() if e > 0]
    den = [(a, -e) for a, e in z.items() if e < 0]
    if not den:
        return piece(num)
    return f"\\frac{{{piece(num)}}}{{{piece(den)}}}"

def detail_rows(shifts, var="q"):
    rows = []
    for k, cf in shifts:
        if cf > 0:
            fac = f"(1-{var}^{{{k}}})" + ("" if cf == 1 else f"^{{{cf}}}")
            contrib = f"\\zeta({k})" + ("" if cf == 1 else f"^{{{cf}}}")
        else:
            e = -cf
            fac = f"(1+{var}^{{{k}}})" + ("" if e == 1 else f"^{{{e}}}")
            contrib = f"\\zeta({k})^{{{cf}}}\\,\\zeta({2*k})^{{{e}}}"
        rows.append(f"  ${k}$ & ${cf}$ & ${fac}$ & ${contrib}$ \\\\")
    return "\n".join(rows)

def build_document(num_pairs, den_pairs, shifts, var, backend, per_line):
    z = shifts_to_zetas(shifts)
    val = zetas_value(z)
    return rf"""\documentclass[11pt]{{article}}
\usepackage{{amsmath,amssymb}}
\usepackage{{longtable}}
\usepackage[margin=1in]{{geometry}}
\begin{{document}}

\section*{{Zeta reduction of an Euler factor}}

Local (Bell) factor, with $q=p^{{-s}}$:
\[
  B(q)=\frac{{{poly_latex(num_pairs, var)}}}{{{poly_latex(den_pairs, var)}}}.
\]

Numerator-shift extraction to {len(shifts)} factor(s). Summing over primes via
$\zeta(s)=\prod_p(1-p^{{-s}})^{{-1}}$ and $1+p^{{-s}}=\zeta(s)/\zeta(2s)$ turns each
factor into zeta values:
\[
  \sum_n a(n)\,n^{{-s}} \;\approx\; {zetas_latex(z, per_line)}
\]
with numerical value $\approx {val:.9f}$.

\begin{{center}}
\begin{{longtable}}{{cccc}}
  \hline
  power $k$ & coeff & factor & $\zeta$-contribution \\
  \hline
\endhead
{detail_rows(shifts, var)}
  \hline
\end{{longtable}}
\end{{center}}

\noindent\footnotesize Generated by \texttt{{tex\_reduction.py}} (backend: \texttt{{{backend}}}).
\end{{document}}
"""

# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description="Generate LaTeX for the Euler->zeta reduction.")
    ap.add_argument("--num", default="0:1 1:-1 3:1",
                    help='numerator as "power:coeff ..." (default: 1 - q + q^3)')
    ap.add_argument("--den", default="0:1 1:-1 2:-1 3:1",
                    help='denominator as "power:coeff ..." (default: 1 - q - q^2 + q^3)')
    ap.add_argument("--shifts", type=int, default=9, help="number of factors to extract")
    ap.add_argument("--backend", choices=list(BACKENDS), default="python")
    ap.add_argument("--var", default="q", help="series variable symbol")
    ap.add_argument("--terms-per-line", type=int, default=12,
                    help="wrap the zeta numerator/denominator every N factors")
    ap.add_argument("--out", default=os.path.join(HERE, "tex", "reduction.tex"))
    ap.add_argument("--compile", action="store_true", help="run pdflatex on the output")
    args = ap.parse_args()

    num_pairs = parse_pairs(args.num)
    den_pairs = parse_pairs(args.den)
    shifts = compute_shifts(num_pairs, den_pairs, args.shifts, args.backend)

    doc = build_document(num_pairs, den_pairs, shifts, args.var, args.backend,
                         args.terms_per_line)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w") as f:
        f.write(doc)

    z = shifts_to_zetas(shifts)
    print(f"shifts ({len(shifts)}): {shifts}")
    print(f"zeta product: {zetas_latex(z)}")
    print(f"value: {zetas_value(z):.9f}")
    print(f"wrote: {args.out}")

    if args.compile:
        subprocess.run(["pdflatex", "-interaction=nonstopmode", "-halt-on-error",
                        os.path.basename(args.out)],
                       cwd=os.path.dirname(args.out), check=True,
                       stdout=subprocess.DEVNULL)
        print("compiled OK")

if __name__ == "__main__":
    main()
