# DSI Studio AI Brain Tumor Presurgical and Postsurgical Evaluation

Use this skill only for brain-tumor presurgical planning or postsurgical structural
evaluation. General segmentation, atlas, region, AutoTrack, tract-statistics, and
rendering commands are maintained in the corresponding DSI Studio AI command files
and `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`; read those when their command details
are needed.

### Companion-manual routing

Use this skill for the tumor-specific decision logic and route command semantics to
the maintained general manuals rather than inferring them:

| Tumor workflow section | Companion manual |
|---|---|
| §1 segmentation, slice readiness, model availability, three-plane QC | `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §2–3 pathway selection and AutoTrack | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md` |
| §4 tract-to-lesion intersection | `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §5 laterality, tract statistics, and view interpretation | `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md` |
| §8 postoperative evaluation | Slice, Rendering, Region, Tract, and Fiber-Tracking manuals above |

## Workflow principle

Evaluate a tumor in this order:

1. Segment and measure tumor and edema.
2. Localize the tumor directly against `CHA` and `Brodmann` with
   `show_region_overlap_statistics`.
3. Select and map relevant named eloquent pathways with AutoTrack.
4. Convert each mapped tract to a region and measure its intersection with tumor and
   edema.
5. Compare left and right tract volume and surface area; assign lesion laterality only after anatomical verification.
6. Integrate overlap, morphology, visual anatomy, and known tractography limitations.

Do not use tumor- or edema-derived regions as ROI, Seed, ROA, End, or other tracking
constraints for standard AutoTrack. Map the named tract independently first, then
measure its spatial relationship to the lesion.

## 1. Segment and characterize the lesion

### 1.1 Input and registration preflight

Select the structural image intended for segmentation before running the model:

```bash
bash ./dsi.sh list_slice
bash ./dsi.sh set_slice <slice-index>
bash ./dsi.sh list_slice
```

When a FIB opened from Fiber Data Hub already exposes its structural MRI in
`list_slice` with status `available`, select that existing slice with `set_slice`;
do not add the same image again with `add_slice`. Poll `list_slice` until the
selected row reports `ready`.

If the selected slice reports `available` or `registering`, keep polling
`list_slice` until it reports `ready`. `ready` means loading/registration has
finished; it does not prove anatomical alignment. Inspect the structural image against
the diffusion anatomy before segmentation, even when dimensions and voxel sizes match.

Record the FIB reconstruction space, structural-image source and slice name, and the
segmentation model ID.

### 1.2 Tumor model and label definition

For this workflow, use `human_tumor` (**U-Net Studio Human Tumor Lesion V2**) by
default. It is the contrast-flexible U-Net Studio tumor model for T1w, T1w-gd, T2w,
FLAIR, and related structural MRI contrasts. `human_tumor_T1w` is the T1w-specific
lightweight alternative.

Do not use `human_tumorsynth` when separate tumor-core and edema measurements are
required; its current DSI Studio output provides a single `Tumor` region.

Confirm model availability for the selected slice with `list_unet`. Use the exact
internal model ID only when its `available` field is true, then run:

```bash
bash ./dsi.sh list_unet
bash ./dsi.sh segment_brain "human_tumor" "<slice-name-or-index>"
bash ./dsi.sh list_region
```

The expected `human_tumor` lesion labels are:

```text
Enhancing Tumor
Necrosis
Peritumoral Edema
```

`human_tumor` also emits five tissue labels. These are useful segmentation outputs but
are not lesion compartments for this workflow. Their presence means the three lesion
rows are not guaranteed to occupy any particular indices. Always resolve
`Enhancing Tumor`, `Necrosis`, and `Peritumoral Edema` by exact name from the fresh
`list_region` output; never infer their row numbers from creation order.

For this skill define:

```text
Tumor Core = Enhancing Tumor ∪ Necrosis
```

Keep `Peritumoral Edema` separate. Never silently substitute one label for another.
If an expected label is missing, report that measurement as unavailable rather than
as zero. Preserve the original segmentation labels.

Before lesion-only QC or statistics, isolate the lesion rows explicitly so tissue
labels and any pre-existing regions do not enter checked-region operations:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>"
```

For a presurgical Tumor Core, create and merge copies so the original component masks
remain untouched. Region indices change after every table mutation, so resolve each
placeholder from the immediately preceding `list_region`:

```bash
bash ./dsi.sh copy_region <current-enhancing-tumor-index>
bash ./dsi.sh list_region
bash ./dsi.sh set_region_name <enhancing-copy-index> "Tumor Core"

bash ./dsi.sh copy_region <current-necrosis-index>
bash ./dsi.sh list_region
bash ./dsi.sh merge_regions "<current-Tumor-Core-index>&<necrosis-copy-index>"
bash ./dsi.sh list_region
```

`copy_region` inserts the copy immediately after its source, shifting all later row
indices. `merge_regions` keeps the first supplied region and removes the later merged
rows. Do not construct Tumor Core if either required presurgical component is
unavailable.

### 1.3 Segmentation QC and lesion size

Inspect the segmentation in sagittal, coronal, and axial views. Center the slice on
Tumor Core for presurgical studies, or on the relevant verified abnormality when a
Tumor Core is not appropriate:

```bash
bash ./dsi.sh show_only_regions "<lesion-region-indices>"
bash ./dsi.sh move_slice_to_region <Tumor-Core-or-abnormality-index>

bash ./dsi.sh set_roi_view 0
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 1
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 2
bash ./dsi.sh preview_screen roi
```

`preview_screen roi` gives an agent a coarse text rendering plus orientation and
coverage metadata. It is useful for gross location/alignment checks but is not a
substitute for full-resolution image inspection, especially for small boundaries,
subtle enhancement, or definitive laterality. When the user requests saved QC or an
output destination is available, use `save_roi_screen` for full-resolution human
review. Do not invent a path solely to save a QC image.

When other relevant structural contrasts are available, compare the lesion against
them. Inspect remote or disconnected components far from the dominant lesion rather
than accepting them automatically. When no independent reference segmentation is
available, treat the automated segmentation as provisional and compare it against all
available relevant structural images as far as the available viewing method permits.

A successful `segment_brain` command means inference completed; it does not mean the
segmentation has passed anatomical QC. Accept the segmentation for quantitative use
only when its location and gross extent agree with the visible structural abnormality
in all three planes, the structural-to-diffusion alignment is anatomically plausible,
and any remote/disconnected component is visually justified. If agent-side text
previews are insufficient to establish this, record the limitation and route the
saved full-resolution image to human review rather than claiming definitive QC.

Immediately before lesion statistics, isolate exactly the lesion rows intended for
the table because `show_region_statistics` reports all currently checked/shown
regions:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<Tumor-Core-index>&<edema-index>"
bash ./dsi.sh show_region_statistics
```

Omit unavailable labels from the explicit list. Record, when available:

```text
Enhancing Tumor volume (mm^3)
Necrosis volume (mm^3)
Tumor Core volume (mm^3)
Peritumoral Edema volume (mm^3)
```

Keep the component measurements separate even when Tumor Core is also reported.

### 1.4 CHA localization

The human atlas is named exactly `CHA`. For this verified atlas name, do not load all
CHA labels into the Region table merely to calculate overlap. Call the nonmutating
atlas-overlap command directly on the current Tumor Core region:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> CHA
```

`show_region_overlap_statistics` maps every atlas label into the source region's
space, intersects it with the source region, discards zero-overlap labels, and returns
the ordinary region-statistics table for the nonempty intersections. Each returned
column is named by the overlapping CHA label. The source Tumor Core itself is not a
result column.

This command does **not** add, delete, rename, reorder, or modify Region-table rows.
Therefore no disposable CHA regions, intersection copies, or cleanup step is needed,
and the Tumor Core index remains valid until some other command mutates the Region
table.

Use the `volume (mm^3)` row from the overlap table and the independently measured
Tumor Core volume from Section 1.3. For each affected CHA region report:

```text
intersection volume (mm^3)
fraction of Tumor Core = intersection volume / total Tumor Core volume
```

Rank affected CHA regions by intersection volume. If edema localization is useful,
run the same direct analysis separately on the current edema region:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-edema-index> CHA
```

An atlas label with zero intersection is omitted from the table. If the source region
is nonempty, the atlas name is valid, and anatomical mapping/QC is acceptable, a
result with no atlas-label columns can represent a true absence of atlas overlap rather
than a command failure.

### 1.5 Brodmann-area involvement

The human atlas is named exactly `Brodmann`. Use the same direct nonmutating command;
do not load all Brodmann labels or use `region_action_all_inter_1st` merely to obtain
intersection statistics:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> Brodmann
```

