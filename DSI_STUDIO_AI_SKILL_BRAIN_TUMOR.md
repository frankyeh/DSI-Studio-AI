# DSI Studio AI Brain Tumor Neurosurgical Evaluation

Use this skill for presurgical or postsurgical brain-tumor evaluation intended to support
a neurosurgeon. The goal is to turn DSI Studio measurements into a concise, anatomically
grounded assessment of the lesion and the eloquent pathways that may affect intervention.
Use the general command manuals for exact command semantics rather than inferring behavior.

This workflow provides imaging and tractography decision support. Tractography does not by
itself establish function, tissue viability, safe resection margins, or whether a pathway
can be sacrificed. Interpret findings together with the neurological examination,
functional imaging when available, cortical/subcortical mapping, operative anatomy, and
other clinical information.

## Mandatory reporting behavior

Do not wait until the end to report everything. **After each major step is completed,
provide a short checkpoint summary before continuing.** Each checkpoint should contain:

1. **Findings** — the few quantitative/anatomical results that matter most.
2. **Potential neurosurgical relevance** — which finding may affect surgical corridor,
   resection margin, eloquent-risk discussion, need for closer functional correlation,
   or postoperative interpretation.

Keep each checkpoint brief, typically 2–6 bullets or a short paragraph. Do not repeat all
raw tables. Do not declare a tract `safe`, `intact`, `destroyed`, or `resectable` from
tractography alone.

### Required explanation before and after every major step

The chat is the primary neurosurgeon-facing presentation. **Do not silently execute several
numbered steps and summarize them only afterward.** Before starting each numbered major
step, give a short plain-language explanation in chat covering:

1. **Purpose** — why this step is being done for this case.
2. **Method** — what DSI Studio will measure or reconstruct and what the measurement means.
3. **What to look for** — the specific result or spatial relationship that will answer the
   clinical question.

After the step finishes, give the required checkpoint with:

4. **Result** — the important case-specific findings, including the key quantitative values.
5. **Neurosurgical meaning** — how those findings may affect intervention, functional-risk
   discussion, or postoperative interpretation, with important limitations stated.

Assume the neurosurgeon may not know the analysis method. Explain terms such as tumor
segmentation, atlas overlap, AutoTrack, T2R, and tract morphology when they first become
relevant. Keep method explanations concise and clinically oriented rather than describing
software implementation details.

At minimum, explain these points as the workflow progresses:

- **Step 1:** why enhancing tumor, necrosis, Tumor Core, and edema are measured separately;
  why volume and structural-registration QC matter.
- **Step 2:** that CHA/Brodmann overlap localizes the lesion anatomically by measuring
  atlas-region intersection; it provides anatomical context and does not establish function.
- **Step 3:** why each selected bilateral pathway is relevant to the lesion location and
  which neurological system it represents.
- **Step 4:** that AutoTrack reconstructs standardized named white-matter pathways and why
  bilateral reconstruction is useful for comparison.
- **Step 5:** that T2R asks how many reconstructed streamlines in each named pathway pass
  through each lesion compartment; explain the numerator, denominator, and bundle fraction.
- **Step 6:** why morphology and the live 3D tumor–tract relationship are inspected in
  addition to T2R counts, and what displacement, compression, marginal course, or direct
  intersection mean structurally.
- **Step 7:** integrate lesion size/location, atlas localization, T2R, and 3D tract geometry
  into a concise presurgical neurosurgical interpretation.
- **Step 8:** for postoperative work, explain that the central question is preservation of
  the same previously relevant eloquent pathways, not merely postoperative tumor volume.
- **Step 9:** explain the preservation categories and what can and cannot be concluded from
  tractography alone.
- **Step 10:** explain what is being retained for reproducibility and why matched settings
  and views matter for pre/post comparison.

### Required interaction pauses

The workflow is long, so use deliberate pause points rather than running the entire case
without giving the surgeon time to inspect the results.

**First hard pause — after the presurgical 3D tumor–tract review and integrated presurgical
summary (Steps 6–7).** Leave the useful 3D tumor/edema and relevant tract scene visible.
Do not immediately start postoperative analysis. End the chat turn with a concise summary
and a continuation prompt such as:

```text
Presurgical analysis is complete and the 3D tumor–tract view is left open for review.
Would you like to:
1. continue with postoperative tract-preservation analysis;
2. inspect another 3D viewpoint or tract combination;
3. prepare/export a DICOM tract overlay for clinical review; or
4. stop here?
```

If the user chooses DICOM overlay export, note that the current DSI Studio workflow is
GUI-based and requires the original DICOM series loaded as the selected custom slice:

```text
Slices -> Mark Tracts on Slices
(optional) Slices -> Mark Regions on Slices
Slices -> Save Slices to DICOM
```

Export marked images as separate DICOM files and keep the original clinical DICOM unchanged.
Do not imply that this GUI workflow is an AI command if no such command exists.

