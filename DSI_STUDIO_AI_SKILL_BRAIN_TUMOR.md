# DSI Studio AI Brain Tumor Report

Use this skill for presurgical or postsurgical brain-tumor evaluation for a neurosurgeon.
The deliverable is a **PowerPoint PPTX report** (§7) that presents the lesion, its anatomical
location, and its relationship to the eloquent pathways. Run the analysis (Steps 1–6)
through, then make the charts and 2D figures, export the native GLB 3D models, and assemble
the PPTX. Keep chat updates short; the report carries the findings. Use the general command manuals for
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
7. Make the charts and 2D figures, export the native GLB models last (export prunes large
   tracts, §7.3), and assemble the PPTX report.

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
workflow. Do not use static 3D screenshots as the report's 3D figure. The only raster image
of a 3D scene is the poster PowerPoint requires for each GLB object (§7.6).

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
  model, registration check, AutoTrack settings, DSI Studio version, report date, and that
  tracts in the 3D models had repeated trajectories removed for export (§7.6).
- Briefly explain segmentation, atlas overlap, AutoTrack, T2R, and curl where their results
  first appear.
- **Style.** One palette everywhere: the DSI Studio compartment colors (§7.5) for charts,
  contour legends, cards, and table accents. Never recolor the GLB to compensate for
  PowerPoint rendering. Keep unconfirmed values visibly marked `[verify]`.

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
3D models     GLB file name, poster file name, and exact scene content per 3D slide
2D figures    file name, slice plane/level, modality, R_side, plane orientation
Charts        file names of the composition, atlas, tract-to-edema, and morphology charts
```

All figures, GLBs, and numbers must come from one accepted analysis state. When reproducing
or revising an analyzed case, reuse its recorded tract set and results; do not re-select
pathways or re-run AutoTrack just to make the PPTX. Re-running AutoTrack changes streamline
counts (one sub-003 reproduction gave SLF 587/5271 instead of the accepted 619/5315 and was
rejected). Re-track only for missing or corrupt data, a user request, or failed QC, then
repeat dependent T2R and morphology and say the reconstruction changed.

### 7.3 Order of work

`save_3d_model` edits tracts: every checked tract with more than 3,000 visible streamlines is
reduced with `delete_repeated_tract 1` in place before export, and the export fails if a
tract is still above 3,000 (`DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`). Typical
AutoTrack bundles exceed this (sub-003: CST 8595, SLF 5315, AF 7255, FAT 5812). So:

1. Finish all numbers first: compartment volumes, atlas overlap, T2R, morphology (§1–§6).
2. Save the accepted tracts: `save_all_tracts "<case>_accepted_tracts.tt.gz"` with all report
   tracts checked. This is the restore point for revisions.
3. Make the charts (§7.5) and every 2D figure (§7.4). They show the full bundles.
4. Export the GLBs and posters last (§7.6).
5. Assemble the PPTX (§7.11).

If anything must be recomputed after step 4, reload the accepted tracts with `open_tract`
first and repeat steps 3–5; never measure on export-reduced tracts.

### 7.4 2D figures

2D slice figures remain static images because they show MRI signal and exact slice context.
They keep DSI Studio's black background. Use contrast-enhanced T1w for the enhancing tumor
and core, and FLAIR for edema and tract-to-edema relationships. Set the slice view
explicitly rather than relying on GUI defaults:

```bash
bash ./dsi.sh set_params "roi_draw_edge=1&roi_edge_width=2"     # tumor as outlines, never filled
bash ./dsi.sh set_params "roi_track=1&roi_track_count=500000"   # tracts drawn on the slice
bash ./dsi.sh set_params "roi_fiber=0&roi_position=0&roi_ruler=0&roi_label=0"   # no glyphs, crosshair lines, ruler, "R" mark
```

- Outlines apply to every 2D figure, including the summary MRI and the tract slices, so the
  tumor signal stays visible. `roi_track` shows the tract on the slice; `roi_fiber` only
  controls diffusion glyphs, so do not turn it on to show a tract.
- Show only the three tumor compartments (no `White_Matter` or Tumor Core copy in 2D),
  resolved by name from a fresh `list_region`: rows shift when `White_Matter` moves to the
  last row.
- Select the modality with `set_slice_by_name "<exact displayed name>"` and the plane with
  `set_roi_view` (`0` sagittal, `1` coronal, `2` axial).
- Center each slice on the **main lesion** with `move_slice_to_region <row>`, which moves to
  the region's per-axis median voxel, so small distant fragments do not pull the slice away.
  Choose the compartment by modality: contrast-enhanced T1w through the main enhancing tumor
  / core; FLAIR through the main edema. Older DSI Studio builds used the midpoint of the
  first and last voxel instead (in sub-003 that put the slice at z ≈ 71, below the tumor);
  with such a build, center on a copy reduced to its main component (`copy_region`, then
  `region_action_defragment`) and delete the copy afterwards. Moving to a wrong row such as
  `White_Matter` lands at the ventricle level.
- Show only the slide's tract (`show_only_tracts`) in its Assigned cluster color. A slice
  shows only the streamline points inside it (one voxel thick), so a tract crossing the plane
  appears as a few dots. Use the one or two planes where the tract and the lesion appear
  together: CST coronal plus axial or sagittal; SLF and AF axial plus sagittal. Add the third
  plane only when it shows something the other two do not.
- Where the relationship changes along the tract, cut 2–3 levels in one plane instead of
  one, e.g. upper, middle, and lower edema in axial for CST. Get the lesion center with
  `move_slice_to_region`, read its position in each view from `preview_screen roi`
  (`slice_info: ... <plane> <position>/<total>`, 1-based, so the voxel index is position − 1),
  then set each level with `move_slice "x y z"`, changing only that plane's coordinate. Keep
  every level inside the lesion extent and convert millimeters to voxels with the voxel size.
- Record `R_side` from the same `preview_screen roi` output for the orientation labels
  (§7.7).
- Save with `save_roi_screen` and open each image: the main lesion's outlines and the tract
  must both be clearly visible in the same slice. If the slice misses the main lesion, or the
  tract is only dots, re-center or change the plane and save again. If a 2D image is redone,
  replace it in the PPTX; do not keep stale figures from a previous analysis state.

### 7.5 Charts and palette

One palette for charts, contour legends, cards, and table accents: the DSI Studio compartment
colors. Contact bars use the enhancing color, zero bars grey. Charts are PNGs at 150 dpi on
white, placed as ordinary pictures. Replace the case values with the recorded inputs (§7.2);
the values below are sub-003's (§7.10).

```python
import numpy as np
import matplotlib.pyplot as plt

