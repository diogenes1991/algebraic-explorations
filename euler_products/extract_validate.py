#!/usr/bin/env python3
"""
Independent replica + validator for the FORM num-shift Euler-product extractor
(euler_product_extractor.frm).

Single variable q (the toy / single-branch case, l = 0). Polynomials are dicts
{power: int coeff}. This mirrors the FORM driver exactly so we can (a) confirm the
FORM output independently and (b) check, convention-free, whether a claimed
zeta factorization actually multiplies back to B(q) = Num/Den.

Toy Euler dictionary (single "prime" q, so no product over p):
    Z(k)      :=  1 / (1 - q^k)            <->   zeta(k s)
    1 + q^k    =  (1 - q^{2k})/(1 - q^k)   =   Z(k) / Z(2k)     [|mu(n)| identity]
so a factor (1 + q^P)^gamma contributes  Z(P)^gamma * Z(2P)^{-gamma}  to B.

Run: python3 extract_validate.py
"""
from collections import defaultdict

N = 40  # working truncation order in q


# --- exact polynomial arithmetic on dicts {power: coeff}, truncated at N -------
def pmul(a, b):
    r = defaultdict(int)
    for i, ci in a.items():
        for j, cj in b.items():
            if i + j <= N:
                r[i + j] += ci * cj
    return {k: v for k, v in r.items() if v != 0}


def psub(a, b):
    r = defaultdict(int)
    for k, v in a.items():
        r[k] += v
    for k, v in b.items():
        r[k] -= v
    return {k: v for k, v in r.items() if v != 0}


def pinv(a):
    """Invert a series with constant term 1."""
    assert a.get(0, 0) == 1, "series must have constant term 1"
    b = {0: 1}
    for k in range(1, N + 1):
        s = sum(a.get(i, 0) * b.get(k - i, 0) for i in range(1, k + 1))
        if s:
            b[k] = -s
    return b


def ppow(base, e):
    r = {0: 1}
    for _ in range(e):
        r = pmul(r, base)
    return r


def Z(k):      # zeta(k s)  ->  1/(1-q^k)
    return pinv({0: 1, k: -1})


def Zinv(k):   # 1/Z(k)     ->  (1-q^k)
    return {0: 1, k: -1}


def build(num_args, den_args):
    """Multiply out prod Z(a) / prod Z(b) as a q-series."""
    r = {0: 1}
    for k in num_args:
        r = pmul(r, Z(k))
    for k in den_args:
        r = pmul(r, Zinv(k))
    return r


def first_diff(a, b):
    for k in range(N + 1):
        if a.get(k, 0) != b.get(k, 0):
            return k
    return None


# --- the extraction algorithm, parameterized by branch convention -------------
def extract(Num, Den, shifts, convention="mixed"):
    """
    convention:
      "mixed"        -> FORM/Mathematica: coeff>0 uses (1-q^P), coeff<0 uses (1+q^P)
      "always-minus" -> canonical Euler transform: always (1-q^P)^coeff
    Returns (Acc dict {zeta_arg: exponent}, list of per-shift records).
    """
    Num, Den = dict(Num), dict(Den)
    Acc = defaultdict(int)
    seq = []
    for i in range(1, shifts + 1):
        diff = psub(Num, Den)
        if not diff:
            seq.append((i, None, 0, "converged", {}))
            break
        P = min(diff)          # lowest differing power (Num, Den agree at order 0)
        coeff = diff[P]
        if convention == "always-minus":
            f = ppow(Zinv(P), abs(coeff))
            Num = pmul(Num, f if coeff > 0 else pinv(f))
            Acc[P] += coeff
            seq.append((i, P, coeff, "-minus", {P: coeff}))
        else:  # mixed (matches the FORM driver)
            if coeff > 0:
                Num = pmul(Num, ppow(Zinv(P), coeff))      # (1 - q^P)^coeff
                Acc[P] += coeff
                seq.append((i, P, coeff, "+", {P: coeff}))
            else:
                Num = pmul(Num, ppow({0: 1, P: 1}, -coeff))  # (1 + q^P)^{-coeff}
                Acc[P] += coeff        # Z(P)^coeff
                Acc[2 * P] += -coeff   # Z(2P)^{-coeff}
                seq.append((i, P, coeff, "(1+)", {P: coeff, 2 * P: -coeff}))
    return Acc, seq


def show(name, Acc):
    num = sorted(k for k in Acc if Acc[k] > 0)
    den = sorted(k for k in Acc if Acc[k] < 0)
    print(f"  {name}")
    print(f"    numerator   Z: {[(k, Acc[k]) for k in num]}")
    print(f"    denominator Z: {[(k, Acc[k]) for k in den]}")


if __name__ == "__main__":
    # Toy input from euler_product_extractor.frm
    Num = {0: 1, 1: -1, 3: 1}
    Den = {0: 1, 1: -1, 2: -1, 3: 1}
    B = pmul(Num, pinv(Den))

    print("Target  B(q) = Num/Den, coeffs 0..15:")
    print("   ", {k: B.get(k, 0) for k in range(16)})
    print()

    acc_mixed, seq = extract(Num, Den, 9, "mixed")
    print("=== FORM/Mathematica convention (9 shifts) ===")
    for s in seq:
        print("   shift", s)
    show("Acc", acc_mixed)
    print()

    acc_min, _ = extract(Num, Den, 9, "always-minus")
    print("=== always-(1-q^P) convention (canonical Euler transform, 9 shifts) ===")
    show("Acc", acc_min)
    print()

    # Validation: does each claimed factorization multiply back to B(q)?
    form_prod = build([2, 3, 4, 5, 13, 14, 16, 18, 20], [8, 9, 10])
    ref_prod = build([2, 3, 4, 5, 13], [8, 9, 10, 16, 24, 26])
    print("=== reconstruction vs B(q) (first order where product != B) ===")
    print(f"    FORM product      matches B through order {first_diff(form_prod, B) - 1}")
    print(f"    reference product matches B through order {first_diff(ref_prod, B) - 1}")
    print(f"    B   coeffs 12..17: {{{', '.join(str(B.get(k,0)) for k in range(12,18))}}}")
    print(f"    ref coeffs 12..17: {{{', '.join(str(ref_prod.get(k,0)) for k in range(12,18))}}}")
