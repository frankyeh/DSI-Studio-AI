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


## HARD GATE FOR COMPLETE PDF REPORTS

When the user requests a **complete brain-tumor PDF/report**, the report-generation contract
in §11 is mandatory and **takes priority over brevity or page-count reduction**. Do not
assemble or deliver the PDF until the report gate in §11.12 passes.

A complete report is a multi-page neurosurgical imaging report, not a compressed summary.
Required page roles are **non-mergeable by default**. Do not combine the tumor MRI page,
tumor composition/3D page, atlas page, all-tract overview, individual clinically important
tract pages, and final synthesis merely to make the report shorter. If two clinically
important tracts require individual pages, the report must contain two individual tract
pages.

Before PDF assembly:

1. finish and accept the quantitative analysis;
2. freeze the accepted case state: selected tract list, completed tract reconstructions,
   tract counts, T2R results, morphology measurements, segmentation labels, and accepted
   region cleanup;
3. create every required 2D and 3D figure from that accepted state;
4. populate the machine-checkable `REPORT_GATE` in §11.12;
5. assemble the PDF only when every mandatory gate item is `PASS` or is explicitly marked
   unavailable with a reason that the user can see.

When reproducing or revising an already analyzed case, **reuse the previously accepted tract
set and results**. Do not silently re-select pathways or re-run AutoTrack merely because a
new agent is generating the PDF. Re-track only when required by missing/corrupt data, an
explicit user request, or a documented QC failure, and disclose that the reconstruction
changed.

For final report figures, presentation quality is part of correctness. A technically valid
DSI screenshot is insufficient if it contains the wrong scene, stereo/lateral duplication,
missing orientation, irrelevant glyphs/crosshairs, or excessive unused page space.

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

For tumor-report 3D rendering, use the **`White_Matter` region produced by the
`human_tumor` segmentation as the brain envelope / spatial anchor**.

Do **not** use `add_surface`, a separate DSI surface object, or a separately generated
isosurface for the tumor report. Set `show_surface=0`; the checked `White_Matter` region
itself provides the translucent brain envelope.

The U-Net `White_Matter` output can contain disconnected fragments. Before final 3D
rendering, **defragment `White_Matter`** and visually verify that it forms a coherent brain
envelope. This cleanup is for `White_Matter` visualization only; do not defragment the tumor
compartments unless the user explicitly requests a segmentation edit.

Resolve the current row by name, then run:

```bash
bash ./dsi.sh region_action_defragment <white-matter-index>
bash ./dsi.sh list_region
```

Keep DSI Studio's **original RGB** for the segmentation regions and change **alpha only**.
`list_region` reports color as `#AARRGGBB`; preserve `RRGGBB` and replace `AA`:

```text
White_Matter       alpha 10  = 0x0A
Necrosis           alpha 200 = 0xC8
Peritumoral Edema  alpha 80  = 0x50
Enhancing Tumor    alpha 100 = 0x64
```

Use `set_region_color` with the resulting unsigned ARGB value. Do not copy RGB values from
another subject. The verified sub-003 example produced:

```text
Necrosis           #c85b484e
Peritumoral Edema  #508397ab
Enhancing Tumor    #64bc6e71
White_Matter       #0ae7e7ee
```

After setting alpha, **move `White_Matter` to the bottom of the Region table so it renders
last**. Re-resolve indices as rows move:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh move_down_region <current-white-matter-index>
# repeat until White_Matter is the final row
bash ./dsi.sh list_region
```

For final tumor 3D scenes, normally show only `Necrosis`, `Peritumoral Edema`,
`Enhancing Tumor`, and `White_Matter`. Hide the other tissue labels unless specifically
needed. The cleaned `White_Matter` region is a visualization anchor and is not part of
Tumor Core.

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
homologs. The contralateral side serves as a control for descriptive bilateral comparison.
Curl (route/distance ratio) may help identify asymmetry, but curl alone does not prove that
a tumor caused displacement; spatial geometry must also support that interpretation.

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
- bilateral homologs reconstructed; contralateral side provides descriptive comparison
  for morphology and tractability

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

For a clearly unilateral lesion, prioritize ipsilesional tract intersections in the
clinical summary. Contralateral zero rows may be omitted only after confirming zero
intersection. Do not assume the contralateral side has zero intersection "by definition";
a crossing, bilateral, or midline lesion can involve either side.

### 5.2 Lesion involvement: volume and reconstructed-streamline fraction

Do not interpret raw streamline counts biologically. Streamline counts are determined by
seeding and reconstruction settings and are not axon counts. Use `intersect volume(mm^3)`
as the spatial overlap measurement. When a fraction helps communicate how much of a
reconstructed bundle contacts a lesion compartment, use the T2R `number of tracts` only as
the numerator of a reconstruction fraction:

```text
intersection volume (mm^3) = T2R "intersect volume(mm^3)" for that region
reconstructed-streamline fraction = T2R "number of tracts" / total bundle streamlines
```

A streamline can pass through multiple lesion compartments, so volumes and fractions are
not expected to sum across compartments.

T2R measures geometric intersection of reconstructed streamlines with segmented regions;
it does not measure histological invasion. Do **not** use the generic T2R `intersect ratio`
as the bundle streamline fraction.

A zero T2R count is valid only after confirming that the tract is nonempty, the lesion
region is nonempty, both belong to the same subject/mapping context, and T2R completed
successfully.

### Required checkpoint after Step 5

For each clinically important pathway, summarize only the lesion compartments with
meaningful intersection plus important zeros:

```text
Findings
- pathway: total reconstructed streamlines
- Enhancing Tumor: intersection volume; reconstructed-streamline fraction when useful
- Necrosis: intersection volume; reconstructed-streamline fraction when useful
- Tumor Core: intersection volume; reconstructed-streamline fraction when useful
- Peritumoral Edema: intersection volume; reconstructed-streamline fraction when useful

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

Compare ipsilesional and contralateral morphology descriptively. Higher ipsilesional curl
can be consistent with a longer or more winding reconstructed route, but curl alone does
not establish tumor-induced displacement. Attribute displacement to the lesion only when
the live/saved 3D geometry also shows the pathway being pushed around the lesion or edema
and the overall anatomical context supports that interpretation. If a pathway has no lesion
contact/intersection, report a large curl asymmetry as a descriptive reconstruction
asymmetry rather than claiming that the tumor caused it. Do not use a universal percentage
threshold such as 20% to diagnose displacement.

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

Offer to save a rotating video for each pathway with the tumor. Keep the
White_Matter region visible for anatomical context:

```bash
bash ./dsi.sh show_only_tracts "<tract-index>"
bash ./dsi.sh show_only_regions "<white-matter-index>&<tumor-core-index>"
bash ./dsi.sh save_rotation_video "<output-path>.avi"
```

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
- pathway — side — total reconstructed streamlines (reconstruction denominator only)
- Tumor Core intersection volume and reconstructed-streamline fraction when useful
- enhancing-tumor intersection volume and reconstructed-streamline fraction when useful
- edema intersection volume and reconstructed-streamline fraction when useful
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

## 11. Required full PDF tumor and tract-tumor report protocol

When the user requests a complete brain-tumor report or PDF, this section is mandatory.
It captures the figure-generation and report-layout requirements needed to produce a
neurosurgeon-readable result. Where these report-specific requirements differ from generic
screenshot defaults elsewhere, follow this section for the final report. For the final PDF,
this section also resolves any earlier ambiguity about figure style, T2R presentation, and
morphology wording.

