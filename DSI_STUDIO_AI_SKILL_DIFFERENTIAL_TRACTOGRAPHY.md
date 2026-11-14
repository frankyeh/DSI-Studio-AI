# DSI Studio Differential Tractography Guide for AI Agents

Differential tractography (dT) adds study-design, spatial-alignment, metric-pairing, and
differential-threshold requirements that are easy to confuse with ordinary tractography, so it has its
own guide. Terminology: https://practicum.labsolver.org/dT.html. Use `bash ./dsi.sh <command>
[parameters...]` throughout, and always inspect returned names, indices, registration state, and
tracking output: never infer metric names or `dt_index` values from filenames.

## 1. Types (study design) vs formula

The practicum Type is the **study design and analysis space**, independent of the formula chosen by
`dt_threshold_type` ("Type 1" is not formula 1).

| Type | Comparison | Space | Typical framework |
|---|---|---|---|
| Type 1 | Longitudinal: baseline vs follow-up | Native subject | GQI baseline FIB |
| Type 2 | Longitudinal: baseline vs follow-up | Template | QSDR/template FIB |
| Type 3 | Cross-sectional: individual vs control reference | Native subject | GQI subject FIB plus MNI control reference |
| Type 4 | Cross-sectional: individual/group vs control reference | Template | QSDR/template space |

Formulas (`dt_threshold_type`): `0` (m1-m2)/m1, `1` (m1-m2)/m2, `2` m1-m2, `3` (m2-m1)/m1,
`4` (m2-m1)/m2, `5` m2-m1, `6` m1/max(m1), `7` m2/max(m2). For a baseline-normalized decrease, `m1` =
baseline/control, `m2` = comparison, formula `0` (positive values = decrease); `dt_threshold=0.2` means a
>20% decrease. Formula `0` is chosen because it is the desired calculation, not because a workflow is
Type 1.

## 2. Setting the metrics

Setting `m1`/`m2` alone tracks nothing: only `run_dif_tracking` applies them (section 6).

**Preferred: `list_param` + `set_param`.** dT indices are **not** `list_slice` rows: the dropdown has
synthetic entries (`zero`, `one`), built-in metrics, and eligible custom slices, e.g. a baseline GQI
window may report `options: 0=zero, 1=one, 2=qa, 3=qir, 4=dti_fa, ..., 8=followup_dti_fa` (then
`dt_index1 4`, `dt_index2 8`). Query them each time; never reuse indices from another subject or window.

```bash
bash ./dsi.sh list_param dt_index1
bash ./dsi.sh list_param dt_index2
bash ./dsi.sh set_param dt_index1 <m1-index>
bash ./dsi.sh set_param dt_index2 <m2-index>
bash ./dsi.sh set_param dt_threshold_type <formula-index>
bash ./dsi.sh set_param dt_threshold <threshold>
```

**Exact names: `set_dt_index`.** `bash ./dsi.sh set_dt_index "<m1-name>&<m2-name>" <formula-index>`,
e.g. `"dti_fa&<exact-followup-slice-name>"`, with names exactly as `list_slice`/`list_param` return them (no guessed abbreviations). It prints the
differential expression (inspect it) and syncs `dt_index1`/`dt_index2`, so either route can be followed
by `run_dif_tracking`.

## 3. Type 1: longitudinal, native space (GQI)

1. GQI-reconstruct baseline and follow-up.
2. Export the metric (commonly `dti_fa`) from the **follow-up** FIB only; the baseline FIB already
   contains its own metrics, so never export and re-add them.
3. Open the **baseline** `.gqi.fz`, add the follow-up map as a slice, and wait for registration.
4. Set `m1`=baseline, `m2`=follow-up, formula `0`, threshold; run and verify.

```bash
bash ./dsi.sh open_fib "<followup.gqi.fz>"
bash ./dsi.sh list_slice
bash ./dsi.sh save_slice_image "<followup_dti_fa.nii.gz>" "dti_fa"
bash ./dsi.sh open_fib "<baseline.gqi.fz>"
bash ./dsi.sh add_slice "<followup_dti_fa.nii.gz>"
bash ./dsi.sh list_slice   # poll until the follow-up row is ready, not registering
```

`add_slice` rigidly registers the map to the GQI space, even when matrix and voxel sizes match. The
expected expression is equivalent to `dt metrics:(baseline-followup)/baseline` (with built-in FA:
`dt metrics:(dti_fa-<followup>)/dti_fa`). Streamline directions
come from the baseline FIB; the differential metric is an extra termination criterion. Strength: native
space with only rigid alignment, no nonlinear template-warp differences. Caution: residual inter-scan
misalignment; inspect the registered map around tissue boundaries, ventricles, lesions, and regions of
anatomical change.

## 4. Type 2: longitudinal, template space (QSDR)

QSDR-reconstruct both scans, export the metric from **both** QSDR FIBs, open the template FIB as the
framework, add both maps as ordinary slices, wait until ready, inspect template alignment, then set
metrics/formula/threshold and run. (Opening a template FIB with both QSDR maps is Type 2, not Type 1.)
The result is directly template-referenced and normalization partly absorbs deformation, but
QSDR/nonlinear misregistration can mimic biological change: inspect both maps against the template near
boundaries, ventricles, lesions, and atrophy. A plausible tract pattern does not rule out registration
artifact.

## 5. Type 3: cross-sectional, native space

The older connectometry-database approach with age/sex matching is no longer the default (age and sex
fit scalar metrics poorly and add model assumptions). Use a direct control average, validated in a live
DSI Studio session:

1. Export the metric from controls in **QSDR space** (voxelwise averaging is valid only for
   QSDR/MNI-aligned maps) and average them with the `tmp` action (one string; DSI Studio expands the
   wildcard). The output is an MNI-space reference:

   ```bash
   bash ./dsi.sh run_cli "--action=tmp --source=<dir>/fa_*.nii.gz --output=<dir>/control_avg_fa.nii.gz"
   ```

   Over Web: `{"cmd":"run_cli","param":"--action=tmp --source=<dir>/fa_*.nii.gz --output=<dir>/control_avg_fa.nii.gz"}`.
2. Confirm the output exists, then `open_fib` the patient `.gqi.fz`.
3. `list_window`: the tracking title must show the **patient** file (a leftover window, e.g. a
   control's QSDR FIB, is a common mistake). `hub_open` may download a Fiber Data Hub file without
   opening it; then `open_fib` the cached path (Hub notes in `DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md`).
4. GQI/native FIB: `add_mni_slice` the average so it is mapped from MNI into native space. (With a
   QSDR/template FIB it can be a regular slice.)
5. Poll `list_slice` until that row is `ready`; confirm its name.
6. `list_param dt_index1` / `dt_index2`; set `m1` (control average), `m2` (patient metric, e.g.
   `dti_fa`), formula, threshold.
7. `run_dif_tracking` and check the verification lines (section 6) before polling.

**Type 4** (cross-sectional, template space): QSDR/MNI-aligned metrics with a template-space framework;
keep the reference and subject/group metrics in one template space and inspect alignment. Expand only
after a validated worked example exists.

## 6. Running and verifying

```bash
bash ./dsi.sh list_param tracking
bash ./dsi.sh list_param dt_index1
bash ./dsi.sh list_param dt_index2
bash ./dsi.sh run_dif_tracking "<descriptive differential bundle name>"
bash ./dsi.sh list_tract status
bash ./dsi.sh list_tract
```

Before polling, confirm the printed lines match intent; a wrong name or reversed expression means the
metrics are wrong:

```text
 set m1:<m1 name>
 set m2:<m2 name>
