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
| `docs\all_core_plan.md` | `D:\AESimFM\all_core_plan.md` | Historical Linux all/core background only. In that context, all=whole source package and core=core source package; it is not a Windows acceptance constraint. |
| `docs\ai_environment_lookup_guide.md` | `D:\AESimFM\ai_environment_lookup_guide.md` | Machine and WSL environment lookup reference. |
| `docs\AutoRemesh_Design.md` | `D:\AESimFM\AutoRemesh_Design.md` | Automatic remeshing design reference. |
| `docs\ExistingRemesh_Summary.md` | `D:\AESimFM\ExistingRemesh_Summary.md` | Existing remeshing workflow summary. |

SHA256 hashes were verified after the initial migration. Path-only moves into
`docs\` were later made to keep project documents out of the Skill directory.

The following Windows/AESimFM maintenance references were also migrated from
`D:\AESimFM\.claude\skills\aesimfm-simulation-maintenance\references`.

Project documents now live under `docs\skill_migrated_references\` unless a
standardized current version exists directly under `docs\`:

- `aesimfm-win-handoff.md`
- `architecture.md`
- `windows-process-chain-state-transfer.md`
- `windows-remesh-architecture.md`
- `windows-solver-capability-baseline.md`
- `windows-solver-interface-contract.md`
- `windows-solver-performance-plan.md`

Skill-only operating references remain under
`.agents\skills\aesimfm-windows-dev\references\`:

- `bug-troubleshooting.md`
- `development-sop.md`
- `execution-rules.md`
- `feature-development-sop.md`
- `inp-keyword-checklist.md`
- `prompt-templates.md`
- `remesh-integration-sop.md`
- `solver-debug-sop.md`
- `windows-build-sop.md`

## Already Local

| Local file | Purpose |
| --- | --- |
| `docs\architecture.md` | Master architecture document for the Windows solver workspace. |
| `.agents\skills\aesimfm-windows-dev\references\windows-build-sop.md` | Windows build SOP bundled with the skill. |
| `docs\project_structure.md` | Repository layout and Skill/project-document boundary. |

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
- Project-only references were moved out of the Skill directory into `docs\skill_migrated_references\`.

No skill-referenced document path is currently known to be missing.