### 11.1 The final report must be complete, not a slide export

- Produce a real PDF report; do not substitute a PowerPoint or a slide-deck export. §11.14
  gives the accepted layout and a ReportLab script that builds it.
- The report must contain both a **tumor report** and a **tract-tumor report**.
- **Every page must contain at least one figure that is directly relevant to that page.**
  A table-only or prose-only page is incomplete.
- A figure may be structural MRI, a quantitative chart, a direct DSI Studio 3D rendering,
  or a tract-on-slice image, but it must help the reader interpret the material on that page.
- Page 1 should identify the case/study and include a short executive summary in addition to
  representative imaging.
- Render the finished PDF and inspect every page before delivery. Check for clipping,
  unreadable labels, wrong orientation, missing White_Matter brain envelopes, corrupted 3D views, and pages
  without a relevant figure. Do not call the report finished until this visual QC passes.

### 11.2 3D figures: direct DSI Studio exports with the segmentation-derived White_Matter brain envelope

Final 3D figures must be **fresh direct DSI Studio saves**. Do not invert a black screenshot,
replace its background, hue-filter an all-tract image, or synthesize missing anatomy.

The canonical brain envelope is the **defragmented `White_Matter` region from
`human_tumor` segmentation**. Do not use `add_surface`, a separate `surface` object, or a
separate isosurface.

#### Canonical tumor + brain-envelope rendering preset

1. Resolve current region rows by name with `list_region`.
2. Defragment `White_Matter`:

```bash
bash ./dsi.sh region_action_defragment <white-matter-index>
bash ./dsi.sh list_region
```

3. Preserve DSI-assigned RGB and change alpha only:

```text
Necrosis           alpha = 200
Peritumoral Edema  alpha = 80
Enhancing Tumor    alpha = 100
White_Matter       alpha = 10
```

4. Move `White_Matter` to the **last Region-table row**, rechecking indices as it moves.
5. Show only the three tumor compartments plus `White_Matter` unless extra tissue anatomy
   is specifically required.
6. Disable separate surface and slice objects:

```bash
bash ./dsi.sh set_param show_surface 0
bash ./dsi.sh set_param show_slice 0
```

7. Use a white 3D background:

```bash
bash ./dsi.sh set_param bkg_color 16777215
```

The cleaned `White_Matter` region should appear as a very translucent brain envelope around
the more opaque tumor compartments.

#### Tract coloring in tumor + tract figures

Do **not** use directional tract coloring in final report figures. Use assigned colors and
cluster-color the tract bundles:

```bash
bash ./dsi.sh set_param tract_color_style 1
bash ./dsi.sh color_all_cluster
```

`tract_color_style=1` is **Assigned** color. Use `show_only_tracts` for one-tract report
figures; preserve the bundle's assigned cluster color. Keep distinct assigned cluster colors
in the all-tract overview.

For every final 3D scene, set an explicit view, call `get_camera`, save with `save_screen`,
and inspect the saved PNG. If the image is missing the `White_Matter` envelope, a tumor
compartment, or the requested tract, return to DSI Studio and regenerate it.

#### One direct view per saved 3D image — no stereo report figures

For final PDF figures, **do not use stereo/lateral-pair rendering such as `save_lr_screen`**
to represent two viewpoints in one image. A stereo pair is not a substitute for two
anatomically specified orthogonal views and often obscures orientation and tumor–tract
relationships.

When two viewpoints are required:

1. set the first explicit view (for example axial), call `get_camera`, and save it with
   `save_screen`;
2. set the second explicit view (for example coronal or sagittal), call `get_camera`, and
   save it separately with `save_screen`;
3. place the two independent PNGs side-by-side in the PDF layout;
4. label each panel with its view and anatomical orientation.

Each saved 3D PNG must therefore correspond to one known camera/view state.


### 11.3 2D slice figures stay on the standard black background

2D structural/slice figures should retain the standard DSI Studio **black background**.
Do not convert them to white to match the 3D figures. The intended report convention is:

```text
3D rendering -> white background
2D structural/slice view -> black background
```

Choose the structural background that best demonstrates the relationship:

- contrast-enhanced T1w for enhancing tumor / tumor-core anatomy;
- FLAIR for edema and tract-to-edema relationships;
- another structural modality only when it better answers the anatomical question.

For each tract-specific slice figure:

- delineate the tumor/edema location with the segmentation overlay or boundary;
- display the tract in the slice;
- label the tract by name and side directly on the figure;
- choose the axial, coronal, or sagittal slice that actually demonstrates the relative
  position; do not use an arbitrary plane merely for consistency.



#### Clean 2D presentation state for the final PDF

A final-report structural image must look like a presentation figure, not a working analysis
screen. Before saving a 2D report figure:

- hide diffusion fiber-orientation glyphs unless the user explicitly requests them;
- hide crosshairs/cursor guides unless they are essential to the stated figure purpose;
- hide unrelated tracts, regions, labels, and analysis overlays;
- show the structural MRI that best demonstrates the lesion relationship;
- show only the relevant tumor/edema segmentation overlay or boundary;
- for a tract-specific slice, show and label only the tract being discussed;
- add explicit anatomical orientation labels from the actual slice metadata/convention.

Do not use a cluttered QC screenshot as a final report figure. QC views may contain
crosshairs, glyphs, or extra overlays, but the final saved figure must be regenerated in the
clean presentation state.

### 11.4 Orientation labels are mandatory

Every final report image must make its anatomical orientation understandable. Never assume
that the reader can infer the view from tract shape alone.

For **3D figures**, obtain `get_camera` immediately after setting the view and use its
`view_direction`, `image_left`, and `image_up` output to assign labels. Do not guess from
screen position. For the standard unflipped DSI views, the currently verified camera output
is:

```text
set_view 2 0 (axial):
  viewed from Inferior toward Superior
  image_left = subject Right
  image_up   = subject Anterior
  labels: image left R, image right L, top A, bottom P

set_view 1 0 (coronal):
  viewed from Anterior toward Posterior
  image_left = subject Right
  image_up   = subject Superior
  labels: image left R, image right L, top S, bottom I

set_view 0 0 (sagittal):
  viewed from Left toward Right
  image_left = subject Anterior
  image_up   = subject Superior
  labels: image left A, image right P, top S, bottom I
```

Still call `get_camera` and verify these for the actual scene, especially after flipping,
rotation, or oblique viewing. For an oblique view, either derive correct labels from camera
metadata or avoid adding misleading cardinal labels.

For **2D ROI/slice figures**, use DSI Studio's orientation metadata / `R_side` and the actual
slice convention. When the slice uses radiological convention, image left is patient right;
label it accordingly. Do not silently switch between radiological and neurological
convention.

The side of a tract and the camera viewing side are different concepts. A figure containing
`Right CST` is not automatically a "right sagittal view." Label the tract separately from
the view orientation.

Do not put raw voxel x/y/z coordinates in the clinical report as an orientation aid.
Neurosurgeons need recognizable anatomy and explicit R/L/A/P/S/I labels, not internal voxel
numbers.

### 11.5 Required report page sequence

