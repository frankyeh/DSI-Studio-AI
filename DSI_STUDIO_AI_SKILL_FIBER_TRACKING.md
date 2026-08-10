# DSI Studio Fiber-Tracking Guide for AI Agents

Use launcher commands throughout this workflow:

```bash
bash ./dsi.sh <command> [parameters...]
```

Always include `bash` before `./dsi.sh`. A successful `open_fib` returns the exact
`tracking<hex-address>` in `tracking window created, id: tracking...` and
automatically selects that new tracking window, so commands in this file can act on
it directly. Use `set_window` only when switching to another already-open tracking
window. Use `list_window` to confirm the ID or discover another tracking window when
needed.

Tractography follows reconstructed diffusion orientations. A streamline is a
computational trajectory, not an observed axon or a measure of connectivity
strength. Anatomical validity requires source QC, justified tracking settings,
explicit region logic, and visual inspection.

## Tutorials

- https://www.youtube.com/watch?v=xyFNXB9nJ90
- https://www.youtube.com/watch?v=oJK8jwTHVhc
- https://www.youtube.com/watch?v=V2pxI2tooPs

## Choose the workflow

| Goal | Preferred approach |
|---|---|
| Data/reconstruction QC | Whole-brain tracking |
| Standard named pathway | AutoTrack when the atlas contains it |
| Custom or distorted pathway | Manual Seed/ROI/ROA constraints |
| Region-to-region connectivity | End-region constraints |
| Cohort standardization | AutoTrack with fixed settings and QC |

Begin by inspecting whole-brain tracking. Major pathways should be coherent,
plausibly symmetric, and free of systematic flips. If many bundles fail, inspect
the acquisition, reconstruction, b-table, orientation, and mask before changing
tract-specific regions.

## Tracking parameters

Start from DSI Studio defaults. Change one setting at a time for a documented
reason; do not tune parameters until a desired-looking tract appears.

| Parameter | Lower value | Higher value | Rule |
|---|---|---|---|
| Tracking threshold | Extends into uncertain tissue | Stops earlier and may miss low-anisotropy fibers | Change only for widespread premature stopping or excessive low-anisotropy tracking |
| Angular threshold | Straighter and conservative | Follows sharper curves but permits false turns | Match expected tract anatomy |
| Step size | Finer and slower | Coarser and faster | Use default or a validated voxel-aware protocol |
| Smoothing | Follows local directions | Adds directional persistence | Treat as trajectory regularization, not display smoothing |
| Minimum length | Retains short/noisy fragments | Removes short valid pathways too | Match expected anatomy |
| Maximum length | Allows long trajectories | Limits loops and erroneous continuation | Set a plausible anatomical bound |

Tract count is the number of accepted streamlines. Seed count limits attempts.
Neither represents axons or biological connection strength.

Inspect live tracking parameters before changing them:

```bash
bash ./dsi.sh list_param tracking
```

Example parameter change:

```bash
bash ./dsi.sh set_params "fa_threshold=0.08&min_length=20"
```

## Differential tractography types

Use the terminology from the DSI Studio practicum:
https://practicum.labsolver.org/dT.html

The type number describes **study design and analysis space**, not the mathematical
formula selected by `dt_threshold_type`:

1. **Type 1:** longitudinal comparison in native space.
2. **Type 2:** longitudinal comparison in template space.
3. **Type 3:** cross-sectional comparison in native space.
4. **Type 4:** cross-sectional comparison in template space.

Do not interpret "Type 1" as "the first differential formula." The formula index is
a separate setting.

## Type 1 differential tractography: longitudinal comparison in native space

Type 1 compares a patient's baseline and follow-up scans in the baseline native
diffusion space. Prefer **GQI** for both scans.

For each longitudinal pair:

1. Run GQI reconstruction on the baseline and follow-up SRC files.
2. Export the desired scalar metric, commonly `dti_fa`, from the **follow-up** GQI
   FIB.
3. Open the **baseline** `.gqi.fz` as the tracking FIB.
4. Add only the exported follow-up metric as another slice.
5. Wait for rigid-body registration to finish.
6. Select the baseline and follow-up metrics for differential tracking and run
   tractography.

The opened baseline GQI FIB already contains its own built-in scalar metrics, such as
`dti_fa`. Do **not** export the baseline FA and add it back as another slice.

If the follow-up metric has not already been exported:

```bash
bash ./dsi.sh open_fib "<followup.gqi.fz>"
bash ./dsi.sh list_slice
bash ./dsi.sh save_slice_image "<followup_dti_fa.nii.gz>" "dti_fa"
```

Then open or return to the baseline GQI FIB and add only the follow-up scalar map:

