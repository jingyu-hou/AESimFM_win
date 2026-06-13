# Windows Process Chain And State Transfer

This document defines the architecture for multi-process continuous simulation such as forging -> heat treatment, carburizing -> tempering, and rough forging -> die change -> finish forging.

## 1. Principle

A process chain is not a list of independent INP files. It is a sequence of solver jobs with explicit state transfer between operations.

Each process boundary must answer:

1. Which fields are carried forward?
2. Which fields are reset?
3. Which geometry, mesh, tooling, and contact definitions change?
4. Which material model state variables remain valid?
5. Which output file proves the transfer was correct?

## 2. Process Chain Object

Recommended high-level schema:

```json
{
  "chain_id": "forge_heat_treat_demo",
  "global_units": "mm_N_s_C",
  "steps": [
    {
      "id": "rough_forge",
      "type": "forging",
      "input": "rough_forge.inp",
      "output_state": "rough_forge.state"
    },
    {
      "id": "finish_forge",
      "type": "forging",
      "input": "finish_forge_template.inp",
      "initial_state": "rough_forge.state",
      "tooling": "finish_die.json"
    },
    {
      "id": "heat_treat",
      "type": "heat_treatment",
      "input": "heat_treat_template.inp",
      "initial_state": "finish_forge.state"
    }
  ]
}
```

The exact JSON format may evolve, but the solver must keep the concept of named steps, typed processes, and explicit state input/output.

## 3. Transfer Fields

| Field | Forge -> heat treatment | Carburize -> temper | Rough -> finish forge |
|---|---|---|---|
| Geometry/mesh | carry final deformed geometry | usually carry same mesh | carry or remesh for new die |
| Temperature | carry final temperature or set furnace initial rule | carry carbon/temperature history | carry final temperature |
| Stress/strain | carry residual stress if model supports it | carry if stress relief matters | carry plastic strain and residual stress |
| Plastic strain | carry | usually carry as history if affects properties | carry |
| SDV | carry mapped named namespaces | carry phase/carbon/tempering state | carry forging and microstructure state |
| Phase fractions | carry to heat treatment | carry | carry if coupled to forging model |
| Grain size/DRX/SRX/MRX | carry | optional property input | carry |
| Porosity/density | carry for HIP/powder routes | not applicable unless coupled | carry if porous forming |
| Carbon concentration | not applicable unless carburizing | carry | not applicable |
| Contact state | reset | reset | reset for new die |
| Boundary conditions | redefine | redefine | redefine |

## 4. State File Requirements

The Windows solver should define a native checkpoint/state representation. FRD plus include files may be kept as a bridge, but a robust process chain needs a named state package:

```text
state/
  manifest.json
  mesh.h5 or mesh.inp
  fields.h5
  legacy/
    jobname.frd
    jobname.nt
    jobname.st
    jobname.stdv
```

Manifest minimum:

```json
{
  "producer": "AESimFM_win solver",
  "version": "",
  "source_job": "",
  "process_type": "",
  "units": "",
  "mesh": "",
  "fields": [
    {"name": "temperature", "location": "node", "units": "C"},
    {"name": "stress", "location": "integration_point", "units": "MPa"},
    {"name": "SDV", "location": "integration_point", "count": 0}
  ],
  "sdv_namespaces": []
}
```

## 5. Mapping Rules

State transfer may be identity mapping, field projection, or remesh mapping.

| Mapping type | Use case | Requirement |
|---|---|---|
| Identity | same mesh and same topology | verify node/element id match |
| Geometry update | same topology but deformed coordinates | verify coordinate frame and units |
| Remesh projection | new mesh | use `windows-remesh-architecture.md` rules |
| Process reduction | next process needs fewer fields | document discarded fields |
| Process expansion | next process needs new fields | initialize with explicit defaults |

Never silently zero a field required by the next process. If a field is missing, fail before solving.

## 6. Example Routes

### 6.1 Forging -> Heat Treatment

Carry:

- final geometry,
- temperature,
- equivalent plastic strain,
- residual stress if enabled,
- DRX/SRX/MRX and grain size SDVs,
- phase fractions if already active.

Reset:

- contact pairs,
- die boundary conditions,
- forging-specific load curves.

### 6.2 Carburizing -> Tempering

Carry:

- carbon concentration,
- temperature history or last temperature,
- phase fractions,
- hardness/property SDVs if defined.

Reset/redefine:

- furnace temperature schedule,
- convection/radiation boundary,
- tempering model activation.

### 6.3 Rough Forging -> Die Change -> Finish Forging

Carry:

- deformed geometry,
- temperature,
- plastic strain,
- stress,
- microstructure SDVs.

Redefine:

- new die geometry,
- contact surfaces,
- boundary conditions,
- optional remesh before finish forging.

## 7. Acceptance

A process chain feature is not complete until:

1. Each process can still run alone.
2. The chain runner creates a state package after each process.
3. The next process validates required fields before starting.
4. At least one forge -> heat treatment smoke chain runs.
5. At least one rough -> finish forge chain with changed tooling is validated.
6. State variables are checked by name/range, not just file existence.

