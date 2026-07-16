# algebraic-explorations

Personal repo of mathematical / algebraic explorations: Jupyter notebooks, symbolic
computation with [FORM](https://github.com/vermaseren/form), and supporting code in
several languages.

## Layout

```
src/                  shared, reusable code organized by language
  frm/                FORM helper library (algexp.hrm) — globally reusable #procedures
  cpp/ hs/ py/ m/     C++, Haskell, Python, Mathematica helpers
euler_products/       exploration: Euler φ / Euler-product extraction
                      (FORM drivers, C++/Haskell extractors, LaTeX in tex/)
*.ipynb               standalone notebooks (Complex_Roots, Spacetime_Diagrams)
```

## FORM conventions

- **Reusable procedures live in one library, `src/frm/algexp.hrm`**, each a
  `#procedure Name(...) ... #endprocedure`. New helpers get appended here rather
  than into their own `.prc` file.
- **Include from a driver** by relative path: `#include- ../src/frm/algexp.hrm`
  (the trailing `-` mutes the listing; the path resolves from FORM's working
  directory, so run drivers from their own folder). Pull it in once near the top,
  then `#call Name(...)` as needed.
- **Or use a search path** — `form -p <repo>/src/frm driver.frm`, or
  `export FORMPATH=<repo>/src/frm` — then `#include- algexp.hrm` needs no relative path.
- **Helper hygiene:** the whole file is wrapped in one `#ifndef `ALGEXPH'` include
  guard, with shared scratch declarations (e.g. `Symbol xPLtmp;`) at the top so
  the header can be included repeatedly and each `#procedure` `#call`-ed without
  re-declaring anything. Use collision-safe internal names (`xPLtmp`, `$PLmax`,
  `$PLmin`, `PLLOCAL`). See `src/frm/algexp.hrm` for the pattern.

## Running

- FORM: `cd euler_products && form highest_power.frm` (use `tform` for the
  threaded build). FORM is not preinstalled everywhere — build from
  github.com/vermaseren/form if missing.
- Notebooks: open the `.ipynb` files in Jupyter.

## Editing

- `.frm`/`.hrm` (FORM) syntax highlighting comes from a local VS Code extension
  (`form-lang`); edit its grammar under `syntaxes/form.tmLanguage.json`, then
  repackage/reinstall.

---
*Draft — expand per-area details in the relevant subdirectory's own CLAUDE.md.*
