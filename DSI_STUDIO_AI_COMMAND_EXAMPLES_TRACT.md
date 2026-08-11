# DSI Studio AI Tract Command Examples and Inventory

Use these with a `tracking<hex-address>` window. Select it once before sending
any command below:

```bash
bash ./dsi.sh set_window tracking<hex-address>
```

The selection persists for the session until changed by another `set_window` call.
Command names and text, path, or composite parameters are strings. Send standalone
numeric parameters as JSON numbers.

This file contains tract and automatic-tracking commands confirmed in the current source. Earlier generic inventory names that had no command handler were removed only after checking the GL, tract, region, device, and tracking dispatch chain.

| Command | Common example | Important behavior |
|---|---|---|
| `list_tract` | `["list_tract"]` | List every tract bundle with `index`, readable `status`, shown state, name, tract count, deleted count, and seeds. |
| `list_tract status` | `["list_tract","status"]` | Return compact `status` and total bundle count. `status=done` means no tracking thread remains active. |
| `run_tracking` | `["run_tracking","Whole Brain"]` | Start asynchronous tracking with the current tracking parameters and checked region settings; `command[1]` is the mandatory new bundle name. |
| `run_tracking` | `["run_tracking","CST","0:3&1:0"]` | Start tracking with explicit region settings: region 0 as Seed and region 1 as ROI. The third element uses `index:type` entries separated by `&`. See **ROI settings syntax** and footnote 2. |
| `list_auto_tract` | `["list_auto_tract"]` | List valid hierarchical automatic tract names. Use a parent entry for the whole tract family and a child only for a requested subdivision; e.g. `Association_CingulumL` maps the full left cingulum rather than one `Association_CingulumL_...` branch. |
| `run_auto_track` | `["run_auto_track","ProjectionBrainstem_CorticospinalTractL"]` | Use an exact name from `list_auto_tract`; never guess atlas labels. For a whole hierarchical tract family, use its parent entry (similarly for cingulum and corpus callosum). Standard coherent bundles generally use about 10,000 tracts with TIP 3–4 when sufficiently populated. |
| `run_auto_track` | `["run_auto_track","ProjectionBrainstem_CorticospinalTractL","0:0&1:1"]` | Explicit extra ROI/ROA constraints are supported but are not the standard AutoTrack workflow because named AutoTrack entries already carry built-in anatomical constraints. Add them only for a specific need, such as isolating a minor branch. |
| `list_history` | `["list_history"]` | List every command recorded so far in this window's session with its `index`, in order. Use this before `run_command_history` to see what would be replayed and to pick which index range(s) to use. |
| `run_command_history` | `["run_command_history","C:/data/subjects"]` | Batch-replay every command recorded so far in this window's session (opens, tracking, saves, etc.) once per file found in the folder, substituting each file into the recorded load step and remapping related load/save filenames. Record the pipeline once against one subject with ordinary commands, then call this to apply it across a folder. |
| `run_command_history` | `["run_command_history","C:/data/s1.fz&C:/data/s2.fz"]` | Same, but against an explicit `&`-joined file list instead of a folder. |
| `run_command_history` | `["run_command_history","C:/data/subjects","2:5"]` | Replay only commands at `list_history` indices 2 through 5 (inclusive), not the whole recorded history. A single index (e.g. `"3"`) replays just that one command. |
| `run_command_history` | `["run_command_history","C:/data/subjects","0:1&12:15&16"]` | Multiple `&`-joined ranges/single indices, replayed in the order given: commands 0-1, then 12-15, then 16. Use this to skip noise (e.g. incidental status checks) recorded between the steps that actually matter. |
| `show_only_tracts` | `["show_only_tracts","0&2&5"]` | Show only listed `&`-separated tract indices and hide all others. |
| `enable_auto_tract` | `["enable_auto_tract"]` | Load the symmetric tract atlas and enable automatic-tract controls. |
| `open_tract` | `["open_tract","C:/output/cst.tt.gz"]` | Open one native-space tract file and show each loaded bundle. Open multiple files by sending one command per path. |
| `open_tract` | `["open_tract","C:/output/all_bundles.tt.gz",0]` | Open the tract file with newly loaded bundles unchecked/hidden. The source tests only whether the third element is empty; any supplied value has this effect. |
| `open_mni_tract` | `["open_mni_tract","C:/data/cst_mni.tt.gz"]` | Open an MNI-space tract and map it into the current subject. |
| `open_tract_name` | `["open_tract_name","C:/data/tract_names.txt"]` | Load whitespace-separated names and apply them in reverse order to the most recently listed tract rows. |
| `load_tract_atlas` | `["load_tract_atlas","Corticospinal_Tract"]` | Load one named population tract-atlas bundle. |
| `load_tract_atlas` | `["load_tract_atlas"]` | Load every tract name from the asymmetric tract atlas; this may create many bundles. |
| `save_tract` | `["save_tract","C:/output/cst.tt.gz",0]` | Save one completed tract bundle by index. |
| `save_mni_tract` | `["save_mni_tract","C:/output/cst_mni.tt.gz",0]` | Save one tract in MNI coordinates. |
| `save_template_tract` | `["save_template_tract","C:/output/cst_template.tt.gz",0]` | Save one tract in loaded template space. |
| `save_slice_tract` | `["save_slice_tract","C:/output/cst_T1w.tt.gz",0]` | Save one tract in current slice space. |
| `save_tract_endpoint` | `["save_tract_endpoint","C:/output/cst_endpoints.txt",0]` | Save native-space endpoints for one tract bundle index. |
| `save_mni_tract_endpoint` | `["save_mni_tract_endpoint","C:/output/cst_mni_endpoints.txt",0]` | Intended to save endpoints in MNI coordinates, but the current implementation is unreliable. See footnote 1. |
| `save_slice_tract_endpoint` | `["save_slice_tract_endpoint","C:/output/cst_T1w_endpoints.txt",0]` | Intended to save endpoints in current slice space, but the current implementation is unreliable. See footnote 1. |
| `save_all_tracts` | `["save_all_tracts","C:/output/checked_tracts.tt.gz"]` | Save all checked tracts together. |
| `save_all_tracts_to_folder` | `["save_all_tracts_to_folder","C:/output/tracts"]` | Save checked tracts as separate files in a folder. |
| `save_tdi` | `["save_tdi","C:/output/cst_tdi.nii.gz",0]` | Save tract-density imaging output in current slice space. |
| `save_tdi2` | `["save_tdi2","C:/output/cst_tdi_2x.nii.gz",0]` | Save the alternate two-times-resolution tract-density output. |
| `save_tract_values` | `["save_tract_values","C:/output/cst_qa.txt",0,"qa"]` | Save the named metric along one tract bundle; arguments are filename, tract index, and metric name. |
| `tract_to_region` | `["tract_to_region",0]` | Convert tract trajectories to a region. |
| `endpoint_to_region` | `["endpoint_to_region",0]` | Convert tract endpoints to region(s). |
| `update_tract` | `["update_tract"]` | Refresh counts and rendering for tract bundles. |
| `delete_tract` | `["delete_tract","0&2&5"]` | Delete one or more tract bundles. Use one index or an `&`-separated index list; omit the index to use the current row. |
| `delete_all_tracts` | `["delete_all_tracts"]` | Delete all tract bundles. |
| `copy_tract` | `["copy_tract",0]` | Duplicate one tract bundle. |
| `merge_all_tracts` | `["merge_all_tracts"]` | Merge all checked tract bundles into the first checked row. |
| `merge_tract_by_name` | `["merge_tract_by_name"]` | Merge tract bundles sharing an identical name. |
| `sort_tract_by_name` | `["sort_tract_by_name"]` | Sort tract bundles by name. |
| `delete_branch` | `["delete_branch","0&2"]` | Delete branch-like portions from tract bundles 0 and 2. Omit the index list to edit every checked bundle. |
| `undo_tract` | `["undo_tract","0&2"]` | Undo the latest supported tract edit in tract bundles 0 and 2. Omit the index list to use checked bundles. |
| `redo_tract` | `["redo_tract","0&2"]` | Redo the latest supported tract edit in tract bundles 0 and 2. Omit the index list to use checked bundles. |
| `trim_tract` | `["trim_tract",0]` | Apply one TIP iteration to tract bundle 0. Omit the index to use every checked bundle. Use for a sufficiently populated visually coherent bundle, including a loaded bundle; do not use as generic whole-brain cleanup. |
| `cut_tract_end_portion` | `["cut_tract_end_portion",0]` | Apply `cut_end_portion(0.25,0.75)` to tract bundle 0. |
| `cut_tract_lps_end` | `["cut_tract_lps_end",0]` | Apply `cut_end_portion(0.25,1.0)` to tract bundle 0. |
| `cut_tract_rai_end` | `["cut_tract_rai_end",0]` | Apply `cut_end_portion(0.0,0.75)` to tract bundle 0. |
| `flip_tract_x` | `["flip_tract_x",0]` | Flip tract bundle 0 along X. |
| `flip_tract_y` | `["flip_tract_y",0]` | Flip tract bundle 0 along Y. |
| `flip_tract_z` | `["flip_tract_z",0]` | Flip tract bundle 0 along Z. |
| `cut_tract_by_x` | `["cut_tract_by_x",80]` | Cut every checked bundle at X slice 80 and retain the default side. |
| `cut_tract_by_x2` | `["cut_tract_by_x2",80]` | Cut every checked bundle at X slice 80 and retain the opposite side. |
| `cut_tract_by_y` | `["cut_tract_by_y",100]` | Cut every checked bundle at Y slice 100 and retain the default side. |
| `cut_tract_by_y2` | `["cut_tract_by_y2",100]` | Cut every checked bundle at Y slice 100 and retain the opposite side. |
| `cut_tract_by_z` | `["cut_tract_by_z",80]` | Cut every checked bundle at Z slice 80 and retain the default side. |
| `cut_tract_by_z2` | `["cut_tract_by_z2",80]` | Cut every checked bundle at Z slice 80 and retain the opposite side. |
| `set_dt_index` | `["set_dt_index","qa&iso",0]` | Set differential metrics `m1&m2` and calculation type; creates the `dT_metrics` slice the first time. Also syncs `dt_index1`/`dt_index2` to the resolved metrics. |
| `run_dif_tracking` | `["run_dif_tracking","CST_dT"]` | Differential-tracking counterpart to `run_tracking`. Resolves the current `dt_index1`/`dt_index2` into `set_dt_index`, then tracks; fails if both are still `0`. Always use this (not `run_tracking`) to launch a differential-tracking run, whichever route configured `m1`/`m2`. `command[2]` accepts the same explicit ROI settings as `run_tracking`. |
| `filter_tract` | `["filter_tract","0:3&1:0"]` | Filter every checked tract using region 0 as Seed and region 1 as ROI. The argument uses the same `index:type` encoding as tracking. |
| `check_tract` | `["check_tract",0,1]` | Set one tract's checked state. |
| `check_uncheck_all_tract` | `["check_uncheck_all_tract",1]` | Check/uncheck all tracts; explicit `1` or `0` is preferred. |
| `select_cluster_color` | `["select_cluster_color",0,4294901760]` | Set one bundle to a packed Qt ARGB color and switch to assigned coloring. |
| `show_tract_statistics` | `["show_tract_statistics"]` | Compute statistics for checked tracts. AI callers get the text directly in `output`; a local user instead sees it in a modal dialog. If the opened FIB is a connectometry database, it also adds one `<subject> mean_<metric>` row per subject per stored metric along the checked tract, without needing a full correlational-tractography run — see `DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md`. |
| `save_tract_statistics` | `["save_tract_statistics","C:/output/tract_stat.txt"]` | Same statistics as `show_tract_statistics`, but always written to the given path (no dialog, no direct-response text), for any caller. The path is required — a bare `save_tract_statistics` with no path fails with a usage error. |
| `show_tract_recognition` | `["show_tract_recognition","",0]` | Recognize tract index 0 and return ranked atlas matches; at least one tract must be checked. AI callers get the text directly in `output`; a local user instead sees it in a modal dialog. |
| `save_tract_recognition` | `["save_tract_recognition","C:/output/tract_names.txt",0]` | Same as `show_tract_recognition`, but always written to the given path, for any caller. The path is required. |
| `save_tract_color` | `["save_tract_color","C:/output/cst_color.txt",0]` | Save per-trajectory colors for one tract bundle. |
| `load_tract_color` | `["load_tract_color","C:/output/cst_color.txt",0]` | Load per-trajectory colors and switch to manual tract coloring. |
| `load_tract_values` | `["load_tract_values","C:/output/cst_values.txt",0]` | Load one value per visible trajectory; counts must match. |
| `save_cluster_color` | `["save_cluster_color","C:/output/bundle_colors.txt"]` | Save one RGB line per checked bundle. |
| `load_cluster_color` | `["load_cluster_color","C:/output/bundle_colors.txt"]` | Load one RGB line per checked bundle. |
| `load_cluster_values` | `["load_cluster_values","C:/output/bundle_values.txt"]` | Load one value per checked bundle; counts must match. |
| `color_all_cluster` | `["color_all_cluster"]` | Assign a generated distinct color to every bundle. |
| `cluster_tract_by_label` | `["cluster_tract_by_label",0,"C:/data/cluster_labels.txt"]` | Replace one bundle with clusters defined by one integer label per visible trajectory. |
| `recognize_and_cluster_tract` | `["recognize_and_cluster_tract",0]` | Replace one bundle with tract-atlas-recognized bundles. |
| `cluster_tract_by_km` | `["cluster_tract_by_km",0,"10 0"]` | Replace one bundle with k-means clusters. |
| `cluster_tract_by_em` | `["cluster_tract_by_em",0,"10 0"]` | Replace one bundle with expectation-maximization clusters. |
| `cluster_tract_by_hy` | `["cluster_tract_by_hy",0,"50 1.0"]` | Replace one bundle with hierarchical clusters and create an `others` bundle. |
| `delete_repeated_tract` | `["delete_repeated_tract",1]` | Delete repeated trajectories in every checked bundle using a 1-voxel distance threshold. Recommend only for a coherent named/loaded bundle; skip routine use for whole-brain tractography and sparse bundles. |
| `resample_tract` | `["resample_tract",0.5]` | Resample checked bundles using a step size in voxels. |
| `delete_tract_by_length` | `["delete_tract_by_length",20]` | Delete trajectories shorter than the supplied millimeter threshold from checked bundles. |
| `separate_deleted_tract` | `["separate_deleted_tract",0]` | Move deleted trajectories into a new bundle. |
| `reconnect_tract` | `["reconnect_tract",0,"4 30"]` | Reconnect trajectories using a maximum distance and angle. |
| `recognize_and_rename_tract` | `["recognize_and_rename_tract"]` | Recognize each checked bundle and rename it to the top atlas match. |