NEC,ENH,EDE,NAVY,GREY = "#5b484e","#bc6e71","#8397ab","#1f3a5f","#b8c2cc"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":15,"axes.titlesize":17,"axes.titleweight":"bold",
                     "axes.spines.top":False,"axes.spines.right":False,"axes.edgecolor":"#8a96a3",
                     "xtick.color":"#4a5560","ytick.color":"#4a5560","axes.titlelocation":"left"})

necrosis,enhancing,edema = 11.961,6.702,60.477
core = necrosis+enhancing
whole = core+edema
cha = [("Posterior cingulate",5.501),("Precentral",1.250),("Postcentral",0.768),("Premotor",0.445),("Precuneus",0.127)]
brodmann = [("BA31 right",2.493),("BA4 right",1.756),("BA23 right",1.046),("BA23 left",0.460),("BA24 right",0.458),
            ("BA5 right",0.371),("BA6 right",0.337),("BA24 left",0.157),("BA31 left",0.111)]
tracts = ["CST","SLF","Arcuate","FAT"]
edema_pct = np.array([8595,619,0,0])/np.array([8595,5315,7255,5812])*100
curl_left,curl_right = [1.120708,1.692461,1.236686,1.192565],[1.253219,1.347196,2.282737,1.223556]

def save(fig,file):
    fig.tight_layout()
    fig.savefig(file,dpi=150,facecolor="white")
    plt.close(fig)