```bash
bash ./dsi.sh open_fib "<baseline.gqi.fz>"
bash ./dsi.sh add_slice "<followup_dti_fa.nii.gz>"
bash ./dsi.sh list_slice
```

`add_slice` applies rigid-body registration to align the follow-up slice to the
opened baseline GQI diffusion space. DSI Studio may still run registration when the
two scans have identical matrix size and voxel size. Poll `list_slice` and do not
configure differential tracking until the follow-up row reports `ready` rather than
`registering`.

### Type 1 differential metric selection

There are two supported ways to configure `m1` and `m2`. The safer default for an
agent is `list_param` plus `set_param` because the differential dropdown indices are
runtime-dependent.

First query the exact options:

```bash
bash ./dsi.sh list_param dt_index1
bash ./dsi.sh list_param dt_index2
```

The returned `dt_index` values are **not the same as `list_slice` row indices**. The
differential dropdown may include synthetic entries such as `zero` and `one`,
built-in metrics, and eligible custom slices. Never copy a `list_slice` row number
into `dt_index1` or `dt_index2` without checking `list_param`.

For example, a baseline GQI window may report:

```text
options: 0=zero, 1=one, 2=qa, 3=qir, 4=dti_fa, ..., 8=followup_dti_fa
```

For a baseline-normalized decrease using those example indices:

```bash
bash ./dsi.sh set_param dt_index1 4
bash ./dsi.sh set_param dt_index2 8
bash ./dsi.sh set_param dt_threshold_type 0
bash ./dsi.sh set_param dt_threshold 0.2
```

Always use the indices returned by the current tracking window rather than assuming
`4` or `8` will apply to another subject or another set of loaded slices.

The exact-name alternative is `set_dt_index`:

```bash
bash ./dsi.sh set_dt_index "dti_fa&<exact-followup-slice-name>" 0
```

Here the first name is `m1`, the second is `m2`, and the final number is the
zero-based **differential formula index**. It is not the practicum Type number. Use
`list_slice` and/or `list_param` to obtain exact metric names; do not guess them.

### Differential formula and direction

For a baseline-normalized decrease analysis, use baseline as `m1` and follow-up as
`m2`. Formula index `0` is:

```text
(m1 - m2) / m1
```

Positive values therefore indicate a decrease from baseline to follow-up. With
`dt_threshold=0.2`, the differential tracking criterion is a baseline-normalized
decrease greater than 20%.

The current formula ordering is:

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

Formula `0` is used for the common baseline-normalized decrease analysis because it
is the desired calculation, **not because the workflow is Type 1**.

A successful setup should report an expression equivalent to:

```text
dt metrics:(dti_fa-<followup>)/dti_fa
```

The streamline directions come from the opened baseline FIB; the differential metric
acts as an additional tracking termination criterion.

### Run and verify Type 1

Before tracking, verify the current settings:

```bash
bash ./dsi.sh list_param tracking
bash ./dsi.sh list_param dt_index1
bash ./dsi.sh list_param dt_index2
```

Then run tracking and wait for completion:

```bash
bash ./dsi.sh run_tracking "<descriptive differential bundle name>"
bash ./dsi.sh list_tract status
bash ./dsi.sh list_tract
```

For a 20% baseline-normalized decrease, confirm
`(baseline-followup)/baseline` and `dt_threshold=0.2` in the operation output.

Save the result with a filename that records the reconstruction space, metric,
direction, and threshold:

```bash
bash ./dsi.sh save_tract "<subject>_GQI_dtiFA_decrease20.tt.gz" <bundle-index>
```

## Type 2 differential tractography: longitudinal comparison in template space

Type 2 compares baseline and follow-up scans in a common template space using
**QSDR**. This is the workflow used when a template-space result is desired.

For each longitudinal pair:

1. Run QSDR reconstruction on both baseline and follow-up SRC files.
2. Export the desired scalar map, commonly `dti_fa`, from **both** QSDR FIB files.
3. Open the template FIB as the tracking framework.
4. Add the exported baseline and follow-up maps as slices.
5. Wait until both slices are ready and verify their alignment.
6. Select the baseline and follow-up metrics and run differential tractography.

The main advantage is that the comparison and tractography are expressed in a common
template space. Normalization also partly handles longitudinal deformation, and the
template provides a common tracking framework across scans or subjects.

The main caution is **spatial normalization/misalignment**. Errors in nonlinear
registration can produce local metric differences that look like biological change.
Type 2 therefore requires careful inspection of the alignment of both scalar maps to
the template, especially near tissue boundaries, ventricles, lesions, atrophy, or
other regions with deformation. A visually plausible tract does not by itself prove
that the differential signal is free of registration error.

