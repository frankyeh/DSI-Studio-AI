# DSI Studio AI T2R Connectome Workflow

Use this guide for tract-to-region (T2R) analysis, including lesion involvement,
longitudinal connectivity work, atlas connectivity output, and 3D T2R rendering.
Read the general tract, region, rendering, slice, and CLI manuals for exact command
semantics.

## 1. What interactive T2R measures

`show_t2r` / `save_t2r` operate on the currently checked tract bundles and checked
regions. For each checked tract bundle, DSI Studio maps the checked regions into the
FIB diffusion grid, identifies the streamlines that **pass through** each region, and
runs ordinary tract quantitative statistics on that passing subset.

Consequently, the T2R table's:

```text
number of tracts
```

row is the number of streamlines from that tract bundle that intersect each region.
This is the preferred quantity when the scientific question is, for example, how much
of a reconstructed pathway passes through a tumor, edema, cavity, or other lesion
mask.

A typical interactive call is:

```bash
bash ./dsi.sh show_only_tracts "<tract-index-1>&<tract-index-2>&..."
bash ./dsi.sh show_only_regions "<region-index-1>&<region-index-2>&..."
bash ./dsi.sh show_t2r
```

One `show_t2r` invocation can analyze several checked tract bundles against several
checked regions. When multiple tracts are checked, the output contains a separate T2R
table for each tract bundle.

### Streamline involvement fraction

T2R does not directly report the fraction of the entire tract bundle that intersects a
region. Calculate it explicitly:

```text
intersecting streamline count =
    T2R "number of tracts" for the target region

total bundle streamline count =
    list_tract tract count or show_tract_statistics "number of tracts"

streamline involvement fraction =
    intersecting streamline count / total bundle streamline count
```

Use the total count from the same completed tract bundle as the denominator.

A streamline can pass through more than one checked region and will then contribute to
each relevant region's count. Fractions across overlapping or adjacent regions are
therefore not expected to sum to one.

### Do not confuse T2R metrics

`show_t2r` returns all quantitative metrics calculated for each passing-streamline
subset and also includes generic coverage metrics. For a streamline-involvement
question:

- use `number of tracts` as the intersecting-streamline count;
- divide by the total bundle streamline count yourself;
- do **not** use the generic T2R `intersect ratio` as the streamline fraction;
- do not describe the resulting count/fraction as an `overlap volume`.

The streamline fraction answers: **what fraction of the reconstructed pathway's
streamlines intersect this region?**

For brain-tumor workflows, follow
`DSI_STUDIO_AI_SKILL_BRAIN_TUMOR.md`, which uses this T2R interpretation for
Enhancing Tumor, Necrosis, Peritumoral Edema, and optionally Tumor Core.

## 2. Why T2R is preferable to tract-to-region conversion for statistics

When only tract-versus-region connectivity is needed, prefer T2R over converting the
tract into a binary ROI and intersecting masks. T2R:

- operates directly on the original tract streamlines;
- maps the target regions into diffusion space internally;
- avoids `tract_to_region` current-slice voxelization;
- avoids temporary lesion copies and region-table mutations;
- avoids resampling one binary mask into another merely to count involvement;
- can analyze several tract bundles and several target regions in one call.

Use `tract_to_region` only when an actual tract-derived ROI object is needed for
visualization, editing, mask operations, or another downstream purpose.

## 3. Text T2R output and 3D T2R rendering are different operations

`show_t2r` / `save_t2r` calculate the T2R table. They do not by themselves make atlas
or lesion parcels appear in the 3D OpenGL view.

For a spatial T2R plot, load/show the desired regions and tract, then configure Region
Rendering so parcel color is driven by the current tract's T2R value. For atlas work,
a representative sequence is:

```bash
bash ./dsi.sh open_fib "C:/data/subject.qsdr.fz"
bash ./dsi.sh list_atlas
bash ./dsi.sh add_region_from_atlas "<template-index> <atlas-index>"
bash ./dsi.sh open_tract "C:/data/arcuate.tt.gz"
bash ./dsi.sh list_param region_rendering
```

The two-element `add_region_from_atlas` form adds every parcel from the selected atlas
and avoids guessing individual label IDs.

## 4. How Region Color selects T2R

The Region Color metric list is constructed from the FIB's native metric list plus one
final special entry named `current tract`.

Selecting `current tract` causes the region renderer to build a `ConnectivityMatrix`
for the loaded regions and current tract and use its T2R values as parcel colors.

Therefore:

1. Load/select the tract that should drive the map.
2. Inspect the live Region Rendering parameter list.
3. Set Region Color style to **Metrics**.
4. Set `region_color_metrics` to the final `current tract` entry.

