# DSI Studio AI Brain Tumor Neurosurgical Evaluation

Use this skill for presurgical or postsurgical brain-tumor evaluation intended to support a neurosurgeon. The goal is to turn DSI Studio measurements into a concise, anatomically grounded assessment of the lesion and the eloquent pathways that may affect intervention.

This workflow provides imaging and tractography decision support. Tractography does not by itself establish function, tissue viability, safe resection margins, or whether a pathway can be sacrificed. Interpret findings together with the neurological examination, functional imaging when available, cortical/subcortical mapping, operative anatomy, and other clinical information.

## Mandatory reporting behavior

Do not wait until the end to report everything. **After each major step is completed, provide a short checkpoint summary before continuing.** Each checkpoint should contain:

1. **Findings** — the few quantitative/anatomical results that matter most.
2. **Potential neurosurgical relevance** — which finding may affect surgical corridor, resection margin, eloquent-risk discussion, need for closer functional correlation, or postoperative interpretation.

Keep each checkpoint brief, typically 2–6 bullets or a short paragraph. Do not repeat all raw tables. Do not declare a tract `safe`, `intact`, `destroyed`, or `resectable` from tractography alone.

When presenting the case to a neurosurgeon, assume the listener may **not** know the analysis method. For every analysis that materially contributes to the interpretation, explain in plain clinical language:

1. **Purpose** — why this analysis is useful for this case.
2. **Method** — what DSI Studio is measuring, in one or two sentences without unnecessary implementation detail.
3. **Result** — the important case-specific quantitative or spatial finding.
4. **Interpretation** — what the finding may mean for intervention or postoperative assessment, including limitations.

For example, do not merely report a T2R fraction. Explain that T2R asks what fraction of the reconstructed streamlines in a named pathway passes through a segmented lesion region, then state why that relationship matters in this case.

For presurgical work, prioritize the relationship of tumor/core/edema to eloquent anatomy. For postsurgical work, the **primary question is whether the previously relevant eloquent tracts remain reconstructable and anatomically preserved around the resection/treatment site**.

## Optional voice-demo mode

When the user asks for a **voice demo**, first complete the quantitative/anatomical evaluation and verify the important findings. Then present the case as an interactive neurosurgical walkthrough rather than reading command output aloud.

Use short spoken segments with the DSI Studio `voice` command when available. Each segment should explain:

```text
what is currently being shown
why this analysis/view is useful
what method produced the finding
what the case-specific result is
why it may matter clinically
```

Keep each spoken segment focused. Do not narrate every command, table row, seed count, or implementation detail.

### Voice demo should use the live 3D window

Use the 3D view actively when explaining the relationship between tumor and eloquent tracts. Show the relevant lesion regions and only the tract bundles needed for the point being discussed, then change viewpoint deliberately to reveal whether the pathway runs through, along, anterior/posterior to, superior/inferior to, or around the lesion.

A typical pattern is:

```bash
bash ./dsi.sh show_only_regions "<relevant-lesion-indices>"
bash ./dsi.sh show_only_tracts "<relevant-tract-indices>"
bash ./dsi.sh set_view 0 0
bash ./dsi.sh preview_screen 3d
bash ./dsi.sh voice "<short explanation of what is shown and why it matters>"

bash ./dsi.sh rotate_view left 20
bash ./dsi.sh preview_screen 3d
bash ./dsi.sh voice "<explain the relationship revealed by this second angle>"

bash ./dsi.sh rotate_view up 15
bash ./dsi.sh preview_screen 3d
bash ./dsi.sh voice "<explain the final spatial relationship or uncertainty>"
```

`rotate` may also be used with an explicit axis, for example:

```bash
bash ./dsi.sh rotate "20 0 1 0"
```

Use only a few purposeful viewpoints. Reset with `set_view 0 0` before starting a comparable pre/post demonstration. For longitudinal presentation, use the same view reset and the same rotation sequence for both sessions whenever possible.

