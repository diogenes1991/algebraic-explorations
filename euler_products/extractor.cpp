// Term-by-term extraction of B_p(x) = NUM(x)/DEN(x) into a product of
// (1 - p^l x^u)^gamma factors. Same algorithm as extractor.hs.
//
// p-polynomial: sparse map power-of-p -> mpz_class coefficient.
// Series in x: vector of p-polynomials, index = power of x.

#include <gmpxx.h>
#include <map>
#include <vector>
#include <iostream>
#include <chrono>
#include <optional>

using PPoly  = std::map<int, mpz_class>;
using Series = std::vector<PPoly>;

static void trim(PPoly &p) {
    for (auto it = p.begin(); it != p.end(); ) {
        if (it->second == 0) it = p.erase(it); else ++it;
    }
}

PPoly pAdd(const PPoly &a, const PPoly &b) {
    PPoly r = a;
    for (auto &kv : b) r[kv.first] += kv.second;
    trim(r);
    return r;
}

PPoly pMul(const PPoly &a, const PPoly &b) {
    PPoly r;
    for (auto &ka : a)
        for (auto &kb : b)
            r[ka.first + kb.first] += ka.second * kb.second;
    trim(r);
    return r;
}

PPoly pOne() { return PPoly{{0, mpz_class(1)}}; }

Series seriesMulTrunc(int n, const Series &a, const Series &b) {
    Series r(n + 1);
    for (int k = 0; k <= n; k++) {
        PPoly acc;
        for (int i = 0; i <= k; i++) acc = pAdd(acc, pMul(a[i], b[k - i]));
        r[k] = acc;
    }
    return r;
}

// Invert a series with constant term exactly 1 (ring Z[p]); nullopt if not.
std::optional<Series> seriesInvert(int n, const Series &a) {
    if (!(a[0].size() == 1 && a[0].count(0) && a[0].at(0) == 1)) return std::nullopt;
    Series inv(n + 1);
    inv[0] = pOne();
    for (int m = 1; m <= n; m++) {
        PPoly s;
        for (int i = 1; i <= m; i++) s = pAdd(s, pMul(a[i], inv[m - i]));
        for (auto &kv : s) kv.second = -kv.second;
        trim(s);
        inv[m] = s;
    }
    return inv;
}

// exact integer binomial coefficient C(g,k) for any integer g (possibly negative)
mpz_class binom(const mpz_class &g, int k) {
    mpz_class num = 1;
    for (int i = 0; i < k; i++) num *= (g - i);
    mpz_class fact = 1;
    for (int i = 1; i <= k; i++) fact *= i;
    return num / fact; // exact
}

// series for (1 - p^l x^u)^c, truncated to order n
Series factorSeries(int n, int u, int l, const mpz_class &c) {
    Series f(n + 1);
    for (int k = 0; k <= n; k++) {
        if (k % u != 0) continue;
        int j = k / u;
        if (j == 0) { f[k] = pOne(); continue; }
        mpz_class co = binom(c, j) * (j % 2 ? -1 : 1);
        if (co != 0) f[k][l * j] = co;
    }
    return f;
}

struct Factor { int u, l; mpz_class gamma; };

std::vector<Factor> extract(int n, Series res) {
    std::vector<Factor> out;
    for (int u = 1; u <= n; u++) {
        // snapshot terms at this order before mutating res via factor division
        std::vector<std::pair<int, mpz_class>> terms(res[u].begin(), res[u].end());
        for (auto &t : terms) {
            int l = t.first;
            mpz_class c0 = t.second;
            if (c0 == 0) continue;
            mpz_class gamma = -c0;
            Series factor = factorSeries(n, u, l, c0);
            res = seriesMulTrunc(n, res, factor);
            out.push_back({u, l, gamma});
        }
    }
    return out;
}

Series mkSeries(int n, const std::vector<std::pair<int, PPoly>> &assoc) {
    Series s(n + 1);
    for (auto &kv : assoc) s[kv.first] = kv.second;
    return s;
}

PPoly poly(const std::vector<std::pair<int, long long>> &terms) {
    PPoly p;
    for (auto &t : terms) if (t.second != 0) p[t.first] = mpz_class((long)t.second);
    return p;
}

int digitCount(const mpz_class &g) {
    mpz_class a = g < 0 ? -g : g;
    return a.get_str().size();
}

void runCase(bool verbose, const std::string &name, int n, const Series &num, const Series &den) {
    std::cout << "=== " << name << " (order N=" << n << ") ===\n";
    auto denInv = seriesInvert(n, den);
    if (!denInv) {
        std::cout << "  DEN(0) != 1 in Z[p]: cannot invert termwise in the polynomial ring. STOP.\n\n";
        return;
    }
    Series r = seriesMulTrunc(n, num, *denInv);
    auto factors = extract(n, r);
    if (verbose) {
        for (auto &f : factors)
            std::cout << "  u=" << f.u << "  l=" << f.l << "  gamma=" << f.gamma
                       << "   -> (1 - p^" << f.l << " x^" << f.u << ")^" << f.gamma << "\n";
    } else {
        std::cout << "  factors extracted: " << factors.size() << "\n";
        int maxDigits = 0;
        for (auto &f : factors) maxDigits = std::max(maxDigits, digitCount(f.gamma));
        std::cout << "  max |gamma| decimal digits: " << maxDigits << "\n";
        if (!factors.empty()) {
            auto &f = factors.back();
            std::cout << "  last: u=" << f.u << " l=" << f.l << " gamma=" << f.gamma << "\n";
        }
    }
    std::cout << "\n";
}

int main() {
    int n = 60;
    bool verbose = false;

    Series num1 = mkSeries(n, { {0, pOne()}, {1, poly({{0,1},{1,-2}})} });
    Series den1 = mkSeries(n, { {0, pOne()}, {1, poly({{2,-1}})} });

    Series num2 = mkSeries(n, { {0, poly({{2,1},{3,-2},{4,1}})}, {1, poly({{0,-1},{1,2}})} });
    Series den2 = mkSeries(n, { {0, poly({{2,1},{3,-2},{4,1}})}, {1, poly({{0,-1},{1,2},{2,-1}})} });

    auto t0 = std::chrono::high_resolution_clock::now();
    runCase(verbose, "phi^2(n)      [Mathar 3.78/3.79 test]", n, num1, den1);
    runCase(verbose, "1/phi(n)^2    [our target]",             n, num2, den2);
    auto t1 = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> dt = t1 - t0;
    std::cout << "CPU time: " << dt.count() << " s\n";
    return 0;
}