Each nonempty returned column is an overlapping Brodmann area. Use the
`volume (mm^3)` row and report:

```text
Brodmann area
intersection volume (mm^3)
fraction of Tumor Core
```

Rank them by intersection volume. Brodmann overlap is anatomical localization, not
proof that the corresponding function is impaired. Large lesions and mass effect can
also reduce atlas-registration accuracy; inspect unexpected or small intersections
conservatively.

CHA and Brodmann are gray-matter parcellations. Their intersection volumes do not
need to sum to the total Tumor Core volume, particularly for white-matter-centered
tumors. No Region-table cleanup is needed after either direct overlap command.

Use `add_region_from_atlas` plus explicit region operations only when actual atlas
region objects are needed for visualization, editing, tracking constraints, or another
operation beyond statistics. Do not materialize atlas regions solely to reproduce the
statistics already returned by `show_region_overlap_statistics`.

## 2. Select eloquent pathways

Use these current human AutoTrack identifiers directly for the standard tumor
workflow; `list_auto_tract` is not needed for these entries.

| Function | Pathway | Left | Right |
|---|---|---|---|
| Motor | Corticospinal tract | `ProjectionBrainstem_CorticospinalTractL` | `ProjectionBrainstem_CorticospinalTractR` |
| Language | Arcuate fasciculus | `Association_ArcuateFasciculusL` | `Association_ArcuateFasciculusR` |
| Language | Superior longitudinal fasciculus | `Association_SuperiorLongitudinalFasciculusL` | `Association_SuperiorLongitudinalFasciculusR` |
| Language | Frontal aslant tract | `Association_FrontalAslantTractL` | `Association_FrontalAslantTractR` |
| Temporal language / semantic | Inferior longitudinal fasciculus | `Association_InferiorLongitudinalFasciculusL` | `Association_InferiorLongitudinalFasciculusR` |
| Vision | Optic radiation | `ProjectionBasalGanglia_OpticRadiationL` | `ProjectionBasalGanglia_OpticRadiationR` |

Use the parent superior longitudinal fasciculus entry. It maps the SLF family,
including SLF II and III, together; do not normally map SLF II and III separately for
tumor planning.

A practical selection is:

- perirolandic or motor lesion: CST;
- frontal language lesion: AF, SLF, and FAT;
- parietal language lesion: AF and SLF;
- temporal language lesion: AF and ILF;
- posterior temporal, parietal, or occipital lesion: optic radiation when vision is
  at risk.

Select pathways from the actual structural lesion location and its white-matter
extension, using CHA/Brodmann overlap only as supporting localization. Do not use a
Brodmann-area label alone to trigger a tract. For temporal lesions, AF and ILF are the
default language/semantic pathways. Add optic radiation when the lesion or edema
extends into posterior temporal or temporo-occipital white matter along the expected
optic-radiation/Meyer's-loop course, or when visual-pathway risk is specifically
relevant. If agent-side anatomy/QC is too coarse to confidently exclude posterior
temporal or temporo-occipital extension, **map the optic radiation rather than omit
it**; Section 6 already requires conservative interpretation of a negative optic-
radiation result. Do not use edema volume alone as the trigger. BA37 involvement
alone is not sufficient.

The inferior fronto-occipital fasciculus and uncinate fasciculus are optional. Map
them when lesion anatomy or the clinical question specifically makes them relevant;
do not include them routinely as core temporal-language pathways.

| Optional pathway | Left | Right |
|---|---|---|
| Inferior fronto-occipital fasciculus | `Association_InferiorFrontoOccipitalFasciculusL` | `Association_InferiorFrontoOccipitalFasciculusR` |
| Uncinate fasciculus | `Association_UncinateFasciculusL` | `Association_UncinateFasciculusR` |

If a pathway outside these tables is required, then use `list_auto_tract` to
discover its current exact identifier.

## 3. Map bilateral pathways

For every pathway selected for quantitative comparison, map the left and right
homologs with identical AutoTrack settings. Follow the AutoTrack QC, tracking-size,
tolerance, TIP, completion, and visualization guidance already maintained in
`DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`.

