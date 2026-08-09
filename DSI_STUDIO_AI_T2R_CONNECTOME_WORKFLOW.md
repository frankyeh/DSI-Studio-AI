# DSI Studio AI T2R Connectome Workflow

Use this guide when the task combines longitudinal Fiber Data Hub selection,
AutoTrack, atlas connectivity output, or 3D tract-to-region (T2R) rendering.
Read the general Hub, tract, region, rendering, and CLI manuals as needed; this
file records the cross-cutting behavior that is easy to miss when those topics
are read separately.

## 1. Select longitudinal data conservatively

Use `hub_repo`, `hub_tags`, `hub_files`, and release/demographic metadata to identify
subjects and sessions. Keep the exact subject identifier fixed across all requested
longitudinal time points.

Do not infer biological age from a generic session number such as `ses-01`. Session
numbering is dataset-specific and may be subject-specific. Prefer explicit age-bearing
session names or demographic/release metadata. Distinguish a study wave (for example,
baseline, 2-year follow-up, 4-year follow-up) from an exact biological age; if the
user requires an exact age, verify it from metadata rather than assuming the cohort's
typical age.

For a longitudinal task, record the exact selected file path for every time point
before beginning tractography. This prevents accidentally mixing subjects, runs, or
sessions when many similarly named Hub files are present.

## 2. AutoTrack connectivity output

For a reconstructed FIB/FZ file, `run_cli` can run AutoTrack and request atlas
connectivity at the same time. A representative command is:

```bash
bash ./dsi.sh run_cli "--action=atk --source=C:/data/subject.qsdr.fz --track_id=Arcuate --connectivity=HCP-MMP --connectivity_output=matrix --overwrite=1"
```

Important behavior confirmed in the current source and live testing:

- A tract identifier such as `Arcuate` may expand into laterality-specific outputs,
  such as left and right arcuate bundles. Inspect the generated paths instead of
  assuming one output file.
- The connectivity matrix is written next to each generated tract using a name of
  the form `<tract>.tt.gz.<atlas>.connectivity.mat`.
- The saved MAT contains both region-to-region (R2R) and tract-to-region (T2R)
  connectivity data. Do not run a second analysis merely because the filename says
  only `connectivity.mat`.
- AutoTrack can produce very verbose console output. Do not batch many subjects or
  time points into one GitHub issue request when using ChatGPT Web.

When tracking already exists and only connectivity must be regenerated or verified,
prefer `--action=ana` instead of retracking:

```bash
bash ./dsi.sh run_cli "--action=ana --source=C:/data/subject.qsdr.fz --tract=C:/data/arcuate.tt.gz --connectivity=HCP-MMP --connectivity_output=matrix"
```

This reloads the tract and runs the post-analysis/connectivity stage, which is much
faster than repeating AutoTrack.

## 3. Text T2R output and 3D T2R rendering are different operations

`show_t2r` / `save_t2r` calculate a tract-to-region table or text output for checked
tracts and regions. They do not by themselves make atlas parcels appear in the 3D
OpenGL view.

For a spatial T2R plot, load the atlas regions and the desired tract, then configure
**Region Rendering** so parcel color is driven by the current tract's T2R values.
A reliable sequence is:

```bash
bash ./dsi.sh open_fib "C:/data/subject.qsdr.fz"
bash ./dsi.sh list_atlas
bash ./dsi.sh add_region_from_atlas "<template-index> <atlas-index>"
bash ./dsi.sh open_tract "C:/data/arcuate.tt.gz"
bash ./dsi.sh list_param region_rendering
```

The two-element `add_region_from_atlas` form adds every parcel from the selected
atlas and avoids guessing individual label IDs.

## 4. How Region Color selects T2R

The Region Color metric list is constructed from the FIB's native metric list plus
one final special entry named `current tract`.

That final `current tract` entry is not another image metric. In the current source,
selecting it causes the region renderer to build a `ConnectivityMatrix` for the
loaded regions and the current tract and use its `t2r_value` as the parcel color
values.

Therefore:

1. Load or select the tract that should drive the map.
2. Inspect the live Region Rendering parameter list.
3. Set Region Color style to **Metrics**.
4. Set `region_color_metrics` to the final `current tract` entry.

Do not hard-code the numeric metric index across datasets. The index equals the
number of native FIB metrics and therefore can differ between reconstructions.
Template slices shown in `list_slice` (for example T1W/T2W/WM template images) are
not necessarily part of the native FIB metric list used to build this selector, so
do not derive the T2R metric index from the last row of `list_slice`.

