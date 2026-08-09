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

## Type 1 differential tractography: two longitudinal scans

Use this workflow when the user asks for the first differential-tractography type,
for example tracking a longitudinal FA decrease from a baseline scan to a follow-up
scan.

### Reconstruction space

Prefer **GQI** for longitudinal differential tractography because it keeps the
analysis in the subject/native diffusion space. QSDR is also supported, but QSDR is
standard/template-space reconstruction and should not be substituted for native-space
GQI unless the user wants standard-space analysis.

For GQI, open the **baseline** `.gqi.fz` as the tracking FIB. Its built-in scalar
metrics, such as `dti_fa`, are already available in that FIB. Do **not** export the
baseline metric to NIfTI and add it back as another slice.

Only the follow-up metric needs to be supplied as a custom slice. If it has not
already been exported, open the follow-up GQI FIB, discover the exact metric name
with `list_slice`, and export that metric in its own subject space:

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

`add_slice` performs the rigid-body alignment needed to bring the follow-up slice
into the opened GQI diffusion space. Even when the two images have identical matrix
size and voxel size, DSI Studio may still run rigid-body registration. Poll
`list_slice` and do not configure differential tracking until the follow-up row
reports `ready` rather than `registering`.

### Type 1 definition and direction

In the DSI Studio UI, **Type 1** is the first differential formula:

```text
(m1 - m2) / m1
```

where `m1` is the baseline metric and `m2` is the follow-up metric. Positive values
therefore indicate a decrease from baseline to follow-up. For example, with
`dt_threshold=0.2`, tracking requires a decrease greater than 20% at the differential
termination criterion.

The internal parameter is zero-based: **Type 1 corresponds to
`dt_threshold_type=0`, not `1`**. The current source orders the formulas as:

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

Do not reverse `m1` and `m2` when the requested result is a longitudinal decrease.
The streamline directions come from the opened baseline FIB; the differential metric
acts as an additional tracking termination criterion.

### Discover differential indices before setting them

There are two supported ways to configure the differential metric. The safer default
for an agent is `list_param` plus `set_param` because the dropdown indices are
runtime-dependent.

First query the exact options:

```bash
bash ./dsi.sh list_param dt_index1
bash ./dsi.sh list_param dt_index2
```

The returned differential indices are **not the same thing as `list_slice` row
indices**. The differential dropdown can contain synthetic entries such as `zero`
and `one`, built-in metrics, and eligible custom slices, so never copy a
`list_slice` index into `dt_index1` or `dt_index2` without checking `list_param`.

For example, a baseline GQI window may report:

```text
options: 0=zero, 1=one, 2=qa, 3=qir, 4=dti_fa, ..., 8=followup_dti_fa
```

Then configure Type 1 as:

```bash
bash ./dsi.sh set_param dt_index1 4
bash ./dsi.sh set_param dt_index2 8
bash ./dsi.sh set_param dt_threshold_type 0
bash ./dsi.sh set_param dt_threshold 0.2
```

Always use the indices returned by the current window rather than assuming `4` or
`8` will be correct for another subject or another set of loaded slices.

### Exact-name alternative: `set_dt_index`

The second supported route is `set_dt_index`, which avoids dropdown-index lookup but
requires the metric names to match exactly:

```bash
bash ./dsi.sh set_dt_index "dti_fa&<exact-followup-slice-name>" 0
```

The first name is `m1`, the second is `m2`, and the final number is the zero-based
differential type. For Type 1, use `0`. Use `list_slice` and/or `list_param` to obtain
the exact displayed names; do not guess abbreviated names.

A successful Type 1 setup should report a differential expression equivalent to:

```text
dt metrics:(dti_fa-<followup>)/dti_fa
```

Either configuration route is valid. Do not mix up an exact slice name with a
runtime dropdown index.

### Run and verify the differential tractography

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

Inspect the operation output and confirm the intended `dt_threshold` and differential
formula. For a 20% baseline-normalized decrease, the formula must be
`(baseline-followup)/baseline` and `dt_threshold` must be `0.2`.

Save the finished bundle with a filename that records the reconstruction space,
metric, direction, and threshold so it cannot be confused with a QSDR or increase
analysis:

```bash
bash ./dsi.sh save_tract "<subject>_GQI_dtiFA_decrease20.tt.gz" <bundle-index>
```

Record at minimum the baseline FIB, follow-up metric source, reconstruction method,
registration status, `m1`, `m2`, differential type, threshold, tracking parameters,
tract count, seed count, and saved tract path.

### Common errors

| Error | Correct response |
|---|---|
| Exporting both baseline and follow-up FA | Open baseline GQI FIB and add only the follow-up FA; baseline `dti_fa` is already inside the FIB |
| Using QSDR by default | Prefer GQI for native-space longitudinal analysis; use QSDR only when standard space is intended |
| Assuming same dimensions mean no registration | `add_slice` can still run rigid-body registration; wait for `ready` |
| Using `list_slice` row numbers as `dt_index` values | Query `list_param dt_index1`/`dt_index2`; the index spaces differ |
| Setting Type 1 with `dt_threshold_type=1` | Type 1 is the first UI formula and uses zero-based internal value `0` |
| Reversing baseline and follow-up | For decrease tracking use `m1=baseline`, `m2=follow-up` |
| Guessing names with `set_dt_index` | Use exact names returned by DSI Studio |
| Starting tracking while the follow-up slice is registering | Poll `list_slice` until the slice status is `ready` |

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

Then use an exact returned name:

```bash
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
```

Atlas names use underscore-separated hierarchical prefixes such as
`Association_*`, `ProjectionBrainstem_*`, and `Commissure_*`. Never guess or use
human-readable shorthand such as `Corticospinal Tract`.

Recommended dense AutoTrack sampling:

```text
tract limit: 50,000
seed limit: 50,000,000
```

Set these limits and optionally disable automatic TIP before a cleanup workflow:

```bash
bash ./dsi.sh set_params "max_tract_count=50000&max_seed_count=50000000&tip_iteration=0"
```

The seed limit prevents difficult, low-yield pathways from running indefinitely.
If it is reached first, fewer than 50,000 tracts may be produced. Adjust AutoTrack
tolerance cautiously: larger values accept more variation and false positives;
smaller values may reject distorted or variable anatomy.

## Dense-bundle cleanup

Topology-informed pruning and repeated-trajectory deletion are recommended only for
a dense, anatomically coherent named pathway bundle with more than 10,000 tracts;
approximately 50,000 tracts before cleanup is preferred.

Do not routinely apply either operation to whole-brain tractography. A whole-brain
tract set contains many pathways rather than one coherent bundle and generally does
not need bundle-specific trimming or repeated-tract deletion. Leave a bundle with
10,000 or fewer tracts intact unless the user specifically requests cleanup.

- AutoTrack applies its configured `tip_iteration` automatically.
- Apply one additional TIP iteration to every checked bundle:

```bash
bash ./dsi.sh trim_tract
```

- Target one explicit bundle index:

```bash
bash ./dsi.sh trim_tract <bundle-index>
```

- Remove near-duplicate trajectories from every checked bundle using a 1-voxel
  distance threshold:

```bash
bash ./dsi.sh delete_repeated_tract 1
```

Uncheck all non-target bundles before either operation. This is mandatory for
`delete_repeated_tract`, whose first parameter is the distance threshold, not a
bundle index.

Recommended cleanup for a dense named bundle:

1. Set dense limits and disable automatic TIP:

   ```bash
   bash ./dsi.sh set_params "max_tract_count=50000&max_seed_count=50000000&tip_iteration=0"
   ```

2. Run AutoTrack with an exact name returned by `list_auto_tract`.
3. Poll until tracking is complete:

   ```bash
   bash ./dsi.sh list_tract status
   ```

4. Confirm the target has more than 10,000 tracts, preferably close to 50,000.
5. Uncheck every non-target bundle, including any whole-brain tract set.
6. Apply `trim_tract` four or five times, inspecting after each round.
7. Run `delete_repeated_tract 1` once.
8. Apply secondary `trim_tract` rounds one at a time until approximately 10,000
   clean trajectories remain. Stop earlier if the valid tract core deteriorates.

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

3. Apply dense-bundle cleanup only when appropriate.
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