`run_auto_track` is asynchronous and independent bundles can be launched one after
another without waiting for the previous bundle to finish. After the desired settings
are established, issue **all selected left/right `run_auto_track` calls back-to-back**.
Do not insert a long wait or a completion poll after each individual launch.

For example, if CST and arcuate fasciculus are selected:

```bash
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractR"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusR"
```

After **all** desired AutoTrack commands have been launched, poll the full tract table
approximately every 10 seconds:

```bash
bash ./dsi.sh list_tract
```

Each requested tract row reports `running` or `done`. Continue polling about every
10 seconds until every requested AutoTrack row reports `done`; then perform dependent
operations such as `tract_to_region`, tract statistics, overlap analysis, saving, or
visualization. This grouped polling is preferred to serially waiting for each tract.
Do not repeatedly poll one bundle at very short intervals while other desired bundles
have not yet been launched.

Do not add tumor or edema constraints to AutoTrack.

If a clinically relevant named pathway remains empty after the bounded AutoTrack
retry procedure in `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`, report the pathway as
`unmappable` and record the tract count, seed limit, tolerance values, and attempts.
Do not convert an unmappable pathway into a zero-overlap result or interpret it as
anatomical absence.

If the lesion is medial, crosses the midline, or has substantial involvement in both
hemispheres, map the relevant left and right pathways and report each side directly.
Do not force an ipsilesional/contralateral designation or calculate an ipsilesional
ratio unless one side is meaningfully designated as the lesion side.

## 4. Measure direct tract overlap with tumor and edema

After AutoTrack finishes, confirm each bundle is nonempty, then use `tract_to_region`
to convert the mapped bundle into a spatial tract region. `tract_to_region` creates the
region in the **current slice space**, so record the current slice plus the resulting
region dimensions and resolution from `list_region`.

`show_tract_overlap_statistics` is for comparing one tract with a **built-in atlas**.
It does not accept an arbitrary tumor or edema region as the overlap target. Therefore
do not substitute it for the lesion-overlap workflow in this section. For tract versus
tumor/edema, `tract_to_region` followed by explicit region intersection remains the
correct operation. Use `show_tract_overlap_statistics <tract-index> <atlas-name>` only
when a separate tract-versus-atlas localization question is needed.

Preserve the original tract regions and the original lesion masks. For tract
involvement, report `Enhancing Tumor`, `Necrosis`, and `Peritumoral Edema`
separately when available. Tumor Core overlap may be added as a summary, but do not
replace the component overlaps with Tumor Core alone.

Region-table indices are not stable across mutations. After `copy_region`,
`merge_regions`, `delete_region`, `tract_to_region`, or
`add_region_from_atlas`, call `list_region` before the next command that uses a
numeric region index. Never predict the shifted index or carry a stale index across
one of these operations.

`region_action_all_inter_1st` preserves its first region but modifies every later
region in place, so lesion copies used for intersection are disposable and mandatory.
Always supply the explicit ordered region-index list for tumor overlap. Explicit
indices are used in the supplied order regardless of checked/shown state. If the index
list is omitted, DSI Studio uses only checked/shown regions in table-index order, which
may make the wrong region the first/reference region. Rename each copy before
intersection so its provenance remains clear.

### 4.1 Generic bilateral pathway command-order pattern

The following CST example applies unchanged to AF, SLF, FAT, ILF, optic radiation,
IFOF, uncinate, or another mapped bilateral pathway. It is intentionally
index-agnostic. Resolve every placeholder from the immediately preceding `list_tract`
or `list_region`; do not reuse stale indices.

```bash
bash ./dsi.sh list_tract

bash ./dsi.sh tract_to_region <right-CST-tract-index>
bash ./dsi.sh list_region

bash ./dsi.sh tract_to_region <left-CST-tract-index>
bash ./dsi.sh list_region
```

For the right CST, create one disposable copy for each available lesion compartment:

```bash
bash ./dsi.sh copy_region <enhancing-tumor-index>
bash ./dsi.sh list_region
bash ./dsi.sh set_region_name <new-index> "Right CST enhancing-tumor overlap"

bash ./dsi.sh copy_region <necrosis-index>
bash ./dsi.sh list_region
bash ./dsi.sh set_region_name <new-index> "Right CST necrosis overlap"

bash ./dsi.sh copy_region <edema-index>
bash ./dsi.sh list_region
bash ./dsi.sh set_region_name <new-index> "Right CST edema overlap"

bash ./dsi.sh region_action_all_inter_1st "<right-CST-region>&<enhancing-copy>&<necrosis-copy>&<edema-copy>"
bash ./dsi.sh show_only_regions "<right-CST-region>&<enhancing-copy>&<necrosis-copy>&<edema-copy>"
bash ./dsi.sh show_region_statistics
```