The previous QSDR workflow that opens the template FIB and inserts both baseline and
follow-up QSDR FA maps is therefore a valid **Type 2** analysis; it should not be
labeled Type 1.

## Differential tractography common errors

| Error | Correct response |
|---|---|
| Treating the practicum Type number as `dt_threshold_type` | Type 1-4 describe study design and analysis space; `dt_threshold_type` separately selects the mathematical formula |
| Exporting both baseline and follow-up FA for Type 1 | Open the baseline GQI FIB and add only the follow-up FA; baseline `dti_fa` is already inside the FIB |
| Calling a QSDR/template workflow Type 1 | Longitudinal QSDR/template-space comparison is Type 2 |
| Assuming equal dimensions mean no Type 1 registration | `add_slice` can still run rigid-body registration; wait for `ready` |
| Using `list_slice` row numbers as `dt_index` values | Query `list_param dt_index1` and `list_param dt_index2`; the index spaces differ |
| Reversing baseline and follow-up for a decrease analysis | Use `m1=baseline`, `m2=follow-up` for `(m1-m2)/m1` |
| Guessing names with `set_dt_index` | Use exact names returned by DSI Studio |
| Starting Type 1 tracking while the follow-up slice is registering | Poll `list_slice` until the slice status is `ready` |
| Trusting Type 2 differences without checking normalization | Inspect both maps in template space; misregistration can mimic biological change |

Record at minimum the practicum type, baseline and follow-up FIBs, scalar-map
sources, reconstruction method, analysis space, registration status, `m1`, `m2`,
differential formula, threshold, tracking parameters, tract count, seed count, and
saved tract path.

## Build regions from anatomy

Prefer anatomical segmentation over drawing regions from scratch:

1. Segment an aligned T1w image in the tracking window.
2. If T1w is unavailable, segment the isotropic diffusion image (`iso`).
3. Select and manually merge segmented labels to form the needed region sets.
4. Inspect boundaries and registration in all three planes.
5. Assign every region an explicit tracking role.

Many segmentation models are modality agnostic, but successful inference does not
prove anatomical validity.

| Region role | Effect |
|---|---|
| Seed | Starts trajectories |
| ROI | Retains trajectories passing through it |
| ROA | Rejects trajectories entering it |
| End | Requires termination in the region |
| Terminative | Stops propagation when reached |
| NotEnd | Rejects termination in the region |
| Limiting | Constrains propagation to the region |

Seed and ROI are not interchangeable. Multiple inclusive ROIs usually express an
AND condition. Every region should have a stated anatomical purpose.

Avoid oversized regions that include adjacent pathways, undersized regions that
miss anatomy or registration variation, and ROAs that intersect valid fibers.
Spatial overlap alone does not establish tract identity because unrelated
trajectories can cross the same voxels.

## Manual tracking

Use manual tracking for distorted anatomy, lesions, pathways absent from the atlas,
or a required explicit anatomical definition.

Before `run_tracking`:

```bash
bash ./dsi.sh list_param tracking
bash ./dsi.sh list_region
bash ./dsi.sh run_tracking "<bundle-name>"
```

Call `list_region` only after regions were created, loaded, segmented, or restored.
A newly opened FIB normally has no regions.

Record the Seed, ROI, ROA, endpoint, and Terminative logic. Inspect the initial
bundle before adding filters or exclusion regions.

Explicit region-role syntax uses `region-index:role` entries joined by `&`:

```bash
bash ./dsi.sh run_tracking "CST" "0:3&1:0&2:1"
```

Roles are `0=ROI`, `1=ROA`, `2=End`, `3=Seed`, `4=Terminative`, `5=NotEnd`, and
`6=Limiting`.

## AutoTrack

Use AutoTrack for standard named pathways and reproducible cohort workflows. First
discover the exact internal atlas identifier:

```bash
bash ./dsi.sh list_auto_tract
```

AutoTrack identifiers are hierarchical. When the user asks for the whole tract
family, choose the parent entry rather than one of its branch-specific descendants.
For example, map the entire left cingulum with `Association_CingulumL`, not an
`Association_CingulumL_...` child; use the corresponding parent entry for the corpus
callosum. Select a child only when a specific subdivision or branch is requested.

Then use the exact returned name:

```bash
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
```

Atlas names use underscore-separated hierarchical prefixes such as
`Association_*`, `ProjectionBrainstem_*`, and `Commissure_*`. Never guess or use
human-readable shorthand such as `Corticospinal Tract`.

For a standard named bundle, a practical starting point is:

```text
tract limit: 10,000
seed limit: 50,000,000
TIP iterations: 3–4
```

