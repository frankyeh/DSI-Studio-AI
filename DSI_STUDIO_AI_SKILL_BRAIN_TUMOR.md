# DSI Studio AI Brain Tumor Report

Use this skill for presurgical or postsurgical brain-tumor evaluation for a neurosurgeon.
The deliverable is a **PDF report** (§7) that presents the lesion, its anatomical location,
and its relationship to the eloquent pathways. Run the analysis (Steps 1–6) through, then
generate the figures and assemble the PDF. Keep chat updates short; the report carries the
findings. Use the general command manuals for exact command semantics rather than inferring
behavior.

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
7. Generate the figures and assemble the PDF report.

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

## 7. PDF report

### 7.1 Report structure

Produce a real PDF, not a slide export, containing a tumor report and a tract–tumor report.
Every page carries at least one figure that helps interpret that page. Keep the page roles
below as separate pages; the number of tract pages follows the case. §7.9 builds this layout.

| Page | Content | Figures |
|---|---|---|
| 1 | Case ID; 2–5 sentence summary of lesion location, Tumor Core/edema burden, and the main tract relationship | Contrast-enhanced T1w and FLAIR through the tumor core, tumor compartments as outlines |
| 2 | Compartment table (volume, % whole lesion, % Tumor Core); whole-lesion and Tumor-Core composition charts; orthogonal diameters when reliable | Axial and coronal 3D tumor + `White_Matter` envelope |
| 3 | CHA and Brodmann overlap, each with its own chart and table (volume and % Tumor Core); short anatomical note | One representative 3D view or tumor slice |
| 4 | All-tract overview: per ipsilesional tract, total streamlines, edema-intersecting streamlines, edema fraction, Tumor-Core intersection; tract-to-edema chart; key finding | Axial and coronal all-tract + tumor 3D |
| 5..N | One affected tract per page: T2R results and interpretation | Two orthogonal single-tract 3D views and one structural slice with the tumor and the labeled tract |
| Last | Integrated conclusion, 3–6 numbered points | Tract-to-edema and bilateral morphology charts; all-tract 3D and a representative slice |

Page notes:

- **Composition.** Report both denominators: whole lesion = Necrosis + Enhancing Tumor +
  Peritumoral Edema; Tumor Core = Necrosis + Enhancing Tumor.
- **Atlas.** Keep CHA and Brodmann separate. `% Tumor Core` = overlap volume / Tumor Core
  volume, i.e. the share of the core lying in that region; the percentages need not sum to
  100.
- **Tract pages.** A tract gets its own page when it intersects any lesion compartment, or
  when the 3D view shows clinically important adjacency, marginal course, compression, or
  displacement. If the user asks for each tract, give every analyzed tract a page. Choose the
  two 3D planes from the anatomy (CST: axial + sagittal; SLF: axial + coronal are often
  useful). Never use an all-tract image, or a masked/recolored one, as a tract figure.
- **Last page.** Answer: where the lesion is and how large its compartments are; which
  regions it involves; which pathways are relevant; which intersect Tumor Core, enhancing
  tumor, necrosis, or edema; whether any are displaced, compressed, marginal, or incompletely
  reconstructed; and where uncertainty calls for functional or anatomical correlation.
  Include unreconstructable pathways and the main segmentation, registration, or
  tractography limitation.
- Briefly explain each method (segmentation, atlas overlap, AutoTrack, T2R, curl) where its
  result first appears; the reader may not know them.

### 7.2 Report inputs

Collect before building figures:

```text
Case          FIB source and reconstruction space, structural slice, segmentation model
Lesion        Enhancing Tumor, Necrosis, Tumor Core, Peritumoral Edema, whole lesion (mL);
              both percentage sets; orthogonal diameters when reliable
Atlas         CHA and Brodmann rows: overlap volume and % Tumor Core
Tracts        AutoTrack identifiers and settings; total streamlines per bundle;
              T2R intersecting streamlines and intersect volume per compartment;
              bilateral curl, volume, surface area; list of tracts that get pages
Figures       file name, scene content, set_view and get_camera orientation for each 3D save
```

All figures and numbers must come from one accepted analysis state. When reproducing or
revising an analyzed case, reuse its recorded tract set and results; do not re-select
pathways or re-run AutoTrack just to make the PDF. Re-track only for missing or corrupt
data, a user request, or a failed QC, then repeat the dependent T2R and morphology and say
the reconstruction changed.

### 7.3 3D figures

3D figures are fresh direct DSI Studio saves. The brain envelope is the `White_Matter`
region from `human_tumor`; do not use `add_surface` or a separate isosurface.

