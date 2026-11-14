# DSI Studio Fiber-Tracking Guide for AI Agents

Use `bash ./dsi.sh <command> [parameters...]` (always with `bash`). A successful `open_fib` returns
`tracking window created, id: tracking...` and selects that `tracking<hex-address>` window; use
`set_window` only to switch to another open tracking window (`list_window` confirms or discovers IDs).

A streamline is a computational trajectory along reconstructed orientations, not an observed axon or a
connectivity-strength measure. Anatomical validity needs source QC, justified settings, explicit region
logic, and visual inspection. Differential tractography has its own guide:
`DSI_STUDIO_AI_SKILL_DIFFERENTIAL_TRACTOGRAPHY.md`.

**Examples.** Offer an already-reconstructed FZ from the
[example dataset catalog](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md): **SCA2
`sub-control01_ses-01_dwi.gqi.fz`** for basic tracking, **UPenn GBM `sub-100_dwi.gqi.fz`** for
tumor-aware tracking (with matched structural NIfTI and segmentation). One small subject, approval
before download, and geometry/quality inspection before interpreting pathways. Tutorials:
https://www.youtube.com/watch?v=xyFNXB9nJ90, https://www.youtube.com/watch?v=oJK8jwTHVhc,
https://www.youtube.com/watch?v=V2pxI2tooPs

## Choose the workflow

| Goal | Approach |
|---|---|
| Data/reconstruction QC | Whole-brain tracking |
| Standard named pathway | AutoTrack when the atlas contains it |
| Custom or distorted pathway | Manual Seed/ROI/ROA constraints |
| Region-to-region connectivity | End-region constraints |
| Cohort standardization | AutoTrack with fixed settings and QC |

Start with whole-brain tracking: major pathways should be coherent, plausibly symmetric, and free of
systematic flips. If many bundles fail, check acquisition, reconstruction, b-table, orientation, and
mask before changing tract-specific regions.

## Tracking parameters

Start from defaults and change one setting at a time for a documented reason, never until a
desired-looking tract appears. Inspect first with `bash ./dsi.sh list_param tracking`; change e.g. with
`bash ./dsi.sh set_params "fa_threshold=0.08&min_length=20"`.

| Parameter | Lower | Higher | Rule |
|---|---|---|---|
| Tracking threshold | Extends into uncertain tissue | Stops earlier, may miss low-anisotropy fibers | Change only for widespread premature stopping or excessive low-anisotropy tracking |
| Angular threshold | Straighter, conservative | Sharper curves, more false turns | Match expected anatomy |
| Step size | Finer, slower | Coarser, faster | Default or a validated voxel-aware protocol |
| Smoothing | Follows local directions | Directional persistence | Trajectory regularization, not display smoothing |
| Minimum length | Keeps short/noisy fragments | Also removes short valid pathways | Match expected anatomy |
| Maximum length | Allows long trajectories | Limits loops and erroneous continuation | Plausible anatomical bound |

Tract count is accepted streamlines; seed count limits attempts. Neither represents axons or
connection strength.

## Build regions from anatomy

Prefer segmentation to drawing: segment an aligned T1w in the tracking window (else the isotropic
diffusion image `iso`), select and merge labels into the needed regions, inspect boundaries and
registration in all three planes, and give every region an explicit role and anatomical purpose. Many
models are modality agnostic, but successful inference does not prove anatomical validity.

| Role | Effect |
|---|---|
| Seed | Starts trajectories |
| ROI | Keeps trajectories passing through it |
| ROA | Rejects trajectories entering it |
| End | Requires termination in it |
| Terminative | Stops propagation when reached |
| NotEnd | Rejects termination in it |
| Limiting | Constrains propagation to it |

Seed and ROI are not interchangeable; multiple inclusive ROIs usually mean AND. Avoid oversized regions
that capture adjacent pathways, undersized ones that miss anatomy or registration variation, and ROAs
intersecting valid fibers. Spatial overlap alone does not establish tract identity: unrelated
trajectories cross the same voxels.

## Manual tracking

For distorted anatomy, lesions, pathways absent from the atlas, or a required explicit definition:

```bash
bash ./dsi.sh list_param tracking
bash ./dsi.sh list_region          # only after regions were created/loaded/segmented; a new FIB has none
bash ./dsi.sh run_tracking "CST" "0:3&1:0&2:1"
```

Entries are `region-index:role` joined by `&`; roles `0=ROI`, `1=ROA`, `2=End`, `3=Seed`,
`4=Terminative`, `5=NotEnd`, `6=Limiting`. Record the Seed, ROI, ROA, endpoint, and Terminative logic,
and inspect the initial bundle before adding filters or exclusions.

## AutoTrack

For standard named pathways and reproducible cohorts. Normally discover exact identifiers with
`bash ./dsi.sh list_auto_tract`; a task skill may supply verified identifiers and waive discovery for
them. Names are underscore-separated hierarchical prefixes (`Association_*`, `ProjectionBrainstem_*`,
`Commissure_*`); never guess or use shorthand such as `Corticospinal Tract`. For a whole tract family
use the parent (the whole left cingulum is `Association_CingulumL`, not an `Association_CingulumL_...`
child; likewise the corpus callosum parent); choose a child only for a requested subdivision or branch.

`run_auto_track` is asynchronous: launch **all** requested bundles with the same settings first, then
poll the full table about every 10 s until every row is `done` (no per-bundle waiting or rapid
polling). Only then run anything depending on finished geometry or indices (statistics,
`tract_to_region`, saving, editing, overlap, visualization).