A complete presurgical tumor/tract report **must use the following non-mergeable page
roles unless the user explicitly requests a different structure**. Additional pages are
allowed. Do not collapse required roles together merely to shorten the report. Missing a
required page/figure is a report-gate failure, not permission to produce a shorter PDF.

#### Page 1 — case identification, executive summary, and representative tumor MRI

- Identify the case/study/subject at the top of the report.
- Give a short 2–5 sentence executive summary of lesion location, tumor-core/edema burden,
  and the main tract relationship; keep the detailed interpretation for later pages.
- Show representative contrast-enhanced T1w and/or FLAIR centered through the tumor core.
- **Do not substitute an all-tract or tract-tumor 3D rendering for the representative tumor MRI on Page 1.**
- 2D images remain black background and must use the clean presentation state in §11.3.
- Add correct orientation labels.
- Briefly describe enhancement, necrosis, edema, and the anatomical location visible on
  the images.

#### Page 2 — tumor burden, composition, and 3D location

Show **both** composition summaries; one does not replace the other:

```text
Whole segmented lesion = Necrosis + Enhancing Tumor + Peritumoral Edema
Tumor Core             = Necrosis + Enhancing Tumor
```

For the whole lesion, report each compartment's volume and percentage of the whole lesion.
For Tumor Core, report necrosis and enhancing-tumor volumes and their percentage of Tumor
Core. A "Tumor Core composition" bar with only necrosis and enhancing tumor is correct but
is incomplete if the report does not also show the whole-lesion composition including edema.

Include a compact volume/composition table so the exact numbers are readable even if the
composition chart is small. When reliable orthogonal diameters are available from Step 1,
include them in the lesion description as well.

On the same page include direct DSI Studio **tumor + cleaned `White_Matter` brain-envelope
3D views**, preferably axial and coronal, on a white background. The segmentation-derived
`White_Matter` region is the required spatial anchor; do not substitute `add_surface` or a
separate isosurface.

#### Page 3 — tumor-atlas localization

Keep `CHA` and `Brodmann` completely separate. They are different atlases and must not be
mixed in one atlas-overlap list, table, or chart.

For every reported nonzero atlas intersection show:

```text
overlap volume (mL or mm^3)
percentage of Tumor Core = overlap volume / Tumor Core volume * 100
```

The percentage is **the percentage of the Tumor Core lying in that atlas region**, not the
percentage of the atlas region occupied by tumor. Because these are different atlas
parcellations and the lesion may include white matter, percentages are not expected to sum
to 100%.

Use separate CHA and Brodmann charts/tables. **Do not replace the tables/charts with prose.**
Each reported atlas row must show both overlap volume and `% Tumor Core`. This atlas page
must also contain a representative anatomical figure, such as a direct DSI 3D tumor +
cleaned `White_Matter` brain-envelope view or a structural tumor slice. A chart/table alone
is not enough, and prose alone is not enough.

#### Next page — all-tract tumor overview

The tract-tumor section starts with an **all selected tracts + tumor + cleaned `White_Matter`
brain envelope** 3D overview. Use fresh direct DSI Studio white-background exports and include orientation
labels. This overview establishes the global spatial context before showing individual
pathways.

Also include a compact quantitative overview identifying which ipsilesional pathways are
actually affected. For each selected ipsilesional tract, show the most useful combination
of:

```text
tract name and side
total reconstructed streamlines (reconstruction denominator only)
Tumor Core intersection volume / fraction
Enhancing Tumor intersection volume / fraction
Necrosis intersection volume / fraction
Edema intersection volume / fraction
```

A small bar chart of reconstructed-streamline fraction or intersection volume may accompany
the table. Highlight the pathways that will receive their own pages.

#### Following pages — one affected/clinically important tract at a time

After the all-tract overview, show each clinically selected ipsilesional pathway separately.
By default, a tract gets its own page if it has a nonzero intersection with any lesion
compartment, or if the 3D review shows clinically important adjacency, marginal course,
compression, or displacement even when voxel intersection is zero. If the user explicitly
asks for "each tract," generate a page for every selected tract, including zero-contact
tracts; do not silently collapse them into one overview.

Each tract page should include:

1. **Direct DSI 3D figure with one tract only**, plus tumor compartments and the cleaned `White_Matter` brain envelope.
2. Two useful orthogonal 3D views chosen to show the relationship. Examples:
   - CST: axial + sagittal is often useful;
   - SLF: axial + coronal is often useful;
   but choose the planes from the actual anatomy rather than following these mechanically.
3. At least one **black-background structural slice** (T1w-gd or FLAIR) with tumor location
   delineated and the tract location labeled.
4. T2R/spatial metrics and a concise interpretation of whether the tract intersects Tumor
   Core, enhancing tumor, necrosis, edema, or only approaches the lesion.
5. When useful, a short bilateral morphology comparison, but do not attribute morphology
   asymmetry to the tumor unless the 3D geometry supports that conclusion.

Never use an all-tract image as the tract-specific figure. Never create a tract-specific
figure by hue filtering or masking an all-tract screenshot.

#### Final page — integrated interpretation

Include at least one relevant figure or quantitative chart. Summarize bilateral morphology,
important T2R findings, spatial relationships, and the major interpretation caveats. End
with 3–6 prioritized intervention-relevant points. Keep this page visually anchored rather
than ending with prose alone.

### 11.6 T2R quantities in the final report

`intersect volume(mm^3)` and reconstructed-streamline fraction answer different questions
and must not be mislabeled.

For a tract and lesion compartment, when both are useful report:

```text
intersection volume = T2R intersect volume(mm^3)
reconstructed-streamline fraction = T2R number of tracts / total bundle streamlines
```

The streamline fraction is a property of the reconstruction, not an axon fraction or a
biological infiltration fraction. The raw streamline count is seeding-dependent; use it to
calculate/describe the reconstruction fraction, not as a biological cell/axon measure.

Do **not** use the generic T2R `intersect ratio` as the streamline fraction. Do not call a
streamline fraction an "overlap volume."

Preferred language includes:

```text
No reconstructed [tract] streamlines entered the Tumor Core.
[X]% of reconstructed [tract] streamlines intersect the segmented edema field.
```

Edema intersection is a geometric tractography relationship and does not establish
histologic invasion. Zero reconstructed Tumor-Core intersection does not prove a safe
surgical plane.

### 11.7 Figure-generation order and state discipline

1. Finish segmentation, tracking, T2R, and morphology measurements first.
2. Resolve region indices by name with `list_region`.
3. Defragment `White_Matter` and verify a coherent brain envelope.
4. Preserve DSI RGB and set alpha only: Necrosis 200, Edema 80, Enhancing Tumor 100,
   White_Matter 10.
5. Move `White_Matter` to the final Region-table row so it renders last.
6. Show the three tumor compartments plus `White_Matter`; hide unnecessary tissue labels.
7. Set `show_surface=0` and `show_slice=0`. Do not call `add_surface`; no separate isosurface
   is required.
8. Set `bkg_color=16777215` for white-background 3D rendering.
9. After all report tracts are present, set `tract_color_style=1` and run
   `color_all_cluster`; do not use directional tract color in the final report. Re-run these
   commands if a tract is added/reloaded or the tract scene is rebuilt before saving.
10. Generate all required tumor-only, all-tract, and single-tract 3D figures while this
    preset remains active. Save one explicit camera/view per PNG with `save_screen`; do not
    use stereo/lateral-pair figures as a substitute for orthogonal views.
