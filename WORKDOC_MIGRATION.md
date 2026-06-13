# AESimFM_win Work Document Migration

This directory is the working root for AESimFM v2.0 Windows native solver development.
The local skill is:

- `D:\AESimFM_win\.agents\skills\aesimfm-windows-dev\SKILL.md`

## Migrated Documents

The following documents were copied from `D:\AESimFM` into `D:\AESimFM_win` so the
Windows solver workspace can be used without jumping back to the Linux/GUI worktree
for every planning or environment lookup step.

| Local file | Source file | Purpose |
| --- | --- | --- |
| `AGENTS.md` | `D:\AESimFM\AGENTS.md` | Shared project rules and recent AI failure checklist. |
| `all_core_plan.md` | `D:\AESimFM\all_core_plan.md` | Linux all/core package structure and boundary reference. |
| `ai_environment_lookup_guide.md` | `D:\AESimFM\ai_environment_lookup_guide.md` | Machine and WSL environment lookup reference. |
| `AutoRemesh_Design.md` | `D:\AESimFM\AutoRemesh_Design.md` | Automatic remeshing design reference. |
| `ExistingRemesh_Summary.md` | `D:\AESimFM\ExistingRemesh_Summary.md` | Existing remeshing workflow summary. |

SHA256 hashes were verified after migration for all five mirrored files.

The following Windows/AESimFM maintenance references were also migrated from
`D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references` into
`D:\AESimFM_win\.agents\skills\aesimfm-windows-dev\references`:

- `aesimfm-win-handoff.md`
- `architecture.md`
- `bug-troubleshooting.md`
- `development-sop.md`
- `execution-rules.md`
- `feature-development-sop.md`
- `inp-keyword-checklist.md`
- `prompt-templates.md`
- `remesh-integration-sop.md`
- `solver-debug-sop.md`
- `windows-process-chain-state-transfer.md`
- `windows-remesh-architecture.md`
- `windows-solver-capability-baseline.md`
- `windows-solver-interface-contract.md`
- `windows-solver-performance-plan.md`

## Already Local

| Local file | Purpose |
| --- | --- |
| `docs\architecture.md` | Master architecture document for the Windows solver workspace. |
| `.agents\skills\aesimfm-windows-dev\references\windows-build-sop.md` | Windows build SOP bundled with the skill. |

## Standardized Local Docs

The following migrated reference documents were copied into `docs\` under the
standard names used by the Windows solver workspace:

| Local docs file | Source reference |
| --- | --- |
| `docs\solver_api.md` | `references\windows-solver-interface-contract.md` |
| `docs\process_chain_guide.md` | `references\windows-process-chain-state-transfer.md` |
| `docs\windows_solver_capability_baseline.md` | `references\windows-solver-capability-baseline.md` |
| `docs\windows_remesh_architecture.md` | `references\windows-remesh-architecture.md` |

## Completed After Migration

The following skill-referenced documents were completed or added after the initial
migration:

- `docs\architecture.md` was rewritten as the current Windows solver architecture entry.
- `docs\inp_keywords_reference.md` was completed using `D:\AESimFM\INP_FRD格式规范参考.md`
  plus current parser evidence.
- `docs\h5_format_spec.md` exists and defines SDV metadata requirements.
- `.agents\skills\aesimfm-windows-dev\references\solver-debug-sop.md` exists.
- `.agents\skills\aesimfm-windows-dev\references\inp-keyword-checklist.md` exists.
- `.agents\skills\aesimfm-windows-dev\references\remesh-integration-sop.md` exists.

No skill-referenced document path is currently known to be missing.