**Second hard pause — after the final postoperative tract-preservation summary.** Leave the
matched postoperative 3D view visible and ask whether the surgeon wants another matched
view, DICOM-overlay guidance, or no further analysis.

For presurgical work, prioritize the relationship of tumor/core/edema to eloquent anatomy.
For postsurgical work, the **primary question is whether the previously relevant eloquent
tracts remain reconstructable and anatomically preserved around the resection/treatment
site**.

### Companion-manual routing

| Tumor workflow section | Companion manual |
|---|---|
| §1 segmentation, slice readiness, model availability, three-plane QC | `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §2 atlas localization | `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §3–4 pathway selection and AutoTrack | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md` |
| §5 tract-to-lesion connectivity | `DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §6 tract morphology, laterality, and spatial QC | `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md` |
| §8 postoperative tract-preservation evaluation | Slice, Rendering, Region, Tract, T2R, and Fiber-Tracking manuals above |

## Workflow overview

### Presurgical evaluation

1. Verify the structural image and segment the lesion.
2. Quantify lesion compartments and establish laterality/anatomical extent.
3. Localize the Tumor Core against `CHA` and `Brodmann` as supporting anatomical context.
4. Select and reconstruct the relevant bilateral eloquent pathways with AutoTrack.
5. Quantify tract-to-lesion involvement with T2R.
6. Compare bilateral tract morphology and inspect tract/lesion spatial relationships.
7. Integrate the findings into a neurosurgical summary.

### Postsurgical evaluation

1. Verify postoperative anatomy and identify the cavity/residual abnormality conservatively.
2. Reconstruct the **same eloquent pathways that were relevant preoperatively**, using
   comparable settings whenever possible.
3. Determine whether each pathway remains reconstructable in its expected course and how
   it relates to the cavity, residual lesion, and postoperative edema.
4. Compare pre/post tract morphology and T2R descriptively.
5. Report the preservation status of each eloquent pathway as reconstruction-based
   evidence, with uncertainty explicitly stated.

Do not use tumor- or edema-derived regions as ROI, Seed, ROA, End, or other tracking
constraints for standard AutoTrack. Reconstruct the named tract independently first, then
measure its relationship to the lesion.

# PRESURGICAL EVALUATION

## 1. Verify imaging, segment, and characterize the lesion

### 1.1 Input and registration preflight

Select the structural image intended for segmentation:

```bash
bash ./dsi.sh list_slice
bash ./dsi.sh set_slice <slice-index>
bash ./dsi.sh list_slice
```

When many structural NIfTIs are available, QC them first to compare
resolutions — pick the highest-resolution structural (e.g. 1 mm isotropic
MPRAGE) for tumor segmentation. Watch out for thick slices: a structural
with fine in-plane resolution but thick slices (e.g. 0.5×0.5×5 mm) is not
good for tumor segmentation, which needs true 3D accuracy. Lower-resolution
structurals give coarser segmentations. `dir` the folder and check each
candidate's dimensions and voxel size before choosing.

When a FIB opened from Fiber Data Hub already exposes its structural MRI in `list_slice`
with status `available`, select that existing slice with `set_slice`; do not add the same
image again with `add_slice`. Poll `list_slice` until the selected row reports `ready`.

`ready` means loading/registration has finished; it does not prove anatomical alignment.
Inspect the structural image against diffusion anatomy before segmentation. Record the FIB
reconstruction space, structural-image source/slice, and segmentation model ID.

### 1.2 Tumor model and label definition

Use `human_tumor` (**U-Net Studio Human Tumor Lesion V2**) by default. It is the
contrast-flexible tumor model for T1w, T1w-gd, T2w, FLAIR, and related structural MRI
contrasts. `human_tumor_T1w` is the T1w-specific lightweight alternative.

Do not use `human_tumorsynth` when separate tumor-core and edema measurements are
required; its current DSI Studio output provides a single `Tumor` region.

Confirm model availability for the selected slice. Use the exact internal model ID only
when its `available` field is true:

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

`human_tumor` also emits five tissue labels. These are not lesion compartments for this
workflow and can shift region indices. Resolve lesion rows by exact name from a fresh
`list_region`; never infer their indices from creation order.

For presurgical work define:

```text
Tumor Core = Enhancing Tumor ∪ Necrosis
```

Keep `Peritumoral Edema` separate. If an expected label is missing, report it as
unavailable rather than zero. Preserve the original segmentation labels.