11. For each view, call `get_camera`, save with `save_screen`, and visually inspect the PNG.
12. Keep 2D structural/slice figures on black background.
13. Assemble the PDF only from accepted direct DSI exports.

### 11.8 Final report QC checklist

Before delivering the PDF verify all of the following:

```text
[ ] every page has a relevant figure
[ ] page 1 identifies the case and contains a concise executive summary
[ ] 3D figures are fresh direct DSI Studio saves, not inverted/recolored substitutes
[ ] all 3D figures use white background
[ ] White_Matter comes from human_tumor segmentation, not add_surface or a separate isosurface
[ ] White_Matter was defragmented/cleaned before final 3D rendering
[ ] White_Matter alpha is 10 and White_Matter is the final Region-table row
[ ] Necrosis / Peritumoral Edema / Enhancing Tumor alpha values are 200 / 80 / 100
[ ] tumor-region RGB values are the original DSI-assigned RGB values
[ ] final tract figures use Assigned cluster colors, not directional colors
[ ] tract scenes were cluster-colored after the final tract set was loaded
[ ] no stereo/lateral-pair image substitutes for required orthogonal 3D views
[ ] Page 1 contains representative tumor MRI, not only tract-tumor 3D
[ ] final 2D figures hide nonessential crosshairs and diffusion glyphs
[ ] required page roles were not merged merely to shorten the report
[ ] final page contains a relevant figure or quantitative chart
[ ] all 2D slice figures retain black background
[ ] defragmented White_Matter region is visibly present as the brain envelope in each required 3D scene
[ ] every image has correct anatomical orientation labels or unambiguous orientation metadata
[ ] radiological vs neurological convention is handled correctly for 2D slices
[ ] no raw voxel x/y/z coordinates are presented as clinical localization
[ ] whole-lesion and Tumor-Core composition are both reported
[ ] exact compartment volumes and percentages are readable in a table/chart
[ ] CHA and Brodmann results are separated
[ ] atlas overlap reports both volume and percentage of Tumor Core
[ ] atlas page has a representative anatomical figure
[ ] tract section starts with all-tract + tumor overview
[ ] all-tract overview contains a compact quantitative tract/lesion summary
[ ] tract-specific pages use one tract at a time
[ ] each affected/clinically important tract gets its own page unless the user requests otherwise
[ ] each tract page has a structural slice showing tumor/tract relative position
[ ] tumor is delineated and tract is labeled on the slice
[ ] T2R intersect volume and reconstructed-streamline fraction are not confused
[ ] raw streamline counts are not interpreted biologically
[ ] curl/morphology asymmetry is not automatically attributed to tumor displacement
[ ] edema intersection is not called histologic invasion
[ ] no figure is visibly corrupted, missing its White_Matter brain envelope, or generated by post-hoc hue masking
[ ] the rendered PDF has been inspected page by page
```

Record the filenames of the accepted direct DSI exports, their `set_view`/camera metadata,
background convention, and any rotations used so another agent can reproduce the same
report later.

### 11.9 Pre-assembly data and figure manifest

Before building the PDF, create a case-specific manifest and do not start final assembly
until the required entries are present or explicitly marked unavailable.

**Quantitative data manifest**

```text
Lesion
- Enhancing Tumor volume
- Necrosis volume
- Tumor Core volume
- Peritumoral Edema volume
- Whole segmented lesion volume
- whole-lesion percentages
- Tumor-Core percentages
- orthogonal diameters when reliable

Atlas localization
- CHA: each reported nonzero region, overlap volume, % Tumor Core
- Brodmann: each reported nonzero area, overlap volume, % Tumor Core

Tracts
- selected bilateral tract names and side
- total reconstructed streamline count for each bundle
- T2R intersection volume by lesion compartment
- T2R reconstructed-streamline numerator/denominator/fraction when useful
- bilateral morphology statistics needed for interpretation
- explicit list of affected/clinically important ipsilesional tracts that require pages
```

**Figure manifest**

```text
2D black-background images
- representative tumor T1w-gd and/or FLAIR with orientation labels
- one appropriate tumor/tract structural slice for each tract-specific page

Fresh direct DSI 3D white-background images
- tumor only + cleaned White_Matter brain envelope: at least axial and coronal
- all selected tracts + tumor + cleaned White_Matter brain envelope: at least one overview, preferably two views
- each affected/clinically important tract + tumor + cleaned White_Matter brain envelope: two useful orthogonal views
```

For every accepted 3D file record the scene contents, view, `get_camera` orientation,
background state, and whether the White_Matter brain envelope/tumor/tract are visibly present. If a required
figure is missing, regenerate it in DSI Studio rather than substituting an older or edited
image.

**Freeze accepted case state before figure generation**

Record the accepted tract list and the exact tract rows/counts used for T2R and morphology.
Figure generation must use this same accepted tract state. If a previously accepted case is
being reproduced, do not shrink the tract set based on a new agent's pathway-selection
judgment. If a tract must be re-run, update the manifest and repeat dependent T2R/morphology
measurements so the report does not mix results from different reconstructions.


### 11.10 Allowed post-processing and annotation

Post-processing must not change the anatomical content of a DSI Studio 3D render. The
following are acceptable when they preserve the underlying image:

- adding R/L/A/P/S/I orientation labels derived from camera/slice metadata;
- adding a tract name/side label and an explanatory arrow;
- adding captions, borders, or page-layout whitespace;
- cropping unused outer margin when no anatomy, brain-envelope, tract, or orientation context is removed.

Do **not** use post-processing to:

- invert or replace the 3D background;
- recolor/hue-filter an all-tract image to simulate a single tract;
- remove structures from a 3D image;
- synthesize a missing tumor or White_Matter brain envelope;
- mirror/flip a figure without recalculating and relabeling orientation.

If the direct DSI export does not contain the desired scene, return to DSI Studio and save
the scene again.

### 11.11 Canonical report composition for a new agent

Unless the user requests a different structure, a new agent should be able to generate the
report from the manifest using this default composition:

| Page | Required content | Minimum figure content |
|---|---|---|
| 1 | Case ID/title, short executive summary, representative tumor MRI | Black-background oriented T1w-gd and/or FLAIR through tumor core |
| 2 | Lesion volume table, whole-lesion composition, Tumor-Core composition, lesion description | Fresh direct white-background axial + coronal tumor + cleaned White_Matter brain-envelope 3D |
| 3 | CHA table/chart and Brodmann table/chart, kept separate; anatomical interpretation | Representative tumor anatomy figure with orientation |
| 4 | All-tract tumor overview plus compact tract-to-lesion quantitative summary | Fresh direct white-background all-tract + tumor + cleaned White_Matter brain-envelope 3D |
| 5..N | One affected/clinically important tract per page; T2R and spatial interpretation | Two direct white-background single-tract 3D views + one black-background tract/tumor slice |
| Final | Integrated tumor + tract interpretation, morphology context, limitations, prioritized clinical points | At least one relevant quantitative chart or overview figure |

The number of tract pages is dynamic. Do not force a fixed seven-page report when more
tracts are clinically important, and do not invent tract pages for pathways that were not
analyzed. Conversely, do not omit an affected tract merely to keep the report short.

A new agent should not declare the report complete until the quantitative manifest, figure
manifest, canonical page composition, and QC checklist have all been satisfied or any
missing item has been explicitly disclosed as unavailable.

