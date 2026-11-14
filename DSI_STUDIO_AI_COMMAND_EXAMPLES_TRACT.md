# DSI Studio AI Tract Command Examples and Inventory

Tract and automatic-tracking commands confirmed in the current source (generic names with no handler
were removed after checking the GL, tract, region, device, and tracking dispatch chain; never use
them, copy exact commands from this file). Use these in a `tracking<hex-address>` window, selected
once with `bash ./dsi.sh set_window tracking<hex-address>` (it persists until changed). Names and
text, path, or composite parameters are strings; send standalone numbers as JSON numbers.

**Index conventions.** Call `["list_tract"]` immediately before an indexed edit. An explicit index
applies to that bundle whether or not it is checked. `delete_tract`, `delete_branch`, `undo_tract`,
`redo_tract`, and `trim_tract` take one index or an `&`-separated list (e.g. `"0&2&5"`); with no
index, `delete_tract` and `trim_tract` use the current row and the others use checked bundles.
`cut_tract_by_*`, `filter_tract`, `delete_repeated_tract`, `resample_tract`, and
`delete_tract_by_length` use `command[1]` for their parameter and take an optional `command[2]`
index list; omitted, they act on every checked bundle:

```bash
bash ./dsi.sh cut_tract_by_x 80 "0&2"
bash ./dsi.sh filter_tract "0:3&1:0" "0&2"
bash ./dsi.sh resample_tract 0.5 "0&2"
```

## Tracking, AutoTrack, and history

| Command | Example | Behavior |
|---|---|---|
| `list_tract` | `["list_tract"]` | One row per bundle: `index  status  shown  name  tracts  deleted  seeds`; `status` is `running` or `done`. Use this full listing to monitor a multi-bundle batch. |
| `list_tract status` | `["list_tract","status"]` | Compact `status  bundles`: `done` means no tracking thread remains; `bundles` is the total row count, not the running jobs. |
| `run_tracking` | `["run_tracking","Whole Brain"]`, `["run_tracking","CST","0:3&1:0"]` | Asynchronous tracking with current parameters; `command[1]` (the new bundle name) is mandatory. Without `command[2]` no region constraints apply; `command[2]` (empty or containing `:`) gives explicit ROI settings, validated before the bundle/thread is created. |
| `run_dif_tracking` | `["run_dif_tracking","CST_dT"]` | Differential counterpart: resolves current `dt_index1`/`dt_index2` into `set_dt_index`, then tracks; fails if both are `0`. Always use it (not `run_tracking`) for a differential run, however `m1`/`m2` were configured; `command[2]` takes ROI settings as above. |
| `set_dt_index` | `["set_dt_index","qa&iso",0]` | Set differential metrics `m1&m2` and calculation type; creates the `dT_metrics` slice the first time and syncs `dt_index1`/`dt_index2`. |
| `list_auto_tract` | `["list_auto_tract"]` | Valid hierarchical AutoTrack names. Normally call before AutoTrack (a task skill may supply verified identifiers and waive discovery). Parent entry = whole family; child only for a requested subdivision or branch. |
| `run_auto_track` | `["run_auto_track","ProjectionBrainstem_CorticospinalTractL"]` | Exact name from `list_auto_tract` or a verified skill identifier; never guess labels. Asynchronous: launch all independent bundles back-to-back, then poll the full `list_tract` about every 10 s until every requested row is `done`; never wait serially. Standard coherent bundles: about 10,000 tracts, TIP 3–4. An optional `command[2]` (e.g. `"0:0&1:1"`) adds ROI/ROA constraints, but named entries already carry anatomical constraints, so add them only for a specific need such as isolating a minor branch. |
| `enable_auto_tract` | `["enable_auto_tract"]` | Load the symmetric tract atlas and enable automatic-tract controls. |
| `prepare_mapping` | `["prepare_mapping","check"]`, `["prepare_mapping"]` | Subject-to-template normalization (see below). Returns `ready` (QSDR FIB, mapping computed, or a mapping file beside the FIB, which loads at once), `running <step>/4`, `failed: <reason>`, or, with `check`, `needed`. Without `check` it starts the normalization in the background when needed and returns at once. |
| `list_history` | `["list_history"]` | Every command recorded in this window's session, with its `index`. Check it before replaying. |
| `run_command_history` | `["run_command_history","C:/data/subjects"]` | Replay the recorded pipeline once per file in a folder (or an `&`-joined list, `"C:/data/s1.fz&C:/data/s2.fz"`), substituting each file into the load step and remapping related load/save names. An optional `command[2]` selects indices: `"2:5"` (inclusive), `"3"`, or `"0:1&12:15&16"` (replayed in that order, to skip noise between steps). See notes below. |

