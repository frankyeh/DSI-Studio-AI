# DSI Studio AI Brain Tumor Presurgical and Postsurgical Evaluation

Use this skill only for brain-tumor presurgical planning or postsurgical structural
evaluation. Use the general command manuals for exact command semantics rather than
inferring behavior.

### Companion-manual routing

| Tumor workflow section | Companion manual |
|---|---|
| §1 segmentation, slice readiness, model availability, three-plane QC | `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §2–3 pathway selection and AutoTrack | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md` |
| §4 tract-to-lesion connectivity | `DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §5 laterality, tract statistics, and view interpretation | `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md` |
| §8 postoperative evaluation | Slice, Rendering, Region, Tract, T2R, and Fiber-Tracking manuals above |

## Workflow principle

Evaluate a tumor in this order:

1. Segment and measure tumor and edema.
2. Localize the tumor directly against `CHA` and `Brodmann` with
   `show_region_overlap_statistics`.
3. Select and map relevant named eloquent pathways with AutoTrack.
4. Measure tract-to-region connectivity between each mapped pathway and the lesion
   regions using T2R, reporting intersecting streamline count and fraction of the
   tract bundle.
5. Compare left and right tract morphology; assign lesion laterality only after
   anatomical verification.
6. Integrate tract-to-lesion involvement, morphology, anatomy, and known tractography
   limitations.

Do not use tumor- or edema-derived regions as ROI, Seed, ROA, End, or other tracking
constraints for standard AutoTrack. Map the named tract independently first, then
measure its relationship to the lesion.

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

`ready` means loading/registration has finished; it does not prove anatomical
alignment. Inspect the structural image against the diffusion anatomy before
segmentation. Record the FIB reconstruction space, structural-image source and slice
name, and segmentation model ID.

### 1.2 Tumor model and label definition

Use `human_tumor` (**U-Net Studio Human Tumor Lesion V2**) by default. It is the
contrast-flexible tumor model for T1w, T1w-gd, T2w, FLAIR, and related structural MRI
contrasts. `human_tumor_T1w` is the T1w-specific lightweight alternative.

Do not use `human_tumorsynth` when separate tumor-core and edema measurements are
required; its current DSI Studio output provides a single `Tumor` region.

Confirm model availability for the selected slice with `list_unet`. Use the exact
internal model ID only when its `available` field is true:

```bash
bash ./dsi.sh list_unet
bash ./dsi.sh segment_brain "human_tumor" "<slice-name-or-index>"
bash ./dsi.sh list_region
```

The expected lesion labels are:

```text
Enhancing Tumor
Necrosis
Peritumoral Edema
```

`human_tumor` also emits five tissue labels. These are not lesion compartments for
this workflow and can shift the lesion-row indices. Always resolve lesion rows by
exact name from a fresh `list_region`; never infer their indices from creation order.

For this skill define:

```text
Tumor Core = Enhancing Tumor ∪ Necrosis
```

Keep `Peritumoral Edema` separate. If an expected label is missing, report that
measurement as unavailable rather than zero. Preserve the original segmentation
labels.

Before lesion-only QC or statistics, isolate the intended lesion rows:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>"
```

For a presurgical Tumor Core, create and merge copies so the original component masks
remain untouched. Re-resolve indices after every mutation:

```bash
bash ./dsi.sh copy_region <current-enhancing-tumor-index>
bash ./dsi.sh list_region
bash ./dsi.sh set_region_name <enhancing-copy-index> "Tumor Core"

bash ./dsi.sh copy_region <current-necrosis-index>
bash ./dsi.sh list_region
bash ./dsi.sh merge_regions "<current-Tumor-Core-index>&<necrosis-copy-index>"
bash ./dsi.sh list_region
```

`copy_region` inserts the copy immediately after its source and shifts later indices.
`merge_regions` keeps the first supplied region and removes the later merged rows. Do
not construct Tumor Core if either required component is unavailable.

### 1.3 Segmentation QC and lesion size

