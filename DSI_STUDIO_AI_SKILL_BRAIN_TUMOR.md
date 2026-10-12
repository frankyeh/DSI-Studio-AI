# DSI Studio AI Brain Tumor Report

Use this skill for presurgical or postsurgical brain-tumor evaluation for a neurosurgeon.
The deliverable is a **PowerPoint PPTX report** (§7) that presents the lesion, its anatomical
location, and its relationship to the eloquent pathways. Run the analysis (Steps 1–6)
through, then generate the 2D figures and native GLB 3D models and assemble the PPTX. Keep
chat updates short; the report carries the findings. Use the general command manuals for
exact command semantics rather than inferring behavior.

This workflow provides imaging and tractography decision support. Tractography does not by
itself establish function, tissue viability, safe resection margins, or whether a pathway
can be sacrificed. Interpret findings together with the neurological examination,
functional imaging when available, cortical/subcortical mapping, operative anatomy, and
other clinical information.

## Workflow overview

Presurgical:

1. Verify the structural image, segment the lesion, and measure its compartments.
2. Localize the Tumor Core against `CHA` and `Brodmann`.
3. Select the relevant bilateral eloquent pathways.
4. Reconstruct them with AutoTrack.
5. Quantify tract-to-lesion involvement with T2R.
6. Compare bilateral tract morphology and inspect tract/lesion spatial relationships.
7. Generate the 2D figures and native GLB models and assemble the PPTX report.

Postsurgical (§8): reconstruct the same eloquent pathways and report whether each remains
reconstructable around the cavity, residual lesion, and edema.

Do not use tumor- or edema-derived regions as ROI, Seed, ROA, End, or other tracking
constraints for standard AutoTrack. Reconstruct the named tract independently first, then
measure its relationship to the lesion.

### Companion manuals

| Section | Companion manual |
|---|---|
| §1 segmentation, slice readiness, model availability, three-plane QC | `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §2 atlas localization | `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §3–4 pathway selection and AutoTrack | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md` |
| §5 tract-to-lesion connectivity | `DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §6–7 morphology, rendering, figures | `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md` |
| §8 postoperative evaluation | Slice, Rendering, Region, Tract, T2R, and Fiber-Tracking manuals above |

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

Then load the built-in atlas version of that pathway, using the same exact identifier, and
try **partial tracking**: track the subject's own streamlines inside a corridor around the
atlas course. This can recover a pathway that is disrupted or displaced near the lesion.

```bash
# 1. atlas tract (warped to the subject in native space)
bash ./dsi.sh load_tract_atlas "ProjectionBrainstem_CorticospinalTractR"
bash ./dsi.sh list_tract                              # note the new row, e.g. 8

# 2. atlas tract -> region; select a diffusion-space slice first so the region is on the FIB grid
bash ./dsi.sh tract_to_region 8
bash ./dsi.sh list_region                             # new row named after the tract, e.g. 10

# 3. dilate by 5 voxels into a corridor
bash ./dsi.sh region_action_dilation_by_voxel 10 5

# 4. copy it: one copy seeds, the other limits propagation (copy is inserted after its source)
bash ./dsi.sh copy_region 10                          # copy at row 11
bash ./dsi.sh list_region

# 5. track inside the corridor (3 = Seed, 6 = Limiting); asynchronous, poll list_tract until done
bash ./dsi.sh run_tracking "CST R partial" "10:3&11:6"
bash ./dsi.sh list_tract

# remove the corridor regions so they do not enter T2R or the figures
bash ./dsi.sh delete_region "10&11"
```

Re-resolve every row number with `list_tract` / `list_region` before using it.
`tract_to_region` builds the region on the current slice grid, `region_action_dilation_by_voxel`
takes the region row and the radius in voxels, and the `run_tracking` region string uses
`row:type` pairs.

- If partial tracking gives a plausible bundle along the expected course, report it as the
  subject's reconstruction, labeled "atlas-guided partial tracking" in the table, header,
  captions, and conclusion. Note that the corridor confines it to the atlas course, so a
  pathway displaced more than about 5 voxels can be missed or truncated. Delete the atlas
  tract row afterwards or keep it only as a reference.
