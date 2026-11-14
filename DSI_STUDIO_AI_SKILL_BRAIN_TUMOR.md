# DSI Studio AI Brain Tumor Report

Presurgical or postsurgical brain-tumor evaluation for a neurosurgeon. The deliverable is a
**PowerPoint PPTX report** (§7) presenting the lesion, its anatomical location, and its relationship to
the eloquent pathways: run Steps 1–6, then make the charts and 2D figures, export the native GLB models,
and assemble the PPTX. Keep chat updates short; the report carries the findings. Take exact command
semantics from the general manuals, never inference.

This is imaging and tractography decision support. Tractography alone does not establish function,
tissue viability, safe resection margins, or whether a pathway can be sacrificed; interpret it with the
neurological examination, functional imaging, cortical/subcortical mapping, operative anatomy, and other
clinical information.

**Teaching case.** Without patient files, **offer** the matched
[UPenn GBM `sub-100` sample](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md) from Fiber Data Hub (T1w, contrast
T1w, FLAIR, tumor segmentation, DWI GQI FZ; SZ optional). Download selected assets only with approval,
verify matching subject IDs and label/FZ alignment before tract-to-lesion analysis, and treat output as
**educational**, not a clinical surgical report.

## Workflow overview

Presurgical: (1) verify the structural image, segment the lesion, measure compartments; (2) localize the
Tumor Core against `CHA` and `Brodmann`; (3) select relevant bilateral eloquent pathways; (4) reconstruct
them with AutoTrack; (5) quantify tract-to-lesion involvement with T2R; (6) compare bilateral morphology
and inspect spatial relationships; (7) make charts and 2D figures, export GLBs last (export prunes large
tracts, §7.3), and assemble the PPTX. Postsurgical (§8): reconstruct the same pathways and report whether
each remains reconstructable around the cavity, residual lesion, and edema.

Never use tumor- or edema-derived regions as ROI, Seed, ROA, End, or other constraints for standard
AutoTrack: reconstruct the named tract independently, then measure its relationship to the lesion.

| Section | Companion manuals |
|---|---|
| §1 segmentation, slice readiness, model availability, three-plane QC | `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §2 atlas localization | `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §3–4 pathway selection, AutoTrack | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md` |
| §5 tract-to-lesion connectivity | `DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| §6–7 morphology, rendering, figures | `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md` |
| §8 postoperative | The Slice, Rendering, Region, Tract, T2R, and Fiber-Tracking manuals above |

# PRESURGICAL EVALUATION

## 1. Verify imaging, segment, and characterize the lesion

### 1.1 Input and registration preflight

```bash
bash ./dsi.sh list_slice
bash ./dsi.sh set_slice <slice-index>
bash ./dsi.sh list_slice
```

With several structural NIfTIs, `dir` the folder and compare each candidate's dimensions and voxel size:
pick the highest-resolution one (e.g. 1 mm isotropic MPRAGE). Thick slices (e.g. 0.5×0.5×5 mm) are poor
for segmentation, which needs true 3D accuracy; lower resolution gives coarser segmentations. When a FIB
from Fiber Data Hub already lists its structural MRI as `available`, `set_slice` it (never `add_slice`
it again) and poll `list_slice` until `ready`. `ready` means loading/registration finished, not
alignment: inspect the structural image against diffusion anatomy first, and record the FIB
reconstruction space, structural source/slice, and segmentation model ID.

### 1.2 Tumor model and label definition

Default `human_tumor` (**U-Net Studio Human Tumor Lesion V2**), contrast-flexible for T1w, T1w-gd, T2w,
FLAIR, and related contrasts; `human_tumor_T1w` is the lightweight T1w-specific alternative. Avoid
`human_tumorsynth` when tumor core and edema must be measured separately (it outputs one `Tumor`
region). Use the exact model ID only when `list_unet` shows `available` true:

```bash
bash ./dsi.sh list_unet
bash ./dsi.sh segment_brain "human_tumor" "<slice-name-or-index>"
bash ./dsi.sh list_region
```

Expected lesion labels: `Enhancing Tumor`, `Necrosis`, `Peritumoral Edema`. `human_tumor` also emits
five tissue labels that are not lesion compartments and shift indices, so resolve lesion rows by exact
name from a fresh `list_region`, never by creation order. Define **Tumor Core = Enhancing Tumor ∪
Necrosis**; keep `Peritumoral Edema` separate. A missing label is unavailable, not zero. Preserve the
original labels.

**Segmentation failure fallback.** If segmentation finds no tumor, is severely fragmented, or lacks a
Tumor Core compartment, first re-run it (correct slice selected; `human_tumor_T1w` for T1w-only data).
Failing that, a rough tumor region can be derived from the isotropic diffusion (ISO) map, where tumor
often stands out, but at diffusion resolution (e.g. 2.5 mm) it suits gross localization only, not
volumetry or margins. Always report which method produced the lesion regions.

Build Tumor Core from copies so the originals stay untouched; do not build it if either component is
missing:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>"
bash ./dsi.sh copy_region <current-enhancing-tumor-index>
bash ./dsi.sh list_region
bash ./dsi.sh set_region_name <enhancing-copy-index> "Tumor Core"
bash ./dsi.sh copy_region <current-necrosis-index>
bash ./dsi.sh list_region
bash ./dsi.sh merge_regions "<current-Tumor-Core-index>&<necrosis-copy-index>"
bash ./dsi.sh list_region
```

**Index bookkeeping:** `copy_region` inserts the copy right after its source; `merge_regions` keeps the
first region and removes later ones; every `copy_region`/`merge_regions`/`delete_region` shifts later
indices. After each mutation run `list_region` and note the new index→name map; resolve all regions a
step needs from one fresh listing. Verify the merge with `show_region_statistics` on the components and
the Core: Core volume must equal Enhancing + Necrosis (within rounding), or the wrong rows were merged.

### 1.3 Three-plane QC and lesion measurements

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

`preview_screen roi` (and `preview_screen 3d` in Step 6) is coarse: gross location/alignment and
co-visibility, not fine boundaries. When an important boundary or laterality decision cannot be
resolved, say so instead of inferring, and use `save_roi_screen` for human review when an output
destination was provided or requested (never invent a path for QC). A completed `segment_brain` is not
anatomical validity: inspect remote/disconnected components rather than accepting them.

`show_region_statistics` uses the checked regions, so isolate them immediately before:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<Tumor-Core-index>&<edema-index>"
bash ./dsi.sh show_region_statistics
```