**Segmentation failure fallback:** if `human_tumor` (or the T1w-specific alternative)
fails to produce a usable lesion segmentation — no tumor found, severely fragmented
labels, or a missing compartment needed for Tumor Core — an alternative is to derive a
rough tumor region from the isotropic diffusion (ISO) map, where tumor tissue often
stands out. The downside is low resolution: the ISO map is at diffusion resolution
(e.g. 2.5 mm), far coarser than the structural image, so the resulting region is
suitable only for gross localization, not for precise volumetry or margin assessment.
Prefer re-running segmentation (check that the correct slice is selected, try
`human_tumor_T1w` for T1w-only data) before falling back to the ISO map, and always
report which method produced the lesion regions.

Before lesion-only QC or statistics, isolate the intended lesion rows:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>"
```

For Tumor Core, create and merge copies so the original components remain untouched.
Re-resolve indices after every mutation:

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
`merge_regions` keeps the first supplied region and removes later merged rows. Do not
construct Tumor Core if either required component is unavailable.

**Index bookkeeping (important):** every `copy_region`/`merge_regions`/`delete_region`
shifts subsequent indices. After each mutation, run `list_region` and write down the new
index→name mapping before issuing the next index-dependent command. Never carry an index
across a mutation without re-resolving it. When a step needs several regions, resolve
all of them from the same fresh `list_region` output.

After merging, verify the derived Tumor Core before using it: its volume should equal
Enhancing Tumor volume + Necrosis volume (within rounding). Run `show_region_statistics`
on the original components and the merged Core; a mismatch means the wrong rows were
merged.

### 1.3 Three-plane QC and lesion measurements

Center on Tumor Core and inspect sagittal, coronal, and axial views:

```bash
bash ./dsi.sh show_only_regions "<lesion-region-indices>"
bash ./dsi.sh move_slice_to_region <Tumor-Core-index>

bash ./dsi.sh set_roi_view 0
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 1
bash ./dsi.sh preview_screen roi
bash ./dsi.sh set_roi_view 2
bash ./dsi.sh preview_screen roi
```

`preview_screen roi` is a coarse text rendering plus orientation/coverage metadata. Use
it for gross location/alignment checks, not as a substitute for full-resolution image
inspection. When a clinically important boundary or laterality decision cannot be resolved
from the text view, state that limitation explicitly rather than inferring the answer,
and use `save_roi_screen` for human review when an output destination has been provided
or requested. Do not invent an output path solely for QC. The same limitation applies to
`preview_screen 3d` in Step 6: it confirms which structures are co-visible, not fine
tumor–tract boundaries.

A successful `segment_brain` means inference completed; it does not establish anatomical
validity. Inspect remote/disconnected components rather than accepting them automatically.

Immediately before lesion statistics, isolate exactly the intended lesion rows because
`show_region_statistics` uses currently checked/shown regions:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<Tumor-Core-index>&<edema-index>"
bash ./dsi.sh show_region_statistics
```

Record when available:

```text
Enhancing Tumor volume (mm^3)
Necrosis volume (mm^3)
Tumor Core volume (mm^3)
Peritumoral Edema volume (mm^3)
lesion hemisphere or bilateral/midline involvement
gross lobe/location and important adjacent anatomy
```

### Radiologist-style tumor reporting

Report the lesion the way a radiologist does: anatomical location plus three
orthogonal diameters, not just volumes. `show_region_statistics` returns a
bounding box (min/max x, y, z in mm) for each checked region. Derive the three
diameters as max minus min per axis, convert to cm, and report largest first.
For the Tumor Core (a merged region), take the union of the component bounding
boxes.

Location comes from Step 2 atlas overlap (CHA/Brodmann), not from raw
coordinates. Hemisphere follows the MNI x sign (negative = left). Report each
atlas region's intersection volume and its fraction of the Tumor Core.

Template:

```text
Findings:

There is a heterogeneously enhancing mass in the [hemisphere] [lobe],
centered in the [gyrus] with extension into [adjacent regions], measuring
approximately [X] x [Y] x [Z] cm (Tumor Core [V] cm^3).

The mass shows [central] necrosis measuring approximately [A] x [B] x [C] cm
([V] cm^3) with a [peripheral] enhancing component measuring [D] x [E] x [F] cm
([V] cm^3). Surrounding vasogenic edema extends to approximately
[G] x [H] x [I] cm ([V] cm^3).

[Atlas] overlap of the Tumor Core: [region 1] [fraction]%, [region 2]
[fraction]%, ...
```

"Central"/"peripheral" are impression descriptions — segmentation gives
bounding boxes and center points, not a direct measurement of the spatial
topology between necrosis and enhancing tissue. State the limitation when the
relationship cannot be resolved from the segmentation output.

Worked example (M028Y): left frontal lobe mass centered in precentral gyrus,
1.5 x 1.3 x 1.1 cm (Tumor Core 9.0 cm^3); central necrosis 1.4 x 1.2 x 1.0 cm
(6.7 cm^3); peripheral enhancing 1.4 x 1.2 x 1.1 cm (2.2 cm^3); edema
1.9 x 2.0 x 2.1 cm (14.8 cm^3). CHA overlap: precentral gyrus 33%,
prefrontal 17%, premotor 9%.

