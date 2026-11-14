# DSI Studio Correlational Tractography Guide for AI Agents

Correlational tractography (Yeh, et al. NeuroImage 245 (2021): 118651) finds white-matter pathways whose
local connectome fingerprint correlates with a study variable across subjects, using nonparametric
partial correlation and a permutation test (Yeh et al. NeuroImage 125 (2016): 162-171):

```text
group scalar-map database + demographics → permutation regression → increase/decrease pathways
```

It is a cross-sectional, cohort-level method: "which pathways relate to this variable across
subjects," not "did this pathway change in this subject." For one subject's before/after comparison use
differential tractography (`DSI_STUDIO_AI_SKILL_DIFFERENTIAL_TRACTOGRAPHY.md`); comparing two separately
recruited, age/sex-matched cohorts is no substitute, since it compares different people. A genuine
*group-level* longitudinal question ("did group A change more than group B") is supported by testing a
database of matched per-subject scan-pair changes (1.2/1.3), still a group average, not one subject's
result.

**Teaching dataset.** [SCA2 `ds001378`](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md) on Fiber Data Hub provides
`sub-all.dz`, `participants.tsv`, `qc.tsv`, and individual SZ/FZ/NIfTI. **Inspect `get_demo` and
`list_voi`** before choosing a model (the prebuilt database may not embed the external demographics);
file availability is not a valid design. Get approval before downloading and analyzing.

## The `connectometry<hex>` window

`group_connectometry` (the Correlational Tractography dialog) has its own `command()` dispatcher
(`open_mr_files`, `run`, `stop`, `progress`, `get_result`, `show_result`, `load_roi_from_atlas`,
`clear_all_roi`, `load_roi_from_file`, `show_cohort`, `apply_selection`, `list_voi`, `set_voi`,
`get_demo`, `list_param`, `set_param`, `set_params`) wired into `bash ./dsi.sh` like
`tracking<hex>`/`recon<hex>`. `open_connectometry` (main window) registers it as `connectometry<hex>`,
found with `list_window` and addressed with `set_window` or by forwarding to that ID.

- `run` starts the permutation workers and returns at once; `list_window` shows `busy` for the whole run
  (only coarse `idle`/`busy`/`waiting`). Poll the window's own `progress` (no parameter):
  `not_started`; `running\t<percent>`; `finished\t<percent>` (reached 100% naturally: `get_result` and
  `show_result` usable); `stopped\t<percent>` (cancelled by `stop` or a local Stop click: results fail
  until a later run finishes). `percent` 100 alone does not mean `finished` (it is also the last
  `running` reading). `stop` fails with "no run in progress" when idle; the GUI Run/Stop toggle forwards
  to it.
- The window is a shared local GUI: a local user can stop the AI's run or start their own at any time,
  so `finished` does not prove the AI's own run produced the result; check `get_demo`/`list_voi`/
  `list_param` against the request when that matters.
- An AI `run` (`command_source::AI`, every pipe request) suppresses the "tractography saved"/"no
  significant finding" popup (shown only for the GUI Run button) and prints nothing to the console.
  After `finished`, `get_result` (no parameter) returns the full HTML report (acquisition summary,
  narrative, increase/decrease findings with FDR) in `output`: the main way to learn the findings.

Headless CLI alternative, no GUI session needed:

```bash
dsi_studio --action=cnt --source=<database> --demo=<covariates> \
  --index_name=<metric> --variable_list=<indices> --voi=<index> \
  --t_threshold=<t> --fdr_threshold=<q> --output=<prefix>
```

## Required workflow

### 1. Find or build the group database

Analysis runs on a connectometry database (`.dz`/`.db.fz`), not subject FIBs; never rebuild one that
exists. For Fiber Data Hub data, search the dataset's tag for a database before downloading subject
QSDR files; if suitable, download and open it, otherwise download the QSDR cohort and build one:

```bash
bash ./dsi.sh hub_files "<exact repository>" "<exact tag>" "\.(dz|db\.fz)$"
bash ./dsi.sh hub_download "<exact repository>" "<exact tag>" "<database file>" "C:/data"
bash ./dsi.sh open_connectometry "C:/data/<database file>"
```