Repeat the same sequence for the left CST using newly created lesion copies. Measure
the original lesion masks separately in Section 1.3; do not use intersection masks as
the source lesion-volume measurements.

For `region_action_all_inter_1st`, the tract-derived region must be first. It defines
the output grid and transform, and later regions are mapped into that space before
being replaced by their intersections.

Use the original **same-session tract-region volume** as the denominator for every
compartment:

```text
enhancing-tumor overlap fraction =
    volume(tract region ∩ Enhancing Tumor) / original tract-region volume

necrosis overlap fraction =
    volume(tract region ∩ Necrosis) / original tract-region volume

edema overlap fraction =
    volume(tract region ∩ Peritumoral Edema) / original tract-region volume
```

Because `tract_to_region` voxelizes into the current slice grid, absolute tract-region
volumes can differ between sessions when slice space, voxel size, registration, or
tracking geometry differs. Do **not** interpret a pre/post change in absolute
`tract_to_region` volume as tract loss or gain. Within-session overlap fractions are
safer because numerator and denominator use the same voxelization. Cross-session
tract volume/surface-area comparisons should remain descriptive and must be qualified
by acquisition, reconstruction, registration, tracking, and voxelization differences.

Verify that each intersection does not exceed the original tract-region volume or its
source lesion volume apart from small resampling/voxelization differences.

A zero-volume overlap is valid only after confirming that:

- the source tract region is nonempty;
- the source lesion mask is nonempty;
- both belong to the same subject and valid mapping context;
- the intersection operation completed successfully.

Otherwise report the overlap as unavailable or not computable rather than zero.

### 4.2 3D overlap QC

After bilateral overlap statistics are recorded, inspect the relevant tracts and
lesion/intersection regions together. Reset the camera explicitly before a recorded
3D QC view; do not omit the third `set_view` argument because omission toggles the
flip state:

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_only_regions "<lesion-and-overlap-region-indices>"
bash ./dsi.sh set_view 0 0
bash ./dsi.sh preview_screen 3d
```

If an oblique view is useful, start from the same explicit `set_view 0 0` and apply
the same `rotate` commands in each session. For pre/post comparison, use the identical
camera recipe in both windows so superior/inferior or flipped views are not compared
accidentally.

Preserve the original lesion masks, original tract bundles, and tract-derived regions.
After statistics and 3D QC are recorded, delete only disposable intersection copies if
cleanup is needed.

Treat a one-voxel or few-voxel intersection as resampling/partial-volume sensitive.
For a clinically important small intersection, center on the intersection and inspect
all three slice planes before interpreting it:

```bash
bash ./dsi.sh show_only_regions "<tract-region>&<small-intersection-region>"
bash ./dsi.sh move_slice_to_region <small-intersection-region>
bash ./dsi.sh set_roi_view 0
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 1
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 2
bash ./dsi.sh preview_screen roi
```

If it remains only a tiny boundary contact, report it as a trace or borderline
overlap rather than treating it as strong evidence of pathway involvement. Do not use
a universal voxel-count threshold.

A nonzero intersection establishes spatial overlap between the reconstructed pathway
and the segmented abnormality. It does not establish histologic infiltration or
functional loss.

## 5. Compare left and right tract morphology

First report raw left and right measurements without assigning lesion side:

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_tract_statistics
```

Record for each side:

```text
total volume(mm^3)
total surface area(mm^2)
```

Verify lesion laterality from the structural anatomy and segmented lesion before
labeling either tract ipsilesional or contralateral. Use the same centered three-plane
inspection from Section 1.3. `preview_screen roi` reports `R_side=left` or
`R_side=right`, but its digit-grid image is coarse; do not treat the text thumbnail
alone as definitive laterality evidence.