- If partial tracking also fails, use the atlas tract itself in its place, as below.

In native space the population atlas is nonlinearly warped to the subject, so the atlas tract
shows the **likely pathway location**, not the subject's own reconstruction. Use it in the
figures and in T2R like the other bundles, but:

- label it as atlas-based everywhere it appears: tract table ("CST R (atlas)"), tract-page
  header, figure captions, and conclusion, with the wording "likely pathway location from the
  population tractography atlas; AutoTrack could not map this pathway";
- report its relationship to the lesion by intersection volume and compartment contact; if a
  streamline fraction is given, call it a fraction of atlas streamlines;
- leave it out of morphology, curl, and left/right asymmetry, which describe subject
  reconstructions only;
- state that mass effect or edema can displace the real pathway from the atlas position, so
  the atlas course near the lesion is the least certain.

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

When the user asks for a rotating video of a pathway with the tumor, keep the
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

## 7. PPTX report

### 7.1 Report structure

Produce a real **PowerPoint `.pptx`** containing a tumor report and a tract–tumor report.
The primary report is PPTX, not PDF. PDF may be exported later as a static derivative, but it
loses interactive 3D and is not the required deliverable.

Every 3D visualization in the report must be a **native DSI Studio GLB** embedded as an
interactive PowerPoint 3D object. Do not convert OBJ/MTL to GLB outside DSI Studio for this
workflow. Do not use static 3D screenshots as the report's 3D figure. A raster image may be
used only as the PowerPoint fallback/poster for the same GLB object.

Do **not** generate multiple fixed 3D views for a scene. Use one interactive GLB model on the
slide and let the reader rotate it. Keep multiple 2D MRI slices only when they add anatomical
information that the interactive 3D model does not provide.

Recommended slide roles:

| Slide | Content | Visuals |
|---|---|---|
| 1 | Summary: location, Tumor Core and edema volumes, main tract relationship, key findings | Contrast-enhanced T1w through the main enhancing tumor and FLAIR through the main edema |
| 2 | Compartment table, composition charts, lesion description, additional foci | One interactive tumor + `White_Matter` GLB |
| 3 | CHA and Brodmann localization, kept separate | Atlas charts; optional same tumor GLB only when it materially helps |
| 4 | Tract table, T2R results, tract-to-edema chart, key finding | One interactive all-relevant-tracts + tumor + `White_Matter` GLB |
| 5..N | One clinically important tract per slide: measures, interpretation, selected 2D slices | One interactive single-tract + tumor + `White_Matter` GLB |
| Last | Impression, bilateral asymmetry, clinical-correlation points, methods and limitations | Tract-to-edema and bilateral morphology charts |

Slide notes:

- **Composition.** Report both denominators: whole lesion = Necrosis + Enhancing Tumor +
  Peritumoral Edema; Tumor Core = Necrosis + Enhancing Tumor.
- **Lesion description.** Hemisphere, lobe and gyrus, depth (cortical, subcortical, deep),
  and whether the lesion reaches the falx, midline, or corpus callosum. Give the three
  diameters of the main component only, never of a region that includes separate fragments.
- **Additional foci.** Every separate component visible in 3D gets a row: location, volume,
  label, and "satellite lesion or false positive: verify on the source images". Do not leave
  visible foci unexplained.
- **Atlas.** Keep CHA and Brodmann separate. Show overlap volume and `% Tumor Core` for every
  nonzero row.
- **Tract table.** Add function to correlate and a relationship tag: `Tumor Core contact`,
  `Edema contact`, `Partial edema contact`, or `No contact`. Tags describe geometry, not risk.
  Mark atlas-guided partial tracking and atlas tracts explicitly as in §4.