Use `hub_download` + `open_connectometry`, not `hub_open` (which opens the plain database viewer, not a
`connectometry<hex>` window). A database is suitable when `list_voi`/`get_demo` show the needed subjects
and demographics and it holds the needed metric. Otherwise build:

```bash
dsi_studio --action=db --source=<glob of *.qsdr.fz files> --demo=<participants.tsv> --output=<group>.dz
```

All subjects must be reconstructed in the **same template space** (QSDR). Without `--demo`, the CLI
looks for `participants.tsv` in the current directory, then its parent (current wins). GUI: `create_db`
in the main window, then load subject FIBs and demographics into `CreateDBDialog`.

### 1.1 Quick group comparison from the database

`open_fib` on a `.dz` gives a fast per-subject, per-metric mean at a region or along a tract, with no
cohort filtering, permutation, or FDR: for eyeballing a suspected difference or sanity-checking the
database, not a substitute for the full analysis.

```bash
bash ./dsi.sh open_fib "<group>.dz"
bash ./dsi.sh list_atlas
bash ./dsi.sh add_region_from_atlas "<template-index> <atlas-index> <label-index>"
bash ./dsi.sh show_region_statistics
# or along a loaded/tracked bundle (open_tract/run_tracking/run_auto_track: DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md)
bash ./dsi.sh open_tract "<bundle.tt.gz>"
bash ./dsi.sh show_tract_statistics
```

With a connectometry database, both commands add one row per subject per stored metric,
`<subject-name> mean_<database-metric>    <mean at that region/tract>` (e.g. a database with `qa`,
`vol`, `dti_fa`, `rd`, `iso`, `rdi` gives `<subject> mean_qa`, `<subject> mean_dti_fa`, ... in one
call); switching the "current metric" is unnecessary and has no effect. Unattended:
`save_region_statistics`/`save_tract_statistics "<output.txt>"`. Validated live on an 18-scan SCA2 QSDR
database with BrainSeg Cerebellum (`open_fib "SCA2_subjects.dz"`, `add_region_from_atlas "0 1 2"`,
`show_region_statistics`): subjects were enumerated automatically, returning the Cerebellum geometry and
one `mean_<metric>` per scan per metric; tracts use the same mechanism.

### 1.2 Longitudinal-change database

A longitudinal/intercept study (`--voi=longitudinal`, step 2) runs on a derived database of pairwise
per-subject **changes**, built from an existing `.dz`/`.db.fz` with `--match`:

```bash
dsi_studio --action=db --source=<group>.dz --match=consecutive \
  --dif_type=0 --filter_type=0 --normalize_iso=1 --output=<group>.dif.dz
```

- `--match=consecutive` pairs stored rows (0,1), (2,3), ... as scan1/scan2. Confirm the order alternates
  by the subject list in the `open_db` GUI or the source file list (`list_window` does not report it).
  `--match=<pairs.txt>` gives explicit 0-based row pairs, whitespace-separated
  (`scan1_row scan2_row scan1_row scan2_row ...`).
- `--dif_type=0` `scan2 - scan1` (default); `1` `(scan2 - scan1) / scan1`.
- `--filter_type=0` (default) keeps the signed change (increases positive, decreases negative; use it to
  test whether change exists). `1` keeps only increases as positive magnitudes (decreases zeroed). `2`
  keeps only decreases, **also as positive magnitudes**: `connectometry_db::calculate_change` in
  `libs/mapping/connectometry_db.cpp` runs `if(filter_type==2) tipl::neg(...)` *before* the zero-clamp,
  so values are never negative.