## Open, save, and convert

| Command | Example | Behavior |
|---|---|---|
| `open_tract` | `["open_tract","C:/output/cst.tt.gz"]` | Open one native-space tract file, showing each bundle (one command per file). Any `command[2]` (only emptiness is tested), e.g. `0`, loads the bundles unchecked/hidden. |
| `open_mni_tract` | `["open_mni_tract","C:/data/cst_mni.tt.gz"]` | Open an MNI-space tract mapped into the current subject. |
| `open_tract_name` | `["open_tract_name","C:/data/tract_names.txt"]` | Apply whitespace-separated names, in reverse order, to the most recently listed rows. |
| `load_tract_atlas` | `["load_tract_atlas","ProjectionBrainstem_CorticospinalTractL"]` | Load atlas streamlines as one bundle named by the text, a case-insensitive substring of `list_auto_tract` names: an exact identifier loads one tract, `CorticospinalTract` merges left and right. With no text, an AI caller always loads every atlas tract as separate bundles (only the GUI menu limits it to the AutoTrack dropdown); for a subset, call once per exact identifier. |
| `save_tract`, `save_mni_tract`, `save_template_tract`, `save_slice_tract` | `["save_tract","C:/output/cst.tt.gz",0]` | Save one completed bundle by index in native, MNI, loaded-template, or current-slice space. |
| `save_tract_endpoint`, `save_mni_tract_endpoint`, `save_slice_tract_endpoint` | `["save_tract_endpoint","C:/output/cst_endpoints.txt",0]` | One bundle's endpoints in native, MNI, or current-slice space. |
| `save_all_tracts` | `["save_all_tracts","C:/output/checked_tracts.tt.gz"]` | All checked tracts in one file. |
| `save_all_tracts_to_folder` | `["save_all_tracts_to_folder","C:/output/tracts"]` | Checked tracts as separate files. |
| `save_tdi`, `save_tdi2` | `["save_tdi","C:/output/cst_tdi.nii.gz",0]` | Tract-density image in current slice space; `save_tdi2` at two-times resolution. |
| `save_tract_values` | `["save_tract_values","C:/output/cst_qa.txt",0,"qa"]` | A named metric along one bundle (file, index, metric). |
| `tract_to_region` | `["tract_to_region",0]` | Voxelize a tract into a region in **current slice space** (see Longitudinal caution). |
| `endpoint_to_region` | `["endpoint_to_region",0]` | Convert tract endpoints to region(s). |

## Selection, editing, and cleanup

Confirm deleting, trimming, cutting, clustering, reconnecting, and merging.

| Command | Example | Behavior |
|---|---|---|
| `show_only_tracts` | `["show_only_tracts","0&2&5"]` | Check/show only these indices and hide all others; also selects them for checked-tract operations such as `show_tract_statistics`. |
| `check_tract` | `["check_tract",0,1]` | Set one tract's checked state. |
| `check_uncheck_all_tract` | `["check_uncheck_all_tract",1]` | Check/uncheck all; pass explicit `1`/`0`. |
| `update_tract` | `["update_tract"]` | Refresh counts and rendering. |
| `delete_tract` | `["delete_tract","0&2&5"]` | Delete bundles. |
| `delete_all_tracts` | `["delete_all_tracts"]` | Delete every bundle. |
| `copy_tract` | `["copy_tract",0]` | Duplicate one bundle. |
| `merge_all_tracts` | `["merge_all_tracts"]` | Merge checked bundles into the first checked row. |
| `merge_tract_by_name`, `sort_tract_by_name` | `["merge_tract_by_name"]` | Merge identically named bundles; sort bundles by name. |
| `delete_branch` | `["delete_branch","0&2"]` | Delete branch-like portions. |
| `undo_tract`, `redo_tract` | `["undo_tract","0&2"]` | Undo/redo the latest supported tract edit. |
| `trim_tract` | `["trim_tract",0]` | One TIP iteration (see Bundle cleanup). |
| `cut_tract_end_portion`, `cut_tract_lps_end`, `cut_tract_rai_end` | `["cut_tract_end_portion",0]` | `cut_end_portion(0.25,0.75)`, `cut_end_portion(0.25,1.0)`, `cut_end_portion(0.0,0.75)`; the target must be checked. |
| `flip_tract_x`, `flip_tract_y`, `flip_tract_z` | `["flip_tract_x",0]` | Flip a checked bundle along an axis. |
| `cut_tract_by_x`, `cut_tract_by_y`, `cut_tract_by_z` | `["cut_tract_by_x",80]` | Cut at that slice and keep the default side; `cut_tract_by_x2`, `cut_tract_by_y2`, `cut_tract_by_z2` keep the opposite side. |
| `filter_tract` | `["filter_tract","0:3&1:0"]` | Filter by ROI settings (same encoding as tracking). |
| `delete_repeated_tract` | `["delete_repeated_tract",1]` | Remove repeated trajectories within a voxel-distance threshold; only for a coherent named/loaded bundle. |
| `resample_tract` | `["resample_tract",0.5]` | Resample with a step size in voxels. |
| `delete_tract_by_length` | `["delete_tract_by_length",20]` | Delete trajectories shorter than a millimeter threshold. |
| `separate_deleted_tract` | `["separate_deleted_tract",0]` | Move deleted trajectories into a new bundle. |
| `reconnect_tract` | `["reconnect_tract",0,"4 30"]` | Reconnect using maximum distance and angle. |