Inspect sagittal, coronal, and axial views. Center on Tumor Core for presurgical
studies, or on the relevant verified abnormality when Tumor Core is not appropriate:

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

`preview_screen roi` is a coarse text rendering plus orientation/coverage metadata.
Use it for gross location and alignment checks, not as a substitute for full-resolution
image inspection. If the text preview is insufficient for a clinically important
boundary or laterality decision, record the limitation and use `save_roi_screen` for
human review when the user supplied or requested an output destination. Do not invent
an output path solely for QC.

A successful `segment_brain` means inference completed; it does not establish
anatomical validity. Accept a segmentation for quantitative use only when gross lesion
location/extent and structural-to-diffusion alignment are plausible. Inspect remote or
disconnected components rather than accepting them automatically.

Immediately before lesion statistics, isolate exactly the intended lesion rows because
`show_region_statistics` uses currently checked/shown regions:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<Tumor-Core-index>&<edema-index>"
bash ./dsi.sh show_region_statistics
```

Omit unavailable labels. Record when available:

```text
Enhancing Tumor volume (mm^3)
Necrosis volume (mm^3)
Tumor Core volume (mm^3)
Peritumoral Edema volume (mm^3)
```

### 1.4 CHA localization

The human atlas is named exactly `CHA`. Do not load CHA labels into the Region table
merely to calculate overlap:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> CHA
```

The command maps atlas labels into the source region space, returns ordinary region
statistics for nonempty intersections, omits zero-overlap labels, and does not mutate
the Region table.

For each affected CHA region report:

```text
intersection volume (mm^3)
fraction of Tumor Core = intersection volume / total Tumor Core volume
```

If edema localization is useful, run it separately on the edema region.

### 1.5 Brodmann-area involvement