def composition(parts,total,title,file):  # stacked bar: volume and % of the stated total
    fig,ax = plt.subplots(figsize=(5.2,1.7))
    start = 0.0
    for name,value,color in parts:
        ax.barh([0],[value],left=[start],color=color,height=0.6)
        if value/total > 0.18:
            ax.text(start+value/2,0,f"{name}\n{value:.2f} mL · {value/total*100:.1f}%",ha="center",va="center",fontsize=9.5,color="white")
        start += value
    ax.set_title(f"{title}  {total:.2f} mL")
    ax.set_xlim(0,total)
    ax.set_yticks([])
    ax.spines["left"].set_visible(False)
    save(fig,file)

def atlas(rows,title,file):  # one atlas per chart; % is of Tumor Core
    names,volumes = zip(*rows[::-1])
    fig,ax = plt.subplots(figsize=(6.2,0.42*len(rows)+1.1))
    ax.barh(names,volumes,color=NAVY,height=0.65)
    for y,value in enumerate(volumes):
        ax.text(value+max(volumes)*0.02,y,f"{value:.2f} mL · {value/core*100:.1f}%",va="center",fontsize=11)
    ax.set_title(title)
    ax.set_xlabel("Overlap with Tumor Core (mL)")
    ax.set_xlim(0,max(volumes)*1.45)
    save(fig,file)

composition([("Necrosis",necrosis,NEC),("Enhancing",enhancing,ENH),("Edema",edema,EDE)],whole,"Whole lesion","whole_lesion_composition.png")
composition([("Necrosis",necrosis,NEC),("Enhancing",enhancing,ENH)],core,"Tumor Core","tumor_core_composition.png")
atlas(cha,"CHA atlas","CHA_tumor_core_overlap.png")
atlas(brodmann,"Brodmann atlas","Brodmann_tumor_core_overlap.png")

fig,ax = plt.subplots(figsize=(6.2,3.2))
for x,value in enumerate(edema_pct):
    ax.bar(x,value,color=ENH if value > 0 else GREY,width=0.6)
    ax.text(x,value+2,f"{value:.1f}%",ha="center",fontsize=12)
ax.set_xticks(range(len(tracts)),tracts)
ax.set_title("Right tracts through edema")
ax.set_ylabel("Reconstructed streamlines (%)")
ax.set_ylim(0,115)
save(fig,"right_tract_to_edema.png")

x = np.arange(len(tracts))
fig,ax = plt.subplots(figsize=(6.2,3.2))
ax.bar(x-0.19,curl_left,0.38,label="Left",color=GREY)
ax.bar(x+0.19,curl_right,0.38,label="Right",color=NAVY)
ax.set_xticks(x,tracts)
ax.set_ylabel("Curl (route / distance)")
ax.set_title("Bilateral tract morphology")
ax.set_ylim(0,2.6)
ax.legend(frameon=False)
save(fig,"bilateral_tract_morphology.png")
```

The y-axis of the edema chart is a reconstructed-streamline fraction (§7.8), not an axon or
infiltration fraction.

### 7.6 Native GLB 3D scenes

Use `save_3d_model <file>.glb` for every 3D report scene, after the 2D figures (§7.3). GLB
and OBJ share DSI Studio's geometry and material preparation: x, z, −y in mm, centered on the
exported scene's bounds, with each object's RGB and alpha (region alpha byte × `region_alpha`,
default 0.8; `tract_alpha` for tracts). Tracts are tubes of `tube_diameter` voxels in one color
per bundle. Record `tube_diameter`, `region_alpha`, and `tract_alpha` with the case.

The brain envelope is the `White_Matter` region from `human_tumor`; do not add a separate
isosurface merely for the report when `White_Matter` is already available.

Prepare the scene once:

1. Resolve tract and region rows from fresh `list_tract` / `list_region` output.
2. Defragment `White_Matter` (`region_action_defragment`) and verify it forms one coherent
   envelope. Do not defragment tumor compartments unless requested.
3. Keep each region's own RGB and change only the alpha byte with `set_region_color <row>
   <unsigned #AARRGGBB>`; read the RGB from the case, never copy it from another subject.
   Alpha: Necrosis 200, Peritumoral Edema 80, Enhancing Tumor 100, White_Matter 10.