Record when available: Enhancing Tumor, Necrosis, Tumor Core, and Peritumoral Edema volumes (mm^3);
lesion hemisphere or bilateral/midline involvement; gross lobe/location and important adjacent anatomy.

**Radiologist-style reporting.** Give location plus three orthogonal diameters, not just volumes: from
each region's bounding box (min/max x, y, z in mm) take max − min per axis, convert to cm, largest first;
for Tumor Core use the union of the component boxes. Location comes from Step 2 atlas overlap, not raw
coordinates; hemisphere follows the MNI x sign (negative = left); give each atlas region's intersection
volume and fraction of Tumor Core.

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

"Central"/"peripheral" are impressions: segmentation gives boxes and centers, not the topology between
necrosis and enhancing tissue, so state the limitation when unresolved. Worked example (M028Y): left
frontal lobe mass centered in precentral gyrus, 1.5 x 1.3 x 1.1 cm (Tumor Core 9.0 cm^3); central
necrosis 1.4 x 1.2 x 1.0 cm (6.7 cm^3); peripheral enhancing 1.4 x 1.2 x 1.1 cm (2.2 cm^3); edema
1.9 x 2.0 x 2.1 cm (14.8 cm^3). CHA overlap: precentral gyrus 33%, prefrontal 17%, premotor 9%.

## 2. Localize the Tumor Core anatomically

Use the nonmutating overlap command with the atlases named exactly `CHA` and `Brodmann`; never load
their labels into the Region table just for overlap:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> CHA
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> Brodmann
```

It maps atlas labels into the region's space, returns ordinary statistics for nonempty intersections
(zero-overlap labels omitted), and leaves the Region table unchanged. For each affected region report
intersection volume (mm^3) and fraction of Tumor Core (intersection / total Tumor Core volume). Run it on
the edema region too when that would materially help pathway selection. Brodmann overlap is anatomy, not
proof of impaired function. CHA and Brodmann are gray-matter parcellations, so intersections need not
sum to the Core volume, especially for white-matter-centered lesions. Use `add_region_from_atlas` only
when real atlas regions are needed for visualization, editing, tracking constraints, or later steps.

## 3. Select the eloquent pathways

These verified human AutoTrack identifiers need no `list_auto_tract`:

| Function | Pathway | Left | Right |
|---|---|---|---|
| Motor | Corticospinal tract | `ProjectionBrainstem_CorticospinalTractL` | `ProjectionBrainstem_CorticospinalTractR` |
| Language | Arcuate fasciculus | `Association_ArcuateFasciculusL` | `Association_ArcuateFasciculusR` |
| Language | Superior longitudinal fasciculus | `Association_SuperiorLongitudinalFasciculusL` | `Association_SuperiorLongitudinalFasciculusR` |
| Language | Frontal aslant tract | `Association_FrontalAslantTractL` | `Association_FrontalAslantTractR` |
| Temporal language / semantic | Inferior longitudinal fasciculus | `Association_InferiorLongitudinalFasciculusL` | `Association_InferiorLongitudinalFasciculusR` |
| Vision | Optic radiation | `ProjectionBasalGanglia_OpticRadiationL` | `ProjectionBasalGanglia_OpticRadiationR` |
| Optional | Inferior fronto-occipital fasciculus | `Association_InferiorFrontoOccipitalFasciculusL` | `Association_InferiorFrontoOccipitalFasciculusR` |
| Optional | Uncinate fasciculus | `Association_UncinateFasciculusL` | `Association_UncinateFasciculusR` |

Use the parent SLF entry, not SLF II/III, for routine planning; discover any other pathway with
`list_auto_tract`. Reconstruct the lesion-side pathways and their contralateral homologs. Only CST and
optic radiation use the contralateral side as a morphology control (§6); other pathways are normally
asymmetric. Curl (route/distance ratio) may flag asymmetry but alone does not prove tumor displacement.

- Perirolandic or motor lesion: CST.
- Frontal language lesion: AF, SLF, FAT. Parietal language: AF, SLF. Temporal language: AF, ILF.
- Posterior temporal, parietal, or occipital lesion: optic radiation when visual risk is relevant; for
  temporal lesions add it when lesion or edema extends into posterior temporal or temporo-occipital
  white matter, and map it when coarse agent-side QC cannot confidently exclude that. Never trigger a
  tract by edema volume or a Brodmann label alone.

## 4. Reconstruct the selected bilateral pathways

Map left and right homologs with identical settings, following the AutoTrack QC, tolerance, TIP, and
retry guidance in `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`. `run_auto_track` is asynchronous: launch all
calls back-to-back, then poll `list_tract` about every 10 s until every requested row is `done` before
statistics, T2R, saving, editing, or visualization; then give each bundle a distinct color.

```bash
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractR"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusR"
bash ./dsi.sh list_tract
bash ./dsi.sh color_all_cluster
```

A pathway still empty after the bounded tolerance retries is `unmappable` (report tract count, seed
limit, tolerance values, attempts); zero yield is not anatomical absence or zero involvement. Then load
the atlas version with the same identifier and try **partial tracking**: the subject's own streamlines
inside a corridor around the atlas course, which can recover a pathway disrupted or displaced near the
lesion.

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

Re-resolve every row with `list_tract`/`list_region` (`tract_to_region` uses the current slice grid;
`region_action_dilation_by_voxel` takes the row and radius in voxels; the region string uses `row:type`).

- A plausible bundle along the expected course is the subject's reconstruction, labeled "atlas-guided
  partial tracking" in the table, header, captions, and conclusion; note that the corridor confines it,
  so a pathway displaced beyond about 5 voxels may be missed or truncated. Delete the atlas row or keep
  it only as reference.
- If partial tracking also fails, use the atlas tract itself. Nonlinearly warped to the subject, it
  shows the **likely pathway location**, not the subject's reconstruction. Use it in figures and T2R
  but label it atlas-based everywhere (table "CST R (atlas)", header, captions, conclusion: "likely
  pathway location from the population tractography atlas; AutoTrack could not map this pathway");
  report its lesion relationship by intersection volume and compartment contact (any streamline fraction
  is a fraction of atlas streamlines); exclude it from morphology, curl, and asymmetry; and state that
  mass effect or edema can displace the real pathway, so the course near the lesion is least certain.

## 5. Quantify tract-to-lesion involvement with T2R

Use **T2R**, not per-tract voxel regions, for involvement. `show_t2r` takes the checked bundles and
regions, maps the lesion regions into the FIB grid internally (no `tract_to_region`, lesion copies,
binary intersections, or disposable masks), and reports ordinary tract statistics for the streamlines
passing through each region; `number of tracts` under a lesion column is that bundle's intersecting
streamline count.

```bash
bash ./dsi.sh list_tract
bash ./dsi.sh list_region
bash ./dsi.sh show_only_tracts "<tract-index-1>&<tract-index-2>&..."
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>&<Tumor-Core-index>"
bash ./dsi.sh show_t2r
```

Omit unavailable regions; one call covers several bundles. Every checked bundle gets a header, but data
rows (`number of tracts`, etc.) appear only for nonzero intersections: a header without rows is a valid
zero (common for contralateral bundles), not a failure. For a clearly unilateral lesion prioritize
ipsilesional intersections; omit contralateral zero rows only after confirming them, since a crossing,
bilateral, or midline lesion can involve either side.

Streamline counts depend on seeding and settings and are not axon counts. Use `intersect volume(mm^3)`
as the spatial overlap; when a fraction helps, use `number of tracts` only as a numerator:

```text
intersection volume (mm^3) = T2R "intersect volume(mm^3)" for that region
reconstructed-streamline fraction = T2R "number of tracts" / total bundle streamlines
```

A streamline can cross several compartments, so values need not sum. T2R is geometric intersection with
segmented regions, not histological invasion; never use the generic `intersect ratio` as the streamline
fraction. A zero is valid only when the tract and lesion are nonempty, share the subject/mapping
context, and T2R completed.

## 6. Morphology, laterality, and spatial relationship

**Left/right morphology is compared only for CST and optic radiation**, approximately symmetric in
healthy brains. AF, SLF, FAT, IFOF, ILF, and uncinate are normally asymmetric: never compare, chart, or
report their left/right curl, volume, surface area, or ratios; describe them by their own lesion
relationship (T2R, geometry).

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_tract_statistics
```