Use the same nonmutating workflow with the atlas named exactly `Brodmann`:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> Brodmann
```

Report each nonempty area with intersection volume and fraction of Tumor Core. Treat
Brodmann overlap as anatomical localization, not proof of functional impairment.
CHA and Brodmann are gray-matter parcellations, so their intersection volumes need not
sum to total Tumor Core volume, especially for white-matter-centered lesions.

Use `add_region_from_atlas` only when actual atlas region objects are needed for
visualization, editing, tracking constraints, or another downstream operation.

## 2. Select eloquent pathways

Use these verified human AutoTrack identifiers directly for the standard tumor
workflow; `list_auto_tract` is not needed for these entries.

| Function | Pathway | Left | Right |
|---|---|---|---|
| Motor | Corticospinal tract | `ProjectionBrainstem_CorticospinalTractL` | `ProjectionBrainstem_CorticospinalTractR` |
| Language | Arcuate fasciculus | `Association_ArcuateFasciculusL` | `Association_ArcuateFasciculusR` |
| Language | Superior longitudinal fasciculus | `Association_SuperiorLongitudinalFasciculusL` | `Association_SuperiorLongitudinalFasciculusR` |
| Language | Frontal aslant tract | `Association_FrontalAslantTractL` | `Association_FrontalAslantTractR` |
| Temporal language / semantic | Inferior longitudinal fasciculus | `Association_InferiorLongitudinalFasciculusL` | `Association_InferiorLongitudinalFasciculusR` |
| Vision | Optic radiation | `ProjectionBasalGanglia_OpticRadiationL` | `ProjectionBasalGanglia_OpticRadiationR` |

Use the parent SLF entry rather than mapping SLF II/III separately for routine tumor
planning.

A practical selection is:

- perirolandic or motor lesion: CST;
- frontal language lesion: AF, SLF, FAT;
- parietal language lesion: AF, SLF;
- temporal language lesion: AF, ILF;
- posterior temporal, parietal, or occipital lesion: optic radiation when visual
  pathway risk is relevant.

For temporal lesions, add optic radiation when lesion or edema extends into posterior
temporal or temporo-occipital white matter. If agent-side anatomy/QC is too coarse to
confidently exclude such extension, map optic radiation rather than omit it; Section 6
already requires conservative interpretation of a negative result. Do not use edema
volume alone as the trigger, and do not use a Brodmann label alone to trigger a tract.

Optional pathways:

| Pathway | Left | Right |
|---|---|---|
| Inferior fronto-occipital fasciculus | `Association_InferiorFrontoOccipitalFasciculusL` | `Association_InferiorFrontoOccipitalFasciculusR` |
| Uncinate fasciculus | `Association_UncinateFasciculusL` | `Association_UncinateFasciculusR` |

If another pathway is required, use `list_auto_tract` to discover its exact identifier.

## 3. Map bilateral pathways

Map left and right homologs with identical AutoTrack settings. Follow the AutoTrack
QC, tolerance, TIP, and retry guidance in
`DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`.

`run_auto_track` is asynchronous. When several bundles are needed with the same
settings, launch all selected calls back-to-back without waiting for each one:

```bash
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractR"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusR"
```

After all desired AutoTrack calls are launched, poll the full tract table about every
10 seconds:

```bash
bash ./dsi.sh list_tract
```

Continue until every requested tract row reports `done`. Only then perform dependent
statistics, T2R, saving, editing, or visualization. Do not serially wait for each
bundle before launching the next.

If a clinically relevant pathway remains empty after the bounded tolerance retry
procedure, report it as `unmappable` with tract count, seed limit, tolerance values,
and attempts. Do not interpret zero yield as anatomical absence or as zero lesion
involvement.

## 4. Measure tract-to-lesion involvement with T2R

Use **tract-to-region connectivity (T2R)** for quantitative tract-versus-lesion
involvement. Do not convert each tract into a voxel region merely to calculate tumor or
edema involvement.

`show_t2r` operates on the currently checked/shown tract bundles and checked/shown
regions. For each tract bundle it identifies the streamlines that pass through each
region and reports ordinary tract statistics for that passing subset. Therefore the
`number of tracts` row under each lesion column is the number of reconstructed
streamlines from that bundle that intersect the lesion region.

The lesion regions are mapped into the FIB diffusion grid internally for this
calculation. This avoids creating tract-derived regions, avoids current-slice
voxelization, and does not require lesion copies or binary region intersections.

### 4.1 T2R command pattern

After all selected AutoTrack bundles are complete:

```bash
bash ./dsi.sh list_tract
bash ./dsi.sh list_region
```

Select all tract bundles that should be analyzed and exactly the lesion compartments
that should be targets:

```bash
bash ./dsi.sh show_only_tracts "<tract-index-1>&<tract-index-2>&..."
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>"
bash ./dsi.sh show_t2r
```

If Tumor Core exists and a summary measure is useful, include its current index as an
additional T2R target. Keep the component regions as separate columns.

One `show_t2r` call can analyze several checked tract bundles. The output identifies
individual tract bundles and gives a T2R table for each, so there is no need to repeat
the call once per tract unless a narrower display is useful.

No `tract_to_region`, `copy_region`, `region_action_all_inter_1st`, or disposable
intersection masks are needed for this quantitative step.

### 4.2 Report the streamline involvement fraction

For each tract bundle and each lesion compartment, record:

```text
intersecting streamline count = T2R "number of tracts" for that lesion region

total bundle streamline count = tract count from list_tract or show_tract_statistics

lesion involvement fraction =
    intersecting streamline count / total bundle streamline count
```

For example:

```text
Tumor Core involvement fraction =
    number of bundle streamlines intersecting Tumor Core /
    total number of streamlines in the bundle
