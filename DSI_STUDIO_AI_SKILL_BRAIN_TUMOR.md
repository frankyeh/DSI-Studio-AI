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
5. Compare ipsilesional and contralateral tract volume and surface area.
6. Integrate overlap, morphology, visual anatomy, and known tractography limitations.

Do not use tumor- or edema-derived regions as ROI, Seed, ROA, End, or other tracking
constraints for standard AutoTrack. Map the named tract independently first, then
measure its spatial relationship to the lesion.

## 1. Segment and characterize the lesion

Use the structural slice best suited to the available tumor model. Discover the
current model ID with `list_unet`, run `segment_brain`, then inspect
`list_region`. Do not assume tumor, edema, necrosis, or other label names or region
indices.

Inspect the segmentation against the structural MRI before quantitative analysis.
For postoperative studies, do not assume a tumor model correctly identifies resection
cavity, hemorrhage, postoperative enhancement, or treatment effect.

### 1.1 Tumor and edema size

Use `show_region_statistics` on the tumor region and, separately, the edema region.
Record `volume (mm^3)`. Keep tumor and edema as separate measurements.

### 1.2 CHA localization

The human atlas is named exactly `CHA`. Atlas numeric indices are runtime-dependent,
so use `list_atlas` to find the current `CHA` atlas index, then load all CHA labels
with `add_region_from_atlas`.

Determine location from actual tumor overlap rather than preselecting a CHA region.
Use the tumor as the first region in `region_action_all_inter_1st` and the disposable
CHA regions as the following regions. The first region is preserved; each following
region becomes:

```text
CHA region ∩ tumor
```

Use `show_region_statistics` and report only nonzero intersections. For each affected
CHA region report:

```text
intersection volume (mm^3)
fraction of tumor = intersection volume / total tumor volume
```

Rank affected CHA regions by intersection volume. If edema localization is useful,
reload CHA and repeat the analysis separately with the edema region.

### 1.3 Brodmann-area involvement

The human atlas is named exactly `Brodmann`. Find its current runtime index with
`list_atlas`, load all labels, and intersect the disposable Brodmann regions with
the original tumor region using the same `region_action_all_inter_1st` logic.

Report only Brodmann areas with nonzero tumor intersection:

```text
Brodmann area
intersection volume (mm^3)
fraction of tumor
```

Rank them by intersection volume. Brodmann overlap is anatomical localization, not
proof that the corresponding function is impaired. Large lesions and mass effect can
also reduce atlas-registration accuracy; visually inspect unexpected or small
intersections.

CHA and Brodmann are gray-matter parcellations. Their intersection volumes do not
need to sum to the total tumor volume, particularly for white-matter-centered tumors.

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

For every pathway selected for quantitative comparison, map the ipsilesional and
contralateral homologs with identical AutoTrack settings. Follow the AutoTrack QC,
tracking-size, tolerance, TIP, completion, and visualization guidance already
maintained in `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md`.

Do not add tumor or edema constraints to AutoTrack.

## 4. Measure direct tract overlap with tumor and edema

After AutoTrack finishes, use `tract_to_region` to convert the mapped bundle into a
spatial tract region.

Preserve the original tract region, tumor region, and edema region. Because
`region_action_all_inter_1st` modifies the following regions, create disposable
copies of tumor and edema first. Call `list_region` after each region-creating or
copying operation before using indices.

Use the tract region as the first region and the lesion copies as following regions:

```text
tract region ∩ tumor
tract region ∩ edema
```

Then use region statistics to obtain:

```text
tumor overlap volume
edema overlap volume
tumor overlap fraction = volume(tract ∩ tumor) / volume(tract region)
edema overlap fraction = volume(tract ∩ edema) / volume(tract region)
```

A nonzero intersection establishes spatial overlap between the reconstructed pathway
and the segmented abnormality. It does not establish histologic infiltration or
functional loss.

## 5. Compare ipsilesional and contralateral tract morphology

Use `show_tract_statistics` with only the bilateral tract pair checked. Record:

```text
total volume(mm^3)
total surface area(mm^2)
```

Report the raw bilateral values and, when useful:

```text
volume ratio = ipsilesional volume / contralateral volume
surface-area ratio = ipsilesional surface area / contralateral surface area
```

Reduced ipsilesional volume or surface area may support pathway involvement when it
agrees with tumor/edema overlap and visible tract distortion. Do not interpret the
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
  tumor volume
  edema volume
  hemisphere

CHA localization
  region — intersection volume — fraction of tumor

Brodmann involvement
  area — intersection volume — fraction of tumor

Eloquent pathway
  pathway and ipsilesional side
  tumor overlap volume and fraction
  edema overlap volume and fraction
  ipsilesional tract volume
  contralateral tract volume
  volume ratio
  ipsilesional surface area
  contralateral surface area
  surface-area ratio
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

Map the same bilateral eloquent pathways with comparable acquisition,
reconstruction, and AutoTrack settings when possible. Repeat tract-to-region
intersection and bilateral tract-statistics analysis.

Changes after surgery can reflect resection, decompression, edema resolution,
hemorrhage, susceptibility artifact, altered diffusion signal, registration, or
acquisition differences. A newly visible postoperative tract can reflect improved
tractability rather than newly preserved fibers.

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
