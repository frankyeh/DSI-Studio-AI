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
| 1 | Header band; summary (location, Tumor Core and edema volumes, main tract relationship); four KPI cards; three key findings | Contrast-enhanced T1w through the main enhancing tumor and FLAIR through the main edema, outlines and contour legend |
| 2 | Compartment table with color chips (volume, % whole lesion, % Tumor Core); both composition charts; lesion description; additional foci | Axial and coronal 3D tumor + `White_Matter` envelope |
| 3 | CHA and Brodmann charts (volume and % Tumor Core), kept separate; localization note | One representative 3D view |
| 4 | Tract table: streamlines, through edema, Tumor Core, function to correlate, relationship tag; tract-to-edema chart; key finding | Axial and coronal all-tract + tumor 3D |
| 5..N | One tract per page: measures table (including level of edema contact and curl R/L) and interpretation | Two orthogonal single-tract 3D views and one labeled structural slice |
| Last | Impression (3–6 points); bilateral asymmetry table; points for clinical correlation; methods and limitations panel | Tract-to-edema and bilateral morphology charts |

Page notes:

- **Composition.** Report both denominators: whole lesion = Necrosis + Enhancing Tumor +
  Peritumoral Edema; Tumor Core = Necrosis + Enhancing Tumor.
- **Lesion description.** Hemisphere, lobe and gyrus, depth (cortical, subcortical, deep),
  and whether the lesion reaches the falx, midline, or corpus callosum. Give the three
  diameters of the main component only, never of a region that includes separate fragments.
- **Additional foci.** Every separate component visible in 3D gets a row: location, volume,
  label, and "satellite lesion or false positive: verify on the source images". Do not leave
  visible foci unexplained.
- **Atlas.** Keep CHA and Brodmann separate. Show overlap volume and `% Tumor Core` (overlap
  volume / Tumor Core volume, the share of the core in that region; need not sum to 100) for
  every nonzero row.
- **Tract table.** Add the function to correlate (CST: contralateral motor; SLF: visuospatial
  attention and praxis on the right, language on the dominant side; arcuate and FAT: language
  and speech initiation on the dominant side) and a relationship tag: "Tumor Core contact",
  "Edema contact", "Partial edema contact", or "No contact". Tags describe geometry, not risk.
- **Tract pages.** A tract gets its own page when it intersects any lesion compartment, or
  when the 3D view shows clinically important adjacency, marginal course, compression, or
  displacement; every analyzed tract when the user asks. Give the level of edema contact
  (for CST: cortex, corona radiata, internal capsule). Choose the two 3D planes from the
  anatomy (CST: axial + sagittal; SLF: axial + coronal). Never use an all-tract image, or a
  masked/recolored one, as a tract figure.
- **Last page.** Answer where the lesion is and how large its compartments are; which regions
  and pathways are involved; which tracts intersect Tumor Core, enhancing tumor, necrosis, or
  edema; whether any are displaced, compressed, marginal, or incompletely reconstructed; and
  where uncertainty calls for functional or anatomical correlation. Add an asymmetry table
  (count and curl, (R − L) / mean) and points for clinical correlation (e.g. motor examination
  and motor mapping for CST in edema), worded as items to correlate, not recommendations.
- **Methods panel.** Structural and diffusion sequences, b-values and resolution, segmentation
  model, registration check, AutoTrack settings, DSI Studio version, and report date.
- Briefly explain each method (segmentation, atlas overlap, AutoTrack, T2R, curl) where its
  result first appears; the reader may not know them.
- **Style.** One palette everywhere: the compartment colors of the 3D regions (Necrosis
  `#5b484e`, Enhancing `#bc6e71`, Edema `#8397ab`) in contours, charts, chips, and KPI cards,
  with a legend next to every figure that shows compartments. Fill the page with full-width
  figures instead of leaving half pages empty. Never truncate a table cell, keep units
  typeset (mm<sup>3</sup>), and leave unconfirmed values visibly marked `[verify]`.

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
- Contours keep the region colors used in 3D; add the contour legend under every slice.
  Overlay text on a slice is white and bold, never dark on black.
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

One palette with the 3D compartment colors; contact bars in the enhancing color, zero bars grey.