```

Use the total count from the **same completed bundle** as the denominator. A streamline
that passes through more than one lesion compartment can contribute to each relevant
column, so Enhancing Tumor, Necrosis, edema, and Tumor Core fractions are not expected
to sum to one.

Do not call this an `overlap volume`. T2R answers a different question: what fraction
of the reconstructed pathway intersects the lesion region?

`show_t2r` may report additional generic tract or coverage metrics. For this tumor
workflow, use the `number of tracts` row for the numerator. Do **not** use T2R's generic
`intersect ratio` as the bundle streamline fraction; calculate the fraction explicitly
from the passing-streamline count divided by the total bundle streamline count.

A zero T2R count is valid only after confirming that the source tract bundle is
nonempty, the lesion region is nonempty, both belong to the same subject/mapping
context, and T2R completed successfully. Otherwise report the result as unavailable or
not computable rather than zero.

### 4.3 Spatial QC of T2R findings

T2R provides the quantitative passing-streamline result but does not replace spatial
QC. Inspect the tract and lesion together without manufacturing an intersection mask:

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_only_regions "<relevant-lesion-region-indices>"
bash ./dsi.sh set_view 0 0
bash ./dsi.sh preview_screen 3d
```

For comparable pre/post captures, use the same explicit `set_view 0 0` and identical
rotations in both sessions.

When a very small number or fraction of streamlines intersects a clinically important
lesion compartment, treat the finding as trace/borderline until spatially reviewed.
Center on that lesion region and inspect all three planes with the relevant tract shown:

```bash
bash ./dsi.sh show_only_tracts <tract-index>
bash ./dsi.sh show_only_regions <lesion-region-index>
bash ./dsi.sh move_slice_to_region <lesion-region-index>
bash ./dsi.sh set_roi_view 0
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 1
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 2
bash ./dsi.sh preview_screen roi
```

A nonzero T2R count establishes spatial intersection between reconstructed streamlines
and the segmented abnormality. It does not establish histologic infiltration,
functional loss, or safe/unsafe resection.

## 5. Compare left and right tract morphology

First report raw left and right tract measurements without assigning lesion side:

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_tract_statistics
```

Record for each side:

```text
total number of tracts
total volume(mm^3)
total surface area(mm^2)
```

The `number of tracts` value is also the denominator used for the T2R involvement
fractions in Section 4 when it refers to the same completed bundle.

Verify lesion laterality from structural anatomy and the segmented lesion before
labeling either tract ipsilesional or contralateral. `preview_screen roi` reports
`R_side=left` or `R_side=right`, but its digit-grid image is coarse; do not treat the
text thumbnail alone as definitive laterality evidence.

When lesion side is clear anatomically, use orientation metadata to translate screen
position into anatomical right/left. Atlas suffixes such as `_R`/`_L`, known
left/right AutoTrack identifiers, MNI-coordinate sign, and tract geometry may
corroborate the assignment. If cues disagree or the preview is ambiguous, keep results
labeled `left` and `right`, do not calculate an ipsilesional ratio, and use
full-resolution human review when available.

For medial, midline, or bilateral lesions, retain left/right reporting and do not force
an ipsilesional designation.

When one side is meaningfully designated as the lesion side, optional morphology
ratios are:

```text
volume ratio = ipsilesional volume / contralateral volume
surface-area ratio = ipsilesional surface area / contralateral surface area
```

Do not interpret these ratios alone. Normal tract asymmetry can be substantial,
particularly for the arcuate fasciculus. In longitudinal studies, changes in tract
count, volume, surface area, or bilateral ratios remain descriptive and can reflect
acquisition, reconstruction, registration, tractability, or tracking differences.

## 6. Optic-radiation caution

Interpret optic radiation more conservatively than the other core pathways. The
anterior optic radiation, particularly Meyer's loop, is difficult to reconstruct
reliably and varies substantially between individuals.

Do not treat the most anterior reconstructed streamline as the true anatomical
boundary. A positive T2R intersection with tumor or edema is meaningful structural
evidence, but absence of reconstructed intersection near the anterior temporal lobe
does not reliably exclude involvement of Meyer's loop.

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
  total bundle streamline count
  enhancing-tumor intersecting streamline count and fraction
  necrosis intersecting streamline count and fraction
  edema intersecting streamline count and fraction
  Tumor Core intersecting streamline count and fraction, when used
  left tract volume
  right tract volume
  left surface area
  right surface area
  verified lesion side, when applicable
  morphology ratios, when applicable
  spatial relationship
  interpretation
```

