# DSI Studio AI T2R Connectome Workflow

Tract-to-region (T2R) analysis: lesion involvement, longitudinal connectivity, atlas connectivity
output, and 3D T2R rendering. Exact command semantics are in the tract, region, rendering, slice, and
CLI manuals; when a manual and the running build disagree, current source behavior and live output win.

## 1. What interactive T2R measures

`show_t2r` / `save_t2r` act on the checked tract bundles and checked regions. For each bundle, DSI
Studio maps the regions into the FIB diffusion grid, finds the streamlines that **pass through** each
region, and runs ordinary tract statistics on that subset. The table's `number of tracts` row is
therefore the count of that bundle's streamlines intersecting each region: the preferred quantity for
how much of a pathway passes through a tumor, edema, cavity, or other lesion mask.

```bash
bash ./dsi.sh show_only_tracts "<tract-index-1>&<tract-index-2>&..."
bash ./dsi.sh show_only_regions "<region-index-1>&<region-index-2>&..."
bash ./dsi.sh show_t2r
```

One call handles several bundles against several regions, giving a separate table per bundle.

**Streamline involvement fraction.** T2R does not report it; compute
`T2R "number of tracts" for the region / total bundle streamline count`, taking the denominator from the
same completed bundle (`list_tract` tract count or `show_tract_statistics` `number of tracts`). A
streamline crossing several regions counts in each, so fractions over overlapping or adjacent regions
need not sum to one. The fraction answers: **what fraction of the reconstructed pathway's streamlines
intersect this region?** Do **not** use the generic T2R `intersect ratio` coverage metric as this
fraction, and never call the count/fraction an `overlap volume`. Brain-tumor work follows
`DSI_STUDIO_AI_SKILL_BRAIN_TUMOR.md`, which applies this to Enhancing Tumor, Necrosis, Peritumoral
Edema, and optionally Tumor Core.

## 2. Prefer T2R to `tract_to_region` for statistics

T2R works on the original streamlines, maps targets into diffusion space internally, handles many
bundles and regions in one call, and avoids current-slice voxelization, temporary lesion copies,
Region-table changes, and mask-to-mask resampling just to count involvement. Use `tract_to_region` only
when a real tract-derived ROI is needed for visualization, editing, mask operations, or later steps.

## 3. Text output vs 3D T2R rendering

`show_t2r` / `save_t2r` compute the table; they do not show parcels in the 3D view. For a spatial plot,
load/show the regions and tract and drive parcel color from the tract's T2R values, e.g. for an atlas:

```bash
bash ./dsi.sh open_fib "C:/data/subject.qsdr.fz"
bash ./dsi.sh list_atlas
bash ./dsi.sh add_region_from_atlas "<template-index> <atlas-index>"   # every parcel; no guessed label IDs
bash ./dsi.sh open_tract "C:/data/arcuate.tt.gz"
bash ./dsi.sh list_param region_rendering
```

The Region Color metric list is the FIB's native metrics plus a final special entry `current tract`;
selecting it makes the renderer build a `ConnectivityMatrix` for the loaded regions and current tract
and color parcels by T2R. So: load/select the driving tract (verify it explicitly when several are
loaded), inspect the live list, set Region Color style to **Metrics**, and set `region_color_metrics`
to the final `current tract` index. Never hard-code that index: it depends on the FIB's metric list.

```bash
bash ./dsi.sh set_params "show_region=1&region_alpha=1&region_color_style=1&region_color_metrics=<current-tract-index>"
```

Regions in the table are not proof of 3D visibility: verify Region Rendering and tract visibility
before saving. For longitudinal figures use a common color scale instead of per-session auto-ranging,
start from an explicit camera (`set_view 0 0`; never omit the third argument, which toggles the flip)
with identical rotations, save with `save_lr_screen` when requested, and use `preview_screen 3d` only
for coarse agent-side inspection.

## 4. AutoTrack/CLI connectivity output

`run_cli` can run AutoTrack on a FIB/FZ and request atlas connectivity together:

```bash
bash ./dsi.sh run_cli "--action=atk --source=C:/data/subject.qsdr.fz --track_id=Arcuate --connectivity=HCP-MMP --connectivity_output=matrix --overwrite=1"
```

An identifier such as `Arcuate` may expand into laterality-specific outputs, so inspect the generated
paths. Each tract gets `<tract>.tt.gz.<atlas>.connectivity.mat`, containing both region-to-region (R2R)
and T2R data. To regenerate or verify connectivity for existing tracts, use `--action=ana` instead of
retracking:

```bash
bash ./dsi.sh run_cli "--action=ana --source=C:/data/subject.qsdr.fz --tract=C:/data/arcuate.tt.gz --connectivity=HCP-MMP --connectivity_output=matrix"
```

## 5. Longitudinal interpretation

Keep the subject identifier fixed, verify exact session/age metadata (never infer age from generic
session names), and record the FIB and tract source per time point. For lesion T2R report per session:
total bundle streamline count, region-intersecting count, and region-intersecting fraction. The
within-session fraction beats comparing tract-derived voxel volumes but still varies with acquisition,
reconstruction, registration, anatomical deformation, diffusion signal, tractability, AutoTrack
tolerance, TIP, and other tracking behavior; never read a change alone as axonal loss or gain. Keep the
tract definition, rendering scale, and camera recipe identical across sessions for atlas figures.

## 6. Response and state recovery

AutoTrack and large atlas operations are verbose. A missing or partial Web response is a transport
problem, not proof of failure: check compact state (`list_window`, `list_tract`, a narrow parameter
query) before repeating expensive work. If DSI Studio restarted or the tracking window vanished, a
tracking command may route to `main` and return `unknown command`: `list_window`, reopen/select the
FIB tracking window, then retry.

## 7. Recommended workflows

**Lesion involvement**

1. Finish tractography; every requested bundle is `done`.
2. `list_tract`: record each bundle's total streamline count.
3. `list_region`: resolve the exact lesion regions.
4. `show_only_tracts` (all bundles) and `show_only_regions` (all lesion targets), then one `show_t2r`.
5. Per tract/region pair record `number of tracts` and compute `intersecting/total`.
6. Spatial QC with the original tract and lesion regions; no tract-derived ROI is needed.

**Longitudinal atlas T2R rendering**

1. Verify subject/session metadata and FIB paths.
2. Generate or load the same named tract at each time point.
3. Generate/verify connectivity with `--action=atk` or `--action=ana`.
4. Load the atlas and tract; set Region Color -> Metrics -> `current tract` via live discovery.
5. Verify visibility and use a common color scale.
6. Same explicit camera and rotations; `save_lr_screen` when requested.
