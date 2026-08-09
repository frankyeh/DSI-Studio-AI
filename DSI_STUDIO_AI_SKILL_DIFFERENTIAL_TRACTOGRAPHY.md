# DSI Studio Differential Tractography Guide for AI Agents

Use this guide for differential tractography (dT). It is separate from the general
fiber-tracking skill because dT adds study-design, spatial-alignment, metric-pairing,
and differential-threshold requirements that are easy to confuse with ordinary
tractography.

Reference terminology:

https://practicum.labsolver.org/dT.html

Use launcher commands throughout:

```bash
bash ./dsi.sh <command> [parameters...]
```

Always inspect DSI Studio's returned names, indices, registration state, and tracking
output. Do not infer metric names or `dt_index` values from filenames alone.

## 1. Differential tractography types

The practicum Type number describes the **study design and analysis space**. It does
not describe the mathematical formula selected by `dt_threshold_type`.

| Practicum type | Comparison | Analysis space | Typical reconstruction/tracking framework |
|---|---|---|---|
| Type 1 | Longitudinal: baseline vs follow-up | Native subject space | GQI baseline FIB |
| Type 2 | Longitudinal: baseline vs follow-up | Template space | QSDR/template FIB |
| Type 3 | Cross-sectional: individual vs control reference | Native subject space | GQI subject FIB plus MNI control reference |
| Type 4 | Cross-sectional: individual/group vs control reference | Template space | QSDR/template space |

Do not interpret "Type 1" as "formula 1" or `dt_threshold_type=1`. The practicum
type and the formula index are independent concepts.

## 2. Differential formula and metric selection

The current differential formula ordering is:

```text
0  (m1-m2)/m1
1  (m1-m2)/m2
2  m1-m2
3  (m2-m1)/m1
4  (m2-m1)/m2
5  m2-m1
6  m1/max(m1)
7  m2/max(m2)
```

For a baseline-normalized decrease, use baseline/control as `m1`, the comparison
scan/subject as `m2`, formula index `0`, and the desired fractional threshold. For
example, `dt_threshold=0.2` selects a >20% decrease criterion for `(m1-m2)/m1`.

There are two supported ways to set the differential metrics.

### 2.1 Preferred agent route: `list_param` + `set_param`

Query the runtime dropdown contents first:

```bash
bash ./dsi.sh list_param dt_index1
bash ./dsi.sh list_param dt_index2
```

The returned differential indices are **not the same as `list_slice` row indices**.
The dT dropdown can contain synthetic entries such as `zero` and `one`, built-in
metrics, and eligible custom slices.

After identifying the exact current indices:

```bash
bash ./dsi.sh set_param dt_index1 <m1-index>
bash ./dsi.sh set_param dt_index2 <m2-index>
bash ./dsi.sh set_param dt_threshold_type <formula-index>
bash ./dsi.sh set_param dt_threshold <threshold>
```

Never reuse example indices from another subject or tracking window.

### 2.2 Exact-name route: `set_dt_index`

When the exact metric names are known, use:

```bash
bash ./dsi.sh set_dt_index "<m1-name>&<m2-name>" <formula-index>
```

Names must match exactly. Discover them with `list_slice` and/or `list_param`; do not
guess abbreviations. A successful setup prints the resulting differential expression,
which should be inspected before tracking.

## 3. Type 1: longitudinal comparison in native space

Type 1 compares baseline and follow-up scans in the baseline subject's native
diffusion space. Prefer **GQI** reconstruction for both scans.

### 3.1 Preferred workflow

1. Reconstruct baseline and follow-up diffusion data with GQI.
2. Export the desired scalar metric, commonly `dti_fa`, from the **follow-up** GQI
   FIB only.
3. Open the **baseline** `.gqi.fz` as the tracking FIB.
4. Add the exported follow-up metric as a custom slice.
5. Wait for rigid-body registration to finish.
6. Configure `m1`, `m2`, formula, and threshold.
7. Run differential tractography and verify the result.