### Brain surface for tumor location visualization

To visualize the tumor on the brain surface, show the `White_Matter` region
from the tumor segmentation — it is already a skull-stripped brain mask. Do
not use `add_surface` on raw T1w (it includes the skull), and do not merge
tissue regions.

Turn off `Gray_Matter` and `Others`; show `White_Matter` plus the tumor
compartments (Necrosis, Peritumoral Edema, Enhancing Tumor). `Basal_Ganglia`
may stay visible. Show `Cerebellar_Cortex` only if the tumor is near the
cerebellum. Gray matter and other tissue labels clutter the surface and hide
the tumor.

### Required checkpoint after Step 1

Report briefly:

```text
Findings
- lesion side and gross anatomical location
- Enhancing Tumor, Necrosis, Tumor Core, and edema volumes
- whether segmentation/alignment QC is acceptable or limited

Potential neurosurgical relevance
- whether the lesion is cortical/subcortical, deep, midline, or crosses compartments
- whether edema or Tumor Core approaches regions where motor, language, or visual
  pathways may need dedicated evaluation
- any segmentation uncertainty that could affect subsequent planning measurements
```

Do not infer functional eloquence from location alone; use Step 2 only as anatomical
context and Steps 3–6 for tract-specific assessment.

## 2. Localize the Tumor Core anatomically

### 2.1 CHA localization

The human atlas is named exactly `CHA`. Do not load CHA labels into the Region table just
to calculate overlap:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> CHA
```

The command maps atlas labels into the source region space, returns ordinary region
statistics for nonempty intersections, omits zero-overlap labels, and does not mutate the
Region table.

For each affected CHA region report:

```text
intersection volume (mm^3)
fraction of Tumor Core = intersection volume / total Tumor Core volume
```

If edema localization would materially help pathway selection, run the same analysis on
the edema region separately.

### 2.2 Brodmann-area localization

Use the same nonmutating workflow with the atlas named exactly `Brodmann`:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> Brodmann
```

Report nonempty areas with intersection volume and fraction of Tumor Core. Brodmann
overlap is anatomical localization, not proof that the corresponding function is impaired.
CHA and Brodmann are gray-matter parcellations, so their intersection volumes need not sum
to total Tumor Core volume, particularly for white-matter-centered lesions.

Use `add_region_from_atlas` only when actual atlas regions are needed for visualization,
editing, tracking constraints, or another downstream operation.

### Required checkpoint after Step 2

Report the **few dominant anatomical involvements**, not the full atlas table:

```text
Findings
- major CHA regions intersected by Tumor Core, ranked by intersection volume
- major Brodmann areas involved, when meaningful
- whether the lesion appears predominantly cortical, subcortical/white-matter, or mixed

Potential neurosurgical relevance
- which functional systems may warrant tract reconstruction or closer functional
  correlation (motor, language, visual, etc.)
- whether cortical localization and white-matter extension suggest different risks
- important caveat if mass effect/registration uncertainty could distort atlas localization
```

Do not use a Brodmann label alone to declare eloquence or to decide resectability.

## 3. Select the eloquent pathways relevant to this lesion

Use these verified human AutoTrack identifiers directly for the standard tumor workflow;
`list_auto_tract` is not needed for these entries.

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

Reconstruct the ipsilateral (lesion-side) pathways and their contralateral
homologs. The contralateral side serves as a control: a displaced tract shows
increased curl (large route/distance ratio) compared to its healthy homolog,
so left-right comparison is useful for detecting tumor-induced displacement.

Practical selection:

- perirolandic or motor lesion: CST;
- frontal language lesion: AF, SLF, FAT;
- parietal language lesion: AF, SLF;
- temporal language lesion: AF, ILF;
- posterior temporal, parietal, or occipital lesion: optic radiation when visual-pathway
  risk is relevant.

For temporal lesions, add optic radiation when lesion or edema extends into posterior
temporal or temporo-occipital white matter. If agent-side anatomy/QC is too coarse to
confidently exclude such extension, map optic radiation rather than omit it. Do not use
edema volume alone as the trigger, and do not use a Brodmann label alone to trigger a
tract.

Optional pathways:

| Pathway | Left | Right |
|---|---|---|
| Inferior fronto-occipital fasciculus | `Association_InferiorFrontoOccipitalFasciculusL` | `Association_InferiorFrontoOccipitalFasciculusR` |
| Uncinate fasciculus | `Association_UncinateFasciculusL` | `Association_UncinateFasciculusR` |

If another pathway is required, use `list_auto_tract` to discover its exact identifier.

### Required checkpoint after Step 3

Before launching tracking, state:

```text
Selected pathways
- pathway names and why each is relevant to this lesion location
- bilateral homologs reconstructed; contralateral side is the control for
  curl (route/distance ratio) comparison to detect displacement

Potential neurosurgical relevance
- which functional domains are being evaluated (motor, language, visual, semantic, etc.)
- which lesion component/location triggered each pathway selection
- any clinically important pathway that cannot be evaluated with the available data
```

Keep this short. The purpose is to make the subsequent tractography scope explicit.

## 4. Reconstruct the selected bilateral pathways

Map left and right homologs with identical AutoTrack settings. Follow AutoTrack QC,
tolerance, TIP, and retry guidance in `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`.

`run_auto_track` is asynchronous. When several bundles are needed with the same settings,
launch all selected calls back-to-back without waiting for each one:

```bash
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractR"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusR"
```

After all desired AutoTrack calls are launched, poll the full tract table about every 10
seconds:

```bash
bash ./dsi.sh list_tract
```

Continue until every requested tract row reports `done`. Only then perform dependent
statistics, T2R, saving, editing, or visualization. Do not serially wait for each bundle
before launching the next.

Once all tracts are done, assign a distinct color to each bundle in one call so
the pathways are visually separable:

```bash
bash ./dsi.sh color_all_cluster
```

If a clinically relevant pathway remains empty after the bounded tolerance retry
procedure, report it as `unmappable` with tract count, seed limit, tolerance values, and
attempts. Do not interpret zero yield as anatomical absence or zero lesion involvement.

### Required checkpoint after Step 4

Report:

```text
Findings
- which requested left/right pathways completed successfully
- total streamline count for each completed bundle
- any pathway that was sparse, required tolerance retry, or remained unmappable

Potential neurosurgical relevance
- whether all clinically relevant systems can be assessed
- which absent/sparse reconstruction limits confidence in planning
- any major left/right asymmetry that deserves attention but has not yet been interpreted
```

Do not call a pathway preserved or disrupted at this stage; that requires Steps 5–6.

## 5. Quantify tract-to-lesion involvement with T2R

Use **tract-to-region connectivity (T2R)** for quantitative tract-versus-lesion
involvement. Do not convert each tract into a voxel region merely to calculate tumor or
edema involvement.

`show_t2r` operates on the currently checked/shown tract bundles and checked/shown
regions. For each tract bundle it identifies streamlines that pass through each region and
reports ordinary tract statistics for that passing subset. The `number of tracts` row
under each lesion column is therefore the number of reconstructed streamlines from that
bundle that intersect the lesion region.

The lesion regions are mapped into the FIB diffusion grid internally. No `tract_to_region`,
lesion copies, binary intersections, or disposable overlap masks are required.

### 5.1 T2R command pattern

After all selected AutoTrack bundles are complete:

```bash
bash ./dsi.sh list_tract
bash ./dsi.sh list_region
bash ./dsi.sh show_only_tracts "<tract-index-1>&<tract-index-2>&..."
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>&<Tumor-Core-index>"
bash ./dsi.sh show_t2r
```

Omit unavailable regions. One `show_t2r` call can analyze several checked bundles; the
output identifies each tract separately.

**Output format note:** the result lists a header for every checked tract bundle, but
data rows (`number of tracts`, etc.) appear only for bundles with nonzero intersection.
A tract that shows a header with no data rows has zero reconstructed intersection with
all checked regions — this is a valid result, not a command failure. Contralateral
bundles routinely show headers without data.

### 5.2 Lesion involvement by volume

Do not report streamline counts — the count is artificial, determined by
seeding parameters rather than biology. Instead, use `intersect volume(mm^3)`
from the T2R output, which estimates the volume of tract-lesion overlap.

For each tract bundle and each lesion compartment, report:

```text
intersect volume (mm^3) = T2R "intersect volume(mm^3)" for that region
```

A streamline can pass through multiple lesion compartments, so volumes are not
expected to sum to the total lesion volume.

T2R answers: **what volume of the reconstructed pathway intersects this lesion
region?** It measures geometric intersection of streamlines with segmented
regions, not histological invasion.

For this workflow use the `number of tracts` row as numerator. Do **not** use the generic
T2R `intersect ratio` as the bundle streamline fraction.

A zero T2R count is valid only after confirming that the tract is nonempty, the lesion
region is nonempty, both belong to the same subject/mapping context, and T2R completed
successfully.

### Required checkpoint after Step 5

For each clinically important pathway, summarize only the lesion compartments with
meaningful intersection plus important zeros:

```text
Findings
- pathway: total streamlines
- Enhancing Tumor: intersecting count and fraction
- Necrosis: intersecting count and fraction
- Tumor Core: intersecting count and fraction
- Peritumoral Edema: intersecting count and fraction

Potential neurosurgical relevance
- direct reconstructed-pathway intersection with Tumor Core is more concerning for
  margin/pathway conflict than edema-only intersection, but does not prove infiltration
- edema-only intersection may indicate a pathway traversing tissue affected by mass effect
  or altered diffusion without proving tract destruction
- zero reconstructed intersection does not guarantee surgical separation, particularly
  for incompletely reconstructed pathways
```