### 11.12 Machine-checkable REPORT_GATE — blocking prerequisite for PDF assembly

For a complete presurgical report, create and fill this gate **before** assembling the PDF.
Use `PASS`, `UNAVAILABLE: <reason>`, or `FAIL`. PDF assembly is allowed only when every
mandatory item is `PASS` or the user has explicitly accepted an unavailable item.

```text
REPORT_GATE

CASE_STATE
accepted_tract_list_frozen                 = PASS
T2R_matches_accepted_tract_state           = PASS
morphology_matches_accepted_tract_state    = PASS

PAGE_1_TUMOR_MRI
case_id_and_executive_summary              = PASS
representative_tumor_MRI                   = PASS
clean_2D_presentation                      = PASS
orientation_labels                         = PASS

PAGE_2_TUMOR_BURDEN_AND_3D
whole_lesion_volume                        = PASS
whole_lesion_percentages                   = PASS
Tumor_Core_volume                          = PASS
Tumor_Core_percentages                     = PASS
composition_table_or_chart                 = PASS
tumor_3D_axial_direct_DSI                  = PASS
tumor_3D_coronal_direct_DSI                = PASS
White_Matter_defragmented_alpha10_last     = PASS
no_add_surface_or_separate_isosurface      = PASS

PAGE_3_ATLAS
CHA_separate_table_or_chart                = PASS
CHA_volume_and_percent_Tumor_Core          = PASS
Brodmann_separate_table_or_chart           = PASS
Brodmann_volume_and_percent_Tumor_Core     = PASS
representative_anatomical_figure           = PASS

ALL_TRACT_OVERVIEW
all_selected_tracts_present                = PASS
assigned_cluster_colors                    = PASS
all_tract_tumor_WM_direct_3D               = PASS
quantitative_tract_lesion_summary          = PASS
orientation_labels                         = PASS

TRACT_PAGE_<TRACT_NAME>
one_tract_only_in_each_3D_scene            = PASS
assigned_cluster_color                     = PASS
direct_DSI_3D_view_1                       = PASS
direct_DSI_3D_view_2                       = PASS
views_are_independent_not_stereo_pair      = PASS
clean_structural_tract_tumor_slice         = PASS
T2R_metrics_and_spatial_interpretation     = PASS
orientation_labels                         = PASS

# Repeat TRACT_PAGE block for every affected/clinically important tract.

FINAL_PAGE
integrated_interpretation                  = PASS
relevant_figure_or_quantitative_chart      = PASS
prioritized_intervention_points            = PASS

GLOBAL_VISUAL_QC
every_page_has_relevant_figure             = PASS
no_required_page_roles_merged_for_brevity  = PASS
no_stereo_or_save_lr_screen_report_figure  = PASS
no_nonessential_crosshairs_or_glyphs       = PASS
all_3D_white_background                    = PASS
all_2D_black_background                    = PASS
orientation_verified                       = PASS
rendered_PDF_inspected_page_by_page        = PASS

PDF_ASSEMBLY_ALLOWED                       = YES
```

Rules:

- `PDF_ASSEMBLY_ALLOWED = YES` is valid only when all mandatory items above pass.
- Do not convert a `FAIL` into a shorter report. Return to DSI Studio and create the missing
  figure or measurement.
- Do not silently merge pages to make missing figures disappear.
- A final page without a figure/chart is a failure.
- An atlas section that reports overlap volumes without `% Tumor Core` is a failure.
- A composition section that reports only volumes without both percentage denominators is a
  failure.
- A tract page without two independent direct DSI 3D views and a clean structural slice is
  a failure.

For a case with two clinically important tract pages (for example CST and SLF), the default
minimum structure is therefore seven page roles:

```text
P1 tumor MRI + executive summary
P2 tumor burden/composition + tumor-only 3D
P3 CHA + Brodmann localization
P4 all-tract + tumor overview
P5 tract 1
P6 tract 2
P7 integrated synthesis
```

More clinically important tracts add more tract pages; they are not collapsed into P4.

### 11.13 Worked example: figure generation for UPenn-GBM sub-003

This is the accepted figure set for a right-hemisphere case with CST and SLF tract pages.
Use it as a template: replace the row indices with the ones `list_region` / `list_tract`
report for the current case, and the numbers with the case's frozen manifest (§11.9).

#### DSI Studio commands for the 3D figures

```bash
dsi() { bash ./dsi.sh "$@"; }
dsi set_window <tracking-window-id>

# Rows after human_tumor: 0 White_Matter, 1 Gray_Matter, 2 Cerebellar_Cortex,
# 3 Basal_Ganglia, 4 Others, 5 Necrosis, 6 Peritumoral Edema, 7 Enhancing Tumor
dsi list_region
dsi region_action_defragment 0

# Alpha only on the subject's own RGB (#AARRGGBB as an unsigned integer)
dsi set_region_color 0 182970350    # 0x0AE7E7EE White_Matter      alpha 10
dsi set_region_color 5 3361425486   # 0xC85B484E Necrosis          alpha 200
dsi set_region_color 6 1350801323   # 0x508397AB Peritumoral Edema alpha 80
dsi set_region_color 7 1690070641   # 0x64BC6E71 Enhancing Tumor   alpha 100

# White_Matter to the last row (it moves 0 -> 7); the tumor rows become 4, 5, 6
for row in 0 1 2 3 4 5 6; do dsi move_down_region $row; done
dsi list_region

dsi show_only_regions "4&5&6&7"
dsi set_param show_region 1
dsi set_param show_surface 0
dsi set_param show_slice 0
dsi set_param bkg_color 16777215
dsi set_zoom 0.8

# Tumor only: axial and coronal
dsi check_uncheck_all_tract 0
dsi set_param show_tract 0
dsi set_view 2 0; dsi get_camera; dsi save_screen sub003_tumor_WM_axial3D.png "1920 1080"
dsi set_view 1 0; dsi get_camera; dsi save_screen sub003_tumor_WM_coronal3D.png "1920 1080"

# The accepted bilateral tract set; poll list_tract until all eight are done,
# then resolve each row by name (here 0/1 CST L/R, 2/3 SLF L/R, 4/5 AF L/R, 6/7 FAT L/R)
for t in ProjectionBrainstem_CorticospinalTract Association_SuperiorLongitudinalFasciculus \
         Association_ArcuateFasciculus Association_FrontalAslantTract; do
    dsi run_auto_track ${t}L; dsi run_auto_track ${t}R
done
dsi list_tract

dsi set_param tract_color_style 1
dsi color_all_cluster
dsi set_param show_tract 1

# All tracts + tumor
dsi show_only_tracts "0&1&2&3&4&5&6&7"
dsi set_view 2 0; dsi get_camera; dsi save_screen sub003_alltracts_tumor_WM_axial3D.png "1920 1080"
dsi set_view 1 0; dsi get_camera; dsi save_screen sub003_alltracts_tumor_WM_coronal3D.png "1920 1080"

# Right CST (row 1): axial + sagittal
dsi show_only_tracts "1"
dsi set_view 2 0; dsi get_camera; dsi save_screen sub003_CST_R_tumor_WM_axial3D.png "1920 1080"
dsi set_view 0 0; dsi get_camera; dsi save_screen sub003_CST_R_tumor_WM_sagittal3D.png "1920 1080"

# Right SLF (row 3): axial + coronal
dsi show_only_tracts "3"
dsi set_view 2 0; dsi get_camera; dsi save_screen sub003_SLF_R_tumor_WM_axial3D.png "1920 1080"
dsi set_view 1 0; dsi get_camera; dsi save_screen sub003_SLF_R_tumor_WM_coronal3D.png "1920 1080"
```

