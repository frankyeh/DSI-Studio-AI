# DSI Studio AI Brain Tumor Presurgical and Postsurgical Evaluation

Use this skill only for brain-tumor presurgical planning or postsurgical structural
evaluation. General segmentation, atlas, region, AutoTrack, tract-statistics, and
rendering commands are maintained in the corresponding DSI Studio AI command files
and `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`; read those only when their command
details are needed.

## Workflow principle

Evaluate a tumor in this order:

1. Segment and measure tumor and edema.
2. Localize the tumor with `CHA` and identify overlapping `Brodmann` areas.
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

Confirm model availability for the selected slice with `list_unet`, then run:

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

For this skill define:

```text
Tumor Core = Enhancing Tumor ∪ Necrosis
```

Keep `Peritumoral Edema` separate. Never silently substitute one label for another.
If an expected label is missing, report that measurement as unavailable rather than
as zero. Preserve the original segmentation labels.

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

`merge_regions` keeps the first supplied region and removes the later merged rows.
Do not construct Tumor Core if either required presurgical component is unavailable.

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

When other relevant structural contrasts are available, compare the lesion against
them. Inspect remote or disconnected components far from the dominant lesion rather
than accepting them automatically. When no independent reference segmentation is
available, treat the automated segmentation as provisional and compare it visually
against all available relevant structural images.

A successful `segment_brain` command means inference completed; it does not mean the
segmentation has passed anatomical QC. Accept the segmentation for quantitative use
only when its location and gross extent agree with the visible structural abnormality
in all three planes, the structural-to-diffusion alignment is anatomically plausible,
and any remote/disconnected component is visually justified. If QC fails, do not
continue quantitative interpretation until the questionable segmentation is corrected
or explicitly accepted.

Use `show_region_statistics` to record, when available:

```text
Enhancing Tumor volume (mm^3)
Necrosis volume (mm^3)
Tumor Core volume (mm^3)
Peritumoral Edema volume (mm^3)
```

Keep the component measurements separate even when Tumor Core is also reported.

### 1.4 CHA localization

The human atlas is named exactly `CHA`. Atlas numeric indices are runtime-dependent,
so use `list_atlas` to find the current `CHA` atlas index, then load all CHA labels
with `add_region_from_atlas`.

Determine location from actual Tumor Core overlap rather than preselecting a CHA
region. Use Tumor Core as the first region in `region_action_all_inter_1st` and the
disposable CHA regions as the following regions. The first region is preserved; each
following region becomes:

```text
CHA region ∩ Tumor Core
```

Use `show_region_statistics` and report only nonzero intersections. For each affected
CHA region report:

```text
intersection volume (mm^3)
fraction of Tumor Core = intersection volume / total Tumor Core volume
```

Rank affected CHA regions by intersection volume. If edema localization is useful,
reload CHA and repeat the analysis separately with the edema region.

### 1.5 Brodmann-area involvement

The human atlas is named exactly `Brodmann`. Find its current runtime index with
`list_atlas`, load all labels, and intersect the disposable Brodmann regions with
the original Tumor Core region using the same `region_action_all_inter_1st` logic.

Report only Brodmann areas with nonzero tumor intersection:

```text
Brodmann area
intersection volume (mm^3)
fraction of Tumor Core
```

Rank them by intersection volume. Brodmann overlap is anatomical localization, not
proof that the corresponding function is impaired. Large lesions and mass effect can
also reduce atlas-registration accuracy; visually inspect unexpected or small
intersections.

CHA and Brodmann are gray-matter parcellations. Their intersection volumes do not
need to sum to the total Tumor Core volume, particularly for white-matter-centered
tumors.

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
to convert the mapped bundle into a spatial tract region. Record each tract-region
dimensions and resolution from `list_region`.

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

Use the original tract-region volume as the denominator for every compartment:

```text
enhancing-tumor overlap fraction =
    volume(tract region ∩ Enhancing Tumor) / original tract-region volume

necrosis overlap fraction =
    volume(tract region ∩ Necrosis) / original tract-region volume

edema overlap fraction =
    volume(tract region ∩ Peritumoral Edema) / original tract-region volume
```

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
lesion/intersection regions together:

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_only_regions "<lesion-and-overlap-region-indices>"
bash ./dsi.sh preview_screen 3d
```

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
`R_side=right`; use that orientation metadata together with the visible lesion
position to assign anatomical right/left. Atlas suffixes such as `_R`/`_L` and
tract geometry may corroborate laterality but should not be the primary evidence.

For medial, midline, or bilateral lesions, keep the results as left/right and do not
force an ipsilesional ratio.

When one side is meaningfully designated as the lesion side, optionally calculate:

```text
volume ratio = ipsilesional volume / contralateral volume
surface-area ratio = ipsilesional surface area / contralateral surface area
```

Reduced ipsilesional volume or surface area may support pathway involvement when it
agrees with lesion overlap and visible tract distortion. Do not interpret the
bilateral ratio alone.

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

Map the same bilateral eloquent pathways with comparable acquisition,
reconstruction, and AutoTrack settings when possible. Repeat tract-to-region
intersection and bilateral tract-statistics analysis. Repeat CHA or Brodmann
localization only when it answers the postoperative question; it is not required for
every follow-up study.

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
- interpretable segmentation and tract QC views;
- any manual segmentation corrections or exclusions.

For agent-side QC, `preview_screen roi` and `preview_screen 3d` are valid recorded
inspection views and do not require a filesystem destination. When the user requests
saved images or supplies an output location, use the documented
`save_roi_screen`/`save_lr_screen` commands. When a tract output destination is
available, save the interpreted bundle with:

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
