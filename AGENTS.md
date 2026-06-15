# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## 5. AESimFM Background And Windows Solver Rules

When working under `D:\AESimFM_win`, treat this repository as the Windows-native
solver project. The Linux `all/core` documents are background references only:
they explain source history, component boundaries, and prior GUI/Linux packaging
decisions. In that old context, `all` means the whole software source package
and `core` means the core source package. The Windows side is currently focused
on solver development and is therefore mostly core solver code. The Linux
`all/core` documents do not constrain Windows-side scope, directory layout,
packaging, or self-code-ratio targets. Windows work should first optimize for
implemented functionality and usability; self-code ratio is only a possible
later-stage concern if the Windows product direction develops normally.

Read order before coding:

1. Read this file first.
2. Read `D:\AESimFM_win\README.md`, `D:\AESimFM_win\docs\architecture.md`, and `D:\AESimFM_win\docs\windows_solver_completion_gap_plan.md` for current Windows solver direction.
3. Read `D:\AESimFM_win\docs\all_core_plan.md` only when you need Linux source-code background or all/core history.
4. Read `D:\AESimFM_win\docs\ai_environment_lookup_guide.md` before diagnosing missing Qt, qmake, gcc, gfortran, make, WSL, local libraries, or runtime dependencies.
5. If multiple agents are working in this Windows repository, read `D:\AESimFM_win\.agents\skills\aesimfm-windows-dev\references\windows-agent-workflow.md` and stay inside your role.

Environment rule:

- Do not assume an environment is missing before checking the local machine.
- For GUI builds, source the existing Qt4 environment script before judging qmake or Qt availability.
- For solver builds, inspect existing Makefiles and build scripts before changing compiler flags or installing packages.
- Downloading or installing dependencies is allowed only after local WSL, Qt4, GCC/gfortran, make, and project-local libraries have been checked and recorded.

Code ownership rule:

- Do not overwrite work from another agent without first comparing the file and understanding why it changed.
- Do not make broad formatting conversions or full-directory replacements unless the plan explicitly requires them.
- If working in the old Linux all/core workspace and restoring files from the original delivery tree, re-apply required all/core changes afterwards: component paths, key handling, solver path, build scripts, and runtime library paths.

GUI quality rule:

- A GUI build is not acceptable if Chinese UI text displays as mojibake such as `����` or `锟斤拷`.
- Do not treat GUI compilation success as final success. The GUI must launch without startup warning/error dialogs and show readable Chinese text in menus, buttons, dialogs, tree views, and bottom information output.
- If mojibake appears in source files, fix it from the original delivered source or a verified correct text source. Do not guess Chinese strings manually.
- A startup dialog that can be dismissed with OK is still a defect. Missing optional/default config files must be resolved by correct packaged paths or safe defaults, not by asking the user to click through.
- The default 3D viewport background for acceptance is white, not black or dark gradient.

Solver integration rule:

- The all package is not acceptable unless the GUI can call the solver from the packaged all directory.
- The current Linux solver artifact is expected to be `solver/solver`; historical names such as `solver/AESim-FM` and `Solver/WeICME` must not be used as GUI fallbacks.
- When launching a selected `.inp`, set the solver working directory to the `.inp` file directory and pass the job name in the form expected by the solver, currently `-i jobname`.

Regression protection rule:

- When fixing a bug or adding a new requirement, do not break already working behavior.
- Before editing, identify the currently working functions that could be affected.
- After editing, verify both the new fix and the affected existing functions.
- If a temporary change is needed for diagnosis, remove it before final packaging or clearly record why it remains.
- A Windows solver change is not complete if it solves the new issue but introduces a broken build, broken CLI invocation, missing runtime components, parser regressions, or incorrect solver outputs. Old all/core package-integrity rules apply only when explicitly working in that Linux/all-core workspace.

## 6. Recent AI Failure Checklist

Avoid repeating these recent mistakes:

- Do not apply `all_core_plan.md` as a Windows acceptance plan. Use it only for Linux/all-core background unless the task explicitly targets that old workspace.
- Do not claim compile success from object/executable existence alone; run the declared build command.
- Do not stop at CLI solver success; verify GUI startup, readable Chinese text, and GUI-to-solver invocation.
- Do not introduce or preserve mojibake. Source text containing `����` or `锟斤拷` is a defect.
- Do not accept startup warning dialogs such as missing PlotOption/ReadResult config. Fix the path or default config handling.
- Do not leave the default viewport with a black/dark background when acceptance requires white.
- Do not fix one issue by breaking an already working feature; every bug fix or new requirement needs targeted regression verification.
- For GUI crashes or unstable clicks, do not guess. Capture the exact click path, terminal log, and gdb backtrace, then fix the concrete null pointer, bounds, signal-slot, or lifetime issue.
- Do not restore original files blindly; compare first and re-apply required project changes.
- Do not assume Windows path behavior on Linux. Case matters: `Solver` and `solver` are different.
- Do not leave third-party source trees, examples, tests, `.o`, tmp, generated Makefiles, or binaries in final source packages.
- Do not package components as source when the route requires libraries plus minimal headers.
- Do not bypass or remove licensing logic unless it is confirmed to be project-owned startup gating, not third-party authorization.
- Do not download dependencies before checking local WSL, project scripts, bundled Qt4, compilers, and existing component libraries.