Do not create universal percentage thresholds for “high risk.” Interpret fractions with
tract geometry, pathway type, segmentation quality, and clinical context.

## 6. Evaluate tract morphology, laterality, and spatial relationship

First obtain raw bilateral tract measurements:

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_tract_statistics
```

Record for each side:

```text
total number of tracts
total volume(mm^3)
total surface area(mm^2)
curl (route/distance ratio)
```

Compare ipsilesional vs contralateral curl: a displaced tract shows increased
curl compared to its healthy homolog. A substantially higher curl on the lesion
side (e.g. 20%+) indicates tumor-induced displacement — the tract is being
pushed aside and taking a longer, more winding route. Similar curl on both
sides suggests the pathway is not significantly displaced.

Verify lesion laterality from structural anatomy and segmentation before labeling a tract
ipsilesional/contralateral. `preview_screen roi` reports `R_side=left` or `R_side=right`,
but its text thumbnail is coarse and is not definitive laterality evidence.

When lesion side is clear anatomically, use orientation metadata to translate screen
position into anatomical right/left. Atlas suffixes, known left/right AutoTrack identifiers,
MNI-coordinate sign, and tract geometry may corroborate. If cues disagree, retain simple
left/right labels and state uncertainty.

Inspect the tract and lesion together:

```bash
bash ./dsi.sh show_only_tracts "<relevant-left-tract>&<relevant-right-tract>"
bash ./dsi.sh show_only_regions "<relevant-lesion-region-indices>"
bash ./dsi.sh set_view 0 0
bash ./dsi.sh preview_screen 3d
```

For a clinically important small T2R intersection, also inspect all three slice planes
with the relevant tract and lesion visible.

Describe the reconstructed pathway in anatomically useful terms such as:

```text
displaced by lesion/edema
compressed/narrowed in the lesion vicinity
grossly maintained around lesion
intersecting Tumor Core
intersecting edema only
passing along a lesion margin
incompletely reconstructed / uncertain
```

When one side is meaningfully designated as lesion side, optional morphology ratios are:

```text
volume ratio = ipsilesional volume / contralateral volume
surface-area ratio = ipsilesional surface area / contralateral surface area
```

Do not interpret ratios alone. Normal asymmetry can be substantial, particularly for the
arcuate fasciculus.

### Optic-radiation caution

Interpret optic radiation more conservatively than the other core pathways. The anterior
optic radiation, especially Meyer's loop, is difficult to reconstruct reliably and varies
between individuals. Do not treat the most anterior reconstructed streamline as the true
anatomical boundary. Positive tumor/edema intersection is meaningful structural evidence,
but absence of reconstructed intersection near the anterior temporal lobe does not reliably
exclude Meyer's-loop involvement.

### Required checkpoint after Step 6

Report the **surgical-anatomy synthesis** for each key pathway:

```text
Findings
- side and pathway
- whether it is grossly reconstructed in the expected course
- relationship to Tumor Core, enhancing tumor, and edema
- displacement/compression/marginal course/intersection
- important bilateral asymmetry or reconstruction uncertainty

Potential neurosurgical relevance
- whether the reconstructed pathway lies within, at the margin of, or separated from the
  lesion/edema
- which functional system may be most exposed during intervention
- where tractography uncertainty is high enough that functional mapping/anatomical
  confirmation becomes especially important
```

Do not convert this into a statement that a particular surgical route is safe or unsafe.

## 7. Integrated presurgical neurosurgical report

The final presurgical report should answer the questions a neurosurgeon is most likely to
need:

1. **Where is the lesion and how large are the surgically relevant compartments?**
2. **Which cortical/anatomical regions are involved?**
3. **Which eloquent pathways are relevant to this lesion?**
4. **Which reconstructed pathways directly intersect Tumor Core, enhancing tumor,
   necrosis, or edema?**
5. **Are important pathways displaced, compressed, marginal, or incompletely
   reconstructed?**
6. **Which findings could materially constrain a surgical corridor or margin, and where
   is uncertainty high enough to require additional functional/anatomical correlation?**

Recommended concise structure:

```text
Presurgical neurosurgical summary

Lesion
- location/laterality
- Enhancing Tumor, Necrosis, Tumor Core, edema volumes
- major anatomical extent and QC limitations

Anatomical localization
- dominant CHA regions
- relevant Brodmann areas, if useful

Eloquent pathways
- pathway — side — total streamlines
- Tumor Core intersection count/fraction
- enhancing-tumor intersection count/fraction
- edema intersection count/fraction
- spatial relationship: displaced/compressed/marginal/intersecting/uncertain

Key intervention-relevant points
- 3–6 prioritized findings most likely to affect approach, margin, or functional-risk
  discussion