1. Resolve region rows by name with `list_region`.
2. Defragment `White_Matter` (`region_action_defragment`) and check it forms one coherent
   envelope. Do not defragment the tumor compartments unless the user asks.
3. Keep each region's own RGB and change alpha only (`set_region_color` with the unsigned
   `#AARRGGBB` value; never copy RGB from another subject): Necrosis 200, Peritumoral Edema
   80, Enhancing Tumor 100, White_Matter 10.
4. Move `White_Matter` to the last Region-table row so it renders last, re-resolving
   indices as it moves.
5. Show only the three tumor compartments and `White_Matter`.
6. `set_param show_surface 0`, `set_param show_slice 0`, `set_param bkg_color -1` (white).
   Tract-style presets also set the background (the "Tube 2" style sets it to black), so set
   `bkg_color` after any style change and keep it white for every 3D save.
7. Once the final tract set is loaded, `set_param tract_color_style 1` (Assigned) and
   `color_all_cluster`; repeat after any tract is added or reloaded. Do not use directional
   color.
8. Save one explicit view per image: `set_view`, `get_camera`, `save_screen`. If a PNG looks
   washed out compared with the screen, the DSI Studio build predates the opaque-framebuffer
   fix; save as `.jpg` instead. Do not use
   `save_lr_screen` or other stereo pairs; place two separate views side by side instead.
9. Open each image. The background must already be white as saved. If it is black or
   transparent, set `bkg_color -1` and save again; never invert or recolor the background
   afterwards, because that destroys the translucent `White_Matter` envelope and the tumor
   colors. Likewise, if the envelope, a tumor compartment, or the requested tract is missing,
   fix the scene and save again.

### 7.4 2D figures

2D slice figures keep DSI Studio's black background. Use contrast-enhanced T1w for the
enhancing tumor and core, and FLAIR for edema and tract-to-edema relationships. Set the
slice view explicitly rather than relying on GUI defaults:

```bash
dsi set_params "roi_draw_edge=1&roi_edge_width=2"     # tumor as outlines, never filled
dsi set_params "roi_track=1&roi_track_count=500000"   # tracts drawn on the slice
dsi set_params "roi_fiber=0&roi_position=0&roi_ruler=0&roi_label=0"   # no glyphs, crosshair lines, ruler, "R" mark
```

- Outlines (`roi_draw_edge=1`) apply to every 2D figure, including the page 1 MRI and the
  tract-page slices, so the tumor signal stays visible. `roi_track` shows the tract on the
  slice; `roi_fiber` only controls diffusion glyphs, so do not turn it on to show a tract.
- Show only the three tumor compartments (no `White_Matter` or Tumor Core copy in 2D),
  resolved by name from a fresh `list_region`: rows shift when `White_Matter` moves to the
  last row.
- Center each slice on the **main lesion** with `move_slice_to_region`, which moves to the
  region's per-axis median voxel, so small distant fragments do not pull the slice away.
  Older DSI Studio builds used the midpoint of the first and last voxel instead (in sub-003
  that put the slice at z ≈ 71, below the tumor); with such a build, center on a copy reduced
  to its main component (`copy_region`, then `region_action_defragment`) and delete the copy
  afterwards. Moving to a wrong row such as `White_Matter` lands at the ventricle level.
- Choose the centering compartment by modality: contrast-enhanced T1w through the main
  enhancing tumor / core; FLAIR through the main edema.
- Choose the plane per tract; do not reuse one axial slice for all. Show only that tract
  (`show_only_tracts`) in its Assigned cluster color. A slice shows only the streamline points
  that lie in it (one voxel thick), so a tract crossing the plane appears as a few dots.
  CST: coronal or sagittal through the lesion, where the tract and the lesion both appear.
  SLF and AF: axial or sagittal. Use the plane in which the tract runs beside the lesion as a
  line.
- Save with `save_roi_screen`, then open each image: the main lesion's outlines and the tract
  must both be clearly visible in the same slice. If the slice misses the main lesion, or the
  tract is only dots, re-center or change the plane and save again. If a slice is redone,
  replace it in the report: every 2D figure in the PDF must come from the final slices.
- The tract name, leader line and arrow are added afterwards by `orient()` in §7.9. Pick the
  arrow point on the tract as it appears in the saved image, not from expected anatomy, and
  put the label box in empty space so the line does not cover the tumor or tract.

### 7.5 Orientation labels