Do not hard-code its numeric index across datasets. The index depends on the native
FIB metric list and can differ between reconstructions.

When several tracts are loaded, explicitly select/verify the tract whose T2R values
should color the parcels before saving a figure.

## 5. Region visibility and reproducible rendering

Loading regions into the Region table does not prove they are visible in the 3D
renderer. Before saving a T2R figure, verify Region Rendering and tract visibility.

A source-verified pattern is:

```bash
bash ./dsi.sh set_params "show_region=2&region_alpha=1&region_color_style=1&region_color_metrics=<current-tract-index>"
```

Use live parameter discovery to verify enum/index meanings. For longitudinal figures,
use a common color scale rather than silently auto-ranging each session independently.

For reproducible pre/post 3D captures, explicitly reset the camera first:

```bash
bash ./dsi.sh set_view 0 0
```

Then apply identical rotations in both sessions. Do not omit the third `set_view`
argument when reproducibility matters because omission toggles the flip state.

Use `save_lr_screen` when a saved 3D tract/region rendering is requested. Use
`preview_screen 3d` for coarse agent-side inspection, not as a substitute for
full-resolution visual review.

## 6. AutoTrack/CLI connectivity output

For a reconstructed FIB/FZ file, `run_cli` can run AutoTrack and request atlas
connectivity at the same time. A representative command is:

```bash
bash ./dsi.sh run_cli "--action=atk --source=C:/data/subject.qsdr.fz --track_id=Arcuate --connectivity=HCP-MMP --connectivity_output=matrix --overwrite=1"
```

Important behavior:

- A tract identifier such as `Arcuate` may expand into laterality-specific outputs;
  inspect generated paths rather than assuming one output file.
- The connectivity matrix is written next to each generated tract in a name such as
  `<tract>.tt.gz.<atlas>.connectivity.mat`.
- The saved MAT contains both region-to-region (R2R) and T2R connectivity data.

When tracking already exists and connectivity alone must be regenerated or verified,
prefer `--action=ana` rather than retracking:

```bash
bash ./dsi.sh run_cli "--action=ana --source=C:/data/subject.qsdr.fz --tract=C:/data/arcuate.tt.gz --connectivity=HCP-MMP --connectivity_output=matrix"
```

## 7. Longitudinal interpretation

For a longitudinal task, keep the exact subject identifier fixed and verify the exact
session/age metadata rather than inferring biological age from generic session names.
Record the exact FIB and tract source for every time point.

For lesion T2R, report for each session:

```text
total bundle streamline count
region-intersecting streamline count
region-intersecting streamline fraction
```

The within-session fraction is preferable to comparing tract-derived binary voxel
volumes, but it is not immune to longitudinal tractography variability. Changes in
streamline count or fraction can reflect acquisition, reconstruction, registration,
anatomical deformation, diffusion signal, tractability, AutoTrack tolerance, TIP, or
other tracking behavior. Do not interpret a longitudinal change as direct axonal loss
or gain by itself.

For atlas T2R figures, use the same tract definition, rendering scale, and camera
recipe across sessions whenever possible.

## 8. GitHub response-size and state-recovery cautions

AutoTrack and large atlas operations can generate verbose output. If a GitHub issue
response is truncated, treat that as a transport/publication problem rather than proof
that DSI Studio failed. Verify compact state with commands such as `list_window`,
`list_tract`, or a narrow parameter query before repeating expensive work.

If DSI Studio restarts or the tracking window disappears, a later tracking command may
route to `main` and return `unknown command`. Call `list_window`, reopen/select the
needed FIB tracking window, and then retry.

## 9. Recommended workflows

### Lesion involvement

1. Complete tractography and verify all requested bundles are `done`.
2. `list_tract` and record each bundle's total streamline count.
3. `list_region` and resolve the exact lesion regions.
4. `show_only_tracts` for all bundles to analyze.
5. `show_only_regions` for all lesion targets.
6. Call `show_t2r` once.
7. For each tract/region pair, record T2R `number of tracts` and calculate
   `intersecting/total`.
8. Perform spatial QC with the original tract and lesion regions; no temporary
   tract-derived ROI is required.

### Longitudinal atlas T2R rendering

1. Verify exact subject/session metadata and FIB paths.
2. Generate or load the same named tract at each time point.
3. Generate/verify connectivity with `--action=atk` or `--action=ana` as appropriate.
4. Load the target atlas and tract for rendering.
5. Set Region Color -> Metrics -> `current tract` using live parameter discovery.
6. Verify visibility and use a common color scale.
7. Reset to the same explicit camera and apply identical rotations.
8. Save with `save_lr_screen` when requested.

Use current DSI Studio source behavior and live command output as the authority when a
manual and running build disagree.