Record per side: total number of tracts, total volume(mm^3), total surface area(mm^2), curl
(route/distance ratio). Compare descriptively. Higher ipsilesional curl fits a longer or more winding
route but alone does not show displacement: attribute it to the lesion only when the 3D geometry shows
the pathway pushed around the lesion or edema and the anatomy supports it. Without lesion contact, report
curl asymmetry as descriptive reconstruction asymmetry. No universal threshold (such as 20%) diagnoses
displacement. Optional ratios for a designated lesion side: volume ratio = ipsilesional / contralateral
volume; surface-area ratio likewise; never interpret ratios alone (CST and optic radiation also have
some normal asymmetry).

Verify lesion laterality from structural anatomy and segmentation before labeling tracts
ipsilesional/contralateral; `preview_screen roi`'s `R_side=left`/`R_side=right` translates screen
position to anatomy, but its thumbnail is not definitive. Atlas suffixes, left/right AutoTrack
identifiers, MNI sign, and geometry may corroborate; if cues disagree, keep plain left/right labels and
state the uncertainty. Inspect tract and lesion together (and all three slice planes for an important
small T2R intersection):

```bash
bash ./dsi.sh show_only_tracts "<relevant-left-tract>&<relevant-right-tract>"
bash ./dsi.sh show_only_regions "<relevant-lesion-region-indices>"
bash ./dsi.sh set_view 0 0
bash ./dsi.sh preview_screen 3d
```

For a requested rotating video, keep White_Matter visible for context:

```bash
bash ./dsi.sh show_only_tracts "<tract-index>"
bash ./dsi.sh show_only_regions "<white-matter-index>&<tumor-core-index>"
bash ./dsi.sh save_rotation_video "<output-path>.avi"
```

Descriptive terms: displaced by lesion/edema; compressed/narrowed in the lesion vicinity; grossly
maintained around lesion; intersecting Tumor Core; intersecting edema only; passing along a lesion margin;
incompletely reconstructed / uncertain.

**Optic radiation** needs more caution: the anterior part, especially Meyer's loop, is hard to
reconstruct and varies between individuals, so the most anterior streamline is not the true boundary.
Positive tumor/edema intersection is meaningful, but no intersection near the anterior temporal lobe
does not exclude Meyer's-loop involvement.

## 7. PPTX report

### 7.1 Report structure