Describe pathways as displaced, compressed, intersecting tumor, intersecting edema,
incompletely reconstructed, or grossly preserved. Do not convert structural findings
alone into categorical statements that a tract is destroyed, functionally intact, or
safe to resect.

## 8. Postsurgical evaluation

For postoperative studies, define the relevant postoperative abnormality from verified
anatomy: residual tumor, resection cavity, postoperative edema, or other treatment-
related change. Automated tumor segmentation may not correctly define a resection
cavity.

Do not automatically construct the presurgical Tumor Core after surgery. Analyze
`Enhancing Tumor`, `Necrosis`, and `Peritumoral Edema` separately when present, and
construct a postoperative composite only when verified anatomy gives it a clear
meaning. Do not treat a resection cavity as tumor necrosis merely because the model
assigns that label.

If postoperative imaging does not independently establish abnormality identity,
preserve the model labels verbatim and report them as provisional model outputs. Do
not derive a cavity from the `Necrosis` label. If a verified/user-supplied cavity mask
exists, analyze it as a separate region.

### 8.1 Postoperative centering and QC

Use the same three-plane QC pattern as Section 1.3. Choose the centering target in this
order when available and anatomically verified:

1. verified resection cavity or other user-supplied postoperative target;
2. verified residual enhancing tumor;
3. the dominant anatomically plausible postoperative abnormality.

Do not choose `Necrosis` merely because it is present or large. A provisional model
label may be used only as a navigation target while retaining its original name and
uncertain interpretation.

### 8.2 Pre/post lesion and tract comparison

For model labels that are meaningfully comparable across sessions, report:

```text
label
preoperative volume (mm^3)
postoperative volume (mm^3)
absolute change (mm^3)
```

Treat such changes as descriptive segmentation findings. Do not infer progression,
residual tumor, cavity size, treatment effect, or biologic response from volume change
alone.

Map the same bilateral eloquent pathways with comparable reconstruction and AutoTrack
settings when possible. Repeat the Section 4 T2R analysis using the postoperative
lesion regions and report the intersecting streamline count and fraction for each
session. Because the fraction uses each session's own completed bundle as denominator,
it is preferable to comparing tract-derived binary voxel volumes. Nonetheless,
pre/post changes in streamline count or fraction can still reflect acquisition,
reconstruction, registration, surgical deformation, diffusion signal, or tracking
behavior and should not be interpreted as direct axonal loss/gain.

Repeat CHA/Brodmann localization only when it answers the postoperative question. For
pre/post 3D comparison, use the same explicit camera recipe in both sessions,
beginning with `set_view 0 0` and applying identical rotations.

A newly visible postoperative tract can reflect improved tractability rather than newly
preserved fibers.

## 9. Reproducibility outputs

Preserve or record:

- FIB source and reconstruction space;
- structural-image source, selected slice, registration/QC status, and model ID;
- original lesion labels and any derived Tumor Core region;
- CHA and Brodmann intersection statistics;
- exact AutoTrack identifiers and relevant tracking settings;
- each analyzed tract bundle's total streamline count;
- the exact lesion regions checked for T2R;
- T2R intersecting streamline counts and calculated bundle fractions;
- left/right tract morphology statistics;
- the exact `set_view`/rotation recipe used for comparable 3D captures;
- interpretable segmentation and tract QC views;
- any manual segmentation corrections or exclusions.

`preview_screen roi` and `preview_screen 3d` are valid recorded **coarse** agent-side
inspection views but are not equivalent to full-resolution visual review. When the
user requests saved images or supplies an output location, use documented
`save_roi_screen`/`save_lr_screen` commands. Do not invent output paths solely to
satisfy reproducibility guidance.

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