The opened baseline GQI FIB already contains its own scalar metrics such as
`dti_fa`. Do **not** export the baseline metric and add it back as another slice.

If the follow-up metric has not already been exported:

```bash
bash ./dsi.sh open_fib "<followup.gqi.fz>"
bash ./dsi.sh list_slice
bash ./dsi.sh save_slice_image "<followup_dti_fa.nii.gz>" "dti_fa"
```

Then open or return to the baseline GQI FIB:

```bash
bash ./dsi.sh open_fib "<baseline.gqi.fz>"
bash ./dsi.sh add_slice "<followup_dti_fa.nii.gz>"
bash ./dsi.sh list_slice
```

`add_slice` applies rigid-body registration to align the follow-up map to the opened
GQI diffusion space. DSI Studio may perform registration even when matrix size and
voxel size are identical. Poll `list_slice` until the follow-up row reports `ready`.
Do not start a dependent dT operation while it reports `registering`.

For a baseline-normalized decrease, set `m1=baseline`, `m2=follow-up`, and formula
index `0`. A successful setup should report an expression equivalent to:

```text
dt metrics:(baseline-followup)/baseline
```

The streamline directions come from the opened baseline FIB; the differential metric
acts as an additional tracking termination criterion.

### 3.2 Type 1 strengths and cautions

The main advantage is that the analysis stays in subject/native diffusion space and
requires only rigid-body alignment of the follow-up scalar map to the baseline. This
avoids introducing nonlinear template-warp differences into the longitudinal
comparison.

The main caution is residual inter-scan alignment. Inspect the registered follow-up
map, particularly around tissue boundaries, ventricles, lesions, and regions with
substantial anatomical change.

## 4. Type 2: longitudinal comparison in template space

Type 2 compares baseline and follow-up scans in a common template space using
**QSDR**.

### 4.1 Preferred workflow

1. Run QSDR reconstruction on both baseline and follow-up scans.
2. Export the desired scalar metric, commonly `dti_fa`, from **both** QSDR FIB files.
3. Open the template FIB as the tracking framework.
4. Add the exported baseline and follow-up maps as ordinary slices.
5. Wait until both maps are ready and inspect their template-space alignment.
6. Configure the differential metrics, formula, and threshold.
7. Run and verify differential tractography.

The benefit is that both scans and the tractography framework are in a common
template space. This makes the result directly template-referenced and normalization
can partly accommodate longitudinal deformation.

The main weakness is sensitivity to QSDR/nonlinear-normalization misalignment.
Registration error can produce local scalar differences that look like biological
change. Carefully inspect both maps against the template, especially near tissue
boundaries, ventricles, lesions, atrophy, or other deformed anatomy. A plausible
tract pattern alone does not prove that the differential signal is free of
registration artifact.

The earlier workflow that opens a template FIB and inserts both baseline and
follow-up QSDR scalar maps is therefore a valid **Type 2** analysis, not Type 1.

## 5. Type 3: cross-sectional comparison in native space

Type 3 compares an individual subject against a control reference while keeping the
subject's tractography in native space.

The older approach used a connectometry database with age- and sex-matching. This is
no longer the preferred default because age and sex alone fit MRI scalar metrics
poorly and can create unnecessary model assumptions.

The current preferred direction is a direct control-average reference:

1. Export the same scalar metric from control subjects in **QSDR space**.
2. Average those already-aligned QSDR-space NIfTI maps using DSI Studio's `tmp`
   command-line action, for example:

   ```text
   --action=tmp --source=*.nii.gz --output=<control>_avg.nii.gz
   ```

3. The source NIfTI files must already be in QSDR/MNI space; otherwise voxelwise
   averaging is invalid because the images are not aligned.
4. The averaged output is therefore an MNI-space control reference.
5. When the subject tracking FIB is **GQI/native space**, insert this control average
   as an **MNI slice** using `add_mni_slice`, so DSI Studio maps it from MNI space
   into the subject's native diffusion space.