A real **PowerPoint `.pptx`** with a tumor report and a tract–tumor report (a later PDF export is only a
static derivative without interactive 3D). Every 3D visualization is a **native DSI Studio GLB** embedded
as an interactive 3D object: no OBJ/MTL converted outside DSI Studio, no static 3D screenshots (the only
3D raster is each GLB's required poster, §7.6), and no multiple fixed views of a scene (the reader
rotates one model). Keep several 2D slices only when they add information the 3D model lacks.

| Slide | Content | Visuals |
|---|---|---|
| 1 | Summary: location, Tumor Core and edema volumes, main tract relationship, key findings | Contrast-enhanced T1w through the main enhancing tumor; FLAIR through the main edema |
| 2 | Tumor composition and position: compartment table, lesion description, additional foci | Both composition charts (Tumor Core = Necrosis + Enhancing; whole lesion = Necrosis + Enhancing + Edema) and the tumor + `White_Matter` GLB |
| 3 | Tumor–CHA localization: overlap table | CHA overlap chart; tumor + overlapping CHA parcels + `White_Matter` GLB |
| 4 | Tumor–Brodmann localization: overlap table | Brodmann overlap chart; tumor + overlapping Brodmann areas + `White_Matter` GLB |
| 5 | Tract-to-lesion relations: tract table, T2R results, key finding | Tract-to-edema chart; all-eloquent-tracts + tumor + `White_Matter` GLB |
| 6..N | One clinically important tract per slide: measures, interpretation | That tract + tumor + `White_Matter` GLB; 2D slices with tumor outlines and the tract |
| N+1 | Bilateral morphology of CST and optic radiation only (§6): curl, volume, surface area, asymmetry | Bilateral chart; left + right CST / optic radiation + tumor + `White_Matter` GLB (omit the slide when neither was reconstructed) |
| Last | Impression, clinical-correlation points, methods and limitations | Text; optional tract-to-edema chart |

Every listed GLB is required (never dropped for space) and gets at least half the slide width.

- **Composition:** both denominators (whole lesion = Necrosis + Enhancing Tumor + Peritumoral Edema;
  Tumor Core = Necrosis + Enhancing Tumor).
- **Lesion description:** hemisphere, lobe and gyrus, depth (cortical, subcortical, deep), and whether it
  reaches the falx, midline, or corpus callosum; three diameters of the main component only, never of a
  region including separate fragments.
- **Additional foci:** every separate component visible in 3D gets a row (location, volume, label,
  "satellite lesion or false positive: verify on the source images"); leave none unexplained.
- **Atlas:** CHA and Brodmann on separate slides, overlap volume and `% Tumor Core` for every nonzero
  row; the atlas GLB shows exactly the table's parcels, matching by name and color.
- **Tract table:** function to correlate and a geometry tag (`Tumor Core contact`, `Edema contact`,
  `Partial edema contact`, `No contact`; not risk); mark atlas-guided partial tracking and atlas tracts
  as in §4.
- **Tract slides:** for a tract intersecting any compartment, or whose 3D scene shows clinically
  important adjacency, marginal course, compression, displacement, or incomplete reconstruction (every
  analyzed tract when asked). Never substitute the all-tract GLB for a tract-specific one.
- **Methods:** structural and diffusion sequences, b-values and resolution, segmentation model,
  registration check, AutoTrack settings, DSI Studio version, report date, and that 3D-model tracts had
  repeated trajectories removed for export (§7.6). Briefly explain segmentation, atlas overlap,
  AutoTrack, T2R, and curl where first used.
- **Style:** one palette (DSI Studio compartment colors, §7.5) for charts, contour legends, cards, and
  table accents; never recolor the GLB for PowerPoint; keep unconfirmed values marked `[verify]`.

### 7.2 Report inputs

```text
Case          FIB source and reconstruction space, structural slice, segmentation model
Lesion        Enhancing Tumor, Necrosis, Tumor Core, Peritumoral Edema, whole lesion (mL);
              both percentage sets; orthogonal diameters when reliable
Atlas         CHA and Brodmann rows: overlap volume and % Tumor Core
Tracts        AutoTrack identifiers and settings; total streamlines per bundle;
              T2R intersecting streamlines and intersect volume per compartment;
              bilateral curl, volume, surface area for CST and optic radiation only;
              list of tracts that get slides
3D models     GLB file name, poster file name, and exact scene content per 3D slide;
              atlas label indices and template/atlas indices from list_atlas
2D figures    file name, slice plane/level, modality, R_side, plane orientation
Charts        file names of the composition, atlas, tract-to-edema, and morphology charts
```

All figures, GLBs, and numbers come from one accepted analysis state. When reproducing or revising a
case, reuse its recorded tracts and results; never re-select pathways or re-run AutoTrack for the PPTX,
since that changes counts (one sub-003 reproduction gave SLF 587/5271 instead of the accepted 619/5315
and was rejected). Re-track only for missing/corrupt data, a user request, or failed QC, then repeat
dependent T2R and morphology and say the reconstruction changed.

### 7.3 Order of work

`save_3d_model` edits tracts: each checked tract above 3,000 visible streamlines gets
`delete_repeated_tract 1` in place, and export fails if still above 3,000
(`DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`); typical bundles exceed this (sub-003: CST 8595, SLF
5315, AF 7255, FAT 5812). Therefore:

1. Finish all numbers (§1–§6): volumes, atlas overlap, T2R, morphology.
2. With all report tracts checked, `save_all_tracts "<case>_accepted_tracts.tt.gz"` (the restore point).
3. Make the charts (§7.5) and every 2D figure (§7.4) from the full bundles.
4. Export GLBs and posters last (§7.6), atlas scenes after all others (they add and delete Region rows).
5. Assemble the PPTX (§7.11).

To recompute after step 4, `open_tract` the accepted tracts first and repeat steps 3–5; never measure on
export-reduced tracts.

### 7.4 2D figures

