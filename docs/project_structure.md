# AESimFM_win Project Structure

This repository should be organized as a Windows-native solver project, with
Codex skills kept as AI operating instructions rather than project source or
project documentation.

`docs\all_core_plan.md` is a historical Linux/all-core reference. In that old
Linux packaging context, `all` means the whole software source package and
`core` means the core source package. The current Windows side is focused on
solver development, so most active work belongs to core solver code rather than
the old whole-software package. Use the historical document to understand source
provenance, prior packaging boundaries, and old GUI/Linux decisions, but do not
let it restrict Windows-native solver architecture, packaging, feature scope, or
delivery gates. Windows development currently does not use self-code ratio as an
acceptance target; the priority is working and usable solver functionality first.
Self-code ratio can be revisited later if the Windows product direction develops
normally and the metric becomes relevant.

## Recommended Layout

```text
D:\AESimFM_win
  README.md
  AGENTS.md
  CMakeLists.txt
  build.ps1

  src\
    solver\        # native solver executable, CalculiX/AESimFM kernel, Fortran/C sources
    io\            # HDF5, FRD, checkpoint, and future structured output modules
    remesh\        # remesh orchestration, FRD readers, mapping, restart builders

  docs\            # project architecture, API contracts, requirements, migration notes
  test\            # regression tests, input decks, runners, expected outputs
  scripts\         # packaging, developer utilities, wrapper-install helpers
  package\         # redistributable runtime layout and packaging outputs
  lib\             # local third-party binary/library staging area

  .agents\
    skills\
      aesimfm-windows-dev\
        SKILL.md
        references\  # SOPs, troubleshooting, prompt templates, checklists only
```

## Mapping From Proposed Names

The proposed layout:

```text
Codex Project/
  calc_engine/
  qt_gui/
  fortran_subroutines/
  docs/
  skills/
  agents.md
```

is conceptually reasonable, but the current project should not rename to that
shape directly.

Recommended mapping:

| Proposed name | Current/recommended location | Reason |
|---|---|---|
| `calc_engine\` | `src\solver\` | Existing CMake and copied CalculiX/AESimFM sources already use solver-centric layout. |
| `fortran_subroutines\` | inside `src\solver\`, optionally later `src\solver\models\` | Fortran files are not standalone plugins yet; they are part of the solver build and call chain. |
| `qt_gui\` | omit for now, or add only if GUI source is imported later | Current Windows project is solver-first; GUI is an external consumer through CLI/files. |
| `docs\` | `docs\` | Correct place for project architecture, requirements, contracts, migration notes, and historical references. |
| `skills\` | `.agents\skills\` | Codex-discoverable skills should stay under `.agents`; do not mix them with product source. |
| `agents.md` | `AGENTS.md` | Keep uppercase because existing agent conventions and this workspace already use it. |

## Skill Boundary

Keep only reusable AI work procedures in `.agents\skills\aesimfm-windows-dev`:

- `SKILL.md`
- build/debug SOPs
- troubleshooting SOPs
- feature-development SOPs
- prompt templates
- keyword/remesh checklists

Do not keep master architecture, interface contracts, performance plans,
capability baselines, or handoff records only under the Skill. Those are project
documents and must be under `docs\` with an index from `README.md` or
`docs\architecture.md`.

## Project Documentation Index

Primary documents:

- `docs\architecture.md`
- `docs\windows_solver_completion_gap_plan.md`
- `docs\inp_keywords_reference.md`
- `docs\solver_api.md`
- `docs\h5_format_spec.md`
- `docs\process_chain_guide.md`
- `docs\windows_solver_capability_baseline.md`
- `docs\windows_remesh_architecture.md`

Migrated historical or secondary references:

- `docs\AutoRemesh_Design.md`
- `docs\ExistingRemesh_Summary.md`
- `docs\ai_environment_lookup_guide.md`
- `docs\WORKDOC_MIGRATION.md`
- `docs\skill_migrated_references\`