```python
import numpy as np
import matplotlib.pyplot as plt

# one palette for charts, contours, 3D, and cards: the DSI Studio compartment colors
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

The y-axis of the edema chart is a reconstructed-streamline fraction (§7.6), not an axon or
infiltration fraction.

### 7.9 Assembling the PDF

The script below builds the report with ReportLab from the §7.8 images and charts: a navy
header band with an accent stripe on every page, a summary panel and KPI cards, figure rows
with captions and contour legends, tables with compartment color chips and relationship tags,
side-by-side figure and text panels, a methods panel, and a footer. For a new case keep the
structure and replace the values, text, and file names with the case inputs (§7.2); values
not yet confirmed stay marked `[verify]`. Add or remove tract pages by editing the tract list.

Orientation labels are written into a margin, never over the anatomy, about 1/16 of the image
width, white on slices. 3D labels come from `get_camera` for that save; 2D labels from
`R_side` (radiological here). A tract callout needs the tract's pixel position in the saved
slice: open the image, find the tract, and place the label box in empty space.

```python
import math
from PIL import Image as PILImage, ImageDraw, ImageFont
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle,Image,PageBreak,KeepTogether

# ---- case inputs (§7.2): replace every value, keep [verify] visible until confirmed ----
CASE = {"title":"UPenn-GBM sub-003","study":"UPenn-GBM","space":"GQI native space",
        "methods":[("Structural","contrast-enhanced T1w (segmentation), FLAIR (edema/tract context)"),
                   ("Diffusion","sub-003_dwi.gqi.fz · 240 × 240 × 155 · 1 mm isotropic · b-values [verify]"),
                   ("Segmentation","U-Net Studio human_tumor V2 · registration checked in three planes"),
                   ("Tractography","AutoTrack, bilateral · TIP 4 · 10,000-tract target"),
                   ("Software","DSI Studio [version] · report generated [date]")]}
NEC,ENH,EDE = colors.HexColor("#5b484e"),colors.HexColor("#bc6e71"),colors.HexColor("#8397ab")
NAVY,INK,MUTED = colors.HexColor("#1f3a5f"),colors.HexColor("#1d2733"),colors.HexColor("#6b7785")
PALE,LINE,RED,AMBER,GREY = colors.HexColor("#f3f6fa"),colors.HexColor("#d5dce4"),colors.HexColor("#b4474b"),colors.HexColor("#c98a1a"),colors.HexColor("#8a96a3")
W = letter[0]-1.2*inch

def style(name,**kw):
    return ParagraphStyle(name,**{"fontName":"Helvetica","fontSize":9.5,"leading":13,"textColor":INK,**kw})
BODY,SMALL,H3 = style("b"),style("s",fontSize=8,leading=10.5,textColor=MUTED),style("h3",fontName="Helvetica-Bold",fontSize=11,leading=14,textColor=NAVY,spaceAfter=3)
CAP = style("cap",fontSize=8,leading=10,textColor=MUTED)

# ---- orientation labels and tract callout, in a margin outside the anatomy (§7.5) ----
def font(size):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf",size)
    except OSError:
        return ImageFont.load_default(size)