- **Tract slides.** A tract gets its own slide when it intersects any lesion compartment or
  when the interactive 3D scene shows clinically important adjacency, marginal course,
  compression, displacement, or incomplete reconstruction; include every analyzed tract when
  the user asks. Never substitute the all-tract GLB for a tract-specific GLB.
- **Methods.** Structural and diffusion sequences, b-values and resolution, segmentation
  model, registration check, AutoTrack settings, DSI Studio version, and report date.
- Briefly explain segmentation, atlas overlap, AutoTrack, T2R, and curl where their results
  first appear.
- **Style.** Use one palette everywhere, derived from the DSI Studio region colors. Never
  recolor the GLB to compensate for PowerPoint rendering. Keep unconfirmed values visibly
  marked `[verify]`.

### 7.2 Report inputs

Collect before assembling the PPTX:

```text
Case          FIB source and reconstruction space, structural slice, segmentation model
Lesion        Enhancing Tumor, Necrosis, Tumor Core, Peritumoral Edema, whole lesion (mL);
              both percentage sets; orthogonal diameters when reliable
Atlas         CHA and Brodmann rows: overlap volume and % Tumor Core
Tracts        AutoTrack identifiers and settings; total streamlines per bundle;
              T2R intersecting streamlines and intersect volume per compartment;
              bilateral curl, volume, surface area; list of tracts that get slides
3D models     GLB file name and exact scene content for each interactive 3D slide
2D figures    file name, slice plane/level, modality, orientation metadata
```

All figures, GLBs, and numbers must come from one accepted analysis state. When reproducing
or revising an analyzed case, reuse its recorded tract set and results; do not re-select
pathways or re-run AutoTrack just to make the PPTX. Re-track only for missing or corrupt
data, a user request, or failed QC, then repeat dependent T2R and morphology and say the
reconstruction changed.

### 7.3 Native GLB 3D scenes

Use `save_3d_model <file>.glb` for every 3D report scene. Native GLB export already shares
DSI Studio's geometry/material preparation with OBJ/MTL, uses the same centered export
coordinates, and preserves the current scene's RGB/alpha values.

The brain envelope is the `White_Matter` region from `human_tumor`; do not add a separate
isosurface merely for the report when `White_Matter` is already available.

Prepare the scene:

1. Resolve tract and region rows from fresh `list_tract` / `list_region` output.
2. Defragment `White_Matter` (`region_action_defragment`) and verify it forms one coherent
   envelope. Do not defragment tumor compartments unless requested.
3. Keep each region's own RGB and change alpha only when needed. The established report
   defaults are approximately: Necrosis 200, Peritumoral Edema 80, Enhancing Tumor 100,
   White_Matter 10 in the alpha byte.
4. Move `White_Matter` to the last Region-table row when practical, re-resolving indices as
   rows move.
5. Show only the three tumor compartments plus `White_Matter`; omit the derived Tumor Core
   copy from the 3D scene unless it adds information not already represented by its component
   regions.
6. Turn off the unrelated DSI isosurface and slice planes for the report GLB:

```bash
bash ./dsi.sh set_param show_surface 0
bash ./dsi.sh set_param show_slice 0
```

7. Use assigned tract colors:

```bash
bash ./dsi.sh set_param tract_color_style 1
bash ./dsi.sh color_all_cluster
```

Repeat `color_all_cluster` after adding/reloading tracts. Do not use directional color for the
report GLB.

Export examples:

```bash
# tumor-only scene
bash ./dsi.sh check_uncheck_all_tract 0
bash ./dsi.sh set_param show_tract 0
bash ./dsi.sh show_only_regions "<necrosis>&<enhancing>&<edema>&<white-matter>"
bash ./dsi.sh save_3d_model "case_tumor_WM.glb"

# all relevant tracts + tumor
bash ./dsi.sh set_param show_tract 1
bash ./dsi.sh show_only_tracts "<all-report-tract-indices>"
bash ./dsi.sh show_only_regions "<necrosis>&<enhancing>&<edema>&<white-matter>"
bash ./dsi.sh save_3d_model "case_alltracts_tumor_WM.glb"

# one tract + tumor
bash ./dsi.sh show_only_tracts "<tract-index>"
bash ./dsi.sh save_3d_model "case_<tract>_tumor_WM.glb"
```

