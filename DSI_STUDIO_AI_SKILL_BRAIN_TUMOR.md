# DSI Studio AI Brain Tumor Neurosurgical Evaluation

Use this skill for presurgical and postsurgical brain-tumor evaluation intended for a
neurosurgeon. Keep the workflow compact. Use the companion manuals for low-level command
semantics instead of expanding every implementation detail here.

The chat is the primary clinical presentation. After each major analysis phase, explain in
plain language:

1. **Purpose** — why the analysis is being done.
2. **Result** — the few findings that matter.
3. **Neurosurgical relevance** — what may affect surgical planning or postoperative
   interpretation.

Do not dump raw tables into chat. Do not call a tract `safe`, `intact`, `destroyed`, or
`resectable` from tractography alone.

The workflow has only three major phases:

1. **Presurgical lesion size and anatomical location**
2. **Presurgical eloquent-tract relationship**
3. **Postoperative eloquent-tract preservation**

The **first mandatory pause** is after the presurgical tumor/tract 3D review so the user can
inspect the live 3D scene before continuing.

## Companion manuals

Use as needed:

- segmentation/slices: `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md`
- regions/atlas overlap: `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md`
- AutoTrack: `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`
- tract commands: `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md`
- T2R: `DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md`
- 3D/camera: `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md`

# PHASE 1 — PRESURGICAL LESION SIZE AND LOCATION

## 1. Segment and verify the lesion

Select the structural image intended for segmentation and wait until it is ready:

```bash
bash ./dsi.sh list_slice
bash ./dsi.sh set_slice <slice-index>
bash ./dsi.sh list_slice
```

When a FIB already exposes the structural image in `list_slice`, select that existing
slice rather than adding it again.

Use `human_tumor` by default when available:

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

`human_tumor` also creates tissue labels. Resolve lesion rows by **exact name** from a fresh
`list_region`; never assume indices from creation order.

For presurgical work define:

```text
Tumor Core = Enhancing Tumor ∪ Necrosis
```

Preserve the original lesion labels. Create Tumor Core from copies if needed. Re-run
`list_region` after any Region-table mutation because indices can shift.

Inspect the lesion in three planes and verify that the segmentation is anatomically
plausible. `preview_screen roi` is coarse agent-side QC only; do not use it as definitive
clinical image review.

## 2. Measure lesion size

Isolate the lesion regions and run region statistics:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh show_only_regions "<enhancing>&<necrosis>&<Tumor-Core>&<edema>"
bash ./dsi.sh show_region_statistics
```

Record when available:

```text
Enhancing Tumor volume (mm^3)
Necrosis volume (mm^3)
Tumor Core volume (mm^3)
Peritumoral Edema volume (mm^3)
```

## 3. Localize the tumor anatomically — REQUIRED

Do **not** skip atlas localization. This is part of the standard tumor assessment and must
be completed before choosing eloquent tracts.

Run nonmutating atlas-overlap statistics on Tumor Core:

```bash
bash ./dsi.sh show_region_overlap_statistics <Tumor-Core-index> CHA
bash ./dsi.sh show_region_overlap_statistics <Tumor-Core-index> Brodmann
```

If edema localization materially affects tract selection, run CHA overlap on edema as
well.

For CHA and Brodmann, report only the dominant nonzero intersections. Use intersection
volume and, when helpful:

```text
fraction of Tumor Core = atlas-intersection volume / Tumor Core volume
```

CHA/Brodmann overlap is anatomical localization. It does not prove functional eloquence.

## Required Phase-1 chat summary — DO NOT OMIT

Before AutoTrack, give the neurosurgeon a concise lesion summary such as:

```text
Tumor summary
- side and gross location/lobe
- Enhancing Tumor, Necrosis, Tumor Core, and edema volumes
- dominant CHA regions involved
- relevant Brodmann areas, if informative
- cortical vs subcortical/white-matter predominance

