# DSI Studio AI Region Command Examples and Inventory

Complete region inventory confirmed in the current source. Use these in a `tracking<hex-address>`
window, selected once with `bash ./dsi.sh set_window tracking<hex-address>` (it persists until
changed). Names and text, path, or composite parameters are strings; send a single index or number
as a JSON number and keep an `&`-separated list as a string. Discover indices and roles with
`list_region` before mutating, and confirm deletion, merging, overwrite, and mask replacement.

## Inventory

| Command | Example | Behavior |
|---|---|---|
| `list_region` | `["list_region"]` | Index, visibility, name, type, color, dimensions, and resolution. |
| `list_atlas` | `["list_atlas"]`, `["list_atlas","<atlas name or index>"]` | Without an argument, every atlas of the *current* template (index, name, region count); with an atlas name or index from that list, its region indices and names. Never guess labels from another source. |
| `add_region_from_atlas` | `["add_region_from_atlas","0 2 5&6"]`, `["add_region_from_atlas","0 2"]` | Add labels 5 and 6 of atlas 2 of template 0 (discover label IDs with `list_atlas` first), or, in the two-element form, every label of that atlas without label IDs. It changes the active template ID first. |
| `set_region_name` | `["set_region_name",0,"Tumor Core"]` | Rename a region. |
| `set_region_type` | `["set_region_type",0,3]` | Role: `0=ROI`, `1=ROA`, `2=End`, `3=Seed`, `4=Terminative`, `5=NotEnd`, `6=Limiting`. |
| `set_region_color` | `["set_region_color",0,4294901760]` | Packed Qt ARGB color. |
| `show_only_regions` | `["show_only_regions","0&3&5"]` | Check/show only the listed regions, unchecking/hiding the rest; this selects the rows for checked-region operations such as `show_region_statistics`. |
| `check_region` | `["check_region","0&2&5",1]` | Set the checked/shown state (`1` check/show, `0` uncheck/hide) of one index or a list; an empty index uses the current row. |
| `check_all_regions`, `uncheck_all_regions` | `["check_all_regions"]` | Check/show or uncheck/hide all regions. |
| `new_region` | `["new_region"]` | Empty region in current slice space. |
| `new_region_whole_brain_seed` | `["new_region_whole_brain_seed"]`, `["new_region_whole_brain_seed",0.6]` | Whole-brain seed at the current `otsu_threshold` parameter × the FIB FA Otsu threshold, or at an explicit Otsu ratio (`0.6`) regardless of the setting. |
| `new_region_from_threshold` | `["new_region_from_threshold",0.6]` | Append a region, then call `region_action_threshold` on the current slice. If threshold selection is canceled or fails, the empty region remains; unattended, give an explicit threshold and verify with `list_region`. |
| `new_region_from_mni`, `new_region_from_sphere` | `["new_region_from_mni","0 -10 21 5"]`, `["new_region_from_sphere","80 100 80 5"]` | Spherical region from MNI or image-space coordinates and a voxel radius. |
| `open_region` | `["open_region","C:/data/seed.nii.gz"]` | Open one native-space region file, or a multi-label NIfTI in one command. |
| `open_mni_region` | `["open_mni_region","C:/data/atlas_roi.nii.gz"]` | Map to MNI space, then load the file into subject space. |
| `save_region` | `["save_region","C:/output/seed.nii.gz",0]` | Save one region; an unsupported or missing extension gets `.nii.gz` appended. |
| `save_4d_region` | `["save_4d_region","C:/output/regions_4d.nii.gz"]` | Checked regions as a 4D NIfTI plus companion label file. |
| `save_all_regions` | `["save_all_regions","C:/output/regions.nii.gz"]` | Checked regions as one 3D label NIfTI. |
| `save_all_regions_to_folder` | `["save_all_regions_to_folder","C:/output/regions"]` | Each checked region as a separate file in the current ROI output format. |
| `save_region_info` | `["save_region_info","C:/output/seed_info.txt",0]` | Coordinates, fiber directions, and quantitative values of one region. |
| `load_region_color` | `["load_region_color","C:/data/region_colors.txt"]` | Positional or name-keyed colors. Positional: one nonblank row per current region in table order, consistently 3 (RGB, alpha 255) or 4 (RGBA) integers separated by spaces or tabs. TSV: `region name<TAB>R<TAB>G<TAB>B<TAB>A`, naming every region exactly once. Channels must be 0-255; mixed formats, malformed counts or values, and unknown, duplicate, or missing names fail before any color changes. |
| `save_region_color` | `["save_region_color","C:/output/region_colors.txt"]` | One RGBA line per region in table order. |
| `delete_region` | `["delete_region","0&2&5"]` | Delete one region or a list; omitted index: the current row. |
| `delete_all_regions` | `["delete_all_regions"]` | Delete all regions. |
| `copy_region` | `["copy_region",0]` | Duplicate a region and insert the copy right after it; every later index shifts, so run `list_region` again. |
| `merge_regions` | `["merge_regions","0&1&2"]`, `["merge_regions"]` | Merge the listed regions into the first and remove the others; without a list, merge the checked regions (at least two) into the first checked. |
| `move_up_region`, `move_down_region` | `["move_up_region",3]` | Move one region up or down in table order. |
| `move_region` | `["move_region","80 100 80",3]` | Center the region at the location, in that region's space; an empty region succeeds without moving. |
| `move_slice_to_region` | `["move_slice_to_region",3]` | Move the slice crosshairs to a region center. |
| `show_region_statistics` | `["show_region_statistics"]` | Statistics of checked regions: text in `output` for AI callers, a modal dialog for a local user. On a connectometry database FIB it adds one `<subject> mean_<metric>` row per subject per stored metric, without a correlational-tractography run (`DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md`). |
| `save_region_statistics` | `["save_region_statistics","C:/output/region_stat.txt"]` | The same, always written to the required path for any caller (no dialog, no response text); a bare call fails with a usage error. |
| `show_region_overlap_statistics` | `["show_region_overlap_statistics",3,"CHA"]` | Intersect one region (`command[1]`; omit only to use the current row on purpose) with every nonempty label of a built-in atlas **without changing the Region table**. AI/Internal callers must give the exact atlas name (`command[2]`, not a runtime index); a local user may pick it in a dialog. Each nonempty label becomes a column (zero-overlap labels omitted; the source region is not a column), with ordinary region-statistics rows. No `save_*` counterpart exists: capture the returned text. |
| `show_t2r` | `["show_t2r"]` | Tract-to-region connectivity of the checked tracts and regions: text in `output` for AI callers, a modal dialog for a local user. |
| `save_t2r` | `["save_t2r","C:/output/tract_to_region.txt"]` | The same, written to the required path for any caller. |
| `open_connectivity_matrix` | `["open_connectivity_matrix","C:/output/sub01.connectivity.mat"]` | Load a region-to-region matrix for 3D graph display (the GUI's Visualize Graph). AI callers must give an existing `.mat` or `.txt` file (any case), else a usage or `cannot find` error. A `.mat` needs a square matrix named `connectivity`; if it also names a built-in `atlas` (not `roi`) with a matching label count, all regions are replaced by that atlas's regions. A `.txt` holds a whitespace-separated square matrix. Its size must equal the region count. On success `region_graph` turns on, all regions are checked, and AI callers get one line, e.g. `connectivity matrix 116x116 loaded (values -0.21 to 0.84); graph display enabled` (the full matrix goes only to a local user's log). Inspect with `preview_screen 3d` or a screenshot. |

## `region_action_<operation>`

`command[1]` is one region index or an `&`-separated list, used in the supplied order regardless of
checked/shown state. When it is omitted for an `all` or `sort` action, the checked/shown regions are
used in table-index order. An additional threshold or voxel radius goes in `command[2]`.

| Command | Example | Behavior |
|---|---|---|
| `region_action_shiftx`, `region_action_shiftnx`, `region_action_shifty`, `region_action_shiftny`, `region_action_shiftz`, `region_action_shiftnz` | `["region_action_shiftx",0]` | Shift by +1 or -1 (`n`) voxel in X, Y, or Z. |
| `region_action_flipx`, `region_action_flipy`, `region_action_flipz` | `["region_action_flipx",0]` | Flip along X, Y, or Z. |
| `region_action_smoothing`, `region_action_erosion`, `region_action_dilation`, `region_action_opening`, `region_action_closing` | `["region_action_smoothing",0]` | Morphological smoothing, erosion, dilation, opening, or closing. |
| `region_action_defragment` | `["region_action_defragment",0]` | Keep the principal connected component. |
| `region_action_negate` | `["region_action_negate",0]` | Invert the mask. |
| `region_action_dilation_by_voxel` | `["region_action_dilation_by_voxel",0,2]` | Dilate by a radius of 2 voxels. |
| `region_action_threshold` | `["region_action_threshold",0,0.6]` | Replace the region with the current-slice mask above `0.6`; a negative threshold selects the low-pass side. |
| `region_action_threshold_current` | `["region_action_threshold_current",0,0.6]` | Keep only existing voxels above `0.6`. |
| `region_action_dilation_by_threshold`, `region_action_erosion_by_threshold` | `["region_action_dilation_by_threshold",0,0.6]` | Grow or shrink the region using the current slice and threshold `0.6`. |
| `region_action_separate` | `["region_action_separate",0]` | Split into connected-component regions. |
| `region_action_sort_name`, `region_action_sort_x`, `region_action_sort_y`, `region_action_sort_z`, `region_action_sort_size` | `["region_action_sort_name","0&1&2"]` | Sort the rows by name (repeating reverses the order), X, Y, or Z position, or volume. |
| `region_action_1st_ex_all` | `["region_action_1st_ex_all","0&1&2"]` | Subtract regions 1 and 2 from region 0. |
| `region_action_all_ex_1st` | `["region_action_all_ex_1st","0&1&2"]` | Subtract region 0 from regions 1 and 2. |
| `region_action_all_inter_1st` | `["region_action_all_inter_1st","0&1&2"]` | Keep the first region and replace each later one in place with its intersection with the first, which defines the output dimensions and transform. Prefer an explicit ordered list with the defining region first; use disposable copies to keep originals. |
| `region_action_all_to_1st` | `["region_action_all_to_1st","0&1&2"]` | Assign and smooth later labels within the first region. |
| `region_action_refine_all` | `["region_action_refine_all","0&1&2"]` | Refine all supplied labels with the current slice intensity image. |

For statistics-only overlap with a built-in atlas, prefer
`show_region_overlap_statistics <region-index> <atlas-name>`: it maps atlas labels into the source
region's space, reports only nonempty intersections, and creates no rows. Use `add_region_from_atlas`
with explicit region operations only when atlas region objects are needed for visualization,
editing, tracking constraints, or downstream mask operations.

## Region Window parameters

These are the `ROI` parameters of the embedded `:/data/options.txt` resource. Check live values with
`list_param` first; `set_param` takes numbers as JSON numbers, `set_params` one combined string. Enum
values are zero-based.

```json
["list_param","roi_zoom"]
["set_param","roi_zoom",5.0]
["set_params","roi_zoom=5.0&roi_opacity=0.8&roi_draw_edge=1"]
```

| Parameter ID | UI setting | Accepted value | Default |
|---|---|---|---|
| `orientation_convention` | Orientation Convention | `0`=Radiology; `1`=Neurology | `0` (Radiology) |
| `roi_zoom` | Zoom | float `0.2–40`; step `0.5` | `5.0` |
| `roi_draw_edge` | Draw Edge | `0`=Off; `1`=On | `0` (Off) |
| `roi_composition` | Composition | `0`=SourceAtop; `1`=DestinationAtop; `2`=Xor; `3`=Plus; `4`=Multiply; `5`=Screen; `6`=Overlay; `7`=Darken; `8`=Lighten; `9`=ColorDodge; `10`=ColorBun; `11`=HardLight; `12`=SoftLight; `13`=Difference; `14`=Exclusion | `0` (SourceAtop) |
| `roi_opacity` | Opacity | float `0–1`; step `0.1` | `1` |
| `roi_edge_width` | Edge Width | integer `1–5`; step `1` | `1` |
| `roi_track` | Show Tracts | `0`=Off; `1`=On | `1` (On) |
| `roi_track_count` | Visible Tracts Count | integer `1000–500000`; step `1000` | `5000` |
| `roi_fiber` | Fiber Direction | `0`=Off; `1`=On; `2`=1st; `3`=2nd | `1` (On) |
| `roi_fiber_color` | Fiber Color | `0`=RGB; `1`=red; `2`=green; `3`=blue | `0` (RGB) |
| `roi_fiber_width` | Fiber Width | float `0.1–1`; step `0.1` | `0.2` |
| `roi_fiber_length` | Fiber Length | float `0.1–4`; step `0.1` | `2.0` |
| `roi_fiber_antialiasing` | Fiber Antialiasing | `0`=Off; `1`=On | `0` (Off) |
| `roi_label` | "R" label | `0`=Off; `1`=On | `1` (On) |
| `roi_position` | Position Line | `0`=Off; `1`=On | `1` (On) |
| `roi_ruler` | Ruler | `0`=Off; `1`=On | `1` (On) |
| `roi_tic` | Ruler Tic | integer `1–8`; step `1` | `2` |
| `roi_layout` | Slice Layout | `0`=Single Slice; `1`=3 Slices; `2`=Mosaic; `3`=Mosaic 2; `4`=Mosaic 3; `5`=Mosaic 4; `6`=Mosaic 5; `7`=Mosaic 6; `8`=Mosaic 7; `9`=Mosaic 8; `10`=Mosaic 9; `11`=Mosaic 10 | `0` (Single Slice) |
| `roi_mosaic_column` | Mosaic Column Number | integer `0–30`; step `5` | `0` |
| `roi_mosaic_skip_row` | Mosaic Skip Row | integer `0–10`; step `1` | `1` |
| `roi_format` | Default Output Format | `0`=nii.gz; `1`=mat; `2`=txt | `0` (nii.gz) |