The GLB is view-independent. Do not make axial/coronal/sagittal copies of the same GLB and do
not use `set_view` merely to create additional 3D report views. The reader rotates the one
embedded model interactively.

For Web sessions, upload each completed GLB with `web_upload` and use the returned attachment
directly; do not ask the user to download and re-upload it.

### 7.4 2D figures

2D slice figures remain static images because they show MRI signal and exact slice context.
Use contrast-enhanced T1w for the enhancing tumor/core and FLAIR for edema and
tract-to-edema relationships. Set the slice view explicitly rather than relying on GUI
defaults:

```bash
bash ./dsi.sh set_params "roi_draw_edge=1&roi_edge_width=2"
bash ./dsi.sh set_params "roi_track=1&roi_track_count=500000"
bash ./dsi.sh set_params "roi_fiber=0&roi_position=0&roi_ruler=0&roi_label=0"
```

- Use outlines rather than filled tumor regions so MRI signal stays visible.
- Show only the three tumor compartments; do not include `White_Matter` in 2D slices.
- Center on the main lesion with `move_slice_to_region` and choose the centering compartment
  by modality: contrast-enhanced T1w through enhancing tumor/core, FLAIR through edema.
- For tract-specific slides, show only that tract in its assigned cluster color. Use the one
  or two planes that best demonstrate the tract/lesion relationship. Add additional levels
  only when the relationship changes along the tract and each image adds information.
- Save with `save_roi_screen` and inspect the result. The lesion outline and relevant tract
  must both be visible when the figure is intended to demonstrate their relationship.
- If a 2D image is redone, replace it in the PPTX; do not keep stale figures from a previous
  analysis state.

### 7.5 Orientation and 3D interaction

Static 2D images require anatomical orientation labels from the slice metadata. Use the
radiological convention consistently and state it when appropriate.

Do not put fixed cardinal orientation labels around an interactive GLB as if it were a
static camera view; the user can rotate it. Instead caption it clearly, for example:

```text
Interactive 3D — drag to rotate
Right CST + tumor compartments + White_Matter envelope
```

If a PowerPoint fallback/poster image is required for the 3D object, use only one image of
the same scene. It is not a second 3D view and must not replace the embedded GLB.

### 7.6 Wording

T2R gives two different quantities; label them correctly:

```text
intersection volume               = T2R intersect volume(mm^3)
reconstructed-streamline fraction = T2R number of tracts / total bundle streamlines
```

Do not use the T2R `intersect ratio` as the streamline fraction. Streamline counts are not
axon counts. Preferred phrasing:

```text
No reconstructed [tract] streamlines entered the Tumor Core.
[X]% of reconstructed [tract] streamlines intersect the segmented edema field.
```

- Do not call a tract `safe`, `intact`, `destroyed`, or `resectable`, or a route safe or
  unsafe, from tractography alone.
- Edema intersection is a geometric relationship, not histologic invasion. Zero Tumor-Core
  intersection does not prove a safe surgical plane.
- Report curl asymmetry without lesion contact as a descriptive reconstruction asymmetry.
- Do not use universal percentage thresholds for risk or displacement.

### 7.7 Annotation and post-processing

Allowed on static content: orientation labels from slice metadata, tract name/caption,
borders, legends, and trimming empty margin. Do not recolor or geometrically modify an
exported GLB after DSI Studio. If a 3D scene is wrong or missing a structure, fix the DSI
scene and export the GLB again.

Do not create a fake single-tract model by masking or recoloring an all-tract export. Export
a tract-specific GLB from DSI Studio.

### 7.8 Worked GLB export pattern

For a right-hemisphere case with right CST and right SLF as tract-specific slides:

```bash
# lesion scene
bash ./dsi.sh check_uncheck_all_tract 0
bash ./dsi.sh set_param show_tract 0
bash ./dsi.sh show_only_regions "<necrosis>&<enhancing>&<edema>&<white-matter>"
bash ./dsi.sh save_3d_model "sub003_tumor_WM.glb"

# all relevant tracts scene
bash ./dsi.sh set_param show_tract 1
bash ./dsi.sh show_only_tracts "<CST-L>&<CST-R>&<SLF-L>&<SLF-R>&<AF-L>&<AF-R>&<FAT-L>&<FAT-R>"
bash ./dsi.sh save_3d_model "sub003_alltracts_tumor_WM.glb"

# right CST scene
bash ./dsi.sh show_only_tracts "<CST-R>"
bash ./dsi.sh save_3d_model "sub003_CST_R_tumor_WM.glb"

# right SLF scene
bash ./dsi.sh show_only_tracts "<SLF-R>"
bash ./dsi.sh save_3d_model "sub003_SLF_R_tumor_WM.glb"
```

No second axial/coronal/sagittal 3D export is needed. Use the interactive model itself for
inspection.

### 7.9 Assemble the PPTX

Use a 16:9 widescreen PowerPoint presentation. Keep the report visually compact and
clinical: concise title/header, summary or table/chart area, and one large interactive 3D
model when a slide calls for 3D.

For every interactive 3D object:

- embed the `.glb` as an Office Model3D part; use a known-good PowerPoint 3D placeholder or
  equivalent OOXML `am3d:model3d` structure rather than converting the GLB to an image;
- keep the GLB material colors and alpha values **unchanged**;
- use PowerPoint global lighting of **white ambient light only, 10% illuminance**;
- use **no directional, point, or spot lights**;
- provide at most one raster fallback/poster for the same GLB scene when required by the
  PPTX package;
- use only one interactive 3D model per slide by default.

The 10% white-ambient setting was selected by direct PowerPoint comparison because stronger
Office lighting washed out DSI Studio's assigned tract and tumor colors. Do not darken GLB
materials to compensate for PowerPoint lighting.

2D MRI figures and charts remain ordinary raster/vector slide content. Keep legends and units
readable without covering anatomy. Do not export the PPTX to PDF as the primary deliverable.

Before delivery:

1. verify the PPTX package opens in desktop Microsoft PowerPoint;
2. rotate every embedded GLB interactively;
3. confirm tumor compartments, requested tract(s), and `White_Matter` envelope are present;
4. confirm tract/tumor colors and transparency are plausible with the 10% ambient setting;
5. inspect every 2D image and chart for clipping, stale values, and orientation errors;
6. confirm each slide uses figures and numbers from the same accepted analysis state.

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

### 8.2 Reconstruct the same eloquent pathways

Use the same bilateral pathways that were clinically relevant preoperatively. Keep
reconstruction and AutoTrack settings comparable whenever possible. Launch all independent
`run_auto_track` calls back-to-back and poll `list_tract` about every 10 seconds until all
requested bundles are `done`.

If a pathway was not part of the presurgical study but postoperative anatomy makes it
clinically relevant, it may be added, but clearly mark it as **postoperative-only** rather
than pretending it has a pre/post baseline.

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

For 3D comparison, export matched native GLB scenes with the same named tract(s), region
content, tract coloring, and transparency settings. A fixed `set_view` is not required
because the PowerPoint models are interactive. When pre/post 3D comparison is needed, use
matched consecutive slides by default rather than multiple fixed camera views.

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
- Show its likely location with the atlas version (§4), labeled as atlas-based; it shows
  where the pathway usually runs, not whether it is preserved.

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

## 9. Postoperative PPTX report

Use the §7 PPTX framework, but lead with eloquent-tract preservation rather than lesion
statistics. Every 3D scene is a native GLB embedded interactively in PowerPoint with the same
white ambient-only 10% lighting and unchanged GLB materials.

Default to one interactive 3D model per slide. When both preoperative and postoperative 3D
models are needed, use matched consecutive slides with comparable scene content rather than
multiple fixed views of either model.

Suggested content:

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