Static images (MRI signal and exact slice context) on DSI Studio's black background: contrast-enhanced
T1w for enhancing tumor and core, FLAIR for edema and tract-to-edema relationships. Set the view
explicitly:

```bash
bash ./dsi.sh set_params "roi_draw_edge=1&roi_edge_width=2"     # tumor as outlines, never filled
bash ./dsi.sh set_params "roi_track=1&roi_track_count=500000"   # tracts drawn on the slice
bash ./dsi.sh set_params "roi_fiber=0&roi_position=0&roi_ruler=0&roi_label=0"   # no glyphs, crosshair lines, ruler, "R" mark
```

- Outlines on every 2D figure (summary and tract slices) keep the tumor signal visible. `roi_track`
  draws the tract; `roi_fiber` only controls diffusion glyphs.
- Show only the three tumor compartments (no `White_Matter` or Tumor Core copy), resolved by name from a
  fresh `list_region` (rows shift when `White_Matter` moves last).
- Modality: `set_slice_by_name "<exact displayed name>"`; plane: `set_roi_view` (`0` sagittal,
  `1` coronal, `2` axial).
- Center on the **main lesion** with `move_slice_to_region <row>` (per-axis median voxel, so distant
  fragments don't pull the slice): ceT1w through the main enhancing tumor/core, FLAIR through the main
  edema. Older builds used the midpoint of the first and last voxel (in sub-003, z ≈ 71, below the
  tumor); there, center on a copy reduced to its main component (`copy_region`, then
  `region_action_defragment`) and delete the copy after. A wrong row such as `White_Matter` lands at the
  ventricle level.
- Show only the slide's tract (`show_only_tracts`) in its Assigned color. A slice shows only the points
  inside it (one voxel thick), so a crossing tract is a few dots: use the one or two planes where tract
  and lesion appear together (CST coronal plus axial or sagittal; SLF and AF axial plus sagittal), a
  third only if it adds something.
- Where the relationship changes along the tract, cut 2–3 levels in one plane (e.g. upper, middle, lower
  edema in axial for CST): after `move_slice_to_region`, read each view's position from `preview_screen
  roi` (`slice_info: ... <plane> <position>/<total>`, 1-based, so voxel index = position − 1), then
  `move_slice "x y z"` changing only that plane's coordinate, staying inside the lesion and converting
  mm to voxels with the voxel size.
- Record `R_side` from the same `preview_screen roi` for orientation labels (§7.7).
- **The tract must be visible in every tract-slide image.** Before each `save_roi_screen`, run
  `preview_screen roi`: it prints a `tract` block only when the checked tract has points in this slice.
  Without it, check in order: the tract is checked (`show_only_tracts`, never `check_uncheck_all_tract
  0` alone); `roi_track=1`; the tract finished drawing (one still updating after `color_all_cluster` or a
  reload is skipped, so preview again); the level crosses the tract (move toward it). Save only once the
  block appears.
- Open each saved image: main-lesion outlines and the tract must both be clear in the same slice;
  otherwise re-center or change plane and save again. Replace redone images in the PPTX; never keep stale
  figures.

### 7.5 Charts and palette

One palette (DSI Studio compartment colors) for charts, legends, cards, and table accents; contact bars
use the enhancing color, zero bars grey. PNG at 150 dpi on white, placed as pictures. Replace sub-003's
values (§7.10) with the recorded inputs (§7.2):

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
morph = {"CST":(1.120708,1.253219)}  # left, right curl; CST and optic radiation only (§6)

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

x = np.arange(len(morph))
fig,ax = plt.subplots(figsize=(4.2,3.2))
ax.bar(x-0.19,[v[0] for v in morph.values()],0.38,label="Left",color=GREY)
ax.bar(x+0.19,[v[1] for v in morph.values()],0.38,label="Right",color=NAVY)
ax.set_xticks(x,list(morph))
ax.set_ylabel("Curl (route / distance)")
ax.set_title("Bilateral tract morphology")
ax.set_ylim(0,max(max(v) for v in morph.values())*1.25)
ax.legend(frameon=False)
save(fig,"bilateral_tract_morphology.png")
```

The edema chart's y-axis is a reconstructed-streamline fraction (§7.8), not an axon or infiltration
fraction.

### 7.6 Native GLB 3D scenes

`save_3d_model <file>.glb` for every 3D scene, after the 2D figures (§7.3). GLB and OBJ share geometry
and materials: x, z, −y in mm, centered on the scene's bounds, each object's RGB and alpha (region alpha
byte × `region_alpha`, default 0.8; `tract_alpha` for tracts); tracts are one-color tubes of
`tube_diameter` voxels. Record `tube_diameter`, `region_alpha`, and `tract_alpha`. The brain envelope is
the `White_Matter` region from `human_tumor`; add no separate isosurface when it exists.

Prepare once:

1. Resolve rows from fresh `list_tract`/`list_region`.
2. `region_action_defragment` `White_Matter` and verify one coherent envelope (don't defragment tumor
   compartments unless asked).
3. Change only each region's alpha byte with `set_region_color <row> <unsigned #AARRGGBB>`, keeping the
   case's own RGB (never copied from another subject): Necrosis 200, Peritumoral Edema 80, Enhancing
   Tumor 100, White_Matter 64. GLB opacity = alpha / 255 × `region_alpha`, so White_Matter is about 0.2.
   PowerPoint draws one translucent layer, unlike DSI Studio's stacking: alpha 10 (opacity 0.03) looks
   fine on screen but leaves the envelope invisible in PowerPoint, so keep 64 even if the screen and
   poster look denser.
4. Move `White_Matter` to the last row with repeated `move_down_region`, re-resolving as rows move.
5. Check only the three tumor compartments and `White_Matter` (no Tumor Core copy).
6. Region rendering on; isosurface and slice planes off:

```bash
bash ./dsi.sh set_param show_region 1
bash ./dsi.sh set_param show_surface 0
bash ./dsi.sh set_param show_slice 0
bash ./dsi.sh set_param tube_diameter 0.5   # any value, but the same for every scene and for postoperative exports
bash ./dsi.sh set_param bkg_color -1        # white poster background; set again after any tract-style change
```

7. Assigned tract colors (never directional) once the final set is loaded, repeated after any tract is
   added or reloaded:

```bash
bash ./dsi.sh set_param tract_color_style 1
bash ./dsi.sh color_all_cluster
```

Per scene:

1. Check exactly its regions (`show_only_regions`) and tracts (`show_only_tracts`, or
   `check_uncheck_all_tract 0` for none): `save_3d_model` exports checked items; `show_tract` does not
   filter it.
2. `preview_screen 3d` until the region block shows every compartment and the envelope and the tract
   block the scene's tracts: meshes are built only while the 3D view draws, and an unbuilt region is
   silently skipped.
3. `save_3d_model "<scene>.glb"`. On "Too many tracts even after deleting repeated tracks", run
   `delete_repeated_tract 2` (then `3`) with only that scene's tracts checked, export again, and state
   the distance in the methods.
4. Poster from the same scene: `save_screen "<scene>_poster.jpg" "1600 1200"` (any view; shown only until
   PowerPoint renders). The background must be white as saved, else `bkg_color -1` and save again.

Atlas scenes (slides 3 and 4), after every other GLB:

1. `list_atlas` gives atlas indices; `list_atlas CHA` (or `Brodmann`) label indices and names. Take the
   labels matching the nonzero `show_region_overlap_statistics` rows (§2); never guess indices.
2. `add_region_from_atlas "<template> <atlas> <label1>&<label2>&..."` adds them with atlas names.
   `list_region`, move `White_Matter` last again, and set each parcel's alpha to about 120 with
   `set_region_color`, keeping its RGB (read with `save_region_color`).
3. Check the tumor compartments, parcels, and `White_Matter`; uncheck all tracts; `preview_screen 3d`,
   `save_3d_model`, poster.
4. `delete_region "<rows>"` the parcels before the next atlas; re-run `list_region`.

Bilateral scene (morphology slide): left and right CST and optic radiation (those reconstructed), tumor
compartments, `White_Matter`.

The GLB is view-independent: no axial/coronal/sagittal copies, no `set_view` for extra report views. Each
GLB is centered on its own scene, so scenes share no coordinate frame. In Web sessions upload each GLB and
poster with `web_upload` and use the returned attachment; never ask the user to download and re-upload.

### 7.7 Orientation labels and 3D captions

Every 2D image gets bold orientation labels in a margin outside the anatomy, about 1/16 of the displayed
image width (at least 12 pt). Left/right comes from that image's `R_side` (radiological convention:
image left is patient right; the slide says so):