Neurosurgical relevance
- which functional systems may be at risk based on location
- which eloquent pathways should therefore be reconstructed
- major segmentation/registration uncertainty, if any
```

This summary is required even when the tractography phase will immediately follow.

# PHASE 2 — PRESURGICAL ELOQUENT-TRACT RELATIONSHIP

## 4. Select the relevant bilateral pathways

Choose tracts based on lesion location. Reconstruct bilateral homologs when clinically
relevant.

| Function | Pathway | Left | Right |
|---|---|---|---|
| Motor | Corticospinal tract | `ProjectionBrainstem_CorticospinalTractL` | `ProjectionBrainstem_CorticospinalTractR` |
| Language | Arcuate fasciculus | `Association_ArcuateFasciculusL` | `Association_ArcuateFasciculusR` |
| Language | Superior longitudinal fasciculus | `Association_SuperiorLongitudinalFasciculusL` | `Association_SuperiorLongitudinalFasciculusR` |
| Language | Frontal aslant tract | `Association_FrontalAslantTractL` | `Association_FrontalAslantTractR` |
| Temporal/semantic | Inferior longitudinal fasciculus | `Association_InferiorLongitudinalFasciculusL` | `Association_InferiorLongitudinalFasciculusR` |
| Vision | Optic radiation | `ProjectionBasalGanglia_OpticRadiationL` | `ProjectionBasalGanglia_OpticRadiationR` |

Practical selection:

- perirolandic/motor lesion → CST
- frontal language lesion → AF, SLF, FAT
- parietal language lesion → AF, SLF
- temporal language lesion → AF, ILF
- posterior temporal/parietal/occipital lesion → optic radiation when relevant

For a temporal lesion, if agent-side anatomical QC cannot confidently exclude posterior
temporal or temporo-occipital involvement, include optic radiation rather than omit it.
Edema volume alone is not the trigger.

## 5. Launch AutoTrack as a batch

Launch all selected independent `run_auto_track` calls back-to-back. Do **not** wait for
one bundle before starting the next.

```bash
bash ./dsi.sh run_auto_track "<tract-1>"
bash ./dsi.sh run_auto_track "<tract-2>"
bash ./dsi.sh run_auto_track "<tract-3>"
```

After all calls are launched, poll the full tract table about every 10 seconds:

```bash
bash ./dsi.sh list_tract
```

Continue when all requested bundles report `done`. Follow the bounded tolerance/retry rules
in the Fiber Tracking skill. An unmappable tract is a limitation, not proof of anatomical
absence.

## 6. Measure tract-to-lesion involvement with T2R

Use T2R instead of converting each tract into a voxel region.

```bash
bash ./dsi.sh list_tract
bash ./dsi.sh list_region
bash ./dsi.sh show_only_tracts "<relevant-tract-indices>"
bash ./dsi.sh show_only_regions "<enhancing>&<necrosis>&<Tumor-Core>&<edema>"
bash ./dsi.sh show_t2r
```

For each bundle/lesion pair:

```text
intersecting streamline count = T2R "number of tracts"
lesion involvement fraction = intersecting streamline count / total streamlines in that bundle
```

Use the `number of tracts` row as the numerator. Do **not** use the generic T2R `intersect
ratio` as the streamline fraction. A streamline may intersect more than one lesion
compartment, so fractions do not need to sum to one.

Interpretation:

- Tumor Core/enhancing-tumor intersection suggests direct reconstructed pathway–lesion
  conflict.
- Edema-only intersection may reflect pathway passage through tissue affected by edema,
  mass effect, or altered diffusion.
- Zero reconstructed intersection does not guarantee surgical separation.

## 7. Show the tumor–tract spatial relationship in 3D

This is the key presurgical visualization step. Leave the live 3D window in a useful state
for the neurosurgeon to inspect.

Show only the lesion regions and clinically relevant tract bundles:

```bash
bash ./dsi.sh show_only_regions "<relevant-lesion-indices>"
bash ./dsi.sh show_only_tracts "<relevant-tract-indices>"
bash ./dsi.sh set_view 0 0
bash ./dsi.sh preview_screen 3d
```

Use a few purposeful viewpoints when needed:

```bash
bash ./dsi.sh rotate_view left 20
bash ./dsi.sh preview_screen 3d
bash ./dsi.sh rotate_view up 15
bash ./dsi.sh preview_screen 3d
```

Describe whether each key tract is:

```text
intersecting Tumor Core
displaced by tumor/edema
compressed/narrowed near the lesion
running along a lesion margin
grossly separated from the lesion
incompletely reconstructed / uncertain
```

For a small but clinically important T2R intersection, inspect the relationship in the
three slice planes as well.

## Required presurgical chat summary and FIRST PAUSE

Explain, in plain language:

```text
Presurgical summary
- tumor size and anatomical location
- dominant CHA/Brodmann involvement
- which eloquent pathways were reconstructed and why
- which pathways intersect Tumor Core/enhancing tumor/edema by T2R
- most important 3D spatial relationships
- the few findings most likely to affect surgical planning
- major uncertainty or unmappable pathway
```

Then **stop**. Do not automatically continue into postoperative analysis.

End the message with a short continuation prompt such as:

```text
The presurgical tumor–tract 3D view is ready for inspection.
Continue with postoperative tract-preservation analysis, or export the tract overlay to DICOM?
```

### If the user chooses DICOM export

DSI Studio's current clinical-navigation export workflow is GUI-based and requires the
original DICOM series to be loaded as the current custom slice:

```text
Slices → Mark Tracts on T1W/T2W
Slices → Save Slices to DICOM
```

`Mark Tracts on T1W/T2W` paints the currently checked tracts into the selected structural
volume. `Save Slices to DICOM` writes modified copies based on the original DICOM files.
Keep the original DICOM series unchanged and export to a separate directory.

Do not offer this export when the selected structural slice is not backed by the original
DICOM series. There is currently no dedicated AI command documented for these two GUI
actions, so do not invent one.

# PHASE 3 — POSTOPERATIVE ELOQUENT-TRACT PRESERVATION

Only enter this phase after the user chooses to continue.

The principal postoperative question is:

> **Are the eloquent pathways that were relevant preoperatively still reconstructable in
> their expected course after surgery/treatment?**

Lesion-volume changes are secondary to this tract-preservation question.

## 8. Verify postoperative anatomy

Identify postoperative anatomy conservatively: verified cavity, residual enhancing lesion,
postoperative edema, hemorrhage/treatment-related change, or another known abnormality.

Do not automatically interpret a segmentation `Necrosis` label as resection cavity.
Use a verified cavity mask separately when available.

Give a short chat summary of the postoperative anatomy and any distortion/artifact that may
limit tractography comparison.

## 9. Reconstruct the same eloquent pathways

Use the same clinically relevant bilateral pathways and comparable AutoTrack settings.
Launch all independent AutoTrack calls back-to-back, then poll `list_tract` about every
10 seconds until all are complete.

A tract absent postoperatively after the bounded retry procedure is `not reconstructable
postoperatively`; this does **not** prove surgical transection.

## 10. Compare tract preservation

For each matched tract compare:

```text
reconstructability in expected anatomical course
gross trajectory around the operative site
streamline count
tract volume and surface area
relationship to cavity/residual lesion/edema
postoperative T2R count/fraction when useful
```

Use the same camera reset and rotation sequence for comparable pre/post 3D views.

Use reconstruction-based language:

- **Reconstruction preserved** — expected gross pathway remains visible around the operative site.
- **Reconstruction partially preserved / altered** — recognizable pathway remains but is substantially reduced, displaced, fragmented, narrowed, or otherwise altered.
- **Preservation uncertain** — sparse/ambiguous reconstruction or major postoperative artifact/distortion limits comparison.
- **Not reconstructable postoperatively** — no reliable reconstruction despite bounded retry; do not equate this with destruction.

Pre/post tract count, volume, surface area, and T2R differences are descriptive. They may
reflect acquisition, registration, brain shift, edema, susceptibility, tracking tolerance,
TIP, or tractability.

## Required postoperative chat summary and pause

Lead with tract preservation:

```text
Postoperative tract-preservation summary
- pathway / side / preservation category
- key pre/post change
- relationship to cavity/residual lesion/edema
- pathway with greatest alteration or uncertainty
- pathways clearly still reconstructable around the operative site
- neurological systems needing clinical correlation
```

Then stop again so the user can inspect the postoperative 3D view and comparison before any
additional export or secondary analysis.

A suitable prompt is:

```text
The postoperative tract-preservation review is ready for inspection.
Continue with detailed pre/post measurements or export images/tract overlays?
```

## Reproducibility record

Keep a compact record of:

- FIB and structural-image sources;
- segmentation model and lesion labels;
- lesion volumes;
- CHA/Brodmann overlaps used in the anatomical summary;
- exact AutoTrack identifiers/settings;
- tract streamline counts;
- T2R intersecting counts and calculated fractions;
- matched pre/post tract identities and preservation categories;
- camera recipe used for comparable 3D views;
- major QC limitations.

## Interpretation references

- Yeh FC, Irimia A, Bastos DCA, Golby AJ. Tractography methods and findings in brain
  tumors and traumatic brain injury. NeuroImage. 2021;245:118651.
- Yeh FC. Shape analysis of the human association pathways. NeuroImage. 2020;223:117329.
- Essayed WI, Zhang F, Unadkat P, et al. White matter tractography for neurosurgical
  planning: a topography-based review of the current state of the art. NeuroImage:
  Clinical. 2017;15:659-672.

Use current DSI Studio AI documentation and live command output as the authority for
software behavior.