- important pathway that could not be reconstructed
- major atlas/segmentation/registration/tractography limitation
```

Prioritize clinically meaningful findings. Do not drown the final summary in all raw atlas
rows or every tract statistic.

After giving this summary, **stop at the first hard pause described above**. Keep the
presurgical 3D tumor–tract scene visible so the surgeon can inspect it before choosing the
next action.

### Optional: export a DICOM series with tract/lesion markings

If the surgical team wants a DICOM series with the evaluated pathways (and optionally a
tumor region) burned into the pixels — e.g. for navigation-system import — produce it
with the slice-marking workflow. **This requires the original DICOM series as the slice
source.** A NIfTI structural image alone is not sufficient: `save_slices_to_dicom`
rejects any slice not loaded from original DICOM files.

Purpose: give the surgeon a DICOM series where the relevant tracts (and, optionally, a
lesion compartment) are visible as intensity markings in the image data itself.

```bash
bash ./dsi.sh add_slice "<dicom1>,<dicom2>,..."   # original DICOM series
bash ./dsi.sh set_slice <dicom-slice-index>       # poll list_slice until ready
bash ./dsi.sh show_only_tracts "<relevant-left-tract>&<relevant-right-tract>"
bash ./dsi.sh mark_tracts_on_slices 1.0
bash ./dsi.sh mark_region_on_slices <tumor-core-index> 1.2   # optional
bash ./dsi.sh save_slices_to_dicom "<output-directory>"
```

What to verify before handing off:

- `mark_tracts_on_slices` burns only **checked** tracts and fails when none are checked;
  confirm the `show_only_tracts` selection matches the pathways from Step 3.
- Marking is cumulative in memory; reload the slice if a marking step needs redoing.
- Reopen the produced `mod_*.dcm` series and verify orientation, intensity, and that the
  tract/region markings land in the expected anatomy.

# POSTSURGICAL EVALUATION

## 8. Primary goal: assess preservation of eloquent pathways

The postoperative evaluation should be organized around a different central question:

> **Are the eloquent pathways that were relevant preoperatively still reconstructable in
> their expected anatomical course after surgery/treatment, and how do they relate to the
> cavity, residual abnormality, and postoperative edema?**

Lesion-volume change remains useful, but it is secondary to the pathway-preservation
assessment when the clinical question is postoperative functional anatomy.

### 8.1 Verify postoperative anatomy

Define postoperative abnormalities conservatively: residual enhancing lesion, verified
resection cavity, postoperative edema, hemorrhage/treatment-related change, or another
verified abnormality.

Do not automatically construct presurgical Tumor Core after surgery. Analyze
`Enhancing Tumor`, `Necrosis`, and `Peritumoral Edema` separately when present, and create
a postoperative composite only when verified anatomy gives it a clear meaning. Do not
interpret the model's `Necrosis` label as a resection cavity unless cavity identity is
independently established.

If a verified/user-supplied cavity mask exists, analyze it as a separate region.

Use the same three-plane QC pattern as presurgical evaluation. Choose the centering target
in this order when available:

1. verified resection cavity or user-supplied postoperative target;
2. verified residual enhancing lesion;
3. dominant anatomically plausible postoperative abnormality.

### Required postoperative checkpoint A — anatomy

```text
Findings
- cavity/residual lesion/postoperative edema that can be identified reliably
- postoperative lesion-compartment volumes when meaningful
- major deformation, hemorrhage, susceptibility, or registration limitation