When the lesion side is clear in the structural anatomy, use `R_side` orientation
metadata to translate screen position into anatomical right/left. Atlas suffixes such
as `_R`/`_L`, the known left/right AutoTrack identifier, MNI-coordinate sign, and
tract geometry may corroborate the assignment. If the text preview is ambiguous or
these cues disagree, keep results labeled simply `left` and `right`, do not calculate
an ipsilesional ratio, and request/save a full-resolution `save_roi_screen` for human
review when an output destination is available.

For medial, midline, or bilateral lesions, keep the results as left/right and do not
force an ipsilesional ratio.

When one side is meaningfully designated as the lesion side, optionally calculate:

```text
volume ratio = ipsilesional volume / contralateral volume
surface-area ratio = ipsilesional surface area / contralateral surface area
```

Reduced ipsilesional volume or surface area may support pathway involvement when it
agrees with lesion overlap and visible tract distortion. Do not interpret the
bilateral ratio alone. For longitudinal pre/post studies, do not interpret change in
these ratios as direct biological tract loss/gain without considering acquisition,
reconstruction, registration, and tracking differences.

The contralateral tract is an internal reference, not a symmetric ground truth.
Normal tract asymmetry can be substantial. This is particularly important for the
arcuate fasciculus, which commonly shows leftward structural asymmetry. A smaller
right AF than left AF can therefore be normal. Do not use a universal bilateral-ratio
threshold.

## 6. Optic-radiation caution

Interpret the optic radiation more conservatively than the other core pathways.
The anterior optic radiation, particularly Meyer's loop, is difficult to reconstruct
reliably and varies substantially between individuals.

Do not treat the most anterior reconstructed streamline as the true anterior
anatomical boundary. For temporal-lobe planning, assume Meyer's loop may extend
anterior to the tractography result.

A positive reconstructed overlap with tumor or edema is meaningful structural
evidence. Absence of reconstructed overlap near the anterior temporal lobe does not
reliably exclude involvement of Meyer's loop.

Prefer wording such as:

> The reconstructed optic radiation lies posterior to the lesion. The anterior extent
> of Meyer's loop is incompletely determined by tractography and may extend further
> anteriorly than the reconstructed streamlines.

## 7. Integrate the presurgical evaluation

Report results in this order:

```text
Lesion
  enhancing-tumor volume
  necrosis volume
  Tumor Core volume
  Peritumoral Edema volume
  hemisphere or bilateral/midline description

CHA localization
  region — intersection volume — fraction of Tumor Core

Brodmann involvement
  area — intersection volume — fraction of Tumor Core

Eloquent pathway
  pathway
  enhancing-tumor overlap volume and fraction
  necrosis overlap volume and fraction
  edema overlap volume and fraction
  left tract volume
  right tract volume
  left surface area
  right surface area
  verified lesion side, when applicable
  volume ratio, when applicable
  surface-area ratio, when applicable
  visual relationship
  interpretation
```

Describe pathways as displaced, compressed, traversing tumor, traversing edema,
incompletely reconstructed, or grossly preserved. Do not convert structural findings
alone into categorical statements that a tract is destroyed, functionally intact, or
safe to resect.

## 8. Postsurgical evaluation

For postoperative studies, define the relevant postoperative abnormality from
verified anatomy: residual tumor, resection cavity, postoperative edema, or other
treatment-related change. Automated tumor segmentation may not correctly define a
resection cavity.

Do not automatically construct the presurgical Tumor Core after surgery. Analyze
`Enhancing Tumor`, `Necrosis`, and `Peritumoral Edema` separately when those
model labels are present, and construct a postoperative composite only when the
verified anatomy gives that composite a clear meaning. In particular, do not treat a
resection cavity as tumor necrosis merely because the model assigns that label.

If postoperative imaging does not independently establish the identity of an
abnormality, preserve the model labels (`Enhancing Tumor`, `Necrosis`, and
`Peritumoral Edema`) verbatim and report them as provisional model outputs. Do not
derive a resection cavity from the `Necrosis` label. If a resection cavity has been
independently verified, or a user-supplied or manually created cavity mask is
available, preserve the model outputs and analyze the cavity as a separate region. If
the available imaging cannot distinguish cavity, residual tumor, and other
postoperative change, stop the anatomical interpretation at `unresolved postoperative
abnormality` rather than inventing a derived cavity or residual-tumor mask.

### 8.1 Postoperative centering and QC