For a presurgical voice demo, emphasize the spatial relationship between Tumor Core/edema and the relevant motor, language, or visual pathways. For a postoperative voice demo, emphasize whether the same eloquent pathways remain reconstructable around the operative site and how their course relates to cavity/residual abnormality/edema.

The narration should teach the analysis as it demonstrates the case. Briefly explain concepts such as:

- **tumor segmentation** — separates enhancing tumor, necrosis, and peritumoral edema so each component can be quantified and related to anatomy;
- **CHA/Brodmann overlap** — localizes which atlas-defined anatomical regions are intersected by the lesion; this is anatomical context, not proof of function;
- **AutoTrack** — reconstructs a named white-matter pathway using standardized tract recognition so bilateral pathways can be compared;
- **T2R** — counts reconstructed streamlines from a tract bundle that pass through each lesion region and allows calculation of a bundle involvement fraction;
- **tract morphology** — compares reconstructed bundle size/shape and gross trajectory, which may show displacement or attenuation but does not directly measure neurological function;
- **postoperative preservation** — asks whether the same pathway remains reconstructable in its expected course after treatment, while acknowledging that failure to reconstruct does not prove transection.

Do not use voice narration to overstate certainty. State important limitations aloud when they materially affect the case.

### Companion-manual routing

| Tumor workflow section | Companion manual |
|---|---|
| segmentation, slice readiness, model availability, three-plane QC | `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| atlas localization | `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| pathway selection and AutoTrack | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md` |
| tract-to-lesion connectivity | `DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| tract morphology, laterality, 3D demonstration | `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`, `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md` |
| postoperative tract preservation | Slice, Rendering, Region, Tract, T2R, and Fiber-Tracking manuals above |

# PRESURGICAL EVALUATION

## 1. Verify imaging, segment, and characterize the lesion

### 1.1 Input and registration preflight

Select the structural image intended for segmentation:

```bash
bash ./dsi.sh list_slice
bash ./dsi.sh set_slice <slice-index>
bash ./dsi.sh list_slice
```

When a FIB already exposes its structural MRI in `list_slice` with status `available`, select that existing slice with `set_slice`; do not add the same image again. Poll `list_slice` until the selected row reports `ready`.

`ready` means loading/registration has finished; it does not prove anatomical alignment. Inspect structural-to-diffusion alignment before quantitative interpretation. Record the FIB reconstruction space, structural-image source/slice, and segmentation model ID.

### 1.2 Tumor segmentation

Use `human_tumor` (**U-Net Studio Human Tumor Lesion V2**) by default. Confirm availability with `list_unet`; use the exact model ID only when `available` is true.

```bash
bash ./dsi.sh list_unet
bash ./dsi.sh segment_brain "human_tumor" "<slice-name-or-index>"
bash ./dsi.sh list_region
```

Expected lesion labels:

```text
Enhancing Tumor
Necrosis
Peritumoral Edema
```

`human_tumor` also emits five tissue labels. They are not lesion compartments and can shift Region-table indices. Resolve lesion rows by exact name from a fresh `list_region`; never infer indices from creation order.

For presurgical work define:

```text
Tumor Core = Enhancing Tumor ∪ Necrosis
```

Keep `Peritumoral Edema` separate. Preserve the original labels. If either Enhancing Tumor or Necrosis is unavailable, report that and do not construct Tumor Core.

Create Tumor Core from copies so original segmentation remains untouched:

```bash
bash ./dsi.sh copy_region <current-enhancing-index>
bash ./dsi.sh list_region
bash ./dsi.sh set_region_name <enhancing-copy-index> "Tumor Core"
bash ./dsi.sh copy_region <current-necrosis-index>
bash ./dsi.sh list_region
bash ./dsi.sh merge_regions "<current-Tumor-Core-index>&<necrosis-copy-index>"
bash ./dsi.sh list_region
```

`copy_region` inserts the copy immediately after the source and shifts later indices. `merge_regions` keeps the first supplied region and removes later merged rows. Re-resolve indices after every mutation.

### 1.3 Three-plane QC and lesion measurements

Isolate the lesion rows and inspect sagittal, coronal, and axial views:

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