Inspect each PNG after saving (or `preview_screen 3d` before it). The orientation labels
come from `get_camera`, as in §11.4.

#### DSI Studio commands for the 2D figures

```bash
# Representative tumor MRI (repeat with the FLAIR slice name for the FLAIR panel)
dsi set_slice_by_name "<exact ceT1w / T1w-gd slice name>"
dsi set_roi_view 2
dsi move_slice_to_region <Tumor-Core-index>
dsi check_uncheck_all_tract 0
dsi save_roi_screen sub003_ceT1w_corecenter.png

# Tract on FLAIR: tumor compartments only, no White_Matter in 2D
dsi set_slice_by_name "<exact FLAIR slice name>"
dsi set_roi_view 2
dsi move_slice_to_region <Tumor-Core-index>
dsi show_only_regions "4&5&6"
dsi show_only_tracts "1"; dsi save_roi_screen sub003_CST_R_FLAIR_axial.png
dsi show_only_tracts "3"; dsi save_roi_screen sub003_SLF_R_FLAIR_axial.png
```

Tract names, arrows and R/L/A/P labels are added afterwards (§11.10, code in §11.14); DSI Studio
does not draw them.

#### Frozen quantitative inputs

When reproducing an accepted report, use its recorded values. Re-running AutoTrack changes
the streamline counts: one reproduction attempt reported SLF 587/5271 instead of the
accepted 619/5315 and was rejected.

```text
Necrosis 11.961 mL   Enhancing 6.702 mL   Tumor Core 18.663 mL
Edema 60.477 mL      Whole lesion 79.140 mL

Right tract   streamlines   edema-intersecting   edema intersect volume   Tumor Core
CST           8595          8595 (100%)          1424 mm^3                0
SLF           5315          619 (11.6%)          556 mm^3                 0
Arcuate       7255          0                    -                        0
FAT           5812          0                    -                        0
```

#### Python for the quantitative charts

Matplotlib defaults (blue/orange/green); the figure sizes match the accepted report.

```python
import numpy as np
import matplotlib.pyplot as plt

plt.rcParams.update({"font.size":18,"axes.titlesize":20,"axes.labelsize":18,
                     "xtick.labelsize":18,"ytick.labelsize":18,"legend.fontsize":16})

necrosis,enhancing,edema = 11.961,6.702,60.477
core = necrosis+enhancing
whole = core+edema
cha = [("Posterior cingulate",5.501),("Precentral",1.250),("Postcentral",0.768),
       ("Premotor",0.445),("Precuneus",0.127)]
brodmann = [("BA31 right",2.493),("BA4 right",1.756),("BA23 right",1.046),("BA23 left",0.460),
            ("BA24 right",0.458),("BA5 right",0.371),("BA6 right",0.337),("BA24 left",0.157),
            ("BA31 left",0.111)]
tracts = ["CST","SLF","Arcuate","FAT"]
edema_pct = np.array([8595,619,0,0])/np.array([8595,5315,7255,5812])*100
curl_left = [1.120708,1.692461,1.236686,1.192565]
curl_right = [1.253219,1.347196,2.282737,1.223556]

def composition(parts,total,title,file):  # stacked bar: volume and % of the stated total
    fig,ax = plt.subplots(figsize=(12.00,2.29),dpi=100)
    start = 0.0
    for name,value in parts:
        ax.barh([0],[value],left=[start])
        ax.text(start+value/2,0,f"{name}\n{value:.3f} mL\n{value/total*100:.1f}%",
                ha="center",va="center",fontsize=16)
        start += value
    ax.set_title(f"{title} = {total:.3f} mL")
    ax.set_xlim(0,total)
    ax.set_yticks([])
    fig.tight_layout(pad=0.25)
    fig.savefig(file,dpi=100)
    plt.close(fig)

def atlas(rows,title,size,xmax,unit,file):  # one atlas per chart; % is of Tumor Core
    names,volumes = zip(*rows[::-1])       # largest at the top
    fig,ax = plt.subplots(figsize=size,dpi=100)
    for bar,value in zip(ax.barh(names,volumes),volumes):
        ax.text(value+xmax*0.008,bar.get_y()+bar.get_height()/2,
                f"{value:.3f}{unit} ({value/core*100:.1f}%)",va="center",fontsize=14)
    ax.set_title(title)
    ax.set_xlabel("Overlap volume (mL)")
    ax.set_xlim(0,xmax)
    fig.tight_layout()
    fig.savefig(file,dpi=100)
    plt.close(fig)

composition([("Necrosis",necrosis),("Enhancing",enhancing),("Edema",edema)],whole,
            "Whole segmented lesion","whole_lesion_composition.png")
composition([("Necrosis",necrosis),("Enhancing",enhancing)],core,
            "Tumor core","tumor_core_composition.png")
atlas(cha,"CHA atlas: tumor-core overlap",(9.86,4.74),7.6," mL","CHA_tumor_core_overlap.png")
atlas(brodmann,"Brodmann area atlas: tumor-core overlap",(9.85,6.10),3.55,"",
      "Brodmann_tumor_core_overlap.png")

fig,ax = plt.subplots(figsize=(9.69,4.06),dpi=100)
for bar,value in zip(ax.bar(tracts,edema_pct),edema_pct):
    ax.text(bar.get_x()+bar.get_width()/2,value+1,f"{value:.1f}%",ha="center",va="bottom",fontsize=15)
ax.set_title("Right tract-to-edema relationship")
ax.set_ylabel("Edema-intersecting\nstreamlines (%)")
ax.set_ylim(0,115)
fig.tight_layout()
fig.savefig("right_tract_to_edema.png",dpi=100)
plt.close(fig)

x = np.arange(len(tracts))
fig,ax = plt.subplots(figsize=(9.69,4.06),dpi=100)
ax.bar(x-0.18,curl_left,0.36,label="Left")
ax.bar(x+0.18,curl_right,0.36,label="Right")
ax.set_xticks(x)
ax.set_xticklabels(tracts)
ax.set_ylabel("Curl")
ax.set_title("Bilateral tract morphology")
ax.set_ylim(0,2.4)
ax.legend()
fig.tight_layout()
fig.savefig("bilateral_tract_morphology.png",dpi=100)
plt.close(fig)
```

The y-axis label of the edema chart is a reconstructed-streamline fraction (§11.6), not an
axon or infiltration fraction.

### 11.14 Report assembly: the accepted sub-003 PDF layout

The accepted sub-003 report was built with ReportLab from the 11.13 PNGs and charts. The
script below reproduces its seven pages: header and summary box, two-panel figure rows with a
caption strip, navy-header tables, side-by-side figure and text blocks, and a footer with the
case name and page number. For a new case, keep the structure and replace the values, text and
file names with the case manifest (11.9). Add or remove tract pages by editing the tract list
(11.5).

Orientation labels are written into a 48-pixel margin, never over the anatomy. 3D labels come
from `get_camera` for that save; 2D labels come from `R_side` (radiological here). A tract
callout needs the tract's pixel position in the saved slice: open the PNG, find the tract, and
place the label box in empty space so the leader line does not cross the lesion.