def orient(src,dst,left,right,top,bottom,dark=False,note=None,callout=None):
    """callout = (text,(x,y) on the tract in source pixels,(x,y) label-box center); the leader runs
    from the nearest side of the box to an arrowhead on the tract."""
    im = PILImage.open(src).convert("RGB")
    s = max(im.size)//16
    m = s*3//2
    out = PILImage.new("RGB",(im.width+2*m,im.height+2*m),"black" if dark else "white")
    out.paste(im,(m,m))
    d,fg = ImageDraw.Draw(out),"white" if dark else "#1d2733"
    Wd,Hd = out.size
    for text,xy in ((top,(Wd/2,m/2)),(bottom,(Wd/2,Hd-m/2)),(left,(m/2,Hd/2)),(right,(Wd-m/2,Hd/2))):
        d.text(xy,text,fill=fg,font=font(s),anchor="mm")
    if note:
        d.text((m//4,Hd-m//4),note,fill=fg,font=font(s//2),anchor="ld")
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

# ---- layout pieces ----
def img(file,width):
    w,h = PILImage.open(file).size
    return Image(file,width,width*h/w)

def box(rows,widths,bg=None,border=LINE,pad=6,extra=()):
    t = Table(rows,colWidths=widths,cornerRadii=[5]*4)
    t.setStyle(TableStyle([("VALIGN",(0,0),(-1,-1),"TOP"),("BOX",(0,0),(-1,-1),0.6,border),
                           ("TOPPADDING",(0,0),(-1,-1),pad),("BOTTOMPADDING",(0,0),(-1,-1),pad),
                           ("LEFTPADDING",(0,0),(-1,-1),pad+2),("RIGHTPADDING",(0,0),(-1,-1),pad+2)]+
                          ([("BACKGROUND",(0,0),(-1,-1),bg)] if bg else [])+list(extra)))
    return t

def header(title,subtitle):  # navy band with a thin accent stripe
    t = Table([[Paragraph(title,style("t",fontName="Helvetica-Bold",fontSize=17,leading=21,textColor=colors.white)),
                Paragraph(subtitle,style("st",fontSize=9,textColor=colors.HexColor("#c9d6e6"),alignment=2))]],
              colWidths=[W*0.62,W*0.38])
    t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,-1),NAVY),("VALIGN",(0,0),(-1,-1),"MIDDLE"),
                           ("TOPPADDING",(0,0),(-1,-1),10),("BOTTOMPADDING",(0,0),(-1,-1),10),
                           ("LEFTPADDING",(0,0),(-1,-1),12),("RIGHTPADDING",(0,0),(-1,-1),12),
                           ("LINEBELOW",(0,0),(-1,-1),3,ENH)]))
    return [t,Spacer(1,10)]

def panel(title,html,bg=PALE,width=W):
    return box([[[Paragraph(title,H3),Paragraph(html,BODY)]]],[width],bg=bg)

def kpis(items):  # (label, value, color) cards with a colored top rule
    cells = [[Paragraph(f'<font size="8" color="#6b7785">{label.upper()}</font><br/><font name="Helvetica-Bold" size="19">{value}</font>',
                        style("k",leading=22)) for label,value,_ in items]]
    extra = [("LINEABOVE",(i,0),(i,0),3,c) for i,(_,_,c) in enumerate(items)]+[("LINEAFTER",(0,0),(-2,0),0.6,LINE)]
    return box(cells,[W/len(items)]*len(items),bg=PALE,pad=8,extra=extra)

def figures(*pairs):  # images side by side with captions
    w = W/len(pairs)
    return box([[img(f,w-14) for f,_ in pairs],[Paragraph(c,CAP) for _,c in pairs]],[w]*len(pairs),pad=5)