## Statistics and recognition

| Command | Example | Behavior |
|---|---|---|
| `show_tract_statistics` | `["show_tract_statistics"]` | Statistics for checked tracts: text in `output` for AI callers, a modal dialog for a local user. For a connectometry database FIB it adds a `<subject> mean_<metric>` row per subject and stored metric, without a correlational-tractography run (see `DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md`). |
| `save_tract_statistics` | `["save_tract_statistics","C:/output/tract_stat.txt"]` | The same statistics written to the required path for any caller (no dialog, no response text); no path is a usage error. |
| `show_tract_overlap_statistics` | `["show_tract_overlap_statistics",0,"CHA"]` | Voxelize one bundle (omit the index only to use the current tract) and intersect it with every nonempty label of a built-in atlas, **without creating Region rows**; zero-overlap labels are omitted and rows are ordinary region statistics. AI callers must give the exact atlas name (a local user may pick from a dialog). No `save_*` counterpart: capture the returned text. For an arbitrary lesion mask (tumor, edema) use `tract_to_region` instead. |
| `show_tract_recognition` | `["show_tract_recognition",0]` | Ranked atlas matches for one bundle (old form `["show_tract_recognition","",0]` also works); no index: the selected tract, else tract 0. At least one tract must be checked; an empty tract fails with `tract <index> has no tracks`. AI: text in `output`; local user: dialog. |
| `save_tract_recognition` | `["save_tract_recognition","C:/output/tract_names.txt",0]` | The same, written to the required path. |
| `recognize_and_rename_tract` | `["recognize_and_rename_tract"]` | Rename each checked bundle to its top atlas match. |

## Color, values, and clustering

Clustering commands delete the original bundle and replace it with clusters.

| Command | Example | Behavior |
|---|---|---|
| `select_cluster_color` | `["select_cluster_color",0,4294901760]` | Packed Qt ARGB color for one bundle; switches to assigned coloring. |
| `color_all_cluster` | `["color_all_cluster"]` | A distinct generated color for every bundle. |
| `save_tract_color`, `load_tract_color` | `["save_tract_color","C:/output/cst_color.txt",0]` | Save/load per-trajectory colors for one bundle; loading switches to manual coloring. |
| `load_tract_values` | `["load_tract_values","C:/output/cst_values.txt",0]` | One value per visible trajectory; counts must match. |
| `save_cluster_color`, `load_cluster_color` | `["save_cluster_color","C:/output/bundle_colors.txt"]` | One RGB line per checked bundle. |
| `load_cluster_values` | `["load_cluster_values","C:/output/bundle_values.txt"]` | One value per checked bundle; counts must match. |
| `cluster_tract_by_label` | `["cluster_tract_by_label",0,"C:/data/cluster_labels.txt"]` | Clusters from one integer label per visible trajectory. |
| `recognize_and_cluster_tract` | `["recognize_and_cluster_tract",0]` | Split into atlas-recognized bundles. |
| `cluster_tract_by_km`, `cluster_tract_by_em` | `["cluster_tract_by_km",0,"10 0"]` | K-means or expectation-maximization clusters. |
| `cluster_tract_by_hy` | `["cluster_tract_by_hy",0,"50 1.0"]` | Hierarchical clusters plus an `others` bundle. |

## Normalization before atlas work