4. Move `White_Matter` to the last Region-table row with repeated `move_down_region`,
   re-resolving indices as rows move.
5. Check only the three tumor compartments and `White_Matter`; omit the Tumor Core copy.
6. Turn region rendering on, and the unrelated isosurface and slice planes off:

```bash
bash ./dsi.sh set_param show_region 1
bash ./dsi.sh set_param show_surface 0
bash ./dsi.sh set_param show_slice 0
bash ./dsi.sh set_param tube_diameter 0.5   # any value, but the same for every scene and for postoperative exports
bash ./dsi.sh set_param bkg_color -1        # white poster background; set again after any tract-style change
```

7. Use assigned tract colors once the final tract set is loaded; repeat after any tract is
   added or reloaded. Do not use directional color:

```bash
bash ./dsi.sh set_param tract_color_style 1
bash ./dsi.sh color_all_cluster
```

Per scene:

1. Check exactly the scene's regions (`show_only_regions`) and tracts (`show_only_tracts`,
   or `check_uncheck_all_tract 0` for none). `save_3d_model` exports checked tracts and
   regions; `show_tract` does not filter it.
2. Run `preview_screen 3d` and confirm the region block shows every compartment and the
   envelope, and the tract block shows the scene's tracts. Region meshes are built only while
   the 3D view draws, and `save_3d_model` silently skips a region whose mesh is not built yet;
   repeat `preview_screen 3d` until all regions appear.
3. `save_3d_model "<scene>.glb"`. If it fails with "Too many tracts even after deleting
   repeated tracks", run `delete_repeated_tract 2` (then `3`) with only that scene's tracts
   checked, export again, and state the distance in the methods.
4. Save the poster from the same scene: `save_screen "<scene>_poster.jpg" "1600 1200"`. Any
   view works; it is shown only until PowerPoint renders the model. The background must be
   white as saved; if not, set `bkg_color -1` and save again.

The GLB is view-independent. Do not make axial/coronal/sagittal copies of the same GLB and do
not use `set_view` merely to create additional 3D report views. Each GLB is centered on its
own scene, so models of different scenes do not share a coordinate frame.

For Web sessions, upload each completed GLB and poster with `web_upload` and use the returned
attachment directly; do not ask the user to download and re-upload it.

### 7.7 Orientation labels and 3D captions

Every 2D image carries anatomical orientation labels, bold, in a margin outside the anatomy,
with a font size of about 1/16 of the displayed image width (at least 12 pt). Take left/right
from `R_side` of that image's `preview_screen roi` (radiological convention: image left is
patient right, and the slide says so):

```text
axial      left/right R|L from R_side   top A   bottom P
coronal    left/right R|L from R_side   top S   bottom I
sagittal   left/right A|P as the saved image shows the face   top S   bottom I
```

A tract's side and the viewing side are different: "Right CST" is not a "right sagittal
view". Do not use voxel coordinates as clinical localization. Add the contour legend
(Necrosis, Enhancing Tumor, Peritumoral Edema in their region colors) under every slice.
Text over a slice is white and bold, never dark on black.

Do not put cardinal labels around an interactive GLB; the reader rotates it. Caption it:

```text
Interactive 3D — drag to rotate
Right CST + tumor compartments + White_Matter envelope
```

### 7.8 Wording

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
- Report streamline counts from the accepted analysis, never from export-reduced tracts.

### 7.9 Annotation and post-processing

Allowed on static content: orientation labels, tract name and caption, contour legends,
borders, and trimming empty margin. Not allowed: recoloring or geometrically modifying an
exported GLB, inverting or replacing a background, masking an all-tract export into a single
tract, removing structures, synthesizing missing anatomy, or mirroring without relabeling. If
a scene or slice is wrong, fix it in DSI Studio and save again.

### 7.10 Worked example: UPenn-GBM sub-003

The accepted set for a right-hemisphere case with CST and SLF tract slides. Use it as a
template: replace row indices with what `list_region` / `list_tract` report for the current
case, and numbers with the case's recorded inputs (§7.2).