`preview_screen roi` is coarse text-based QC. Use it for gross location/alignment checks, not subtle boundary validation. If a clinically important boundary or laterality decision cannot be resolved, state the limitation and use `save_roi_screen` for human review when the user provided or requested an output destination.

Immediately before statistics, isolate only the lesion regions because `show_region_statistics` reports currently checked/shown regions:

```bash
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<Tumor-Core-index>&<edema-index>"
bash ./dsi.sh show_region_statistics
```

Record when available:

```text
Enhancing Tumor volume (mm^3)
Necrosis volume (mm^3)
Tumor Core volume (mm^3)
Peritumoral Edema volume (mm^3)
lesion laterality
gross lobe/location and important adjacent anatomy
```

### Required checkpoint after Step 1

Explain briefly:

```text
Purpose/method
- segmentation separates the major lesion compartments so their burden and anatomical extent can be measured independently

Findings
- lesion side and location
- lesion-compartment volumes
- whether segmentation/alignment QC is acceptable or limited

Potential neurosurgical relevance
- whether Tumor Core or edema approaches motor, language, visual, deep, or midline structures
- uncertainty that could affect subsequent planning measurements
```

## 2. Localize Tumor Core anatomically

### 2.1 CHA

```bash
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> CHA
```

This maps atlas regions into the source region space and reports statistics only for nonempty intersections without adding atlas rows to the Region table.

For each important CHA region report:

```text
intersection volume (mm^3)
fraction of Tumor Core = intersection volume / total Tumor Core volume
```

### 2.2 Brodmann

```bash
bash ./dsi.sh show_region_overlap_statistics <current-Tumor-Core-index> Brodmann
```

Report only clinically meaningful nonempty areas. Brodmann/CHA overlap provides anatomical localization; it does not prove functional impairment or eloquence. Gray-matter atlas intersections need not sum to total Tumor Core volume, especially for white-matter-centered lesions.

### Required checkpoint after Step 2

Explain:

```text
Purpose/method
- atlas overlap identifies which standardized anatomical parcels physically intersect the segmented Tumor Core

Findings
- dominant CHA regions
- relevant Brodmann areas
- cortical versus subcortical/white-matter predominance

Potential neurosurgical relevance
- which functional systems warrant tract reconstruction or closer functional correlation
- atlas/registration limitations caused by mass effect or distortion
```

## 3. Select relevant bilateral eloquent pathways

Use verified AutoTrack identifiers:

| Function | Pathway | Left | Right |
|---|---|---|---|
| Motor | Corticospinal tract | `ProjectionBrainstem_CorticospinalTractL` | `ProjectionBrainstem_CorticospinalTractR` |
| Language | Arcuate fasciculus | `Association_ArcuateFasciculusL` | `Association_ArcuateFasciculusR` |
| Language | Superior longitudinal fasciculus | `Association_SuperiorLongitudinalFasciculusL` | `Association_SuperiorLongitudinalFasciculusR` |
| Language | Frontal aslant tract | `Association_FrontalAslantTractL` | `Association_FrontalAslantTractR` |
| Temporal/semantic | Inferior longitudinal fasciculus | `Association_InferiorLongitudinalFasciculusL` | `Association_InferiorLongitudinalFasciculusR` |
| Vision | Optic radiation | `ProjectionBasalGanglia_OpticRadiationL` | `ProjectionBasalGanglia_OpticRadiationR` |

Practical selection:

- perirolandic/motor lesion → CST;
- frontal language lesion → AF, SLF, FAT;
- parietal language lesion → AF, SLF;
- temporal language lesion → AF, ILF;
- posterior temporal/parietal/occipital lesion → optic radiation when visual-pathway risk is relevant.

For temporal lesions, add optic radiation when lesion or edema extends into posterior temporal or temporo-occipital white matter. If agent-side anatomy/QC is too coarse to confidently exclude such extension, map optic radiation rather than omit it. Do not use edema volume alone as the trigger.

Optional pathways when clinically relevant include IFOF and uncinate fasciculus. Use `list_auto_tract` to discover other exact identifiers.