- `--normalize_iso` (default `1`) divides `qa`/`rdi`/`nrdi*`-type metrics by the subject's isotropic map
  before differencing (the GUI's "Normalize QA/RDI/NRDI by ISO" default).
- `--output` defaults to `longitudinal` plus `.dif.dz`, `.pos_dif.dz`, or `.neg_dif.dz` by filter type
  (the GUI "Save DB as" naming).

The result is marked unfiltered, increase-only, or decrease-only (filter 0/1/2), cannot be
re-differenced (`--match` on it fails), and is passed to `--action=cnt` as `--source`; `get_demo` reports
its kind. `--voi=longitudinal` (equivalently `Intercept`) tests whether change exists, pooling every
(cohort-filtered) subject; `--voi=<a demographics column, e.g. group>` tests whether the *amount* of
change differs between groups.

### 1.3 Two-phase longitudinal group comparison

For "did the patients decline more than controls":

1. **Confirm change exists in the affected group.** Build with `--filter_type=0`, cohort-filter to that
   group (`--select`/`select_text`, e.g. `group=0`), and test `--voi=longitudinal`. If nothing is found,
   stop: a group-difference test is unlikely to be meaningful.
2. **Isolate the predicted direction, then compare groups.** Rebuild with `--filter_type=2` (metric
   expected to *decrease*, e.g. neuronal injury) or `1` (*increase*), so each voxel is a positive
   magnitude of change in that direction (0 otherwise), and test `--voi=group` (not `longitudinal`) on
   the full, cohort-unfiltered set. A significant `hypothesis_inc`/`hypothesis_dec` then means one
   group's change in that direction exceeds the other's, not merely that change occurred.

### 2. Define the analysis

- `--index_name`: the metric (e.g. `qa`, `rdi`; default the database's first index). `qa` and `dti_fa`
  are the most tested: consider both, as they differ in sensitivity (`dti_fa` is often more sensitive to
  neuronal injury). Keep `--normalize_iso` on (default) for `qa` and other anisotropy-type metrics
  (`rdi`, `nrdi*`), which correct a between-scan/scanner intensity issue; `dti_fa` does not need it.
- `--voi`: the variable of interest (feature index, or literal `Intercept`/`longitudinal` for a
  longitudinal database).
- `--variable_list`: comma-separated feature indices for the partial correlation (covariates plus the
  variable of interest). Choose deliberately: age and sex when they vary meaningfully; a `site` covariate
  (0/1 or more categories) for multi-site data; for a **longitudinal** database the inter-scan interval
  (e.g. a `days_interval_between_ses1_and_ses2`-style column), since longer gaps plausibly mean more
  change.

Indices follow the demographics column order loaded into the database: never guess them. Before running,
re-list every column (`get_demo`, or the CLI's printed `selectable variables include` list) and decide
for each whether it is a covariate; don't stop at a plausible subset such as age+sex.

In a session, `set_voi <voi> <variable_list>` replaces both flags and accepts feature **names** or
indices (matched like `hub_open`/`hub_show` rows/names). `list_voi` prints `index\tname\tselected`: read
it first. The second argument is the full set (the variable of interest is added if omitted), and
`set_voi` clears earlier selections (not additive). A categorical column's name embeds its encoding,
e.g. `group(0=SCA2 1=CONTROL)`, so a bare `"group"` fails with `invalid variable of interest: group`:
prefer `list_voi` indices for categorical variables (continuous names are usually safe verbatim):

```bash
bash ./dsi.sh list_voi
bash ./dsi.sh set_voi 0 "0,1,2"                           # categorical study variable by index
bash ./dsi.sh set_voi "age_exam_ses01" "age_exam_ses01,2"  # a continuous variable by name
```

`get_demo` first prints `database type:` (`cross-sectional (not longitudinal)`,
`longitudinal, unfiltered (signed scan2-scan1 change)`, `longitudinal, increase-only (positive magnitude,
scan2>scan1 kept)`, or `longitudinal, decrease-only (positive magnitude, scan2<scan1 kept)`), then the
loaded per-subject table (`subject<TAB><column>...`). Use it to confirm column names and values
(including subject-name rematching) before `set_voi`, and the database kind without re-deriving it.

### 3. Select the cohort

CLI `--select`; in a session set `select_text` or append a clause with `apply_selection`, then
`show_cohort` to apply and inspect (`select_cohort` is internal, not a command). Clauses are
comma-separated `name<op>value` with `=`, `>`, `<`, or `/` (not equal; shown "≠" but sent as `/`), e.g.
`age>40,sex=1`. A categorical column needs its full `list_voi`/`get_demo` name, e.g.
`group(0=SCA2 1=CONTROL)=0` (bare `group=0` fails with "cannot parse selection text"). `subject` filters
by name substring (`>`/`<` mean contains/does-not-contain); `value` applies to every selected feature;
numeric comparisons use 3-decimal precision. Always confirm the resulting `n=`: too few subjects
invalidate the permutation test.

### 4. Propagation threshold and FDR (independent controls)

- **Propagation threshold** (`--t_threshold` or `--effect_size`, related by `rho = t / sqrt(t² + n - 2)`;
  setting one overwrites the other): per-voxel correlation needed to extend a streamline. Default effect
  size `0.3` in the CLI (`cmd/cnt.cpp`, when `--t_threshold` is absent) and GUI (`group_connectometry`
  constructor). Prefer `effect_size` to a fixed t, whose meaning shifts with sample size, and confirm the
  current value (`list_param effect_size`) since earlier commands (yours or a local user's) may have
  changed it. A low threshold never "recovers" a null result: it changes valid steps, not significance.
  Running a small range (e.g. `0.2`, `0.3`, `0.4`) and reporting how extent changes separates threshold
  artifacts from robust findings.
- **`--fdr_threshold`** selects the reported track length after the run. At default `0.0` (disabled) a
  fixed `--length_threshold` (voxels) truncates results and the report states whatever FDR resulted.

### 5. Region constraints (optional, discouraged)

Whole-brain seeding (no ROI/seed) is the recommended default. Seeding-time ROIs usually yield far fewer
findings, partly by shrinking the permutation null sample; prefer running whole-brain and filtering the
inc/dec tracts to a region afterwards (e.g. in a tracking window). Reserve the seeding flags (as in
fiber tracking: `--roi`, `--roi2`..`--roi5`, `--roa`..`--roa5`, `--seed`, `--end`, `--end2`,
`--ter`..`--ter5`, `--nend`, `--lim`, or atlas-based `--track_id`/`--use_roi`/`--tolerance`) for a strong
anatomical hypothesis. `--exclude_cb` (remove the cerebellum before seeding) is a narrower, usually safer
exclusion.

### Pre-run checklist

Re-confirm each item before `run`/`--action=cnt`; stale values from earlier commands raise no error:

- **Database kind** (`get_demo` `database type:`) fits this step (not cross-sectional vs longitudinal by
  accident).
- **`index_name`** (`list_param index_name`) is intended, not the first-index default.
- **`voi`** (`list_voi`) is not left over from a previous analysis.
- **Covariates** reviewed against *every* `get_demo` column (age/sex is a start, not the ceiling; check
  site, scan interval, and dataset-specific columns).
- **Cohort filter** (`select_text`/`show_cohort`) and `n=` match this phase (cleared for full-cohort,
  set for a restricted step).
- **`effect_size`/`threshold`** (`list_param effect_size`) deliberately set; start at `effect_size=0.3`.
- **FDR** (`fdr_control`/`fdr_threshold`) set for this run.
- **ROI/seed** whole-brain unless deliberately narrowed.

### 6. Run and interpret

The run yields independent `hypothesis_inc` and `hypothesis_dec` from the sign of each voxel's
regression T-statistic: "increase" = positive association with the variable (or increase over time for
longitudinal/intercept), "decrease" the opposite. Report both, with their separate tract counts. Report
wording (`get_result`, HTML report, `show_result`):

- `longitudinal`/`Intercept` (1.3 phase 1): "increased `<METRIC>`" / "decreased `<METRIC>`", the signed
  change pooled over subjects.
- Categorical variable (e.g. `group`) on a **cross-sectional** or **unfiltered-longitudinal** database:
  each hypothesis names one level with the **same** word, e.g. "higher `<METRIC>` in CONTROL" / "higher
  `<METRIC>` in SCA2"; "increased"/"decreased" would misdescribe a between-group comparison.
- Categorical variable on a **filtered-longitudinal** database (`--filter_type=1`/`2`, already a positive
  magnitude): "more `<METRIC>` increase over time in `<group>`" / "more `<METRIC>` decline over time in
  `<group>`", again the same word ("more") naming different groups. "less `<METRIC>` decline in X" would
  restate the other hypothesis as if separate: a regression of a known-fixed bug, not a finding.

A paragraph says "significantly" only when that side's FDR is strictly below `0.05`, regardless of
`--fdr_threshold`; a finding under a more lenient search threshold is still shown with its FDR, without
that word. `--tip_iteration` (default 16) prunes both result sets and their null distributions before
FDR; `--region_pruning` (default on) adds topology-based cleanup afterwards.

### 7. Validate before reporting

- Check inc and dec tract counts at the reported FDR/length; near zero on one side is a valid "no
  finding."
- Check anatomical location: a plausible shape in an implausible place is suspect.
- Re-examine covariates: an unadjusted confound can create a spurious pathway.
- Confirm `--normalize_iso` (default on when applicable, for `qa`, `rdi`, `nrdi*`) matches the intended
  analysis.
- For a longitudinal group finding (1.3 phase 2), check the **cross-sectional** baseline at that
  location. A site already lesioned in the affected group may sit near its floor, capping further
  decline, while the unaffected group still declines normally (e.g. aging), producing "more decline in
  the unaffected group at the lesion site." Seen live: SCA2-vs-control DTI_FA showed significantly more
  decline in CONTROL at SCA2's known lesion sites, plus an independent finding of more decline in SCA2
  elsewhere; both are real permutation results, but the first must be read against SCA2's already-low
  baseline, not as controls declining unusually fast.

### 8. Post-hoc anatomy and tract volume

Characterize a supported result **post hoc** in its result tracking window instead of naming pathways by
appearance. `show_result` opens or exposes the tractogram in a `tracking<hex>` window; find it with
`list_window` and confirm which tract index is the reported inc/dec finding.

```bash
bash ./dsi.sh show_tract_statistics
bash ./dsi.sh show_tract_overlap_statistics 0 HCP842_tractography
bash ./dsi.sh show_tract_overlap_statistics 0 BrainSeg
```

`show_tract_statistics` gives streamline count, spatial volume (mm^3), length/surface statistics, and,
with a database attached, per-subject means per metric. That volume is the **space occupied by the
significant group-level tractogram**, not a lesion volume, a sum of subject lesions, or a subject
average. `show_tract_overlap_statistics <tract-index> <atlas-name>` lists intersected labels with voxel
counts, overlap volume (mm^3), centers/bounding boxes, and per-subject metric summaries: use a tract
atlas (`HCP842_tractography`) for named pathways and `BrainSeg` for structures such as cerebellum,
thalamus, red nucleus, and white matter. Prefer this when automatic recognition fails or the result is
distributed; never force one label because a pathway looks dominant.

- Atlas-overlap volumes are **not mutually exclusive** and can sum past the tractogram volume; never add
  them, and report the tractogram volume separately.
- Overlap is descriptive anatomy, not a second test; it does not change permutation/FDR significance.
- Characterize only supported side(s) and keep the direction explicit (e.g. "higher DTI_FA in CONTROL",
  hence lower DTI_FA in SCA2).
- With many small labels, summarize dominant systems and keep the full table for reproducibility.

```text
The significant tractogram occupied <V> mm^3. Post-hoc HCP842 overlap showed
predominant involvement of <major pathways>, while BrainSeg overlap localized
the finding mainly to <major structures>. Atlas-overlap volumes are
non-additive because atlas labels overlap spatially.
```

### 9. Save and visualize

`--output` sets the file prefix (omitted: an automatic suffix). With `--no_tractogram=0` (GUI default;
forced to `1`, disabled, in a headless CLI run unless the process keeps its GUI event loop), DSI Studio
also opens a hidden tracking window and saves inc/dec screenshots and an HTML report beside the tracts.

## Common failures

| Observation | Check first |
|---|---|
| Zero subjects after selection | Clause syntax, operator character, column spelling (categorical: full encoded name) |
| Result identical across thresholds | `t_threshold` and `effect_size` both set (they overwrite each other) |
| "Significant" pathway with implausible anatomy | Unadjusted covariates, database space/registration, too few subjects |
| Increase and decrease both empty | Cohort too small, weak effect, or covariates absorbing it |
| FDR arbitrary/unstable | `fdr_threshold=0` uses fixed length; set an explicit `fdr_threshold` |
| Database load fails | Mixed template spaces, or `.dz` built from mismatched index sets |
| Region/tract statistics show one database metric | Both should iterate every stored metric; a build predating this fix |
| Connectometry command ignored or errors | `list_window`: right `connectometry<hex>` ID and `idle`, not `busy` |
| `set_voi` "invalid variable" | Use an exact `list_voi` `name` or its `index` |
| Covariate seemingly ignored | `set_voi` replaces the whole set; pass every variable in one call |
| "cannot parse selection text" on a categorical column | Full encoded name, e.g. `group(0=SCA2 1=CONTROL)=0` |
| Recognition fails on a distributed result | `show_tract_overlap_statistics` with `HCP842_tractography` and `BrainSeg` |
| Overlap volumes exceed tractogram volume | Expected (overlapping labels); total volume from `show_tract_statistics` |
| Finding worded "less `<METRIC>` decline/increase in `<group>`" | Regression of a fixed bug; both hypotheses must say "more", naming different groups |

## Example commands

```bash
# build the database
dsi_studio --action=db --source=*.qsdr.fz --demo=participants.tsv --index_name=qa --output=group.dz
# per-subject metrics at a region / along a tract
bash ./dsi.sh open_fib "group.dz"
bash ./dsi.sh add_region_from_atlas "0 1 2"
bash ./dsi.sh show_region_statistics
bash ./dsi.sh open_tract "cst.tt.gz"
bash ./dsi.sh show_tract_statistics
# cross-sectional correlation, one variable of interest and two covariates, filtered, explicit FDR
dsi_studio --action=cnt --source=group.dz --demo=participants.tsv \
  --index_name=qa --variable_list=0,1,2 --voi=1 \
  --select="age>18" --effect_size=0.3 --fdr_threshold=0.05 \
  --tip_iteration=16 --output=age_correlation
# longitudinal/intercept study
dsi_studio --action=cnt --source=longitudinal.dz --voi=longitudinal \
  --variable_list=0 --effect_size=0.3 --output=longitudinal_change
```

Interactive equivalent adjusting for age and sex (`0` = study variable `group`, covariates `0,1,2`):

```bash
bash ./dsi.sh open_connectometry "group.dz"
bash ./dsi.sh get_demo
bash ./dsi.sh list_voi
bash ./dsi.sh set_voi 0 "0,1,2"
bash ./dsi.sh set_param select_text "age>18"
bash ./dsi.sh show_cohort
bash ./dsi.sh set_params "effect_size=0.3&fdr_control=1&fdr_threshold=0.05&tip=16"
bash ./dsi.sh run
```

`set_param`/`set_params` use the ids `list_param` reports, not CLI flag names, and some differ (`tip`
for `--tip_iteration`, `threshold` for `t_threshold`). Poll `progress` to `finished`, then `get_result`
(and/or `show_result`); for a significant result continue with step 8. Parameters vary by version;
prefer commands from the current GUI command history when reproducing an interactive workflow.

## Record for reproducibility

Database file, subject list, template space, stored indices; database kind (`get_demo` `database type:`)
and, if longitudinal, the `--match`/`--dif_type`/`--filter_type`; demographics source and every column
used; variable of interest and full `variable_list`; cohort clause and subject count;
`t_threshold`/`effect_size` (one setting, two forms); `fdr_threshold` or fallback `length_threshold` and
the FDR/length reported; `tip_iteration`, `region_pruning`, `normalize_iso`, `exclude_cb`; ROI/seed
constraints; permutation count; inc and dec tract counts and output paths; for post-hoc work, direction,
tract index/window, streamline count and volume from `show_tract_statistics`, atlas name(s), and the
dominant non-additive overlap volumes/labels from `show_tract_overlap_statistics`.