On a native-space FIB, the first use of the template mapping needs a normalization of a minute or
more: the atlas button and `add_region_from_atlas`, AutoTrack, `enable_auto_tract`, tract
recognition, `load_tract_atlas`, `add_surface` on a built-in slice, `add_mni_slice`, MNI/template
tract open or save, atlas overlap statistics, template masks, and the `vol` metric. In the tracking
window it never blocks: the first such step starts it in the background and returns at once with
`normalization started in the background; try again when it finishes` (a user who clicks a button or
menu item sees this as a message, before any file dialog), later ones return `normalization is running in the background (step N of 4) ...`,
and the window title shows `- normalization N/4` until it ends (`- normalization failed: <reason>`
on failure). A QSDR FIB needs none, and the mapping is saved beside the FIB, so it runs once per FIB.

Start it early: right after opening a native-space FIB that the task will use with atlases,
AutoTrack, or surfaces, run `prepare_mapping` (tell the user it takes about a minute; in a tutorial
ask first, e.g. "The next step lines this brain up with the template, about a minute the first time.
Proceed?" `Yes` `Not now`). Keep teaching or working meanwhile, and poll `prepare_mapping check`
until `ready` before the step that needs it; on `failed`, report the reason.

## ROI settings syntax

`&`-separated `region-index:role` entries, e.g. `0:3&1:0&2:1`. Roles: `0=ROI`, `1=ROA`, `2=End`,
`3=Seed`, `4=Terminative`, `5=NotEnd`, `6=Limiting`. Run `list_region` immediately before building
the string; the listed rows are used directly and need not be checked. Named AutoTrack bundles
usually need none.

## Workflow notes

- **Differential state.** `run_tracking` clears leftover differential state when `dt_index1` and
  `dt_index2` are both `0`, so it never silently reuses an earlier `run_dif_tracking`. If they are
  nonzero but never applied (e.g. `set_param` without `run_dif_tracking`/`set_dt_index`),
  `run_tracking` fails and suggests `run_dif_tracking`.
- **Completion.** `list_tract` row statuses are the definitive completion signal; `list_tract status`
  gives only the aggregate flag.
- **`run_command_history`.** Build the pipeline once against one subject with ordinary commands
  (`open_fib`, `run_tracking`, `save_tract`, ...), check it with `list_history`, then replay. It fails
  if nothing is recorded or no selected command is a `load_`/`open_` command. Called by an agent, it
  logs and skips a missing/failed file instead of opening a dialog.

## Bundle cleanup

TIP pruning is for a visually coherent bundle (AutoTrack, loaded, or recognized). A sufficiently
populated one (roughly 5,000–10,000+ tracts) normally wants 3–4 iterations: AutoTrack applies them via
`tip_iteration`; for an existing bundle call `trim_tract` one iteration at a time. Do not use
`trim_tract`, `delete_repeated_tract`, or TIP as generic cleanup of whole-brain tractography, which
contains many pathways, or of sparse bundles.

## Longitudinal and voxelization caution

`tract_to_region` depends on the current slice grid, voxel size, registration, and sampled geometry,
so the same bundle can yield different voxel counts across sessions. Use the tract-region volume
mainly as a **within-session denominator** for overlap fractions, and record the current slice and
the region's dimensions/resolution when quantitative. A pre/post change in absolute tract-derived
volume, or in `show_tract_statistics` volume/surface area, is descriptive, not direct tract loss or
gain, unless acquisition, reconstruction, registration, tracking parameters, spatial definition, and
QC are controlled. State these limits in longitudinal reports and favor concordant anatomical and
overlap findings over an isolated volume change.

## Tracking parameters

Use live discovery rather than assumed defaults:

```json
["list_param","tracking"]
["list_param","fa_threshold"]
["set_param","fa_threshold",0.08]
["set_params","fa_threshold=0.08&min_length=20&turning_angle=60"]
["get_parameter_id"]
["load_parameter_id","<parameter id>"]
```

`list_param tracking` returns current values from the basic, differential, and advanced groups
(metric lists depend on the loaded FIB). `get_parameter_id` prints the compact ID encoding the
current settings (the code in the methods text); `command[1]` is `include_tip` (default `1` keeps
`tip_iteration`; `0` gives the regular non-AutoTrack form, still with TIP when differential tracking
is active). `load_parameter_id` applies an ID in one step (inverse of `get_parameter_id`; malformed
IDs are not validated; AI callers must supply it or get a usage error).

Common IDs: `tracking_index`, `fa_threshold`, `turning_angle`, `step_size`, `min_length`,
`max_length`, `max_seed_count`, `max_tract_count`, `track_voxel_ratio`, `tip_iteration`, `tolerance`,
`dt_index1`, `dt_index2`, `dt_threshold_type`, `dt_threshold`, `tracking_method`, `smoothing`,
`check_ending`, `otsu_threshold`, `track_format`.