```bash
bash ./dsi.sh set_params "max_tract_count=10000&max_seed_count=50000000&tip_iteration=4"
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractR"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusR"
bash ./dsi.sh list_tract   # each row running or done
```

Starting point for a named bundle: tract limit 10,000, seed limit 50,000,000 (stops low-yield pathways
from running indefinitely), TIP 3–4. Named bundles carry built-in anatomical constraints, so add
ROI/ROA/END/NotEND/Limiting/Terminative regions only for a specific question such as isolating a minor
branch.

**Zero-tract retry (bounded).** Record `list_param tracking` and `list_tract` first. The batch
implementation tries three tolerances: default, default + one subject voxel size, default + two (human
template default 24 mm, so 24, 26, 28 mm for 2-mm isotropic data; scale by the actual voxel size, and
never invent it if metadata lack it). Use `set_param tolerance <value>` and rerun the same identifier;
for one bundle wait for each result before advancing, and for several bundles at the same tolerance
launch the retries back-to-back and poll together. Stop after these attempts: report the pathway as
unmappable with seed limit, tolerances, and counts; zero yield does not prove the pathway is absent. If
many pathways fail, investigate data quality, b-table/orientation, reconstruction, and mapping instead
of relaxing tolerance. Larger tolerance accepts more variation and false positives; smaller may reject
distorted anatomy. To tell registration failure from tracking failure, run file-based AutoTrack with
`--debug=1 --overwrite=1` ("AutoTrack diagnostics" in `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md`),
which saves the warped template and atlas plus a per-attempt table without changing the result.

## Atlas-overlap statistics

For overlap with a **built-in atlas**, use the nonmutating commands (exact atlas name required for AI;
verify it with `list_atlas`):

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <region-index> <exact-atlas-name>
bash ./dsi.sh list_tract
bash ./dsi.sh show_tract_overlap_statistics <tract-index> <exact-atlas-name>
```

They report only labels with nonzero intersection as a normal region-statistics table (the source
region/tract is not a result column) and never create, delete, rename, reorder, or modify Region rows,
avoiding the index churn and cleanup of `add_region_from_atlas` + `region_action_all_inter_1st`. Use
`add_region_from_atlas` only when real atlas regions are needed for display, editing, tracking
constraints, or mask operations. For tract overlap with a tumor, edema, resection cavity, or other
ordinary mask, use `tract_to_region` and region operations instead.

## Bundle cleanup

TIP is bundle-level cleanup for a visually coherent bundle (AutoTrack, loaded, or recognized). With
roughly 5,000–10,000+ tracts before pruning, 3–4 iterations are normally desired; do not disable TIP
just to maximize tract count, and skip it only to examine an unpruned bundle or when the bundle is too
sparse. Never routinely apply TIP or repeated-trajectory deletion to whole-brain tractography (many
pathways, not one bundle). AutoTrack applies `tip_iteration` itself; for an existing bundle apply one
iteration at a time with `bash ./dsi.sh trim_tract <bundle-index>` and inspect. Remove near-duplicates
from checked coherent bundles only when needed with `bash ./dsi.sh delete_repeated_tract 1`, after
unchecking non-target bundles. Both modify bundles: preserve the original or get user approval when
cleanup must stay recoverable.

## Result cleanup and visualization

When every requested `list_tract` row is `done`:

1. Read final bundle indices and counts; apply cleanup only when appropriate.
2. `bash ./dsi.sh color_all_cluster` (distinct colors).
3. `bash ./dsi.sh check_tract <whole-brain-index> 0` (hide whole-brain; never obscure mapped bundles).
4. `bash ./dsi.sh show_only_tracts <target-index>`.
5. `bash ./dsi.sh set_param show_slice 0`.
6. `bash ./dsi.sh add_surface 0 25` (subject-mapped white-matter context).

Pick a useful view per bundle rather than one camera; e.g. the left arcuate from view 0 in small
increments, then verify orientation and capture several oblique views:

```bash
bash ./dsi.sh set_view 0 0
bash ./dsi.sh rotate "15 1 0 0"
bash ./dsi.sh rotate "20 0 1 0"
```

## Quality control

| Observation | Check or response |
|---|---|
| Most tracts stop early | Reconstruction, mask, tracking threshold |
| Tracts enter gray matter or CSF | Threshold may be too low |
| Expected curve missing | ROI placement and local orientations before raising angle |
| Implausible sharp turns | Lower angular threshold; inspect crossings |
| Fragmented bundle | Sampling, threshold, restrictive regions, minimum length |
| Many unrelated branches | Region size, waypoint logic, conservative ROAs |
| Bundle vanishes after ROA | ROA likely intersects valid anatomy |
| TIP removes nearly everything | Bundle too sparse or settings poor |
| AutoTrack takes too long | Low yield; keep a finite seed limit |
| Many AutoTrack pathways fail | Data, b-table, orientation, or reconstruction |
| One pathway fails | Yield, tolerance, or anatomical distortion |

Endpoint tracking is sensitive to gray-white segmentation, gyral bias, anisotropy near cortex, and
endpoint-mask extent; failing to reach cortex does not prove a connection is absent.

## Reproducibility

Record: source FIB and reconstruction space; tracking method, index, threshold, angle, step size,
smoothing; min/max length and stopping criteria; tract and seed limits; every region's name, source,
space, role, and purpose; AutoTrack identifier, tolerance, TIP iterations; repeated-tract threshold and
other cleanup; random seed when exact repeatability is required; output files and QC findings.