Use the same three-plane QC pattern as Section 1.3. Choose the centering target in
this order when available and anatomically verified:

1. verified resection cavity or other user-supplied postoperative target;
2. verified residual enhancing tumor;
3. the dominant anatomically plausible postoperative abnormality.

Do not choose `Necrosis` merely because it is present or large, and do not relabel it
as cavity unless cavity identity is independently established. When only provisional
model labels are available, one may be used as a navigation target while retaining its
original label and explicitly stating that its postoperative identity is unresolved.

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<relevant-postoperative-region-indices>"
bash ./dsi.sh move_slice_to_region <verified-or-provisional-centering-target>
bash ./dsi.sh set_roi_view 0
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 1
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 2
bash ./dsi.sh preview_screen roi
```

Apply the same coarse-preview limitation from Section 1.3: if the text view cannot
resolve anatomy sufficiently, do not upgrade a provisional label to a definitive
postoperative diagnosis; use full-resolution human review when available.

### 8.2 Pre/post lesion measurements

For model labels that are meaningfully comparable across sessions, report the raw
preoperative and postoperative values side by side:

```text
label
preoperative volume (mm^3)
postoperative volume (mm^3)
absolute change (mm^3)
```

A change in `Enhancing Tumor`, `Necrosis`, or `Peritumoral Edema` is a descriptive
segmentation finding. Do not infer progression, residual tumor, cavity size,
treatment effect, or biologic response from the volume change alone. Registration,
contrast timing, surgical change, hemorrhage, susceptibility, treatment effect,
segmentation behavior, and acquisition differences can all alter these measurements.

Map the same bilateral eloquent pathways with comparable acquisition,
reconstruction, and AutoTrack settings when possible. Repeat tract-to-region
intersection and bilateral tract-statistics analysis. Use same-session tract-region
volumes as overlap denominators and apply the cross-session voxelization caution from
Section 4.1. Repeat CHA or Brodmann localization only when it answers the postoperative
question; when needed, use the direct `show_region_overlap_statistics` workflow from
Sections 1.4-1.5 rather than materializing atlas labels.

For pre/post 3D tract/lesion comparison, use the same explicit camera recipe in both
sessions, beginning with `set_view 0 0` and applying identical rotations before
`preview_screen 3d` or a saved rendering.

Changes after surgery can reflect resection, decompression, edema resolution,
hemorrhage, susceptibility artifact, altered diffusion signal, registration, or
acquisition differences. A newly visible postoperative tract can reflect improved
tractability rather than newly preserved fibers.

## 9. Reproducibility outputs

Preserve or record:

- FIB source and reconstruction space;
- structural-image source, selected slice, registration/QC status, and model ID;
- original lesion labels and any derived Tumor Core region;
- CHA and Brodmann intersection statistics;
- bilateral named-tract results used for interpretation, recorded in the report and
  saved when the user supplied or selected an output destination;
- tract statistics and tract/lesion intersection statistics;
- the current slice/grid used for each `tract_to_region` quantitative overlap;
- the exact `set_view`/rotation recipe used for comparable 3D captures;
- interpretable segmentation and tract QC views;
- any manual segmentation corrections or exclusions.

For agent-side QC, `preview_screen roi` and `preview_screen 3d` are valid recorded
**coarse** inspection views and do not require a filesystem destination. They should
not be described as equivalent to full-resolution visual inspection. When the user
requests saved images or supplies an output location, use the documented
`save_roi_screen`/`save_lr_screen` commands for human review. When a tract output
destination is available, save the interpreted bundle with:

```bash
bash ./dsi.sh save_tract "<provided-output-path>" <bundle-index>
```

Do not invent an output path merely to satisfy this reproducibility section.

Distinguish successful command execution from an anatomically accepted result in the
final record.

## Interpretation references

- Yeh FC, Irimia A, Bastos DCA, Golby AJ. Tractography methods and findings in brain
  tumors and traumatic brain injury. NeuroImage. 2021;245:118651.
- Yeh FC. Shape analysis of the human association pathways. NeuroImage.
  2020;223:117329.
- Essayed WI, Zhang F, Unadkat P, et al. White matter tractography for neurosurgical
  planning: a topography-based review of the current state of the art. NeuroImage:
  Clinical. 2017;15:659-672.

Use current DSI Studio AI documentation and live command output as the authority for
software behavior.