6. When the tracking FIB is **QSDR/template space**, the same MNI-space average can
   be loaded as a regular slice because the tracking framework is already in the
   corresponding template space.

This Type 3 control-average workflow has been validated in a live DSI Studio session.
After inserting the MNI control average into a GQI patient FIB, use `list_slice` and
`list_param dt_index1`/`dt_index2` to verify the runtime names and dT indices before
setting the differential comparison.

## 6. Type 4: cross-sectional comparison in template space

Type 4 performs a cross-sectional comparison in template space. Use QSDR/MNI-aligned
metrics and a template-space tracking framework. Keep the control reference and the
subject/group metrics in the same template space and inspect spatial alignment before
interpreting differential results.

Expand this section only after a validated worked example is available.

## 7. Running and verifying differential tractography

Before tracking:

```bash
bash ./dsi.sh list_param tracking
bash ./dsi.sh list_param dt_index1
bash ./dsi.sh list_param dt_index2
```

Then run and poll:

```bash
bash ./dsi.sh run_tracking "<descriptive differential bundle name>"
bash ./dsi.sh list_tract status
bash ./dsi.sh list_tract
```

Pay special attention to TIP pruning in differential tractography. A large
`tip_iteration` can remove too many differential trajectories. A practical approach
is to set `tip_iteration=0` during tracking and then apply `trim_tract` afterward one
round at a time, checking `list_tract` after each round. One or two trim rounds are
often sufficient for review. Roughly 5,000-10,000 remaining tracts is usually a
convenient range for evaluation and visualization, not a biological or statistical
cutoff. If trimming becomes excessive, stop or use `undo_tract` rather than
continuing a fixed number of rounds.

When practical, consider showing a series of differential thresholds rather than only
one selected threshold, for example 10%, 20%, 30%, and 40% decrease. This gives a
more comprehensive view of how the mapped pathways persist or shrink as the required
effect size increases and reduces dependence on a single visually favorable
threshold. Treat this as a presentation and robustness check, not as a substitute for
study-specific statistical analysis.

Verify the operation output shows the intended `dt_threshold`, metric direction, and
formula. Save results with filenames that encode analysis space, metric, direction,
and threshold, for example:

```bash
bash ./dsi.sh save_tract "<subject>_GQI_dtiFA_decrease20.tt.gz" <bundle-index>
```

Record at minimum:

- practicum Type;
- baseline/subject and comparison/control sources;
- reconstruction method and analysis space;
- registration or MNI-mapping status;
- exact `m1` and `m2` names;
- differential formula and threshold;
- tracking parameters;
- tract and seed counts;
- output tract path;
- alignment QC findings.

## 8. Common errors

| Error | Correct response |
|---|---|
| Treating practicum Type as `dt_threshold_type` | Type 1-4 describe study design/space; `dt_threshold_type` selects the formula |
| Exporting both baseline and follow-up metrics for Type 1 | Open baseline GQI FIB and add only the follow-up metric |
| Calling a QSDR/template longitudinal workflow Type 1 | Longitudinal QSDR/template comparison is Type 2 |
| Assuming equal dimensions mean no Type 1 registration | `add_slice` can still run rigid-body registration; wait for `ready` |
| Using `list_slice` row numbers as `dt_index` values | Query `list_param dt_index1` and `dt_index2`; the index spaces differ |
| Guessing names with `set_dt_index` | Use exact names returned by DSI Studio |
| Reversing metric direction | Explicitly define which image is `m1` and which is `m2` for the chosen formula |
| Trusting Type 2 differences without checking normalization | Inspect both maps in template space; misregistration can mimic change |
| Averaging native-space control NIfTI files voxelwise | Average only QSDR/MNI-aligned maps |
| Loading an MNI control average as an ordinary native slice in GQI | Use `add_mni_slice` |
| Using many TIP iterations by default for dT | Start with `tip_iteration=0` or very light pruning; use `trim_tract` incrementally and inspect tract/deleted counts |
