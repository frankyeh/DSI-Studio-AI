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

## Availability: reachable as a `connectometry<hex>` window

`group_connectometry` (the Correlational Tractography dialog) implements its
own internal `command()` dispatcher (`open_mr_files`, `run`, `show_result`,
`load_roi_from_atlas`, `clear_all_roi`, `load_roi_from_file`, `show_cohort`,
`apply_selection`, `list_param`, `set_param`, `set_params`), and is wired
into the `bash ./dsi.sh` named-pipe dispatcher the same way
`tracking<hex>`/`recon<hex>` windows are. Opening it from the main window
(`open_connectometry`) registers it and assigns it an ID of the form
`connectometry<hex>`, discoverable via `list_window` and addressable with
`set_window` or by forwarding commands directly to that window ID.

Because `run` starts the permutation test asynchronously (polled to
completion via an internal timer), `list_window` reports the window as
`busy` for the whole duration of the run, not just for the instant the
`run` command itself was dispatched — poll `list_window` and wait for
`idle` before issuing `show_result` or another command to the same window.

The CLI batch action remains available as a scriptable, headless
alternative that does not require an open GUI session:

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
(QSDR) so their per-voxel scalar maps are spatially comparable. If `--demo` is
omitted, the CLI checks for `participants.tsv` in the current working directory and
then its parent (preferring the current directory when both exist). The GUI equivalent
is `create_db` from the main window, followed by loading subject FIBs and demographics
into `CreateDBDialog`.

### 1.1 Quick group comparison: region or tract statistics from the database

A completed `.dz` database can also be opened directly with `open_fib` for a
simple, fast group comparison -- a per-subject, per-metric mean at one region
or along one tract -- without running the full permutation-based workflow
below. There is no cohort filtering, no permutation test, and no FDR control
here; use it to eyeball a suspected group difference or sanity-check the
database before committing to the full analysis, not as a substitute for it.

**Region-based**, using the usual atlas/ROI tools on the opened database:

```bash
bash ./dsi.sh open_fib "<group>.dz"
bash ./dsi.sh list_atlas
bash ./dsi.sh add_region_from_atlas "<template-index> <atlas-index> <label-index>"
bash ./dsi.sh show_region_statistics
```

**Tract-based**, on a bundle that is loaded or tracked in the opened database
(see `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` for `open_tract`/`run_tracking`/
`run_auto_track`):

```bash
bash ./dsi.sh open_fib "<group>.dz"
bash ./dsi.sh open_tract "<bundle.tt.gz>"
bash ./dsi.sh show_tract_statistics
```

When the opened FIB contains a connectometry database, both `show_region_statistics`
and `show_tract_statistics` iterate through every scalar metric stored in the
database and add one row per subject per metric, in the form:

```text
<subject-name> mean_<database-metric>    <mean at that region/tract>
```

For example, a database containing `qa`, `vol`, `dti_fa`, `rd`, `iso`, and
`rdi` reports the subject values for each of those metrics in one call (e.g.
`<subject> mean_qa`, `<subject> mean_dti_fa`, etc.) -- there is no need to
switch the database's "current metric" first, and doing so has no effect on
this output. For unattended output, use `save_region_statistics`/
`save_tract_statistics "<output.txt>"` instead of the `show_*` form.

The region-based path was validated live on an 18-scan SCA2 QSDR database and
BrainSeg Cerebellum:

```bash
bash ./dsi.sh open_fib "SCA2_subjects.dz"
bash ./dsi.sh add_region_from_atlas "0 1 2"
bash ./dsi.sh show_region_statistics
```

That test confirmed database subjects are enumerated automatically inside an
atlas ROI, returning the Cerebellum geometry and one `mean_<metric>` value for
each of the 18 scans for every metric stored in the database. `show_tract_statistics`
uses the identical per-subject, per-metric mechanism along a tract instead of
a region.

### 1.2 Build a longitudinal-change database from an existing database

A longitudinal/intercept study (`--voi=longitudinal` in step 2 below) does not
run on the group database built in step 1 directly -- it runs on a derived
database of per-subject **changes** between two scans, matched pairwise.
Build that derived database from an already-built `.dz`/`.db.fz` database
with the same `--action=db`, adding `--match`:

```bash
dsi_studio --action=db --source=<group>.dz --match=consecutive \
  --dif_type=0 --filter_type=0 --normalize_iso=1 --output=<group>.dif.dz
```

- `--match=consecutive` pairs subjects by their stored order: (row 0, row 1),
  (row 2, row 3), and so on -- each pair is one subject's scan1/scan2. Confirm
  the database's subject order actually alternates scan1/scan2 by inspecting the
  subject list in the `open_db` GUI or the source file list used to build the database;
  `list_window` does not report database subject order.
- `--match=<pairs.txt>` uses explicit pairing instead: a text file of
  whitespace-separated integer subject-row indices, two per pair
  (`scan1_row scan2_row scan1_row scan2_row ...`), 0-based in the same
  subject order as the database.
- `--dif_type=0` computes `scan2 - scan1` (default); `--dif_type=1` computes
  `(scan2 - scan1) / scan1`.