Clinical relevance
- which postoperative abnormality is most relevant to interpreting nearby tracts
- whether image/segmentation quality is adequate for a tract-preservation comparison
```

### 8.2 Reconstruct the same eloquent pathways

Use the same bilateral pathways that were clinically relevant preoperatively. Keep
reconstruction and AutoTrack settings comparable whenever possible. Launch all independent
`run_auto_track` calls back-to-back and poll `list_tract` about every 10 seconds until all
requested bundles are `done`.

If a pathway was not part of the presurgical study but postoperative anatomy makes it
clinically relevant, it may be added, but clearly mark it as **postoperative-only** rather
than pretending it has a pre/post baseline.

### Required postoperative checkpoint B — tract reconstruction

For each relevant pathway report:

```text
- preoperative reconstruction available: yes/no
- postoperative reconstruction: successful / sparse / unmappable
- total postoperative streamline count
- whether the expected gross trajectory is visible
```

The main clinical question at this stage is whether each eloquent pathway remains
reconstructable. Do not yet equate an absent reconstruction with surgical transection.

### 8.3 Compare pre/post tract preservation

For each eloquent pathway, compare the same side and named tract using:

```text
reconstructability in expected anatomical course
gross trajectory continuity around the operative site
total streamline count
tract volume
tract surface area
spatial relationship to verified cavity/residual lesion/edema
T2R intersecting streamline count/fraction for postoperative regions when useful
```

Use identical `set_view 0 0` and the same rotations for comparable pre/post 3D captures.

Interpret pre/post tract count, volume, surface area, and T2R changes descriptively.
Differences may reflect acquisition, reconstruction, registration, brain shift/deformation,
diffusion signal, edema, susceptibility, tolerance, TIP, or tractability. A newly visible
postoperative tract can reflect improved tractability rather than newly preserved fibers.
An absent postoperative tract can reflect tractography failure rather than true pathway
loss.

### 8.4 Preservation categories for reporting

Use the following **reconstruction-based** language. These are imaging descriptions, not
functional diagnoses:

**Reconstruction preserved**
- the pathway remains reconstructable in the expected gross anatomical course;
- its trajectory can be followed around/adjacent to the operative site;
- no major new discontinuity is apparent in the reconstructed bundle.

**Reconstruction partially preserved / altered**
- a recognizable pathway remains but is substantially reduced, displaced, fragmented,
  narrowed, or altered near the operative site;
- interpretation should explicitly include acquisition/tracking uncertainty.

**Preservation uncertain**
- reconstruction is sparse, anatomically ambiguous, heavily affected by postoperative
  distortion/artifact, or not directly comparable with preoperative data.

**Not reconstructable postoperatively**
- the pathway cannot be reconstructed despite the standard bounded retry procedure.
- Do **not** translate this automatically to `transected` or `destroyed`; state that true
  pathway disruption versus tractography failure cannot be distinguished from the
  tractography result alone.

### Required postoperative checkpoint C — preservation assessment

After evaluating each clinically relevant tract, provide a short tract-by-tract summary:

```text
CST L/R
- preservation assessment: reconstruction preserved / partially preserved or altered /
  uncertain / not reconstructable
- key pre/post change
- relationship to cavity/residual lesion/edema
- motor-system implication for clinical correlation

AF / SLF / FAT / ILF / OR as relevant
- same fields
```

Then add:

```text
Key postoperative clinical points
- which eloquent pathways are clearly still reconstructable
- which pathway shows the greatest postoperative alteration or uncertainty
- whether a pathway courses along the cavity or residual lesion margin
- which findings warrant correlation with postoperative neurological function or other
  functional assessment
```

### 8.5 Postoperative lesion-volume comparison

When model labels are meaningfully comparable across sessions, report:

```text
label
preoperative volume (mm^3)
postoperative volume (mm^3)
absolute change (mm^3)
```

Treat these as descriptive segmentation findings. Do not infer progression, residual tumor,
cavity size, treatment effect, or biological response from volume change alone.

Repeat CHA/Brodmann localization only when it answers a postoperative question; pathway
preservation should remain the principal postoperative focus.

## 9. Final postoperative neurosurgical report

Lead with eloquent-tract preservation rather than lesion statistics.

Recommended structure:

```text
Postoperative neurosurgical summary

Eloquent-tract preservation
- pathway — side — preservation assessment
- key pre/post morphology/reconstructability change
- relationship to cavity/residual lesion/edema
- important uncertainty

Most clinically important pathway findings
- pathways grossly preserved around the operative site
- pathways altered/attenuated/uncertain
- pathways not reconstructable postoperatively

Postoperative anatomy
- verified cavity/residual lesion/edema
- major volume changes when meaningful

Clinical correlation priorities
- neurological domains corresponding to altered/uncertain pathways
- areas where tractography cannot distinguish preserved function from structural injury
- imaging/artifact/registration limitations affecting interpretation
```

Do not make the postoperative report primarily a tumor-volume report when the clinical
question is tract preservation.

After this report, **stop at the second hard pause described above** and leave the matched
postoperative 3D view visible for inspection.

## 10. Reproducibility record

Preserve or record:

- FIB source and reconstruction space;
- structural-image source, selected slice, registration/QC status, and segmentation model;
- original lesion labels and any derived Tumor Core;
- CHA/Brodmann intersection statistics used for interpretation;
- exact AutoTrack identifiers and relevant tracking settings;
- each analyzed tract's total streamline count;
- lesion regions checked for T2R;
- T2R intersecting streamline counts and calculated bundle fractions;
- left/right tract morphology statistics;
- for postoperative work, the matched pre/post tract identity and preservation category;
- exact `set_view`/rotation recipe used for comparable 3D captures;
- interpretable segmentation/tract QC views;
- manual segmentation corrections, exclusions, or accepted uncertainties.

`preview_screen roi` and `preview_screen 3d` are valid recorded **coarse** agent-side
inspection views but are not equivalent to full-resolution visual review. When the user
requests saved images or supplies an output location, use documented
`save_roi_screen`/`save_lr_screen` commands. Do not invent output paths solely for
reproducibility.

Distinguish successful command execution from an anatomically accepted result.

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