## `list_tract` output

```text
index    status    shown    name    tracts    deleted    seeds
```

Each row's `status` is `running` or `done`. Compact status returns:

```text
status    bundles
```

`bundles` is the total number of tract rows, not the number of running jobs. Poll
`["list_tract","status"]` until `status=done` before a dependent operation.

## Tract-index selection for edit commands

Call `["list_tract"]` immediately before an indexed edit. These commands accept
one numeric index or one `&`-separated index list:

```json
["delete_tract","0&2&5"]
["delete_branch","0&2&5"]
["undo_tract","0&2&5"]
["redo_tract","0&2&5"]
["trim_tract","0&2&5"]
```

With no index, `delete_tract` uses the current row; the other commands operate on
checked bundles. `cut_tract_by_*`, `filter_tract`, `delete_repeated_tract`,
`resample_tract`, and `delete_tract_by_length` use their second element for
another parameter and always operate on checked bundles.

## ROI settings syntax

Tracking and filtering accept an `&`-separated list of `region-index:role` entries:

```text
0:3&1:0&2:1
```

Roles are `0=ROI`, `1=ROA`, `2=End`, `3=Seed`, `4=Terminative`, `5=NotEnd`, and
`6=Limiting`. Use `list_region` immediately before constructing the string.
Explicit settings use the supplied rows directly and do not require them to be
checked.