### Required checkpoint after Step 3

State which pathways are selected, why each is relevant to the lesion location, which functional systems are being evaluated, and any clinically important pathway that cannot be assessed.

## 4. Reconstruct selected pathways

Map bilateral homologs with comparable settings. `run_auto_track` is asynchronous. Launch all independent bundles back-to-back first:

```bash
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractL"
bash ./dsi.sh run_auto_track "ProjectionBrainstem_CorticospinalTractR"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusR"
```

After all desired calls are launched, poll the entire tract table about every 10 seconds:

```bash
bash ./dsi.sh list_tract
```

Continue until every requested bundle reports `done`. Do not serially wait for each bundle before launching the next. Only after all required bundles are complete should the agent perform dependent statistics, T2R, editing, saving, or visualization.

Follow the bounded tolerance-retry procedure in the Fiber Tracking skill. A zero-yield tract is `unmappable` after the bounded retry procedure; it is not proof of anatomical absence.

### Required checkpoint after Step 4

Explain that AutoTrack reconstructs standardized named pathways so the lesion-side tract can be assessed against its contralateral homologue. Report successful/sparse/unmappable pathways, total streamline counts, retries, and which missing reconstruction limits the evaluation.

## 5. Quantify tract-to-lesion involvement with T2R

Use **tract-to-region connectivity (T2R)** rather than converting every tract into a binary voxel region.

```bash
bash ./dsi.sh list_tract
bash ./dsi.sh list_region
bash ./dsi.sh show_only_tracts "<relevant-tract-indices>"
bash ./dsi.sh show_only_regions "<enhancing-index>&<necrosis-index>&<edema-index>&<Tumor-Core-index>"
bash ./dsi.sh show_t2r
```

`show_t2r` analyzes all checked tract bundles against all checked lesion regions. For a tract/region pair, the T2R `number of tracts` value is the number of streamlines from that bundle that pass through the region.

Calculate:

```text
lesion involvement fraction =
    T2R intersecting streamline count /
    total streamline count of that same completed bundle
```

Do not call this an overlap volume. Do not use T2R's generic `intersect ratio` as the bundle streamline fraction. A streamline can intersect several lesion compartments, so fractions do not need to sum to 100%.

### Required checkpoint after Step 5

For each important pathway explain:

```text
Purpose/method
- T2R quantifies how much of the reconstructed pathway actually passes through each segmented lesion compartment

Findings
- total bundle streamlines
- Tumor Core / enhancing / necrosis / edema intersecting counts and fractions

Potential neurosurgical relevance
- Tumor Core intersection indicates a closer pathway-lesion conflict than edema-only intersection, without proving infiltration
- edema-only intersection may reflect pathway passage through tissue affected by edema/mass effect
- zero reconstructed intersection does not guarantee true anatomical separation
```

Do not create universal percentage thresholds for surgical risk.

## 6. Evaluate tract morphology and 3D spatial relationship

Obtain bilateral tract statistics:

```bash
bash ./dsi.sh show_only_tracts "<left-tract>&<right-tract>"
bash ./dsi.sh show_tract_statistics
```

Record total tracts, volume, and surface area. Verify lesion laterality from structural anatomy and segmentation before labeling a tract ipsilesional/contralateral. Normal bilateral asymmetry can be substantial, especially for association tracts.

Show the lesion and relevant tract together:

```bash
bash ./dsi.sh show_only_tracts "<relevant-tracts>"
bash ./dsi.sh show_only_regions "<relevant-lesion-regions>"
bash ./dsi.sh set_view 0 0
bash ./dsi.sh preview_screen 3d
```

Describe geometry using clinically useful terms:

```text
displaced by lesion/edema
compressed or narrowed near lesion
grossly maintained around lesion
intersecting Tumor Core
intersecting edema only
passing along a lesion margin
incompletely reconstructed / uncertain
```

For a voice demo, this is the main 3D teaching stage. Rotate through a small number of meaningful perspectives and narrate the relative location of the tract and lesion at each view. Explain what spatial relationship becomes easier to see from that angle.