Every image carries anatomical orientation labels, large enough to read in the PDF: about
1/16 of the image width (roughly 10 pt or more as printed), bold, in a margin outside the
anatomy. This applies whatever tool assembles the report. For 3D, read `image_left` and `image_up`
from `get_camera` after each `set_view`. For the standard unflipped views:

```text
set_view 2 0  axial      image left R, right L, top A, bottom P
set_view 1 0  coronal    image left R, right L, top S, bottom I
set_view 0 0  sagittal   image left A, right P, top S, bottom I
```

Still call `get_camera` for every save, especially after flips or rotations; do not put
cardinal labels on an oblique view. For 2D, use `R_side` and the slice convention; in
radiological convention image left is patient right, and the figure says so. A tract's side
and the viewing side are different: "Right CST" is not a "right sagittal view". Do not use
voxel coordinates as clinical localization.

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

Allowed: orientation labels from camera/slice metadata, a tract name and arrow, captions,
borders, and trimming empty margin. Not allowed: inverting or replacing the 3D background,
recoloring or masking an all-tract image into a single tract, removing structures,
synthesizing missing anatomy, or mirroring without relabeling. If a figure is wrong, save it
again from DSI Studio.

### 7.8 Worked example: figures for UPenn-GBM sub-003

This is the accepted figure set for a right-hemisphere case with CST and SLF tract pages.
Use it as a template: replace the row indices with the ones `list_region` / `list_tract`
report for the current case, and the numbers with the case's recorded inputs (§7.2).

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
dsi set_param bkg_color -1    # white; set again after any tract-style change
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

Inspect each image after saving (or `preview_screen 3d` before it). The orientation labels
come from `get_camera`, as in §7.5.

#### DSI Studio commands for the 2D figures

```bash
# 2D view state from §7.4.
dsi set_params "roi_draw_edge=1&roi_edge_width=2"
dsi set_params "roi_track=1&roi_track_count=500000"
dsi set_params "roi_fiber=0&roi_position=0&roi_ruler=0&roi_label=0"
dsi list_region                    # 4 Necrosis, 5 Peritumoral Edema, 6 Enhancing Tumor, 7 White_Matter
dsi show_only_regions "4&5&6"      # outlines of the three tumor compartments only
dsi check_uncheck_all_tract 0

# Representative MRI: ceT1w through the main enhancing tumor, FLAIR through the main edema
dsi set_slice_by_name "<exact ceT1w / T1w-gd slice name>"
dsi set_roi_view 2
dsi move_slice_to_region 6    # median of Enhancing Tumor
dsi save_roi_screen sub003_ceT1w_corecenter.png
dsi set_slice_by_name "<exact FLAIR slice name>"
dsi move_slice_to_region 5    # median of Peritumoral Edema
dsi save_roi_screen sub003_FLAIR_corecenter.png

# Tract slices on FLAIR through the main edema, plane chosen per tract
dsi show_only_tracts "1"           # right CST: coronal
dsi set_roi_view 1
dsi move_slice_to_region 5
dsi save_roi_screen sub003_CST_R_FLAIR_coronal.png
dsi show_only_tracts "3"           # right SLF: axial
dsi set_roi_view 2
dsi move_slice_to_region 5
dsi save_roi_screen sub003_SLF_R_FLAIR_axial.png
```

Open each saved slice and check that the main lesion and the tract appear together before
using it.

Tract names, arrows and R/L/A/P labels are added afterwards (§7.7, code in §7.9); DSI Studio
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

The y-axis label of the edema chart is a reconstructed-streamline fraction (§7.6), not an
axon or infiltration fraction.

### 7.9 Assembling the PDF

The accepted sub-003 report was built with ReportLab from the §7.8 images and charts. The
script below reproduces its seven pages: header and summary box, two-panel figure rows with a
caption strip, navy-header tables, side-by-side figure and text blocks, and a footer with the
case name and page number. For a new case, keep the structure and replace the values, text and
file names with the case inputs (§7.2). Add or remove tract pages by editing the tract list
(§7.1).

Orientation labels are written into a margin, never over the anatomy, and scale with the image
(about 1/16 of its width) so they stay readable at half-page width. 3D labels come
from `get_camera` for that save; 2D labels come from `R_side` (radiological here). A tract
callout needs the tract's pixel position in the saved slice: open the image, find the tract, and
place the label box in empty space so the leader line does not cross the lesion.