def side(left,right,split=0.5):  # two columns; a callable gets its column width (for panels and tables)
    wl,wr = W*split-6,W*(1-split)
    left,right = [x(w) if callable(x) else x for x,w in ((left,wl),(right,wr))]
    t = Table([[left,right]],colWidths=[W*split,W*(1-split)])
    t.setStyle(TableStyle([("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),0),("RIGHTPADDING",(0,0),(0,0),6),
                           ("RIGHTPADDING",(1,0),(1,0),0)]))
    return t

def table(header_row,rows,widths,chips=None,tags=None):
    """chips: {row: color} draws a compartment color chip in column 0; tags: {(row,col): color} renders a pill."""
    t = Table([[Paragraph(f"<b>{h}</b>",style("th",fontSize=8.5,textColor=colors.white)) for h in header_row]]+
              [[Paragraph(str(c),style("td",fontSize=9)) for c in r] for r in rows],colWidths=widths,repeatRows=1)
    s = [("BACKGROUND",(0,0),(-1,0),NAVY),("LINEBELOW",(0,1),(-1,-1),0.5,LINE),("VALIGN",(0,0),(-1,-1),"MIDDLE"),
         ("ROWBACKGROUNDS",(0,1),(-1,-1),[colors.white,PALE])]
    for r,c in (chips or {}).items():
        s += [("LINEBEFORE",(0,r+1),(0,r+1),6,c)]
    for (r,col),c in (tags or {}).items():
        t._cellvalues[r+1][col] = Paragraph(f'<font color="white"><b>&nbsp;{rows[r][col]}&nbsp;</b></font>',style("tag",fontSize=8,backColor=c,borderPadding=2))
    t.setStyle(TableStyle(s))
    return t

def legend(items):  # compartment color key for contours and 3D: a color chip before each name
    t = Table([sum(([" ",Paragraph(n,SMALL)] for n,_ in items),[])],colWidths=sum(([8,len(n)*4.6+14] for n,_ in items),[]),hAlign="LEFT")
    t.setStyle(TableStyle([("BACKGROUND",(2*i,0),(2*i,0),c) for i,(_,c) in enumerate(items)]+
                          [("TOPPADDING",(0,0),(-1,-1),1),("BOTTOMPADDING",(0,0),(-1,-1),1),("LEFTPADDING",(0,0),(-1,-1),4),
                           ("RIGHTPADDING",(0,0),(-1,-1),8),("VALIGN",(0,0),(-1,-1),"MIDDLE")]))
    return t

def footer(canvas,doc):
    canvas.saveState()
    canvas.setStrokeColor(LINE)
    canvas.line(0.6*inch,0.55*inch,letter[0]-0.6*inch,0.55*inch)
    canvas.setFont("Helvetica",7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(0.6*inch,0.38*inch,f"{CASE['title']} · DSI Studio tumor and tractography report · imaging decision support, not a diagnosis")
    canvas.drawRightString(letter[0]-0.6*inch,0.38*inch,f"Page {doc.page}")
    canvas.restoreState()

# ---- labeled figures ----
AXIAL3D,CORONAL3D,SAGITTAL3D = ("R","L","A","P"),("R","L","S","I"),("A","P","S","I")
for f,o in [("tumor_WM_axial3D",AXIAL3D),("tumor_WM_coronal3D",CORONAL3D),("alltracts_tumor_WM_axial3D",AXIAL3D),
            ("alltracts_tumor_WM_coronal3D",CORONAL3D),("CST_R_tumor_WM_axial3D",AXIAL3D),("CST_R_tumor_WM_sagittal3D",SAGITTAL3D),
            ("SLF_R_tumor_WM_axial3D",AXIAL3D),("SLF_R_tumor_WM_coronal3D",CORONAL3D)]:
    orient(f"sub003_{f}.png",f"sub003_{f}_lab.png",*o)
RAD = dict(left="R",right="L",top="A",bottom="P",dark=True,note="Radiological convention")
for f in ["ceT1w_corecenter","FLAIR_corecenter"]:
    orient(f"sub003_{f}.png",f"sub003_{f}_lab.png",**RAD)
orient("sub003_CST_R_FLAIR_coronal.png","sub003_CST_R_FLAIR_coronal_lab.png",callout=("Right CST",(530,560),(260,650)),**{**RAD,"top":"S","bottom":"I"})
orient("sub003_SLF_R_FLAIR_axial.png","sub003_SLF_R_FLAIR_axial_lab.png",callout=("Right SLF",(330,490),(220,350)),**RAD)
CONTOURS = legend([("Necrosis",NEC),("Enhancing tumor",ENH),("Peritumoral edema",EDE)])

# ---- pages ----
s = header("Brain Tumor Imaging &amp; Tractography",f"{CASE['study']} · {CASE['title'].split()[-1]} · {CASE['space']}")
s += [panel("Summary","Predominantly right parasagittal lesion centered in posterior cingulate / perirolandic territory: "
            "Tumor Core 18.66 mL (necrosis 11.96 mL, enhancing 6.70 mL) with 60.48 mL peritumoral edema. "
            "All reconstructed right CST streamlines pass through edema and 11.6% of right SLF streamlines do; "
            "no reconstructed tract enters the Tumor Core."),Spacer(1,8),
      kpis([("Tumor Core","18.7 mL",NEC),("Edema","60.5 mL",EDE),("Right CST in edema","100%",RED),("Right SLF in edema","11.6%",AMBER)]),Spacer(1,8),
      figures(("sub003_ceT1w_corecenter_lab.png","Contrast-enhanced T1w · axial through the main enhancing tumor"),
              ("sub003_FLAIR_corecenter_lab.png","FLAIR · axial through the main edema")),
      Spacer(1,3),CONTOURS,Spacer(1,8),
      panel("Key findings","1. Right parasagittal posterior cingulate / perirolandic lesion with edema three times the Tumor Core volume.<br/>"
            "2. Right CST lies within the edema field; no reconstructed streamline enters necrosis or enhancing tumor.<br/>"
            "3. Two small separate foci (see page 2) need verification on the source images.",bg=colors.white),
      PageBreak()]

s += header("Lesion compartments","Automated human_tumor segmentation")
s += [side(table(["Compartment","Volume","% whole lesion","% Tumor Core"],
                 [["Necrosis","11.96 mL","15.1%","64.1%"],["Enhancing tumor","6.70 mL","8.5%","35.9%"],
                  ["Peritumoral edema","60.48 mL","76.4%","—"],["Tumor Core","18.66 mL","23.6%","100%"],
                  ["Whole lesion","79.14 mL","100%","—"]],
                 [W*0.17,W*0.1,W*0.11,W*0.11],chips={0:NEC,1:ENH,2:EDE,3:NAVY,4:GREY}),
           [img("whole_lesion_composition.png",W*0.47),img("tumor_core_composition.png",W*0.47)],split=0.5),Spacer(1,8),
      figures(("sub003_tumor_WM_axial3D_lab.png","Axial 3D · tumor within the White_Matter envelope"),
              ("sub003_tumor_WM_coronal3D_lab.png","Coronal 3D")),Spacer(1,3),CONTOURS,Spacer(1,8),
      side(lambda w:panel("Lesion description","Right hemisphere, parasagittal; posterior cingulate gyrus extending to the perirolandic region; "
                 "deep white matter and cortex; abuts the falx [verify midline / corpus callosum]. Main-component diameters "
                 "[AP × LR × SI cm, verify].",width=w),
           [Paragraph("Additional foci",H3),
            table(["Focus","Volume","Label"],[["Left frontal","[mL]","Enhancing"],["Inferior [location]","[mL]","Enhancing"]],[W*0.2,W*0.1,W*0.15]),
            Paragraph("Satellite lesion or segmentation false positive: verify on the source images.",SMALL)],split=0.52),
      PageBreak()]

s += header("Anatomical localization","Tumor Core overlap · CHA and Brodmann atlases")
s += [side(img("CHA_tumor_core_overlap.png",W*0.49),img("Brodmann_tumor_core_overlap.png",W*0.49)),Spacer(1,6),
      Paragraph("Percentages are the share of the 18.66 mL Tumor Core lying in each region; the two atlases are separate parcellations "
                "and need not sum to 100%.",SMALL),Spacer(1,8),
      side(img("sub003_tumor_WM_coronal3D_lab.png",W*0.42),
           lambda w:panel("Localization","Largest CHA overlap: posterior cingulate (29.5% of the core); perirolandic overlap in precentral (6.7%), "
                 "postcentral (4.1%), and premotor (2.4%) cortex. Brodmann overlap is mainly right-sided: BA31 (13.4%), BA4 (9.4%), "
                 "BA23 (5.6%). Atlas overlap localizes anatomy; it does not establish function.",width=w),split=0.45),
      PageBreak()]

s += header("Eloquent tracts","Bilateral AutoTrack · tract-to-region (T2R) analysis")
s += [figures(("sub003_alltracts_tumor_WM_axial3D_lab.png","Axial · all analyzed tracts"),
              ("sub003_alltracts_tumor_WM_coronal3D_lab.png","Coronal · all analyzed tracts")),Spacer(1,8),
      table(["Right tract","Function to correlate","Streamlines","Through edema","Tumor Core","Relationship"],
            [["CST","Contralateral motor","8,595","8,595 (100%)","0","Edema contact"],
             ["SLF","Visuospatial attention, praxis","5,315","619 (11.6%)","0","Partial edema contact"],
             ["Arcuate","Language if right-dominant","7,255","0","0","No contact"],
             ["FAT","Speech initiation if right-dominant","5,812","0","0","No contact"]],
            [W*0.09,W*0.25,W*0.13,W*0.16,W*0.11,W*0.26],tags={(0,5):RED,(1,5):AMBER,(2,5):GREY,(3,5):GREY}),Spacer(1,8),
      side(img("right_tract_to_edema.png",W*0.5),
           lambda w:panel("Key finding","No reconstructed tract enters necrosis or enhancing tumor. The main relationship is the right CST "
                 "running through the edema field; the right SLF has limited edema contact. Streamline percentages describe the "
                 "reconstruction, not axon counts.",width=w),split=0.52)]

for name,short,views,plane,metrics,note in [
    ("Right corticospinal tract","CST_R",[("axial3D","Axial 3D"),("sagittal3D","Sagittal 3D")],"coronal",
     [("Streamlines","8,595"),("Through edema","8,595 (100%)"),("Edema intersection","1,424 mm<super>3</super>"),
      ("Tumor Core","0"),("Level of edema contact","corona radiata [verify]"),("Curl R / L","1.25 / 1.12")],
     "The reconstructed motor pathway runs through the edema field and does not enter the Tumor Core. "
     "Consider correlation with motor examination and, where planned, intraoperative motor mapping."),
    ("Right superior longitudinal fasciculus","SLF_R",[("axial3D","Axial 3D"),("coronal3D","Coronal 3D")],"axial",
     [("Streamlines","5,315"),("Through edema","619 (11.6%)"),("Edema intersection","556 mm<super>3</super>"),
      ("Tumor Core","0"),("Level of edema contact","lateral parietal [verify]"),("Curl R / L","1.35 / 1.69")],
     "A minority of reconstructed right SLF streamlines contact edema; the Tumor Core remains separate.")]:
    tract = short.split("_")[0]
    s += [PageBreak()]+header(name,"Tract-to-lesion relationship")
    s += [figures(*[(f"sub003_{short}_tumor_WM_{v}_lab.png",f"{label} · right {tract} + tumor") for v,label in views]),Spacer(1,8),
          side([img(f"sub003_{short}_FLAIR_{plane}_lab.png",W*0.46),Paragraph(f"FLAIR · {plane} through the main edema",CAP),CONTOURS],
               [table(["Measure","Right "+tract],[list(m) for m in metrics],[W*0.25,W*0.24]),Spacer(1,8),
                panel("Interpretation",note,width=W*0.5)],split=0.5)]

def ai(r,l):  # asymmetry index, % of the mean
    return f"{(r-l)/((r+l)/2)*100:+.0f}%"
s += [PageBreak()]+header("Integrated impression","For imaging review and planning support")
s += [side(img("right_tract_to_edema.png",W*0.49),img("bilateral_tract_morphology.png",W*0.49)),Spacer(1,6),
      table(["Tract","Streamlines L / R","Asymmetry","Curl L / R","Asymmetry"],
            [["CST","8,013 / 8,595",ai(8595,8013),"1.12 / 1.25",ai(1.25,1.12)],["SLF","3,459 / 5,385",ai(5385,3459),"1.69 / 1.35",ai(1.35,1.69)],
             ["Arcuate","8,688 / 7,246",ai(7246,8688),"1.24 / 2.28",ai(2.28,1.24)],["FAT","5,767 / 5,642",ai(5642,5767),"1.19 / 1.22",ai(1.22,1.19)]],
            [W*0.16,W*0.24,W*0.18,W*0.24,W*0.18]),Spacer(1,8),
      side(lambda w:panel("Impression","1. Right parasagittal posterior cingulate / perirolandic lesion: Tumor Core 18.66 mL, edema 60.48 mL.<br/>"
                 "2. Right CST runs through the edema field (100% of reconstructed streamlines); no Tumor-Core intersection.<br/>"
                 "3. Right SLF: partial edema contact (11.6%). Arcuate and FAT: no lesion contact.<br/>"
                 "4. Right arcuate curl is higher than left without lesion contact: a descriptive reconstruction asymmetry.<br/>"
                 "5. Two small separate foci require verification.",width=w),
           lambda w:panel("For clinical correlation","Motor examination and motor mapping for the CST relationship; visuospatial assessment for "
                 "the right SLF; functional MRI or stimulation mapping where eloquence is uncertain.",bg=colors.white,width=w),split=0.56),
      Spacer(1,8),
      box([[Paragraph("Methods and limitations",H3)]]+[[Paragraph(f"<b>{k}</b> &nbsp;{v}",SMALL)] for k,v in CASE["methods"]]+
          [[Paragraph("Streamlines are reconstructed trajectories, not axons. Edema intersection is geometric, not histologic invasion; "
                      "zero Tumor-Core intersection does not prove a safe plane. Verify against the source images.",SMALL)]],[W],pad=4)]

SimpleDocTemplate("sub003_tumor_report.pdf",pagesize=letter,leftMargin=0.6*inch,rightMargin=0.6*inch,
                  topMargin=0.5*inch,bottomMargin=0.75*inch).build(s,onFirstPage=footer,onLaterPages=footer)
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