```bash
bash ./dsi.sh set_params "max_tract_count=10000&max_seed_count=50000000&tip_iteration=4"
```

The seed limit prevents difficult, low-yield pathways from running indefinitely.
AutoTrack already carries built-in anatomical region constraints for the named
bundle, so do not add ROI/ROA/END/NotEND/Limiting/Terminative constraints unless a
specific anatomical question requires additional restriction, such as isolating a
minor branch. Adjust AutoTrack tolerance cautiously: larger values accept more
variation and false positives; smaller values may reject distorted or variable
anatomy.

## Bundle cleanup

TIP is bundle-level cleanup. Apply it to a visually coherent tract bundle, including
an AutoTrack bundle or a previously loaded or recognized bundle result. If the bundle
is sufficiently populated (roughly 5,000–10,000 or more tracts before pruning),
3–4 TIP iterations are normally desired. Do not disable TIP merely to maximize tract
count. Use no TIP only when intentionally examining an unpruned bundle or when the
bundle is too sparse for pruning.

Do not routinely apply TIP or repeated-trajectory deletion to whole-brain
tractography. A whole-brain tract set contains many pathways rather than one coherent
visual bundle and generally does not need bundle-specific pruning.

AutoTrack applies its configured `tip_iteration` automatically. For a previously
loaded or already generated bundle that still needs cleanup, apply one additional TIP
iteration at a time and inspect the result:

```bash
bash ./dsi.sh trim_tract <bundle-index>
```

To remove near-duplicate trajectories from checked coherent bundles when specifically
needed:

```bash
bash ./dsi.sh delete_repeated_tract 1
```

Uncheck all non-target bundles before checked-bundle cleanup operations. Preserve the
original or obtain user approval when cleanup must remain recoverable.

## Result cleanup and visualization

After tracking finishes:

1. Poll until `status=done`:

   ```bash
   bash ./dsi.sh list_tract status
   ```

2. Inspect bundle indices and tract counts:

   ```bash
   bash ./dsi.sh list_tract
   ```

3. Apply bundle cleanup only when appropriate.
4. Assign distinct bundle colors:

   ```bash
   bash ./dsi.sh color_all_cluster
   ```

5. Hide the whole-brain bundle:

   ```bash
   bash ./dsi.sh check_tract <whole-brain-index> 0
   ```

6. Show only the target bundle:

   ```bash
   bash ./dsi.sh show_only_tracts <target-index>
   ```

7. Turn off slice rendering:

   ```bash
   bash ./dsi.sh set_param show_slice 0
   ```

8. Add subject-mapped built-in white-matter context:

   ```bash
   bash ./dsi.sh add_surface 0 25
   ```

Choose a useful inspection view for each bundle rather than reusing one camera. For
the left arcuate fasciculus, start from view 0 and adjust in small increments:

```bash
bash ./dsi.sh set_view 0
bash ./dsi.sh rotate "15 1 0 0"
bash ./dsi.sh rotate "20 0 1 0"
```

Verify orientation and capture several oblique views. Do not obscure mapped bundles
with whole-brain streamlines.

TIP and repeated-tract deletion modify checked bundles. Preserve the original or
obtain user approval when cleanup must remain recoverable.

## Quality-control guide

| Observation | Check or response |
|---|---|
| Most tracts stop early | Reconstruction, mask, and tracking threshold |
| Tracts enter gray matter or CSF | Threshold may be too low |
| Expected curve is missing | ROI placement and local orientations before raising angle |
| Implausible sharp turns | Reduce angular threshold and inspect crossings |
| Bundle is fragmented | Sampling, threshold, restrictive regions, and minimum length |
| Many unrelated branches | Region size, waypoint logic, and conservative ROAs |
| Bundle vanishes after ROA | ROA likely intersects valid anatomy |
| TIP removes nearly everything | Bundle is too sparse or tracking settings are poor |
| AutoTrack takes too long | Low yield; retain a finite seed limit |
| Many AutoTrack pathways fail | Data, b-table, orientation, or reconstruction problem |
| One pathway fails | Tract yield, tolerance, or anatomical distortion |

Endpoint tracking is sensitive to gray-white segmentation, gyral bias, anisotropy
near cortex, and endpoint-mask extent. Failure to reach cortex does not necessarily
prove absence of a connection.

## Reproducibility

Record:

- source FIB and reconstruction space;
- tracking method, index, threshold, angle, step size, and smoothing;
- minimum/maximum length and stopping criteria;
- tract and seed limits;
- every region name, source, space, role, and anatomical purpose;
- AutoTrack identifier, tolerance, and TIP iterations;
- repeated-tract threshold and other cleanup;
- random seed when exact repeatability is required;
- output tract files and QC findings.