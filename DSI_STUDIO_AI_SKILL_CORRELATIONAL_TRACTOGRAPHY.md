# DSI Studio Correlational Tractography Guide for AI Agents

Correlational tractography (Yeh, et al. NeuroImage 245 (2021): 118651) finds
white-matter pathways whose local connectome fingerprint is correlated with a
study variable across a group of subjects, using a nonparametric partial
correlation and a permutation test for statistical control (Yeh et al.
NeuroImage 125 (2016): 162-171):

```text
group scalar-map database + demographics → permutation regression → increase/decrease pathways
```

This is a cross-sectional, cohort-level correlation method. It answers "which
pathways relate to this variable across subjects," not "did this pathway
change over time in this subject." For a single subject's own before/after
comparison, use differential tractography instead; connectometry with
age/sex-matching is no longer the preferred way to approximate a longitudinal
comparison.

## Availability: use the CLI batch action today

`group_connectometry` (the Correlational Tractography dialog) implements its
own internal `command()` dispatcher (`open_mr_files`, `run`, `show_result`,
`load_roi_from_atlas`, `clear_all_roi`, `load_roi_from_file`, `show_cohort`,
`apply_selection`, `list_param`, `set_param`, `set_params`), but as of this
writing that window is **not yet reachable through the `bash ./dsi.sh`
named-pipe dispatcher** the way `tracking<hex>`/`recon<hex>` windows are —
there is no `set_window`-addressable ID for it yet. Opening it from the main
window (`create_db`, `open_db`, `open_connectometry`) works, but no follow-up
session command can currently reach it.

Until that wiring exists, run correlational tractography through the CLI
batch action instead:

```bash
dsi_studio --action=cnt --source=<database> --demo=<covariates> \
  --index_name=<metric> --variable_list=<indices> --voi=<index> \
  --t_threshold=<t> --fdr_threshold=<q> --output=<prefix>
```

## Required Workflow

### 1. Build the group database first

Correlational tractography runs on a connectometry database (`.dz`/`.db.fz`),
not directly on subject FIB files. Build one with:

```bash
dsi_studio --action=db --source=<glob of *.qsdr.fz files> --demo=<participants.tsv> --output=<group>.dz
```

All subjects must already be reconstructed into the **same template space**
(QSDR) so their per-voxel scalar maps are spatially comparable. `--demo`
auto-detects a `participants.tsv` alongside the sources if omitted. The GUI
equivalent is `create_db` from the main window, followed by loading subject
FIBs and demographics into `CreateDBDialog`.

### 1.1 Inspect per-subject regional measurements from the database

A completed `.dz` database can also be opened directly with `open_fib`. This
creates a normal tracking window in template space, allowing the usual atlas
and ROI tools to be applied to the aggregated database:

```bash
bash ./dsi.sh open_fib "<group>.dz"
bash ./dsi.sh list_atlas
bash ./dsi.sh add_region_from_atlas "<template-index> <atlas-index> <label-index>"
bash ./dsi.sh show_region_statistics
```

When the opened FIB contains a connectometry database, `show_region_statistics`
iterates through **all scalar metrics stored in the database** and reports one
regional mean for every subject for every metric. The subject rows therefore
follow the form:

```text
<subject-name> mean_<database-metric>    <regional-mean>
```

For example, a database containing `qa`, `vol`, `dti_fa`, `rd`, `iso`, and `rdi`
should report the regional subject values for each of those metrics in one
statistics operation. Agents should not manually switch a "current metric" and
repeat the command metric by metric. For unattended output, use
`save_region_statistics "<output.txt>"` instead of `show_region_statistics`.

The initial live SCA2 test used an 18-scan QSDR database and BrainSeg Cerebellum:

```bash
bash ./dsi.sh open_fib "SCA2_subjects.dz"
bash ./dsi.sh add_region_from_atlas "0 1 2"
bash ./dsi.sh show_region_statistics
```

That test confirmed that database subjects are enumerated automatically inside an
atlas ROI. The ROI-statistics implementation is being updated so the same call
iterates every stored database metric rather than returning only the selected
metric. This workflow is useful for inspecting, exporting, or comparing regional
measurements across all subjects without opening each subject FIB separately.

### 2. Define the analysis

- `--index_name` selects the scalar metric to study (e.g. `qa`, `rdi`);
  defaults to the first index stored in the database.
- `--voi` is the variable of interest — the feature index (or the literal
  string `Intercept`/`longitudinal` for a longitudinal database) whose
  correlation with the metric is being tested.
- `--variable_list` is the comma-separated set of feature indices to include
  as covariates in the partial correlation (confounders to control for, plus
  the variable of interest itself).

Do not guess feature indices; they come from the demographics file's column
order as loaded into the database. Confirm them before running rather than
assuming a fixed layout across studies.

### 3. Select the cohort

An optional filter narrows which subjects are included, via `--select` (CLI)
or the `select_cohort`/`apply_selection`/`show_cohort` session commands
(GUI). The clause syntax is comma-separated `name<op>value` terms, where
`<op>` is one of `=` (equal), `>` (greater), `<` (less), or `/` (not equal —
shown as "≠" in the GUI but sent as the literal `/` character):

```text
age>40,sex=1
```

A clause named `subject` filters by subject-name substring instead of a
numeric comparison (`>`/`<` become contains/does-not-contain for that one
case). A clause named `value` applies the comparison to every currently
selected feature at once rather than one named feature. Numeric comparisons
are evaluated at 3-decimal precision.

Always confirm the resulting subject count (`n=`) before running — too few
subjects after filtering invalidates the permutation test.

### 4. Set the propagation threshold and the FDR criterion