```python
from PIL import Image as PILImage, ImageDraw, ImageFont

def font(size):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf",size)
    except OSError:
        return ImageFont.load_default(size)

def orient(src,dst,left,right,top,bottom,dark=False,note=None,callout=None):
    """Pad a DSI export and write R/L/A/P/S/I labels (from get_camera or R_side) in the margin.
    callout = (text,(x,y) of the tract in source pixels,(x,y) of the label box)."""
    im = PILImage.open(src).convert("RGB")
    m = 48
    out = PILImage.new("RGB",(im.width+2*m,im.height+2*m),"black" if dark else "white")
    out.paste(im,(m,m))
    d,fg = ImageDraw.Draw(out),"white" if dark else "black"
    W,H = out.size
    for text,xy in ((top,(W/2,m/2)),(bottom,(W/2,H-m/2)),(left,(m/2,H/2)),(right,(W-m/2,H/2))):
        d.text(xy,text,fill=fg,font=font(28),anchor="mm")
    if note:
        d.text((12,H-12),note,fill=fg,font=font(16),anchor="ld")
    if callout:
        text,(tx,ty),(lx,ly) = callout
        box = d.textbbox((lx+m,ly+m),text,font=font(20),anchor="mm")
        d.line([(lx+m,ly+m),(tx+m,ty+m)],fill="white",width=2)
        d.rounded_rectangle([box[0]-6,box[1]-4,box[2]+6,box[3]+4],radius=5,fill="black",outline="white",width=2)
        d.text((lx+m,ly+m),text,fill="white",font=font(20),anchor="mm")
    out.save(dst)

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle,Image,PageBreak,KeepTogether)

CASE = "UPenn-GBM sub-003"
NAVY,PALE,GRID = colors.HexColor("#1f3a5f"),colors.HexColor("#e8eef6"),colors.HexColor("#c8d0da")
WIDTH = letter[0]-1.5*inch
H1 = ParagraphStyle("h1",fontName="Helvetica-Bold",fontSize=24,leading=30,textColor=NAVY,alignment=1)
H2 = ParagraphStyle("h2",fontName="Helvetica-Bold",fontSize=17,leading=22,textColor=NAVY,spaceBefore=6,spaceAfter=4)
SUB = ParagraphStyle("sub",fontName="Helvetica",fontSize=10,leading=13,textColor=colors.grey)
BODY = ParagraphStyle("body",fontName="Helvetica",fontSize=10,leading=13.5)
CAP = ParagraphStyle("cap",parent=BODY,fontSize=8.5,leading=11)

def img(file,width):
    w,h = PILImage.open(file).size
    return Image(file,width,width*h/w)

def grid(cells,widths=None,caption_row=False):  # side-by-side figures/flowables, optional caption row
    widths = widths or [WIDTH/len(cells[0])]*len(cells[0])
    t = Table(cells,colWidths=widths)
    style = [("VALIGN",(0,0),(-1,-1),"TOP"),("BOX",(0,0),(-1,-1),0.5,GRID),("LEFTPADDING",(0,0),(-1,-1),3),("RIGHTPADDING",(0,0),(-1,-1),3)]
    if caption_row:
        style.append(("BACKGROUND",(0,-1),(-1,-1),colors.HexColor("#f4f6f8")))
    t.setStyle(TableStyle(style))
    return t

def figures(*pairs):  # (file,caption) pairs in one row
    w = WIDTH/len(pairs)-6
    return grid([[img(f,w) for f,_ in pairs],[Paragraph(c,CAP) for _,c in pairs]],caption_row=True)

def table(header,rows,widths=None):
    t = Table([[Paragraph(f"<b>{h}</b>",ParagraphStyle("th",parent=BODY,textColor=colors.white)) for h in header]]+
              [[Paragraph(str(c),BODY) for c in r] for r in rows],colWidths=widths,repeatRows=1)
    t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),NAVY),("GRID",(0,0),(-1,-1),0.5,GRID),("VALIGN",(0,0),(-1,-1),"MIDDLE")]))
    return t

def box(html):
    t = Table([[Paragraph(html,BODY)]],colWidths=[WIDTH])
    t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,-1),PALE),("BOX",(0,0),(-1,-1),0.5,GRID),("PADDING",(0,0),(-1,-1),8)]))
    return t

def footer(canvas,doc):
    canvas.saveState()
    canvas.setStrokeColor(GRID)
    canvas.line(0.75*inch,0.6*inch,letter[0]-0.75*inch,0.6*inch)
    canvas.setFont("Helvetica",8)
    canvas.setFillColor(colors.grey)
    canvas.drawString(0.75*inch,0.42*inch,f"{CASE} | Tumor and tract-tumor report")
    canvas.drawRightString(letter[0]-0.75*inch,0.42*inch,f"Page {doc.page}")
    canvas.restoreState()

# ---- orientation labels: values from get_camera (3D) and R_side (2D) ----
AXIAL3D,CORONAL3D,SAGITTAL3D = ("R","L","A","P"),("R","L","S","I"),("A","P","S","I")
for f,o in [("sub003_tumor_WM_axial3D",AXIAL3D),("sub003_tumor_WM_coronal3D",CORONAL3D),
            ("sub003_alltracts_tumor_WM_axial3D",AXIAL3D),("sub003_alltracts_tumor_WM_coronal3D",CORONAL3D),
            ("sub003_CST_R_tumor_WM_axial3D",AXIAL3D),("sub003_CST_R_tumor_WM_sagittal3D",SAGITTAL3D),
            ("sub003_SLF_R_tumor_WM_axial3D",AXIAL3D),("sub003_SLF_R_tumor_WM_coronal3D",CORONAL3D)]:
    orient(f+".png",f+"_lab.png",*o)
RADIOLOGICAL = dict(left="R",right="L",top="A",bottom="P",dark=True,note="Radiological convention")
for f in ["sub003_ceT1w_corecenter","sub003_FLAIR_corecenter"]:
    orient(f+".png",f+"_lab.png",**RADIOLOGICAL)
orient("sub003_CST_R_FLAIR_axial.png","sub003_CST_R_FLAIR_axial_lab.png",callout=("Right CST",(530,560),(260,650)),**RADIOLOGICAL)
orient("sub003_SLF_R_FLAIR_axial.png","sub003_SLF_R_FLAIR_axial_lab.png",callout=("Right SLF",(330,490),(220,350)),**RADIOLOGICAL)

# ---- pages ----
s = [Paragraph(CASE,H1),
     Paragraph("Complete tumor and tract-tumor relationship report | Fresh direct DSI Studio 3D exports",ParagraphStyle("c",parent=SUB,alignment=1)),
     Spacer(1,10),
     box("<b>Summary.</b> Right posterior-medial/perirolandic lesion with 18.663 mL tumor core and 60.477 mL peritumoral edema. "
         "No reconstructed CST, SLF, arcuate, or FAT streamlines enter necrosis or enhancing tumor. The right CST shows complete "
         "edema-field contact; right SLF shows limited edema contact."),
     Paragraph("Representative tumor imaging",H2),
     figures(("sub003_ceT1w_corecenter_lab.png","Contrast-enhanced T1w-gd"),("sub003_FLAIR_corecenter_lab.png","FLAIR")),
     PageBreak(),

     Paragraph("Tumor segmentation, composition, and 3D location",H2),
     Paragraph("Fresh direct DSI Studio 3D saves on white background with the defragmented White_Matter brain envelope.",SUB),
     figures(("whole_lesion_composition.png","Whole segmented lesion"),("tumor_core_composition.png","Tumor core")),
     Spacer(1,6),
     table(["Compartment","Volume","% whole lesion","% tumor core"],
           [["Necrosis","11.961 mL","15.11%","64.09%"],["Enhancing tumor","6.702 mL","8.47%","35.91%"],
            ["Peritumoral edema","60.477 mL","76.42%","-"],["Tumor core","18.663 mL","23.58%","100.00%"],
            ["Whole segmented lesion","79.140 mL","100.00%","-"]],[WIDTH*0.34]+[WIDTH*0.22]*3),
     Spacer(1,6),
     figures(("sub003_tumor_WM_axial3D_lab.png","Axial 3D tumor + White_Matter envelope"),
             ("sub003_tumor_WM_coronal3D_lab.png","Coronal 3D tumor + White_Matter envelope")),
     PageBreak(),

     Paragraph("Tumor-atlas overlap",H2),
     Paragraph("CHA and Brodmann overlaps are reported separately. Percentages use the 18.663 mL tumor core as denominator.",SUB),
     grid([[img("CHA_tumor_core_overlap.png",WIDTH/2-6),img("Brodmann_tumor_core_overlap.png",WIDTH/2-6)],
           [table(["CHA region","Overlap","% core"],[["Posterior cingulate","5.501 mL","29.48%"],["Precentral","1.250 mL","6.70%"],
                   ["Postcentral","0.768 mL","4.12%"],["Premotor","0.445 mL","2.38%"],["Precuneus","0.127 mL","0.68%"]]),
            table(["Brodmann area","Overlap","% core"],[["BA31 right","2.493 mL","13.36%"],["BA4 right","1.756 mL","9.41%"],
                   ["BA23 right","1.046 mL","5.60%"],["BA23 left","0.460 mL","2.46%"],["BA24 right","0.458 mL","2.45%"],
                   ["BA5 right","0.371 mL","1.99%"],["BA6 right","0.337 mL","1.81%"],["BA24 left","0.157 mL","0.84%"],
                   ["BA31 left","0.111 mL","0.59%"]])]]),
     Spacer(1,6),
     grid([[img("sub003_tumor_WM_coronal3D_lab.png",WIDTH*0.45),
            Paragraph("<b>Representative anatomy.</b> CHA shows the largest overlap in posterior cingulate (29.48% of core). "
                      "The Brodmann atlas shows the largest overlap in right BA31 (13.36%) and right BA4 (9.41%).",BODY)]],
          [WIDTH*0.47,WIDTH*0.53]),
     PageBreak(),

     Paragraph("Tract-tumor report: all reconstructed pathways",H2),
     figures(("sub003_alltracts_tumor_WM_axial3D_lab.png","Axial all-tract overview"),
             ("sub003_alltracts_tumor_WM_coronal3D_lab.png","Coronal all-tract overview")),
     Spacer(1,6),
     table(["Right tract","Total","Edema-intersecting","Edema fraction","Core intersection"],
           [["CST","8,595","8,595","100.0%","0"],["SLF","5,315","619","11.6%","0"],
            ["Arcuate","7,255","0","0%","0"],["FAT","5,812","0","0%","0"]]),
     Spacer(1,6),
     grid([[img("right_tract_to_edema.png",WIDTH*0.5),
            Paragraph("<b>Key finding.</b> No reconstructed named pathway enters necrosis or enhancing tumor. The dominant "
                      "relationship is the right CST within the edema field; right SLF has limited edema contact.",BODY)]],
          [WIDTH*0.52,WIDTH*0.48])]

for name,short,views,t2r,interpretation in [
    ("right corticospinal tract (CST)","CST_R",[("axial3D","Axial"),("sagittal3D","Sagittal")],
     ["8,595 / 8,595 right-CST streamlines intersect edema (100%).","0 intersect necrosis.","0 intersect enhancing tumor.",
      "Edema-intersecting tract volume: 1,424 mm<super>3</super>."],
     "the reconstructed motor pathway is embedded in the edema environment but does not enter the reconstructed tumor core."),
    ("right superior longitudinal fasciculus (SLF)","SLF_R",[("axial3D","Axial"),("coronal3D","Coronal")],
     ["619 / 5,315 right-SLF streamlines intersect edema (11.6%).","0 intersect necrosis.","0 intersect enhancing tumor.",
      "Edema-intersecting tract volume: 556 mm<super>3</super>."],
     "a minority of reconstructed right-SLF streamlines contact edema; the reconstructed tumor core remains separate.")]:
    tract = short.split("_")[0]
    s += [PageBreak(),Paragraph(f"Affected tract: {name}",H2),
          figures(*[(f"sub003_{short}_tumor_WM_{v}_lab.png",f"{label} 3D right {tract} + tumor + White_Matter envelope") for v,label in views]),
          Spacer(1,6),
          grid([[img(f"sub003_{short}_FLAIR_axial_lab.png",WIDTH*0.5),
                 Paragraph(f"<b>FLAIR axial slice.</b> Radiological convention: image left = patient right. The tumor/edema "
                           f"mask is delineated and the right {tract} is labeled.<br/><br/><b>T2R</b><br/>"+
                           "<br/>".join("&bull; "+x for x in t2r)+f"<br/><br/><b>Interpretation:</b> {interpretation}",BODY)]],
               [WIDTH*0.52,WIDTH*0.48])]

s += [PageBreak(),Paragraph("Integrated interpretation and bilateral context",H2),
      figures(("right_tract_to_edema.png","Right tract-to-edema relationship"),("bilateral_tract_morphology.png","Bilateral tract morphology (curl)")),
      Spacer(1,6),
      figures(("sub003_alltracts_tumor_WM_axial3D_lab.png","All tracts + tumor, axial"),("sub003_FLAIR_corecenter_lab.png","FLAIR through tumor core")),
      Spacer(1,8),
      box("<b>Integrated conclusion</b><br/><br/>"
          "1. Tumor core volume is 18.663 mL; peritumoral edema is 60.477 mL.<br/><br/>"
          "2. CHA and Brodmann overlaps are presented independently. Largest CHA overlap is posterior cingulate (29.48% of core); "
          "largest Brodmann overlaps are right BA31 (13.36%) and right BA4 (9.41%).<br/><br/>"
          "3. No reconstructed CST, SLF, arcuate, or FAT streamline enters necrosis or enhancing tumor. Right CST shows 100% edema "
          "contact; right SLF 11.6%; right arcuate and FAT 0%.<br/><br/>"
          "4. Right arcuate curl is markedly higher than left, but without lesion intersection this remains a descriptive "
          "reconstruction asymmetry.<br/><br/>"
          "5. Edema-mask intersection is a geometric tractography relationship, not proof of histologic invasion or a surgical corridor.")]

SimpleDocTemplate("sub003_tumor_report.pdf",pagesize=letter,leftMargin=0.75*inch,rightMargin=0.75*inch,
                  topMargin=0.6*inch,bottomMargin=0.8*inch).build(s,onFirstPage=footer,onLaterPages=footer)
```

After `build`, render every page to an image and inspect it (11.8) before delivering.