```text
axial      left/right R|L from R_side   top A   bottom P
coronal    left/right R|L from R_side   top S   bottom I
sagittal   left/right A|P as the saved image shows the face   top S   bottom I
```

A tract's side is not the viewing side ("Right CST" is not a "right sagittal view"); never use voxel
coordinates as clinical localization. Put the contour legend (Necrosis, Enhancing Tumor, Peritumoral
Edema in region colors) under every slice; text over a slice is white and bold. No cardinal labels
around a GLB; caption it:

```text
Interactive 3D — drag to rotate
Right CST + tumor compartments + White_Matter envelope
```

### 7.8 Wording

```text
intersection volume               = T2R intersect volume(mm^3)
reconstructed-streamline fraction = T2R number of tracts / total bundle streamlines
```

Never use `intersect ratio` as the streamline fraction; streamline counts are not axon counts. Preferred:

```text
No reconstructed [tract] streamlines entered the Tumor Core.
[X]% of reconstructed [tract] streamlines intersect the segmented edema field.
```

- Never call a tract `safe`, `intact`, `destroyed`, or `resectable`, or a route safe or unsafe, from
  tractography alone.
- Edema intersection is geometry, not histologic invasion; zero Tumor-Core intersection does not prove a
  safe surgical plane.
- Left/right morphology only for CST and optic radiation (never AF, SLF, or other association
  asymmetry); CST/optic-radiation curl asymmetry without lesion contact is descriptive.
- No universal percentage thresholds for risk or displacement.
- Counts come from the accepted analysis, never export-reduced tracts.

### 7.9 Annotation and post-processing

Allowed on static content: orientation labels, tract name and caption, contour legends, borders, trimming
empty margin. Not allowed: recoloring or reshaping an exported GLB, inverting or replacing a background,
masking an all-tract export into one tract, removing structures, synthesizing anatomy, or mirroring
without relabeling. Fix a wrong scene or slice in DSI Studio and save again.

### 7.10 Worked example: UPenn-GBM sub-003

Accepted set for a right-hemisphere case with CST and SLF tract slides; replace row indices with what
`list_region`/`list_tract` report and numbers with the case inputs (§7.2).

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
dsi set_region_color 0 1088940014   # 0x40E7E7EE White_Matter      alpha 64
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
scene sub003_CST_bilateral_tumor_WM "0&1"   # morphology slide: CST only (no optic radiation analyzed)