### Optic-radiation caution

Interpret optic radiation conservatively. Meyer's loop is difficult to reconstruct reliably and varies between individuals. Positive tumor/edema intersection is meaningful structural evidence; absence of reconstructed intersection near the anterior temporal lobe does not reliably exclude involvement.

### Required checkpoint after Step 6

For each key pathway report whether it is grossly reconstructed in the expected course; whether it intersects, borders, or appears spatially separated from Tumor Core/edema; whether it appears displaced/compressed/attenuated; and which functional system may be exposed during intervention. State where mapping or tractography uncertainty is important.

## 7. Integrated presurgical neurosurgical summary

Answer:

1. Where is the lesion and how large are the major compartments?
2. Which anatomical parcels are substantially involved?
3. Which eloquent pathways are relevant?
4. Which reconstructed pathways intersect Tumor Core, enhancing tumor, necrosis, or edema?
5. Are key pathways displaced, compressed, marginal, or incompletely reconstructed?
6. Which findings may affect approach, margin, or functional-risk discussion?
7. What cannot be concluded reliably from these data?

Recommended structure:

```text
Presurgical neurosurgical summary

Lesion
- location/laterality
- Enhancing Tumor, Necrosis, Tumor Core, edema volumes
- major QC limitations

Anatomical localization
- dominant CHA regions
- relevant Brodmann areas

Eloquent pathways
- pathway / side / total streamlines
- Tumor Core and edema T2R counts/fractions
- spatial relationship

Key intervention-relevant points
- 3–6 prioritized findings
- unmappable/sparse important pathway
- major segmentation/registration/tractography limitation
```

# POSTSURGICAL EVALUATION

## 8. Primary goal: preservation of eloquent pathways

The central postoperative question is:

> **Are the eloquent pathways that were relevant preoperatively still reconstructable in their expected anatomical course after surgery/treatment, and how do they relate to the cavity, residual abnormality, and postoperative edema?**

Lesion-volume change is secondary when the primary clinical question is functional-anatomical preservation.

### 8.1 Verify postoperative anatomy

Identify residual enhancing lesion, verified cavity, postoperative edema, hemorrhage/treatment change, or other verified abnormalities conservatively. Do not assume the model's `Necrosis` label is a resection cavity. If a verified/user-supplied cavity mask exists, analyze it separately.

Use the same three-plane QC pattern. Center on, in order of preference:

1. verified cavity/user-supplied postoperative target;
2. verified residual enhancing lesion;
3. dominant anatomically plausible postoperative abnormality.

### Postoperative checkpoint A

Explain what postoperative anatomy can be identified reliably, which abnormalities are most relevant to nearby tracts, and whether distortion/artifact/registration limits the comparison.

### 8.2 Reconstruct the same pathways

Use the same clinically relevant bilateral pathways and comparable settings whenever possible. Launch all independent AutoTrack calls back-to-back, then poll `list_tract` about every 10 seconds until all requested bundles are complete.

A postoperative-only pathway may be added when clinically necessary but should be labeled as such because it has no preoperative baseline.

### Postoperative checkpoint B

For each pathway report:

```text
preoperative reconstruction available: yes/no
postoperative reconstruction: successful / sparse / unmappable
postoperative streamline count
expected gross trajectory visible: yes/no/uncertain
```

Do not equate absent reconstruction with surgical transection.

### 8.3 Compare preservation

For each matched pathway compare:

```text
reconstructability in expected course
gross trajectory around operative site
streamline count
tract volume
tract surface area
relationship to cavity/residual lesion/edema
T2R count/fraction for postoperative regions when useful
```

For comparable 3D views, use the same camera recipe in both sessions:

```bash
bash ./dsi.sh set_view 0 0
bash ./dsi.sh rotate_view left 20
bash ./dsi.sh rotate_view up 15
```

Use the same sequence pre- and post-op. In a voice demo, alternate between matching pre/post views and explicitly point out what is preserved, displaced, attenuated, or uncertain.