Frozen quantitative inputs:

```text
Necrosis 11.961 mL   Enhancing 6.702 mL   Tumor Core 18.663 mL
Edema 60.477 mL      Whole lesion 79.140 mL

Right tract   streamlines   edema-intersecting   edema intersect volume   Tumor Core
CST           8595          8595 (100%)          1424 mm^3                0
SLF           5315          619 (11.6%)          556 mm^3                 0
Arcuate       7255          0                    -                        0
FAT           5812          0                    -                        0
```

Scene setup and accepted tracts:

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
dsi list_region                     # 4 Necrosis, 5 Peritumoral Edema, 6 Enhancing Tumor, 7 White_Matter

# Accepted bilateral tracts (reloaded, not re-tracked): 0/1 CST L/R, 2/3 SLF L/R, 4/5 AF L/R, 6/7 FAT L/R
dsi list_tract
dsi set_param tract_color_style 1
dsi color_all_cluster
dsi check_uncheck_all_tract 1
dsi save_all_tracts sub003_accepted_tracts.tt.gz
```

2D figures (before any GLB export):

```bash
dsi set_params "roi_draw_edge=1&roi_edge_width=2"
dsi set_params "roi_track=1&roi_track_count=500000"
dsi set_params "roi_fiber=0&roi_position=0&roi_ruler=0&roi_label=0"
dsi show_only_regions "4&5&6"      # outlines of the three tumor compartments only
dsi check_uncheck_all_tract 0

# Summary MRI: ceT1w through the main enhancing tumor, FLAIR through the main edema
dsi set_slice_by_name "<exact ceT1w / T1w-gd slice name>"
dsi set_roi_view 2
dsi move_slice_to_region 6    # median of Enhancing Tumor
dsi preview_screen roi        # R_side and slice_info for the labels
dsi save_roi_screen sub003_ceT1w_corecenter.png
dsi set_slice_by_name "<exact FLAIR slice name>"
dsi move_slice_to_region 5    # median of Peritumoral Edema
dsi save_roi_screen sub003_FLAIR_corecenter.png

# Lesion center from the edema median: read x, y, z (position - 1) from slice_info in each view
dsi move_slice_to_region 5
dsi set_roi_view 0; dsi preview_screen roi     # slice_info: ... sagittal <x+1>/<total>
dsi set_roi_view 1; dsi preview_screen roi     # coronal <y+1>
dsi set_roi_view 2; dsi preview_screen roi     # axial <z+1>

# Right CST: coronal through the center, axial at two levels through the edema
dsi show_only_tracts "1"
dsi set_roi_view 1; dsi move_slice "X Y Z";    dsi save_roi_screen sub003_CST_R_FLAIR_coronal_center.png
dsi set_roi_view 2; dsi move_slice "X Y Z+12"; dsi save_roi_screen sub003_CST_R_FLAIR_axial_upper.png
dsi move_slice "X Y Z-12";                     dsi save_roi_screen sub003_CST_R_FLAIR_axial_lower.png

# Right SLF: axial at two levels, sagittal through the tract beside the lesion
dsi show_only_tracts "3"
dsi set_roi_view 2; dsi move_slice "X Y Z+8";  dsi save_roi_screen sub003_SLF_R_FLAIR_axial_upper.png
dsi move_slice "X Y Z-8";                      dsi save_roi_screen sub003_SLF_R_FLAIR_axial_lower.png
dsi set_roi_view 0; dsi move_slice "X-20 Y Z"; dsi save_roi_screen sub003_SLF_R_FLAIR_sagittal_center.png
```

`X Y Z` stand for the voxel indices read above; the offsets (here 1 mm voxels) are examples.
Pick levels where the edema and the tract both appear. For the sagittal SLF level, step x from
the center toward the tract and confirm the direction on the saved image. Open each saved
slice and check that the main lesion and the tract appear together before using it.

GLB scenes and posters (last):

```bash
dsi set_param show_region 1
dsi set_param show_surface 0
dsi set_param show_slice 0
dsi set_param tube_diameter 0.5
dsi set_param bkg_color -1
dsi show_only_regions "4&5&6&7"