These are two independent controls, not one:

- **Propagation threshold** (`--t_threshold` or `--effect_size`, mutually
  derived from each other via `rho = t / sqrt(t² + n - 2)`): the per-voxel
  correlation strength required to keep extending a streamline during
  tracking. Default effect size `0.3`.
- **`--fdr_threshold`**: the false-discovery-rate criterion used to select
  the reported track length **after** the permutation run finishes. If left
  at the default `0.0` (disabled), a fixed `--length_threshold` (voxels) is
  used to truncate results instead, and the report states whatever FDR value
  happened to result at that length rather than enforcing one.

Do not treat a low `t_threshold` as a way to "recover" a null result — it
changes what counts as a valid streamline step, not the significance of the
overall finding.

### 5. Configure region constraints (optional)

If no ROI/seed is specified, the whole brain is seeded automatically. To
constrain the analysis to specific pathways, use the same ROI flags as
fiber tracking (`--roi`, `--roi2`..`--roi5`, `--roa`..`--roa5`, `--seed`,
`--end`, `--end2`, `--ter`..`--ter5`, `--nend`, `--lim`, or atlas-based
`--track_id`/`--use_roi`/`--tolerance`). `--exclude_cb` removes the
cerebellum from consideration before seeding.

### 6. Run and interpret increase/decrease

The permutation run produces two independent results, `hypothesis_inc` and
`hypothesis_dec`, from the sign of each voxel's regression T-statistic:
"increase" means the metric is positively associated with the variable of
interest (or increases over time, for a longitudinal/intercept study);
"decrease" means the opposite. These are separate pathway sets with
separate tract counts — report both, not just whichever is larger.

`--tip_iteration` (default 16) applies topology-informed pruning to both
result sets and their null distributions before FDR is computed;
`--region_pruning` (default on) applies additional topology-based cleanup
after that.

### 7. Validate before reporting a finding

- Check the resulting tract count for both increase and decrease at the
  reported FDR/length — a near-zero count on one side is a valid "no
  finding" result, not an error.
- Inspect where the significant pathways are anatomically; a plausible-shaped
  bundle in an implausible location is still suspect.
- Re-examine the covariate list: an unadjusted confound can produce a
  spuriously "significant" pathway.
- `--normalize_iso` (default on when applicable) divides an anisotropy-type
  metric (`qa`, `rdi`, `nrdi*`) by the subject's isotropic diffusion map
  before regression; confirm this matches the intended analysis rather than
  leaving it at whatever the default happens to be for the chosen metric.

### 8. Save and, if needed, visualize

`--output` sets the result file-name prefix; if omitted, an
automatically generated suffix is used. With `--no_tractogram=0` (GUI
default; forced to `1`, i.e. disabled, in a headless CLI run unless the
process keeps its GUI event loop), DSI Studio additionally opens a hidden
tracking window on the result and saves inc/dec bundle screenshots and an
HTML report alongside the tract files.

## Common Failures

| Observation | Check first |
|---|---|
| Zero subjects after cohort selection | Clause syntax, operator character, and feature/column name spelling |
| Result looks identical regardless of threshold | Confirm `t_threshold`/`effect_size` are not both being set (they overwrite each other) |
| "Significant" pathway with no plausible anatomy | Unadjusted covariates, database space/registration, or too few subjects |
| Increase and decrease both empty | Cohort too small, effect too weak, or covariate list absorbing the true effect |
| FDR looks arbitrary/unstable | `fdr_threshold=0` uses a fixed length instead of an FDR criterion — set an explicit `fdr_threshold` if a controlled FDR is required |
| Database load fails | Subjects not all reconstructed in the same template space, or `.dz` built from mismatched index sets |
| ROI statistics show only one database metric | The updated `show_region_statistics` behavior should iterate every stored database metric; a single-metric result indicates an older build or an incomplete update |
| Trying to send a follow-up session command to the connectometry window | Not yet wired to `bash ./dsi.sh`; use the CLI batch action instead |

## Example Commands

Build the database:

```bash
dsi_studio --action=db --source=*.qsdr.fz --demo=participants.tsv --index_name=qa --output=group.dz
```

Inspect regional metrics across all subjects in the database:

```bash
bash ./dsi.sh open_fib "group.dz"
bash ./dsi.sh add_region_from_atlas "0 1 2"
bash ./dsi.sh show_region_statistics
```

Run a cross-sectional correlation with one variable of interest and two
covariates, cohort-filtered, with an explicit FDR criterion:

```bash
dsi_studio --action=cnt --source=group.dz --demo=participants.tsv \
  --index_name=qa --variable_list=0,1,2 --voi=1 \
  --select="age>18" --t_threshold=2.5 --fdr_threshold=0.05 \
  --tip_iteration=16 --output=age_correlation
```

Longitudinal/intercept-style database study:

```bash
dsi_studio --action=cnt --source=longitudinal.dz --voi=longitudinal \
  --variable_list=0 --effect_size=0.3 --output=longitudinal_change
```

Available parameters may vary by version. Prefer commands captured from the
current GUI command history when reproducing an interactive workflow.

## Record for Reproducibility

Record:

- database file, its subject list, template space, and stored scalar indices;
- demographics source and every feature column used;
- variable of interest and full covariate (`variable_list`) set;
- cohort-selection clause and resulting subject count;
- `t_threshold`/`effect_size` (they are the same setting, expressed two ways);
- `fdr_threshold` or the fallback `length_threshold`, and the FDR/length
  actually reported;
- `tip_iteration`, `region_pruning`, `normalize_iso`, `exclude_cb`;
- ROI/seed constraints, if any;
- permutation count;
- increase and decrease tract counts and output file paths.