For named AutoTrack bundles, these explicit region settings are usually unnecessary
because AutoTrack already has built-in anatomical constraints. Add extra regions only
for a specific anatomical purpose, such as isolating a minor branch.

## Bundle cleanup

TIP pruning is for a visually coherent tract bundle, including AutoTrack and
previously loaded or recognized bundle results. If such a bundle is sufficiently
populated (roughly 5,000–10,000 or more tracts), 3–4 TIP iterations are normally
desired. AutoTrack can apply them automatically through `tip_iteration`; for an
already loaded/generated bundle, use `trim_tract` one iteration at a time as needed.

Do not routinely use `trim_tract` or `delete_repeated_tract` for whole-brain
tractography, which contains many pathways rather than one coherent visual bundle.
Do not use TIP as generic tract-count cleanup.

`delete_repeated_tract` always operates on checked bundles; its first parameter
is a distance threshold, not a tract index.

## Tracking workflow notes

- `run_tracking` requires a nonempty bundle name.
- The two-element form uses current parameters and checked regions.
- The three-element form accepts explicit ROI settings when the third string is empty or contains `:`.
- `run_tracking` clears any leftover differential-tracking state whenever `dt_index1` and `dt_index2` are both `0`, so a plain tracking run never silently reuses metrics from an earlier `run_dif_tracking`. Use `run_dif_tracking` for a differential run instead of `run_tracking`.
- If `dt_index1`/`dt_index2` are nonzero but were never applied (e.g. `set_param` was used without a following `run_dif_tracking`/`set_dt_index`), `run_tracking` fails with an error suggesting `run_dif_tracking`, instead of silently tracking without the differential metrics.
- Tracking is asynchronous; `status=done` from `list_tract status` is definitive completion.
- `run_command_history` fails if this window's session has no recorded commands yet, or if none of the *selected* commands is a `load_`/`open_` command (there is nothing to substitute a new file into). Build the pipeline first with ordinary commands (`open_fib`, `run_tracking`, `save_tract`, ...) against one subject, then call `list_history` to check exactly what was recorded, then `run_command_history` to replay it -- all of it, a single `from:to` range, or several `&`-joined ranges/indices (e.g. `"0:1&12:15&16"`) to skip noise recorded in between. It never pops a dialog for a missing/failed file when called by an agent; it logs and skips that file instead of blocking.
- AutoTrack names are hierarchical: use a parent entry for the whole tract family and a child only for a requested subdivision or branch.
- Clustering commands delete the original bundle and replace it with clusters.
- Confirm deleting, trimming, cutting, clustering, reconnecting, and merging.
- Removed generic names with no handler must not be used; copy exact commands from this file.

## Tracking parameters

Use live discovery rather than assuming resource defaults:

```json
["list_param","tracking"]
["list_param","fa_threshold"]
["set_param","fa_threshold",0.08]
["set_params","fa_threshold=0.08&min_length=20&turning_angle=60"]
```

`list_param tracking` returns current values from the basic, differential, and
advanced tracking groups. Metric lists may depend on the loaded FIB.

Common parameter IDs include `tracking_index`, `fa_threshold`, `turning_angle`,
`step_size`, `min_length`, `max_length`, `max_seed_count`, `max_tract_count`,
`track_voxel_ratio`, `tip_iteration`, `tolerance`, `dt_index1`, `dt_index2`,
`dt_threshold_type`, `dt_threshold`, `tracking_method`, `smoothing`,
`check_ending`, `otsu_threshold`, and `track_format`.

## Footnotes

1. The current transformed-endpoint implementations should not be relied on.
   `save_slice_tract_endpoint` falls through to native endpoint saving, and
   `save_mni_tract_endpoint` appends native coordinates before the same fallthrough.
2. `run_tracking` appends the new bundle/thread before validating explicit ROI
   settings. Validate every region index and role with `list_region` first.