scene() {   # scene <name> <tract indices or empty>
    if [ -z "$2" ]; then dsi check_uncheck_all_tract 0; else dsi show_only_tracts "$2"; fi
    dsi preview_screen 3d        # all four regions and the tracts must appear; repeat if not
    dsi save_3d_model "$1.glb"
    dsi save_screen "$1_poster.jpg" "1600 1200"
}
scene sub003_tumor_WM ""
scene sub003_alltracts_tumor_WM "0&1&2&3&4&5&6&7"
scene sub003_CST_R_tumor_WM "1"
scene sub003_SLF_R_tumor_WM "3"
```

### 7.11 Assemble the PPTX

Build a 16:9 deck with python-pptx: title bar, tables, charts, and labeled 2D slices as
ordinary content, and each GLB as a PowerPoint 3D model. python-pptx has no 3D-model API, so
`add_glb()` adds the GLB part and inserts the Office `am3d:model3d` XML with its poster:

- GLB materials stay **unchanged**; the poster is the required raster fallback.
- Lighting is **white ambient only, 10% illuminance** (`illuminance n="100000"
  d="1000000"`); no directional, point, or spot lights. Stronger Office lighting washed out
  DSI Studio's tract and tumor colors in the PowerPoint comparison (To-Do #27). Do not darken
  GLB materials instead.
- `meterPerModelUnit` = 1 / largest scene extent (read from the GLB), so PowerPoint fits the
  model; the GLB is already centered, so `preTrans` is zero.
- One interactive 3D model per slide by default.

```python
import json,struct
from xml.sax.saxutils import quoteattr
from pptx import Presentation
from pptx.util import Emu,Inches,Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.opc.package import Part
from pptx.opc.packuri import PackURI
from pptx.oxml import parse_xml
from PIL import Image

NEC,ENH,EDE,NAVY,GREY = "5B484E","BC6E71","8397AB","1F3A5F","B8C2CC"
RT_MODEL3D = "http://schemas.microsoft.com/office/2017/06/relationships/model3d"

prs = Presentation()
prs.slide_width,prs.slide_height = Inches(13.333),Inches(7.5)

def new_slide(title,subtitle=""):
    slide = prs.slides.add_slide(prs.slide_layouts[6])  # blank
    bar = slide.shapes.add_shape(1,0,0,prs.slide_width,Inches(0.9))
    bar.fill.solid()
    bar.fill.fore_color.rgb = RGBColor.from_string(NAVY)
    bar.line.fill.background()
    text(slide,title,Inches(0.4),Inches(0.12),Inches(9),Inches(0.6),26,True,"FFFFFF")
    if subtitle:
        text(slide,subtitle,Inches(9.2),Inches(0.25),Inches(3.8),Inches(0.5),13,False,"D9E1EA",PP_ALIGN.RIGHT)
    return slide

def text(slide,value,x,y,w,h,size=14,bold=False,color="1A1A1A",align=PP_ALIGN.LEFT):
    frame = slide.shapes.add_textbox(x,y,w,h).text_frame
    frame.word_wrap = True
    for i,line in enumerate(value.split("\n")):
        p = frame.paragraphs[0] if i == 0 else frame.add_paragraph()
        p.alignment = align
        run = p.add_run()
        run.text = line
        run.font.size,run.font.bold = Pt(size),bold
        run.font.color.rgb = RGBColor.from_string(color)
    return frame

def table(slide,rows,x,y,w,size=12):  # first row is the header
    shape = slide.shapes.add_table(len(rows),len(rows[0]),x,y,w,Inches(0.35)*len(rows))
    for r,row in enumerate(rows):
        for c,value in enumerate(row):
            cell = shape.table.cell(r,c)
            cell.text = str(value) or "-"
            font = cell.text_frame.paragraphs[0].runs[0].font
            font.size,font.bold = Pt(size),r == 0
    return shape

def picture(slide,file,x,y,w):
    return slide.shapes.add_picture(file,x,y,width=w)