```python
import math
from PIL import Image as PILImage, ImageDraw, ImageFont

def font(size):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf",size)
    except OSError:
        return ImageFont.load_default(size)

def orient(src,dst,left,right,top,bottom,dark=False,note=None,callout=None):
    """Pad a DSI export and write R/L/A/P/S/I labels (from get_camera or R_side) in the margin.
    callout = (text,(x,y) of the tract in source pixels,(x,y) of the label box center).
    The leader line runs from the nearest side of the label box to an arrowhead on the tract."""
    im = PILImage.open(src).convert("RGB")
    s = max(im.size)//16                  # label size: readable when the panel is half a page wide
    m = s*3//2
    out = PILImage.new("RGB",(im.width+2*m,im.height+2*m),"black" if dark else "white")
    out.paste(im,(m,m))
    d,fg = ImageDraw.Draw(out),"white" if dark else "black"
    W,H = out.size
    for text,xy in ((top,(W/2,m/2)),(bottom,(W/2,H-m/2)),(left,(m/2,H/2)),(right,(W-m/2,H/2))):
        d.text(xy,text,fill=fg,font=font(s),anchor="mm")
    if note:
        d.text((m//4,H-m//4),note,fill=fg,font=font(s//2),anchor="ld")
    if callout:
        text,(tx,ty),(lx,ly) = callout
        tx,ty,lx,ly = tx+m,ty+m,lx+m,ly+m
        b = d.textbbox((lx,ly),text,font=font(s*3//4),anchor="mm")
        box = (b[0]-s//6,b[1]-s//10,b[2]+s//6,b[3]+s//10)
        sx,sy = min(((box[0],ly),(box[2],ly),(lx,box[1]),(lx,box[3])),key=lambda p:(p[0]-tx)**2+(p[1]-ty)**2)
        d.line([(sx,sy),(tx,ty)],fill="white",width=max(2,s//20))
        n = max(1.0,math.hypot(tx-sx,ty-sy))
        ux,uy,a,w = (tx-sx)/n,(ty-sy)/n,max(8,s//5),max(5,s//9)
        d.polygon([(tx,ty),(tx-a*ux-w*uy,ty-a*uy+w*ux),(tx-a*ux+w*uy,ty-a*uy-w*ux)],fill="white")
        d.rounded_rectangle(box,radius=max(4,s//8),fill="black",outline="white",width=max(2,s//24))
        d.text((lx,ly),text,fill="white",font=font(s*3//4),anchor="mm")
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
orient("sub003_CST_R_FLAIR_coronal.png","sub003_CST_R_FLAIR_coronal_lab.png",callout=("Right CST",(530,560),(260,650)),
       **{**RADIOLOGICAL,"top":"S","bottom":"I"})
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

for name,short,views,plane,t2r,interpretation in [
    ("right corticospinal tract (CST)","CST_R",[("axial3D","Axial"),("sagittal3D","Sagittal")],"coronal",
     ["8,595 / 8,595 right-CST streamlines intersect edema (100%).","0 intersect necrosis.","0 intersect enhancing tumor.",
      "Edema-intersecting tract volume: 1,424 mm<super>3</super>."],
     "the reconstructed motor pathway is embedded in the edema environment but does not enter the reconstructed tumor core."),
    ("right superior longitudinal fasciculus (SLF)","SLF_R",[("axial3D","Axial"),("coronal3D","Coronal")],"axial",
     ["619 / 5,315 right-SLF streamlines intersect edema (11.6%).","0 intersect necrosis.","0 intersect enhancing tumor.",
      "Edema-intersecting tract volume: 556 mm<super>3</super>."],
     "a minority of reconstructed right-SLF streamlines contact edema; the reconstructed tumor core remains separate.")]:
    tract = short.split("_")[0]
    s += [PageBreak(),Paragraph(f"Affected tract: {name}",H2),
          figures(*[(f"sub003_{short}_tumor_WM_{v}_lab.png",f"{label} 3D right {tract} + tumor + White_Matter envelope") for v,label in views]),
          Spacer(1,6),
          grid([[img(f"sub003_{short}_FLAIR_{plane}_lab.png",WIDTH*0.5),
                 Paragraph(f"<b>FLAIR {plane} slice.</b> Radiological convention: image left = patient right. The tumor/edema "
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

After `build`, render every page to an image and look at it before delivering: clipped or
unreadable labels, wrong orientation, a 3D view missing the envelope, tumor, or tract, or a
page without a relevant figure means returning to DSI Studio or the script, not editing the
image.

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

## 9. Postoperative PDF report

Use the §7 framework (figures, orientation, wording, assembly), but lead with eloquent-tract
preservation rather than lesion statistics: one page per relevant pathway with matched
pre/post 3D views (same `set_view` and rotations) and its preservation category, then
postoperative anatomy and the conclusion. Content:

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
