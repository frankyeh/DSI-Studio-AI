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
own internal `command()` dispatcher (`open_mr_files`, `run`, `stop`,
`progress`, `get_result`, `show_result`, `load_roi_from_atlas`,
`clear_all_roi`, `load_roi_from_file`, `show_cohort`, `apply_selection`,
`list_voi`, `set_voi`, `get_demo`, `list_param`, `set_param`, `set_params`),
and is wired into the `bash ./dsi.sh` named-pipe dispatcher the same way
`tracking<hex>`/`recon<hex>` windows are. Opening it from the main window
(`open_connectometry`) registers it and assigns it an ID of the form
`connectometry<hex>`, discoverable via `list_window` and addressable with
`set_window` or by forwarding commands directly to that window ID.

`run` starts the permutation test's worker threads and returns immediately
(it does not block waiting for them). While they run, `list_window` reports
the window as `busy` -- not just for the instant `run` was dispatched, but
for the whole run. For percent-complete, poll that window's own `progress`
command (no parameter) instead of `list_window`, which only reports coarse
`idle`/`busy`/`waiting`. `progress`'s `output` is one of:

- `not_started` -- no run has ever started on this window;
- `running\t<percent>`;
- `finished\t<percent>` -- the run reached 100% naturally; `get_result` and
  `show_result` are now usable;
- `stopped\t<percent>` -- cancelled (via `stop`, or a local user's own Stop
  click) before finishing; `get_result`/`show_result` fail on this window
  until a later run finishes.

`percent` reaching 100 does not by itself mean `finished` -- 100 is also the
very last `running` reading just before the state flips. `stop` cancels an
in-progress run (fails with "no run in progress" if none is running); the
GUI's own Run/Stop toggle button forwards to the same `stop` command
internally.

This is a shared, local-GUI window, not an AI-exclusive session: whoever is
sitting at the DSI Studio machine can click Run or Stop themselves at any
time, independent of anything the AI does. A run the AI started can be
stopped by a local user before it finishes (`progress` then reports
`stopped`, not `finished`), and a local user can start their own run on the
same window the AI is currently watching -- `progress` reporting `finished`
does not by itself prove the AI's own run (rather than a local user's) is
what produced the result available from `get_result`; check
`get_demo`/`list_voi`/`list_param` against what was actually requested if
that distinction matters.

An AI-initiated `run` (i.e. `command_source::AI`, which covers every request
sent over the pipe) also suppresses the local "tractography saved"/"no
significant finding" popup that would otherwise appear when the run
completes -- only a `run` triggered by a local user clicking the GUI's own
Run button shows it. Once `progress` reports `finished`, call `get_result`
(no parameter) to get the full HTML report (MRI acquisition summary, the
analysis narrative, and increase/decrease findings with their FDR) directly
in `output` -- this is the primary way an AI caller learns the actual
findings, since nothing is printed to the console automatically.

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
- `--filter_type=0` (default) keeps the raw signed change at every voxel --
  increases positive, decreases negative, nothing zeroed. Use this for
  testing whether a change exists at all (see 1.3 phase 1 below).
- `--filter_type=1` keeps only increases, as a positive magnitude: any
  voxel that decreased is zeroed, increases are left as-is.
- `--filter_type=2` keeps only decreases, **also as a positive magnitude,
  not a negative one**: every value is first negated (so an original
  decrease, negative, becomes positive), then anything below zero (i.e.
  every original increase, now negative) is zeroed. Confirmed directly
  against the implementation (`libs/mapping/connectometry_db.cpp`,
  `connectometry_db::calculate_change`: `if(filter_type==2) tipl::neg(...)`
  runs *before* the zero-clamp) -- do not assume `2` produces negative
  "amount of decrease" values; it does not.
- `--normalize_iso` (default `1`) divides `qa`/`rdi`/`nrdi*`-type metrics by
  the subject's isotropic diffusion map before differencing, matching the
  GUI's "Normalize QA/RDI/NRDI by ISO" checkbox default.
- `--output` defaults to `longitudinal` plus a suffix that encodes
  `--filter_type` (`.dif.dz`, `.pos_dif.dz`, or `.neg_dif.dz`), mirroring the
  GUI's "Save DB as" default naming.

The resulting database has `is_longitudinal` set and cannot be re-differenced
(`--match` again on it fails). Feed it to `--action=cnt` as `--source`.
`--voi=longitudinal` (equivalently `Intercept`) tests whether a change
exists at all, pooling every subject in the (possibly cohort-filtered)
database; `--voi=<a demographics column, e.g. group>` instead tests whether
the *amount* of change differs between groups -- see 1.3.

### 1.3 Two-phase strategy for a longitudinal group comparison

To answer "did the patient group decline more than the control group"
(or any longitudinal group-difference question), build and test in two
separate steps rather than jumping straight to a group comparison:

1. **Confirm a real change exists first, within just the affected group.**
   Build the longitudinal database once with the default `--filter_type=0`
   (signed change, both directions kept). Cohort-filter to the group
   expected to change (`--select`/`select_text`, e.g. `group=0`) and test
   `--voi=longitudinal` there -- this asks "does this group show a
   significant nonzero change at all," ignoring the comparison group
   entirely. If nothing is found, a downstream group-difference test on the
   same data is unlikely to be meaningful; stop here rather than proceeding
   to step 2.
2. **Isolate the direction the hypothesis predicts, then compare groups.**
   Rebuild the longitudinal database with the filter matching that
   direction -- `--filter_type=2` for a metric expected to *decrease*
   (e.g. a neuronal-injury hypothesis), `--filter_type=1` for one expected
   to *increase*. Each subject's per-voxel value is now a positive
   magnitude of change in that one direction (0 if they went the other
   way or didn't change). Test `--voi=group` (not `longitudinal`) on this
   filtered database, with the full (unfiltered-by-cohort) subject set --
   a significant `hypothesis_inc`/`hypothesis_dec` finding now means one
   group's magnitude of change in that direction exceeds the other's, not
   merely that change occurred.

### 2. Define the analysis

- `--index_name` selects the scalar metric to study (e.g. `qa`, `rdi`);
  defaults to the first index stored in the database. `qa` and `dti_fa` are
  the two most commonly tested metrics -- consider running both rather than
  just one, since they can be differentially sensitive (e.g. `dti_fa` is
  often more sensitive to neuronal injury than `qa`). When studying `qa` (or
  another anisotropy-type metric: `rdi`, `nrdi*`), leave `--normalize_iso`
  at its default (on) -- it corrects a between-scan/between-scanner
  intensity-consistency issue `qa` is otherwise sensitive to. `dti_fa` does
  not need it.
- `--voi` is the variable of interest — the feature index (or the literal
  string `Intercept`/`longitudinal` for a longitudinal database) whose
  correlation with the metric is being tested.
- `--variable_list` is the comma-separated set of feature indices to include
  as covariates in the partial correlation (confounders to control for, plus
  the variable of interest itself). Choice of covariates needs deliberate
  consideration, not a default checklist -- age and sex are the usual
  baseline when either varies meaningfully across the cohort. For a
  multi-site dataset, also consider a `site` covariate (encoded as a 0/1, or
  more, categorical demographics column) to control for scanner/site
  effects.

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

Rather than committing to one `effect_size`/`t_threshold` value, running the
same analysis across a small range (e.g. `0.2`, `0.3`, `0.4`) and reporting
how the finding's extent changes across it usually gives a more complete and
more defensible picture than a single threshold — particularly useful for
telling a threshold artifact apart from a robust finding.

### 5. Configure region constraints (optional, generally discouraged)

If no ROI/seed is specified, the whole brain is seeded automatically — this
is the recommended default, not just the fallback. Constraining seeding to
an ROI at run time usually yields far fewer significant findings than a
whole-brain search, partly because it also shrinks the null-distribution
sample the permutation test itself builds from. Prefer running whole-brain
and filtering the resulting inc/dec tract files to a region of interest
**after** the run (post-hoc, e.g. loading them into a tracking window and
applying region filters there) over constraining seeding directly. Reserve
the seeding-time ROI flags (same as fiber tracking: `--roi`, `--roi2`..
`--roi5`, `--roa`..`--roa5`, `--seed`, `--end`, `--end2`, `--ter`..`--ter5`,
`--nend`, `--lim`, or atlas-based `--track_id`/`--use_roi`/`--tolerance`)
for a specific, strong anatomical hypothesis that justifies narrowing the
search itself. `--exclude_cb` removes the cerebellum from consideration
before seeding and is a narrower, usually-safer exclusion than a positive
ROI constraint.

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
bash ./dsi.sh set_voi 0 "0,1,2"
bash ./dsi.sh set_param select_text "age>18"
bash ./dsi.sh show_cohort
bash ./dsi.sh set_params "threshold=2.5&fdr_control=1&fdr_threshold=0.05&tip=16"
bash ./dsi.sh run
```

`set_voi` used indices here (`0`=study variable `group`, covariates
`0,1,2`) rather than names: a categorical column's `list_voi` name has its
value encoding baked in (e.g. `group` shows as `group(0=SCA2 1=CONTROL)`),
which is easy to mistype or mis-quote as a name -- confirmed live, a bare
`"group"` fails with `invalid variable of interest: group`. Prefer the
`index` column from `list_voi` for any categorical variable; a continuous
variable's name is usually safe to use verbatim. The GUI parameter id is
`threshold`, not the CLI's `--t_threshold` flag name -- `set_param`/
`set_params` follow the ids `list_param` reports, not the CLI's flag names,
and a few differ subtly.

`run` starts the permutation asynchronously; poll `progress` until it
reports `finished`, then `get_result` (and/or `show_result` to visualize).

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