Changes in tract count, volume, surface area, and T2R can reflect acquisition, registration, brain shift, edema, susceptibility, reconstruction settings, or tractability. A newly visible postoperative tract can reflect improved tractability; an absent tract can reflect tracking failure.

### 8.4 Reconstruction-based preservation language

Use these imaging descriptions:

**Reconstruction preserved**
- pathway remains reconstructable in the expected gross course;
- trajectory can be followed around/adjacent to operative site;
- no major new discontinuity is apparent in the reconstructed bundle.

**Reconstruction partially preserved / altered**
- recognizable pathway remains but is substantially reduced, displaced, fragmented, narrowed, or otherwise altered near the operative site.

**Preservation uncertain**
- reconstruction is sparse, anatomically ambiguous, or heavily affected by postoperative distortion/artifact, or pre/post datasets are not directly comparable.

**Not reconstructable postoperatively**
- pathway cannot be reconstructed despite the bounded retry procedure.
- Do **not** translate this automatically to `transected` or `destroyed`.

### Postoperative checkpoint C

For each clinically relevant tract report the preservation category, the key pre/post change, relationship to cavity/residual lesion/edema, and the corresponding neurological system that warrants clinical correlation.

Then identify:

```text
which eloquent pathways are clearly still reconstructable
which pathway shows the greatest postoperative alteration or uncertainty
which pathway courses along the cavity/residual-lesion margin
which findings warrant correlation with postoperative neurological function
```

### 8.5 Lesion-volume comparison

When comparable, report pre/post volumes and absolute changes for the same segmentation labels. Treat these as descriptive findings only. Do not infer progression, residual tumor, cavity size, treatment effect, or biological response from segmentation volume change alone.

## 9. Final postoperative neurosurgical report

Lead with eloquent-tract preservation:

```text
Postoperative neurosurgical summary

Eloquent-tract preservation
- pathway / side / preservation assessment
- key pre/post reconstruction or morphology change
- relationship to cavity/residual lesion/edema
- uncertainty

Most important pathway findings
- pathways grossly preserved around operative site
- pathways altered/attenuated/uncertain
- pathways not reconstructable postoperatively

Postoperative anatomy
- verified cavity/residual lesion/edema
- major volume changes when meaningful

Clinical correlation priorities
- neurological domains corresponding to altered/uncertain pathways
- findings tractography cannot resolve confidently
- artifact/registration limitations
```

For a postoperative voice demo, begin with the main preservation conclusion, then show the relevant pre/post 3D tract-tumor/cavity relationships. Explain the purpose and meaning of each comparison so a neurosurgeon unfamiliar with tractography metrics can follow the reasoning.

## 10. Reproducibility record

Record:

- FIB source/reconstruction space;
- structural source/slice and registration/QC status;
- segmentation model and original labels;
- derived Tumor Core when used;
- CHA/Brodmann statistics used for interpretation;
- exact AutoTrack identifiers/settings;
- tract streamline counts;
- lesion regions used in T2R;
- T2R counts and calculated bundle fractions;
- bilateral tract morphology statistics;
- matched pre/post tract identity and preservation category;
- exact `set_view`/rotation recipe for comparable 3D views;
- major QC limitations and accepted uncertainties.

`preview_screen roi` and `preview_screen 3d` are coarse agent-side inspection tools, not full-resolution clinical review. When requested or when an output destination is supplied, use `save_roi_screen`/`save_lr_screen` for human review.

Distinguish successful command execution from an anatomically accepted result.

## Interpretation references

- Yeh FC, Irimia A, Bastos DCA, Golby AJ. Tractography methods and findings in brain tumors and traumatic brain injury. NeuroImage. 2021;245:118651.
- Yeh FC. Shape analysis of the human association pathways. NeuroImage. 2020;223:117329.
- Essayed WI, Zhang F, Unadkat P, et al. White matter tractography for neurosurgical planning: a topography-based review of the current state of the art. NeuroImage: Clinical. 2017;15:659-672.

Use current DSI Studio AI documentation and live command output as the authority for software behavior.