dt metrics:<expression>
```

- `run_dif_tracking` resolves `dt_index1`/`dt_index2` into `set_dt_index` and fails if both are `0`.
  `run_tracking` fails if they are nonzero but never applied, and otherwise clears leftover
  differential state, so never use it for dT.
- Tracking stops at `max_tract_count`: a bundle at exactly that count (e.g. 10,000) means the true
  extent, and dT tract volume, are larger. Raise it and rerun, or report as capped.
- Large `tip_iteration` can remove too many differential trajectories. Track with `tip_iteration=0`,
  then `trim_tract` one round at a time, checking `list_tract` (tract/deleted counts) after each; one or
  two rounds usually suffice. About 5,000-10,000 remaining tracts is a convenient review range, not a
  biological or statistical cutoff. If trimming becomes excessive, stop or `undo_tract`.
- When practical, show a threshold series (e.g. 10%, 20%, 30%, 40% decrease) to see how pathways
  persist as the effect size rises: a robustness/presentation check, not a substitute for statistics.
- **Cohort FDR** needs **all controls and all patients** processed first (never one subject or a
  subset). Per threshold: `FDR = mean dT tract volume from controls / mean dT tract volume from patients`.
- Verify the output shows the intended `dt_threshold`, direction, and formula, and save with names
  encoding space, metric, direction, and threshold:
  `bash ./dsi.sh save_tract "<subject>_GQI_dtiFA_decrease20.tt.gz" <bundle-index>`.

Record at minimum: practicum Type; baseline/subject and comparison/control sources; reconstruction
method and space; registration or MNI-mapping status; exact `m1`/`m2` names; formula and threshold;
tracking parameters; tract and seed counts; output path; alignment QC findings.

## 7. Common errors

| Error | Correct response |
|---|---|
| Practicum Type taken as `dt_threshold_type` | Types are design/space; the parameter is the formula |
| Type 1 exporting both metrics | Open baseline GQI; add only the follow-up metric |
| QSDR/template longitudinal called Type 1 | It is Type 2 |
| Equal dimensions assumed to skip registration | `add_slice` may still register; wait for `ready` |
| `list_slice` rows used as `dt_index` | Query `list_param dt_index1`/`dt_index2` |
| Guessed `set_dt_index` names | Use exact returned names |
| `run_tracking` for dT | `run_dif_tracking` |
| Reversed direction | Define `m1`/`m2` explicitly for the formula |
| Type 2 differences trusted unchecked | Inspect both maps in template space |
| Averaging native-space control NIfTI | Average only QSDR/MNI-aligned maps |
| MNI average added as a native slice in GQI | `add_mni_slice` |
| Many TIP iterations by default | `tip_iteration=0` or light pruning; incremental `trim_tract` |
| Trusting `hub_open` opened the file | Check `list_window`; `open_fib` the cached path |
| Polling before checking `set m1:`/`set m2:`/`dt metrics:` | Verify those lines first |
| Bundle at `max_tract_count` treated as complete | Raise it or report capped |
| FDR before the cohort is complete | Process all controls and patients first |