def slice_image(slide,file,x,y,w,plane,r_side,caption):  # §7.7 labels in a margin around the image
    margin = Inches(0.4)
    pic = picture(slide,file,x+margin,y+margin,w-2*margin)
    size = max(12,round(pic.width/12700/16))
    lr = ("R","L") if r_side == "left" else ("L","R")
    labels = {"axial":(lr,"A","P"),"coronal":(lr,"S","I")}.get(plane)
    if labels is None:  # sagittal: plane is "sagittal:AP" or "sagittal:PA", left then right as the saved image shows
        labels = ((plane[-2],plane[-1]),"S","I")
    (left,right),top,bottom = labels
    cx,cy,ph = pic.left,pic.top,pic.height
    box = Inches(0.4)
    text(slide,left,x,cy+ph//2-box//2,margin,box,size,True,"1A1A1A",PP_ALIGN.CENTER)
    text(slide,right,cx+pic.width,cy+ph//2-box//2,margin,box,size,True,"1A1A1A",PP_ALIGN.CENTER)
    text(slide,top,cx,y,pic.width,margin,size,True,"1A1A1A",PP_ALIGN.CENTER)
    text(slide,bottom,cx,cy+ph,pic.width,margin,size,True,"1A1A1A",PP_ALIGN.CENTER)
    text(slide,caption+"\nOutline: Necrosis · Enhancing Tumor · Peritumoral Edema   (radiological: image left = patient right)",
         x,cy+ph+margin,w,Inches(0.6),11)

def glb_extent(file):  # largest scene extent in model units (mm) from the POSITION accessors
    with open(file,"rb") as f:
        f.seek(12)
        length,_ = struct.unpack("<II",f.read(8))
        gltf = json.loads(f.read(length))
    bounds = [a for a in gltf["accessors"] if "min" in a]
    return max(max(a["max"][i] for a in bounds)-min(a["min"][i] for a in bounds) for i in range(3))

def add_glb(slide,glb,poster,x,y,w,h,caption):
    package = slide.part.package
    index = sum(str(p.partname).endswith(".glb") for p in package.iter_parts())+1
    model = Part(PackURI(f"/ppt/media/model3d{index}.glb"),"model/gltf-binary",package=package,blob=open(glb,"rb").read())
    rid_model = slide.part.relate_to(model,RT_MODEL3D)
    _,rid_poster = slide.part.get_or_add_image_part(poster)
    iw,ih = Image.open(poster).size  # fit the frame to the poster aspect
    if w*ih > h*iw:
        x,w = x+(w-h*iw//ih)//2,h*iw//ih
    else:
        y,h = y+(h-w*ih//iw)//2,w*ih//iw
    sid = max([s.shape_id for s in slide.shapes]+[1])+1
    descr = quoteattr(caption)
    mpu = max(1,round(1e6/glb_extent(glb)))
    xfrm = f'<a:off x="{x}" y="{y}"/><a:ext cx="{w}" cy="{h}"/>'
    slide.shapes._spTree.append(parse_xml(f'''
<mc:AlternateContent xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
 <mc:Choice xmlns:am3d="http://schemas.microsoft.com/office/drawing/2017/model3d" Requires="am3d">
  <p:graphicFrame>
   <p:nvGraphicFramePr><p:cNvPr id="{sid}" name="3D Model {sid}" descr={descr}/>
    <p:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></p:cNvGraphicFramePr><p:nvPr/></p:nvGraphicFramePr>
   <p:xfrm>{xfrm}</p:xfrm>
   <a:graphic><a:graphicData uri="http://schemas.microsoft.com/office/drawing/2017/model3d">
    <am3d:model3d r:embed="{rid_model}">
     <am3d:spPr><a:xfrm>{xfrm}</a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></am3d:spPr>
     <am3d:camera><am3d:pos x="0" y="0" z="66000000"/><am3d:up dx="0" dy="36000000" dz="0"/>
      <am3d:lookAt x="0" y="0" z="0"/><am3d:perspective fov="2700000"/></am3d:camera>
     <am3d:trans><am3d:meterPerModelUnit n="{mpu}" d="1000000"/><am3d:preTrans dx="0" dy="0" dz="0"/>
      <am3d:scale><am3d:sx n="1000000" d="1000000"/><am3d:sy n="1000000" d="1000000"/><am3d:sz n="1000000" d="1000000"/></am3d:scale>
      <am3d:rot/><am3d:postTrans dx="0" dy="0" dz="0"/></am3d:trans>
     <am3d:raster rName="Office3DRenderer" rVer="16.0.8326"><am3d:blip r:embed="{rid_poster}"/></am3d:raster>
     <am3d:objViewport viewportSz="{min(w,h)}"/>
     <am3d:ambientLight><am3d:clr><a:scrgbClr r="100000" g="100000" b="100000"/></am3d:clr>
      <am3d:illuminance n="100000" d="1000000"/></am3d:ambientLight>
    </am3d:model3d>
   </a:graphicData></a:graphic>
  </p:graphicFrame>
 </mc:Choice>
 <mc:Fallback>
  <p:pic><p:nvPicPr><p:cNvPr id="{sid}" name="3D Model {sid}" descr={descr}/>
    <p:cNvPicPr><a:picLocks noGrp="1" noRot="1" noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>
   <p:blipFill><a:blip r:embed="{rid_poster}"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>
   <p:spPr><a:xfrm>{xfrm}</a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic>
 </mc:Fallback>
</mc:AlternateContent>'''))
    text(slide,"Interactive 3D — drag to rotate\n"+caption,x,y+h,w,Inches(0.6),11,False,"4A5560",PP_ALIGN.CENTER)

# ---- example: tract slide (sub-003 right CST); build the other slides the same way ----
slide = new_slide("Right corticospinal tract","sub-003 · presurgical")
add_glb(slide,"sub003_CST_R_tumor_WM.glb","sub003_CST_R_tumor_WM_poster.jpg",
        Inches(0.4),Inches(1.1),Inches(6.2),Inches(5.2),"Right CST + tumor compartments + White_Matter envelope")
table(slide,[["Measure","Value"],["Streamlines","8595"],["Edema-intersecting","8595 (100%)"],
             ["Edema intersect volume","1424 mm³"],["Tumor Core","0"],["Tag","Edema contact"]],
      Inches(6.9),Inches(1.1),Inches(3.0))
slice_image(slide,"sub003_CST_R_FLAIR_coronal_center.png",Inches(10.0),Inches(1.0),Inches(3.2),"coronal","left",
            "FLAIR coronal, lesion center")
prs.save("sub003_tumor_report.pptx")
```

The `am3d` block follows the structure PowerPoint writes for an inserted 3D model. If
PowerPoint reports that the file needs repair, or a model does not appear, insert any GLB in
desktop PowerPoint (Insert > 3D Models > This Device), save, unzip, and compare
`ppt/slides/slideN.xml` and its `.rels` with this block; fix the template from that file
rather than switching to static images.

### 7.12 Before delivery

1. Open the PPTX in desktop Microsoft PowerPoint without a repair prompt.
2. Rotate every embedded GLB; confirm tumor compartments, the requested tract(s), and the
   `White_Matter` envelope are present and colors and transparency are plausible.
3. Inspect every 2D image and chart for clipping, stale values, and orientation errors;
   every slice has orientation labels and a contour legend.
4. Confirm every number matches the accepted analysis (§7.2), not export-reduced tracts.
5. Keep `[verify]` marks visible on anything unconfirmed.

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
content, tract coloring, transparency, and `tube_diameter` settings as the preoperative
export (§7.6). A fixed `set_view` is not required because the PowerPoint models are
interactive. Each GLB is centered on its own scene, so pre/post models are compared by
rotating each one, not by overlaying coordinates. When pre/post 3D comparison is needed, use
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
statistics. The same rules apply: the order of work (§7.3, numbers and 2D figures before any
GLB export), 2D figures and labels (§7.4, §7.7), charts and palette (§7.5), GLB scenes and
posters (§7.6), and `add_glb()` with white ambient-only 10% lighting and unchanged GLB
materials (§7.11).

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