When only one tract is open, `open_tract` normally makes it the relevant current
tract. When several tracts are loaded, explicitly select/verify the tract whose T2R
values should color the parcels before saving the figure.

## 5. Region visibility must be enabled before saving a screenshot

Loading atlas parcels into the Region table does not prove they are visible in the
3D renderer. `save_screen`/`save_lr_screen` capture the rendered OpenGL scene; if
Region Rendering is off, the PNG can contain the tract but no atlas parcels.

The root rendering flag `show_region` uses Qt check-state values. In the current
implementation, a fully checked/visible state is `2` (`Qt::Checked`), not Boolean
`1`. For automated screenshots, explicitly enable it rather than relying on a
remembered GUI setting.

A source-verified pattern is:

```bash
bash ./dsi.sh set_params "show_region=2&region_alpha=1&region_color_style=1&region_color_metrics=<current-tract-index>"
```

Use live parameter discovery to verify enum/index meanings before setting them.
Enable the color bar when useful for interpretation. Before longitudinal comparison,
choose a common color scale across all time points; do not silently use a different
auto-range for each scan. Derive an appropriate range from the data or from the
user's requested convention rather than assuming `0-1` is universally appropriate.

After the rendering state is correct, save the image with the tracking-window
`save_lr_screen` command documented in the rendering manual. Prefer it over plain
`save_screen` here: a T2R figure is meant to convey the spatial relationship between
a tract and atlas parcels, and the left/right stereo-pair view makes that relationship
legible from a single saved image. Use plain `save_screen` instead only if the user
explicitly asked for a single-view screenshot.

```bash
bash ./dsi.sh save_lr_screen "C:/output/t2r.png"
```

If a screenshot is being judged visually, keep the tracking window open until the
user or agent has verified that parcels, tract, and color mapping are all present.

## 6. GitHub issue-channel response-size trap

ChatGPT Web uses one GitHub issue comment for the latest DSI Studio result. Commands
that add a large atlas (for example all 360 HCP-MMP parcels), or verbose AutoTrack
runs, can generate a result larger than GitHub's practical comment payload limit.
In live testing, replies around 105-110 KB were replaced with:

```text
response truncated: exceeds GitHub comment size limit
```

Treat this as a **result-publication/transport error**, not proof that the DSI Studio
command itself failed. The request ID may still advance and the operations may have
completed successfully.

When this happens:

- Check whether `last_id` advanced to the submitted ID.
- Verify state with a later compact request such as `list_window`, `list_tract`, or a
  narrowly scoped parameter/status query while the correct tracking window is still
  selected.
- Do not immediately repeat a long synchronous computation merely because the issue
  reply was truncated.
- Keep verbose steps separate. Do not batch multiple AutoTrack subjects/time points
  in one request.
- Large `add_region_from_atlas` operations may still be verbose even when sent alone;
  rely on compact follow-up state checks rather than requesting a full region dump.

A truncated GitHub reply and a DSI Studio freeze are separate failure modes. During
live testing the same T2R rendering request later completed repeatedly in about
7-8 seconds while its GitHub result still exceeded the comment limit. Diagnose GUI
responsiveness and transport size independently.

## 7. Window-state recovery during testing

If DSI Studio is restarted or a tracking window disappears, a later tracking command
may route to `main` and return `unknown command`. Before assuming the command itself
is invalid, call `list_window`, reopen/select the needed FIB window, and then retry
the tracking-window command.

This matters especially for `list_param`: it is valid in a tracking window but will
be unknown if the active target is `main`.

## 8. Recommended longitudinal T2R workflow

For each cohort or subject:

1. Verify the exact longitudinal subject and session/age metadata.
2. Download/open the exact QSDR FIB/FZ files.
3. Run AutoTrack once per time point with the requested tract and atlas connectivity.
4. Record every generated left/right tract path and connectivity MAT path.
5. If connectivity needs repair or verification, use `--action=ana` on the existing
   tract rather than retracking.
6. For a 3D plot, open one FIB, add the atlas, open/select the desired tract, enable
   Region Rendering, and select Region Color -> Metrics -> `current tract`.
7. Verify parcel visibility and use a common color scale before saving the screenshot.
8. Save the screenshot with `save_lr_screen` (plain `save_screen` only if the user asked
   for a single view), then close the tracking window when it is no longer needed.
9. Repeat one time point at a time to keep state and GitHub responses manageable.

For bilateral reporting, remember that matrix generation may already have produced
separate left and right tract outputs. Decide explicitly whether the requested figure
should show left, right, or a merged bilateral tract; do not silently choose one side
when the user's intended laterality matters.
