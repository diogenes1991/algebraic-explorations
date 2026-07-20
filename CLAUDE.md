# algebraic-explorations

Personal repo of long-term mathematical explorations, mostly in **algebraic
geometry** and **algebraic number theory**: Jupyter notebooks, symbolic computation
(notably with [FORM](https://github.com/vermaseren/form)), and supporting code in
several languages (C++, Haskell, Python, Mathematica).

Each self-contained exploration lives in its own top-level directory with its **own
`CLAUDE.md`** carrying the math, notation, and workflow specific to it. This file
covers only what is true repo-wide; read the active exploration's `CLAUDE.md` for the
details of the work at hand.

## Working modes ("hats")

Work happens under one of two hats; **the current hat is stated at the end of this
section.** Stay within the active hat unless told to switch.

- **Writeup** — documentation only. Touch only `.tex`, `.md`, and comments in code;
  do not change code behavior. Follow the math-notation conventions in the active
  exploration's own `CLAUDE.md`.
- **Develop** — algorithms and debugging. Write and modify code (FORM, Haskell,
  Python, C++, Mathematica), run it, verify.

**Current hat: Writeup.**

## Layout

```
src/                  shared, reusable code organized by language
  frm/                FORM helper library (algexp.hrm) — globally reusable #procedures
  cpp/ hs/ py/ m/     C++, Haskell, Python, Mathematica helpers
<exploration>/        one directory per exploration, each with its own CLAUDE.md
  euler_products/     Euler φ / Euler-product → ζ-ratio extraction
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

- FORM: run a driver from its own exploration folder, e.g. `cd <exploration> && form
  driver.frm` (use `tform` for the threaded build). FORM is not preinstalled
  everywhere — build from github.com/vermaseren/form if missing.
- Notebooks: open the `.ipynb` files in Jupyter.
- Per-exploration run details live in that exploration's `CLAUDE.md`.

## Editing

- `.frm`/`.hrm` (FORM) syntax highlighting comes from a local VS Code extension
  (`form-lang`); edit its grammar under `syntaxes/form.tmLanguage.json`, then
  repackage/reinstall.

---
*Repo-wide conventions only — per-exploration details live in each subdirectory's own `CLAUDE.md`.*
