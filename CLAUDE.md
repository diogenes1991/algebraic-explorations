# algebraic-explorations

Personal repo of mathematical / algebraic explorations: Jupyter notebooks, symbolic
computation with [FORM](https://github.com/vermaseren/form), and supporting code in
several languages.

## Layout

```
src/                  shared, reusable code organized by language
  frm/                FORM helper procedures (.prc) — globally reusable
  cpp/ hs/ py/ m/     C++, Haskell, Python, Mathematica helpers
euler_products/       exploration: Euler φ / Euler-product extraction
                      (FORM drivers, C++/Haskell extractors, LaTeX in tex/)
*.ipynb               standalone notebooks (Complex_Roots, Spacetime_Diagrams)
```

## FORM conventions

- **Reusable procedures live in `src/frm/`** as `Name.prc`, each wrapping a single
  `#procedure Name(...) ... #endprocedure`.
- **Include from a driver** by relative path: `#include- ../src/frm/Name.prc`
  (the trailing `-` mutes the listing; the path resolves from FORM's working
  directory, so run drivers from their own folder).
- **Or use a search path** — `form -p <repo>/src/frm driver.frm`, or
  `export FORMPATH=<repo>/src/frm` — then just `#call Name(...)` and FORM
  auto-loads the `.prc` (no `#include` needed). Preferred as `src/frm/` grows.
- **Helper hygiene:** collision-safe internal names (e.g. `xHPtmp`, `$HPmax`,
  `HPLOCAL`) and an `#ifndef` guard around one-time `Symbol` declarations, so
  repeated `#call`s don't re-declare. See `src/frm/HighestPower.prc` for the pattern.

## Running

- FORM: `cd euler_products && form highest_power.frm` (use `tform` for the
  threaded build). FORM is not preinstalled everywhere — build from
  github.com/vermaseren/form if missing.
- Notebooks: open the `.ipynb` files in Jupyter.

## Editing

- `.frm`/`.prc` syntax highlighting comes from a local VS Code extension
  (`form-lang`); edit its grammar under `syntaxes/form.tmLanguage.json`, then
  repackage/reinstall.

---
*Draft — expand per-area details in the relevant subdirectory's own CLAUDE.md.*