# atlas scenes last; label and atlas indices come from list_atlas, never from this example
dsi list_atlas
dsi list_atlas CHA                      # match names to the nonzero CHA overlap rows
dsi add_region_from_atlas "<template> <CHA-atlas> <posterior-cingulate>&<precentral>&<postcentral>&<premotor>&<precuneus>"
dsi list_region                         # parcels added after White_Matter (rows 8..12)
for row in 7 8 9 10 11; do dsi move_down_region $row; done   # White_Matter back to the last row
dsi list_region
dsi save_region_color sub003_region_colors.txt                # RGB of each parcel for the alpha change
dsi set_region_color <parcel-row> <0x78RRGGBB as unsigned>     # alpha 120, one call per parcel
dsi show_only_regions "4&5&6&7&8&9&10&11&12"
scene sub003_tumor_CHA_WM ""
dsi delete_region "7&8&9&10&11"         # the parcel rows from list_region
dsi list_region
# repeat with Brodmann for sub003_tumor_Brodmann_WM
```

### 7.11 Assemble the PPTX

- **Local agents** (Codex, Claude, Muse, Antigravity, Grok) write and run the Python script with their own
  tools on the user's computer. Without file tools: `bash ./dsi.sh write_text_file make_report.py --stdin
  <<'PY'` ... `PY`, then `bash ./dsi.sh run_shell "python make_report.py"`.
- **Web agents** (no local files or Python): send the script with `write_text_file`, run it with
  `run_shell "python make_report.py"` (Windows fallback `py make_report.py`), fetch the PPTX and charts
  with `web_upload`, and install missing packages with
  `run_shell "python -m pip install --user python-pptx matplotlib pillow"`. Each `write_text_file` asks
  the user to confirm, so combine the chart code (§7.5) and this script in one file where practical
  (`DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md`).

Build a 16:9 python-pptx deck: title bar, tables, charts, and labeled 2D slices as ordinary content, each
GLB as a PowerPoint 3D model. python-pptx has no 3D API, so `add_glb()` adds the GLB part and the Office
`am3d:model3d` XML with its poster:

- GLB materials stay **unchanged**; the poster is the required raster fallback.
- Lighting is **per model** (no deck-wide setting): **white ambient only, 10% illuminance**
  (`illuminance n="100000" d="1000000"`), with PowerPoint's three point lights written as
  `enabled="false"` so no default lighting is added. Stronger Office lighting washed out DSI Studio's
  colors in the PowerPoint comparison (To-Do #27); never darken GLB materials instead.
- Geometry (verified in PowerPoint on sub-003): `meterPerModelUnit` = 1 / largest scene extent (largest
  extent scales to 1 m); `preTrans` zero (already centered); inner `am3d:spPr` offset 0,0 (relative to
  the frame; repeating the slide position shifts the poster down-right). `viewportSz` is the camera's
  square output on the slide, set larger than the frame until the front-view extent fills it (equal to
  the frame leaves the model small; moving the camera closer doesn't help).
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
LIGHTS_OFF = "".join(  # PowerPoint's three point lights, disabled so only the 10% ambient light remains
    f'<am3d:ptLight rad="0" enabled="false"><am3d:clr><a:scrgbClr r="100000" g="100000" b="100000"/></am3d:clr>'
    f'<am3d:intensity n="0" d="1000000"/><am3d:pos x="{x}" y="{y}" z="{z}"/></am3d:ptLight>'
    for x,y,z in ((21959998,70920001,16344003),(-37964106,51130435,57631972),(-37739122,58056624,-34769649)))

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

def glb_extents(file):  # x, y, z scene extents in model units (mm) from the POSITION accessors
    with open(file,"rb") as f:
        f.seek(12)
        length,_ = struct.unpack("<II",f.read(8))
        gltf = json.loads(f.read(length))
    bounds = [a for a in gltf["accessors"] if "min" in a]
    return [max(a["max"][i] for a in bounds)-min(a["min"][i] for a in bounds) for i in range(3)]

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
    extents = glb_extents(glb)
    mpu = max(1,round(1e6/max(extents)))
    # camera output square at the model: 2 * 66000000 EMU * tan(22.5 deg); front-view extent in EMU (1 m = 36000000)
    viewport = round(min(w,h)*2*66000000*0.41421356/(36000000*max(extents[:2])/max(extents)))
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
     <am3d:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{w}" cy="{h}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></am3d:spPr>
     <am3d:camera><am3d:pos x="0" y="0" z="66000000"/><am3d:up dx="0" dy="36000000" dz="0"/>
      <am3d:lookAt x="0" y="0" z="0"/><am3d:perspective fov="2700000"/></am3d:camera>
     <am3d:trans><am3d:meterPerModelUnit n="{mpu}" d="1000000"/><am3d:preTrans dx="0" dy="0" dz="0"/>
      <am3d:scale><am3d:sx n="1000000" d="1000000"/><am3d:sy n="1000000" d="1000000"/><am3d:sz n="1000000" d="1000000"/></am3d:scale>
      <am3d:rot/><am3d:postTrans dx="0" dy="0" dz="0"/></am3d:trans>
     <am3d:raster rName="Office3DRenderer" rVer="16.0.8326"><am3d:blip r:embed="{rid_poster}"/></am3d:raster>
     <am3d:objViewport viewportSz="{viewport}"/>
     <am3d:ambientLight><am3d:clr><a:scrgbClr r="100000" g="100000" b="100000"/></am3d:clr>
      <am3d:illuminance n="100000" d="1000000"/></am3d:ambientLight>
     {LIGHTS_OFF}
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

The `am3d` block follows what PowerPoint writes for an inserted model. On a repair prompt or missing
model, insert any GLB in desktop PowerPoint (Insert > 3D Models > This Device), save, unzip, and compare
`ppt/slides/slideN.xml` and its `.rels` with this block; fix the template from that file rather than
switching to static images.

### 7.12 Before delivery

1. Opens in desktop PowerPoint without repair; every slide XML with a model has ambient illuminance
   `n="100000"` and only `enabled="false"` point lights (`unzip -p report.pptx "ppt/slides/slide*.xml" |
   grep -o "<am3d:illuminance[^>]*>\|<am3d:ptLight[^>]*>"`).
2. Rotate every GLB: tumor compartments, the requested tract(s) or parcels, and the `White_Matter`
   envelope present with plausible colors and transparency; every §7.1 GLB slide has one.
3. Every tract-slide 2D image shows the tract, not just outlines.
4. No clipping, stale values, or orientation errors in images and charts; every slice has orientation
   labels and a contour legend.
5. Every number matches the accepted analysis (§7.2), not export-reduced tracts.
6. `[verify]` marks stay visible on anything unconfirmed.

# POSTSURGICAL EVALUATION

## 8. Primary goal: preservation of eloquent pathways

> **Are the eloquent pathways relevant preoperatively still reconstructable in their expected
> anatomical course after surgery/treatment, and how do they relate to the cavity, residual
> abnormality, and postoperative edema?**

Lesion-volume change is secondary to this when the question is postoperative functional anatomy.

### 8.1 Verify postoperative anatomy

Define abnormalities conservatively: residual enhancing lesion, verified resection cavity,
postoperative edema, hemorrhage/treatment-related change, or another verified abnormality. Don't build a
presurgical Tumor Core automatically: analyze `Enhancing Tumor`, `Necrosis`, and `Peritumoral Edema`
separately, composing them only when verified anatomy gives a clear meaning, and never read the model's
`Necrosis` as a cavity unless independently established. A verified/user-supplied cavity mask is a
separate region. Same three-plane QC, centered on (in order of availability) the verified cavity or
user-supplied target, the verified residual enhancing lesion, or the dominant plausible abnormality.

### 8.2 Reconstruct the same pathways

Same bilateral pathways and comparable reconstruction/AutoTrack settings; launch all `run_auto_track`
calls back-to-back and poll `list_tract` about every 10 s until `done`. A pathway newly relevant after
surgery may be added but is marked **postoperative-only**, without a pretended baseline.

### 8.3 Compare pre/post preservation

Per pathway (same side and name): reconstructability in the expected course; trajectory continuity
around the operative site; total streamline count; tract volume; surface area; relationship to verified
cavity/residual lesion/edema; T2R intersecting count/fraction for postoperative regions when useful.
For 3D, export matched GLB scenes with the same tracts, region content, coloring, transparency, and
`tube_diameter` as the preoperative export (§7.6), on matched consecutive slides (no fixed `set_view` or
multiple camera views; each GLB is centered on its own scene, so compare by rotating, not overlaying).
Changes are descriptive: acquisition, reconstruction, registration, brain shift, diffusion signal, edema,
susceptibility, tolerance, TIP, or tractability can cause them. A newly visible tract may reflect better
tractability; an absent one may be tractography failure rather than loss.

### 8.4 Preservation categories (reconstruction-based, not functional diagnoses)

- **Reconstruction preserved:** reconstructable in the expected gross course, followable around/adjacent
  to the operative site, no major new discontinuity.
- **Reconstruction partially preserved / altered:** recognizable but substantially reduced, displaced,
  fragmented, narrowed, or altered near the site; state acquisition/tracking uncertainty.
- **Preservation uncertain:** sparse, anatomically ambiguous, heavily affected by postoperative
  distortion/artifact, or not comparable with preoperative data.
- **Not reconstructable postoperatively:** fails despite the bounded retry procedure. Never translate to
  `transected` or `destroyed`: tractography alone cannot distinguish disruption from failure. Show the
  likely location with the atlas version (§4), labeled atlas-based (usual course, not preservation).

### 8.5 Postoperative lesion volumes

When labels are comparable across sessions report label, preoperative volume (mm^3), postoperative volume
(mm^3), and absolute change (mm^3), as descriptive segmentation findings: never infer progression,
residual tumor, cavity size, treatment effect, or response from volume alone. Repeat CHA/Brodmann
localization only when it answers a postoperative question.

## 9. Postoperative PPTX report

Use the §7 framework, leading with tract preservation rather than lesion statistics, with the same rules:
order of work (§7.3), 2D figures and labels (§7.4, §7.7), charts and palette (§7.5), GLB scenes and
posters (§7.6), and `add_glb()` with white ambient-only 10% lighting and unchanged materials (§7.11). One
interactive model per slide; pre/post 3D on matched consecutive slides with comparable content.

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

Never make it primarily a tumor-volume report when the question is tract preservation.

### Optional: DICOM series with tract/lesion markings

For a navigation-ready DICOM series with the evaluated pathways (and optionally a tumor region) burned
into the pixels. **Requires the original DICOM series as the slice source**: `save_slices_to_dicom`
rejects slices not loaded from original DICOM files, so NIfTI alone is insufficient (details in
`DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`).

```bash
bash ./dsi.sh add_slice "<dicom1>,<dicom2>,..."   # original DICOM series
bash ./dsi.sh set_slice <dicom-slice-index>       # poll list_slice until ready
bash ./dsi.sh show_only_tracts "<relevant-left-tract>&<relevant-right-tract>"
bash ./dsi.sh mark_tracts_on_slices 1.0
bash ./dsi.sh mark_region_on_slices <tumor-core-index> 1.2   # optional
bash ./dsi.sh save_slices_to_dicom "<output-directory>"
```

`mark_tracts_on_slices` burns only **checked** tracts (fails if none): confirm the selection matches
Step 3. Marking is cumulative in memory (reload the slice to redo). Reopen the `mod_*.dcm` series and
verify orientation, intensity, and that markings land in the expected anatomy.

## Interpretation references

- Yeh FC, Irimia A, Bastos DCA, Golby AJ. Tractography methods and findings in brain
  tumors and traumatic brain injury. NeuroImage. 2021;245:118651.
- Yeh FC. Shape analysis of the human association pathways. NeuroImage.
  2020;223:117329.
- Essayed WI, Zhang F, Unadkat P, et al. White matter tractography for neurosurgical
  planning: a topography-based review of the current state of the art. NeuroImage:
  Clinical. 2017;15:659-672.

Current DSI Studio AI documentation and live command output are the authority for software behavior.