- `--filter_type=0` keeps all changes (default); `1` keeps only increases in
  scan2 (negative values zeroed); `2` keeps only decreases (sign-flipped,
  then negative values zeroed).
- `--normalize_iso` (default `1`) divides `qa`/`rdi`/`nrdi*`-type metrics by
  the subject's isotropic diffusion map before differencing, matching the
  GUI's "Normalize QA/RDI/NRDI by ISO" checkbox default.
- `--output` defaults to `longitudinal` plus a suffix that encodes
  `--filter_type` (`.dif.dz`, `.pos_dif.dz`, or `.neg_dif.dz`), mirroring the
  GUI's "Save DB as" default naming.

The resulting database has `is_longitudinal` set and cannot be re-differenced
(`--match` again on it fails). Feed it to `--action=cnt` as `--source` with
`--voi=longitudinal` for the actual regression, per section 2 below.

### 2. Define the analysis

- `--index_name` selects the scalar metric to study (e.g. `qa`, `rdi`);
  defaults to the first index stored in the database.
- `--voi` is the variable of interest — the feature index (or the literal
  string `Intercept`/`longitudinal` for a longitudinal database) whose
  correlation with the metric is being tested.
- `--variable_list` is the comma-separated set of feature indices to include
  as covariates in the partial correlation (confounders to control for, plus
  the variable of interest itself). It is common practice to include age and
  sex as covariates when either varies meaningfully across the cohort.

Do not guess feature indices for the CLI's `--voi`/`--variable_list`; they
come from the demographics file's column order as loaded into the database.
Confirm them before running rather than assuming a fixed layout across
studies.

In a `connectometry<hex>` session, the equivalent of `--voi`/`--variable_list`
is one command, `set_voi <voi> <variable_list>`, and it takes feature **names**
instead of indices (an index still works, matched the same way `hub_open`/
`hub_show` accept either a row index or an exact name):

```bash
bash ./dsi.sh list_voi
bash ./dsi.sh set_voi "group" "group,age_exam_ses01,gender"
```

`list_voi` prints every available feature with its current selected state
(`index\tname\tselected`) -- read this first rather than guessing names, the
same caution as the CLI's indices. `set_voi`'s second argument is the full set
of variables to include (covariates plus the variable of interest itself, same
convention as `--variable_list`); the variable of interest is added
automatically if omitted from it. `set_voi` clears any previously selected
variables before applying the new set -- it is not additive. `get_demo` prints
the raw per-subject demographics table (`subject<TAB><column>...`) actually
loaded into the database, useful for confirming exact column names and values
(including any subject-name rematching) before calling `set_voi`.

### 3. Select the cohort

An optional filter narrows which subjects are included. Use `--select` in the CLI.
In a `connectometry<hex>` session, set the `select_text` parameter directly or use
`apply_selection` to append a clause, then call `show_cohort` to apply and inspect the
selection. (`select_cohort` is an internal model operation, not a session command.)
The clause syntax is comma-separated `name<op>value` terms, where
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
| Region/tract statistics show only one database metric | Both `show_region_statistics` and `show_tract_statistics` should iterate every stored database metric; a single-metric result indicates a build that predates this fix |
| Follow-up command to the connectometry window seems ignored or errors | Confirm the window ID via `list_window` (`connectometry<hex>`) and that its status is `idle`, not `busy`, before sending the next command |
| `set_voi` fails with "invalid variable" | Run `list_voi` first and use one of the exact `name` values (or its `index`), not a guessed demographics-file column name |
| Result seems to ignore a covariate | `set_voi`'s variable list is a full replacement, not additive to whatever was selected before -- include every variable (covariates plus the variable of interest) in the same call |

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

Inspect along-tract metrics across all subjects in the database instead:

```bash
bash ./dsi.sh open_fib "group.dz"
bash ./dsi.sh open_tract "cst.tt.gz"
bash ./dsi.sh show_tract_statistics
```

Run a cross-sectional correlation with one variable of interest and two
covariates, cohort-filtered, with an explicit FDR criterion:

```bash
dsi_studio --action=cnt --source=group.dz --demo=participants.tsv \
  --index_name=qa --variable_list=0,1,2 --voi=1 \
  --select="age>18" --t_threshold=2.5 --fdr_threshold=0.05 \
  --tip_iteration=16 --output=age_correlation
```

The same cross-sectional correlation as an interactive `connectometry<hex>`
session, adjusting for age and sex:

```bash
bash ./dsi.sh open_connectometry "group.dz"
bash ./dsi.sh get_demo
bash ./dsi.sh list_voi
bash ./dsi.sh set_voi "group" "group,age,sex"
bash ./dsi.sh set_param select_text "age>18"
bash ./dsi.sh show_cohort
bash ./dsi.sh set_params "t_threshold=2.5&fdr_control=1&fdr_threshold=0.05&tip=16"
bash ./dsi.sh run
```

`run` starts the permutation asynchronously; poll `list_window` until the
`connectometry<hex>` entry is `idle` again, then `show_result`.

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