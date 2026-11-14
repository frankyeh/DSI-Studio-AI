# DSI Studio AI Rendering Command Examples and Inventory

Rendering, camera, surface, and display commands confirmed in the current source (generic rows with
no handler were removed after checking the full tracking-window dispatch chain). Use these in a
`tracking<hex-address>` window, selected once with `bash ./dsi.sh set_window tracking<hex-address>`
(it persists until changed). Names and text, path, or composite parameters are strings; send
standalone numbers as JSON numbers.

## Camera and view

| Command | Example | Behavior |
|---|---|---|
| `rotate` | `["rotate","15 1 0 0"]` | Rotate by degrees around axis `x y z`. |
| `rotate_view` | `["rotate_view","left",15]` | Rotate by `command[2]` degrees: `"left"`/`"right"` yaw around the vertical axis, `"up"`/`"down"` pitch around the horizontal axis; easier than `rotate` when the exact axis doesn't matter. The direction-to-sign mapping is not empirically re-verified: test a small angle with `preview_screen 3d` before a large rotation. |
| `set_view` | `["set_view",0,0]` | Reset to view `0`, `1`, or `2` (others rejected); `command[2]` `0` unflipped, `1` flipped. **Always pass it for scripted views**: omitted, the flip state toggles on each call. |
| `set_zoom` | `["set_zoom",1.5]` | Absolute zoom (from the transformation-matrix determinant); zero is rejected. |
| `set_camera` | `["set_camera","1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"]` | Replace the camera matrix with the first 16 floats (at least 16 required; extras ignored). |
| `get_camera` | `["get_camera"]` | Print `view_direction`, `view_position (voxel)`, `image_left`, and `image_up`; the last two are the subject LPS directions at the screen's left and top (from the inverse camera matrix), so rolled or oblique views can be verified without pixels. |
| `save_camera`, `open_camera` | `["save_camera","C:/work/camera.txt"]` | Save the raw round-trippable 16-float matrix; load one from a file (at least 16 floats). |
| `store_camera`, `store_camera1`, `store_camera2` | `["store_camera"]` | Store the camera in the default `cameraa` settings slot, slot 1, or slot 2. Each shows a modal notice and records the command as canceled although the setting is stored. |
| `restore_camera`, `restore_camera1`, `restore_camera2` | `["restore_camera"]` | Restore the default `cameraa` slot, slot 1, or slot 2. |
| `set_stereoscopic` | `["set_stereoscopic"]` | Switch the OpenGL widget to stereoscopic view mode. |

## Screens, video, and 3D models

The optional third element `"width height"` (e.g. `"1920 1080"`) temporarily resizes the GL widget
around the grab, then restores it; with no path a save dialog opens.

| Command | Example | Behavior |
|---|---|---|
| `save_lr_screen` | `["save_lr_screen","C:/output/tracts_lr.png","1920 1080"]` | **Default for saving a 3D rendering**: the left/right pair of the "Copy to Clipboard -> 3D Screen Left/Right Views" action, two angles in one image so tract shape, parcel-tract overlap, and bilateral structures are legible without a live session. |
| `save_screen` | `["save_screen","C:/output/tracts.png","1920 1080"]` | A single view; use only when the user explicitly wants a plain screenshot. |
| `save_hd_screen` | `["save_hd_screen","C:/output/tracts_hd.png","1920 1080"]` | Same as `save_screen` with a size (kept for compatibility); prompts for a size if omitted, so never omit it when scripting. |
| `save_3view_screen` | `["save_3view_screen","C:/output/tracts_3view.png","1920 1080"]` | 2×2 composite: three 3D views plus the current slice scene. |
| `save_h3view_screen`, `save_v3view_screen` | `["save_h3view_screen","C:/output/tracts_h3view.png","1920 1080"]` | Four directional views, horizontal (cropped) or vertical. |
| `save_rotation_video` | `["save_rotation_video","C:/output/rotation.avi"]` | MJPG AVI rotating around Y in 0.2° steps through 360° at 30 fps; non-macOS builds render at 1980×1080 meanwhile. Camera and widget size are restored on success, failure, or cancel. JPEG-encoding and AVI-open failures return errors and cancellation is reported separately, but the AVI API does not report later frame-write or finalization errors, so success cannot rule out a disk-write failure; a canceled/failed export may leave a partial file. No extension validation or codec/fps/step controls. |
| `save_3d_model` | `["save_3d_model","C:/output/tumor.model.obj"]` | Export visible slices, checked tracts, checked regions, and the visible surface. `.obj` writes OBJ (+ .mtl and slice texture JPGs); `.glb` writes one glTF binary with embedded textures and transparency (e.g. `tumor.model.glb` for PowerPoint 3D models). Needs at least one checked tract or region. A tract with more than 3,000 visible tracks gets `delete_repeated_tract` automatically; still over 3,000, the export fails. |
| `preview_screen` | `["preview_screen","3d"]` | Coarse inline text inspection (`"3d"` or `"roi"`) when no image file is being opened; see below. |

## Surfaces and provenance

| Command | Example | Behavior |
|---|---|---|
| `add_surface` | `["add_surface",0,25]`, `["add_surface",7,0.6]` | Build the single isosurface from a slice index (default: the current slice, `list_slice` `current`=1) at a threshold. Built-in slice: ICBM152 white-matter template at `25` (recommended); custom slice: that image at a threshold in its range. Always pass the threshold (omitted: a local dialog waits for the user). See Brain surface. |
| `add_surface_left`, `add_surface_right` | `["add_surface_left",7,0.6]` | Keep the source left/right of the current X slice position, then build. |
| `add_surface_upper`, `add_surface_lower` | `["add_surface_upper",7,0.6]` | Keep the portion above/below the current Z position. |
| `add_surface_posterior`, `add_surface_anterior` | `["add_surface_posterior",7,0.6]` | Keep the portion posterior/anterior of the current Y position. |
| `clear_surface` | `["clear_surface"]` | Remove the surface and refresh; `show_surface` is unchanged. |
| `show_fib_protocol` | `["show_fib_protocol"]` | The FIB's processing protocol (numbered steps from source to FIB) for methods/provenance: text in `output` for AI callers, a dialog for a local user. |
| `save_fib_protocol` | `["save_fib_protocol","C:/output/sub01_fib_protocol.txt"]` | The same text written to the required path, for any caller. |

There is one surface, styled through `set_param` (`surface_*`, `show_surface`). No handlers exist for
surface IDs/lists, `load_surface`, `save_surface`, `delete_surface`, `set_surface_color`,
`set_surface_alpha`, `set_surface_visible`, or `set_device_color` (use the device table UI).

## Brain surface

The recommended surface is the MNI white-matter template warped to subject space:

```bash
bash ./dsi.sh set_slice 0      # also displays it; index 0 is always built in (custom slices follow)
bash ./dsi.sh add_surface 0 25 # 25 = MNI white-matter map threshold
```

- **Built-in slice** (`qa`, `dti_fa`, other FIB metrics): the slice values are not used; the warped
  template is thresholded, so `0.6` does not give a QA isosurface. Use `25`.
- **Custom slice** (`add_slice`/`add_mni_slice`): the template is never used, even with `25`.
- The warp needs the subject-to-MNI mapping. A QSDR FIB maps directly; for a native-space FIB (e.g.
  GQI) the first call reuses a saved mapping file or runs normalization (can be slow). If no mapping
  can be made (e.g. no template for the species), it **silently** falls back to the slice image, where
  `25` is far above the `qa` range and the surface is empty or wrong: check with `preview_screen 3d`.

## Reading `preview_screen` output

`command[1]` must be exactly `"3d"` or `"roi"`. Optional `command[2]` `"x0 y0 x1 y1"` (normalized
`0..1`) crops that channel's cached capture instead of re-rendering, so first call without it; a zoom
with no prior capture fails. Cached crops are labeled and omit the current camera/slice orientation,
which may have changed: use the original metadata or re-capture. Channels are picked automatically
from what is visible:

- `"3d"`: the same camera frame as `get_camera`, then one block per enabled
  `show_slice`/`show_region`/`show_tract`/`show_surface`, each captured with the other three hidden.
- `"roi"`: `R_side=left|right` (side of anatomical right, from `orientation_convention`, matching the
  2D view's "R" label), then `slice_info: <modality> <sagittal|coronal|axial> <position>/<total>`
  (e.g. `slice_info: qa axial 41/80`; selected Slice Modality row, active orientation, 1-based
  position), then a `slice` block (always) and `region` and `tract` blocks showing only that layer on a
  black background (so small blobs or thin lines are not swamped by brain luminance). Those appear only
  when the layer is enabled (region checked / "Show Tracts" on) and non-empty at this slice. This is
  exact only in the single-slice ROI layout; 3-view/mosaic falls back to a composited per-channel
  re-render gated on toggle state alone.

Each block:

```text
<label>:
0: 0 0 3 7 9 9 7 3 0 0 0 0 0 0 0 0
1: ...
coverage=18% bbox=(0.34,0.12)-(0.71,0.88) left/right=48%/52% blobs=1 luminance(min/mean/max)=0/42/255
```

A row-labeled 16-column digit grid (cell luminance `0`=black to `9`=white), a fixed 8x8 grid in the
same format, then `coverage` (foreground cells against the image's own background), normalized
foreground bbox, left/right split, connected components (`blobs`), and raw luminance. The full capture
is also written to a temp JPG (`dsi_preview_3d_<label>.jpg` / `dsi_preview_roi_<label>.jpg`).

**Visual-QC limits.** The grid suits gross checks (expected side, layer intersects the slice, camera
obviously wrong), not subtle boundaries, small contacts, segmentation acceptance, near-midline
laterality, or detailed pre/post morphology. For full-resolution human review, when the user asked for
saved images or gave an output location, use `save_roi_screen` (2D) and `save_lr_screen` (3D); never
invent output paths to get around the preview, but report the limitation instead.

**Reproducible 3D captures.** Reset the camera explicitly and keep the recipe identical across
sessions:

```bash
bash ./dsi.sh set_view 0 0        # the final 0 prevents a flip toggle
bash ./dsi.sh rotate "15 1 0 0"   # only if the same rotation is used every session
bash ./dsi.sh rotate "20 0 1 0"
bash ./dsi.sh preview_screen 3d
```

For an exact matrix with a file destination, use `save_camera`/`open_camera`.

## Rendering parameter reference

IDs come from the embedded `:/data/options.txt` used by `RenderingTableWidget::initialize()`:

```json
["list_param"]
["list_param","tract_alpha"]
["set_param","tract_alpha",0.5]
["set_params","tract_alpha=0.5&show_tract=1"]
```

Send `set_param` values as JSON numbers; `set_params` keeps one assignment string. Enums are zero-based
indices; Off/On settings are `0`/`1`; colors are packed Qt RGB/ARGB integers. "slider" means an
integer `0–10` slider; ranges are `min–max/step`. Metric and color-map options below are resource
defaults: `["list_param","<id>"]` on a single dropdown parameter (not a domain or `"all"` listing)
also prints a live `options: 0=<text>, 1=<text>, ...` line (e.g. `tract_color_metrics` is repopulated
from the loaded data); check it when the exact mapping matters. Each entry: `id` (UI label) values =
default.

**Shared enums.** Blend Func1 (`*_bend1`): `0`=ZERO, `1`=ONE, `2`=DST_COLOR,
`3`=ONE_MINUS_DST_COLOR, `4`=SRC_ALPHA, `5`=ONE_MINUS_SRC_ALPHA, `6`=DST_ALPHA,
`7`=ONE_MINUS_DST_ALPHA. Blend Func2 (`*_bend2`): the same except `2`=SRC_COLOR. Light (`*_light_option`):
`0`=One source, `1`=Two sources, `2`=Three sources (tract: `2`=Off). Mesh Rendering: `0`=Original,
`1`=Smoothed, `2`=Smoothed2. Color Map: `0`=assigned, `1`=files.

### Object visibility

Root items of `TreeModel` (Slice/Tract/Region/Surface/Device/Label/ODF Rendering): `show_slice`,
`show_tract`, `show_region`, `show_surface`, `show_device` default on (`1`); `show_label`, `show_odf`
default off (`0`).

### Background and global

`scale_voxel` (Scale with voxel size) Off/On = 1 · `perspective` slider = 5 · `3d_perspective`
(3D Perspective) `0.5–3/0.5` = 1.0 · `bkg_color` (Background Color) = -1 · `anti_aliasing` Off/On = 1
· `line_smooth`, `point_smooth`, `poly_smooth` (Line/Point/Polygon Smooth) Off/On = 0 ·
`stereoscopy_angle` (Stereoview Angle) `0.0–5.0/0.2` = 1.

### Slice

`slice_alpha` (Opacity) `0–1/0.1` = 1 · `slice_mag_filter` (Mag Filter) `0`=NEAREST, `1`=LINEAR = 1 ·
`slice_smoothing` (Smoothing) Off/On = 0 · `slice_match_bkcolor` (Match Background Color) Off/On = 0 ·
`slice_bend1` = 2 (DST_COLOR) · `slice_bend2` = 5 (ONE_MINUS_SRC_ALPHA).

### Tract

| Parameter ID (UI) | Values = default |
|---|---|
| `tract_alpha` (Opacity) | `0–1/0.1` = 1 |
| `tract_color_saturation`, `tract_color_brightness` | `0–1/0.1` = 0.7, 0.5 |
| `tract_color_style` (Style) | `0`=Directional, `1`=Assigned, `2`=Local Metrics, `3`=Averaged Metrics, `4`=Max Metrics, `5`=Loaded Value = 0 |
| `tract_color_metrics` (Metrics) | `0`=qa, `1`=iso = 0 |
| `tract_color_max_value`, `tract_color_min_value` | `0–1/0.1` = 1.0, 0.0 |
| `tract_color_map` (Map) | color map = 0 |
| `tract_color_max`, `tract_color_min` (Max/Min Color) | 12079178, 14465098 |
| `tract_show_color_bar` | Off/On = 1 |
| `tract_style` (Style) | `0`=Line, `1`=Tube, `2`=End, `3`=End1, `4`=End2 = 1 |
| `tract_line_width` | `1.0–10/0.5` = 3 |
| `tract_visible_tract` (Visible Tracts) | `5000–1000000/5000` = 25000 |
| `tract_shader` (Shade) | `0–20/1` = 4 |
| `tract_tube_detail` | `0`=Coarse, `1`=Fine, `2`=Finer, `3`=Finest = 1 |
| `tube_diameter` (Tube Diameter (voxel)) | `0.01–5/0.1` = 0.2 |
| `end_point_shift` (Endpoint Shift (voxel)) | `0–10/1` = 0 |
| `tract_light_option` | light = 1 (Two sources) |
| `tract_sel_angle` (Tract Selection Angle) | `0–90/5` = 45 |
| `tract_bend1`, `tract_bend2` | 6 (DST_ALPHA), 2 (SRC_COLOR) |

### Region and graph

| Parameter ID (UI) | Values = default |
|---|---|
| `region_alpha` (Opacity) | `0–1/0.1` = 0.8 |
| `region_color_style` (Style) | `0`=Assigned, `1`=Metrics = 0 |
| `region_color_metrics` | `0`=qa, `1`=iso = 0 |
| `region_color_max_value`, `region_color_min_value` | `0–1/0.1` = 1.0, 0.0 |
| `region_color_map` | color map = 0 |
| `region_color_max`, `region_color_min` | 12079178, 14465098 |
| `region_show_color_bar` | Off/On = 1 |
| `region_graph` (Graph) | Off/On = 0 |
| `region_node_size`, `region_edge_size` | slider = 4, 4 |
| `region_constant_node_size`, `region_constant_edge_size` | Off/On = 0 |
| `region_hide_unconnected_node` | Off/On = 1 |
| `region_pos_edge_color1`, `region_pos_edge_color2` (Edge Min/Max Color(Positive)) | -1, 8224255 |
| `region_neg_edge_color1`, `region_neg_edge_color2` (Edge Min/Max Color(Negative)) | -1, 16743293 |
| `region_edge_threshold` (Binary Graph Threshold) | `0.00–1/0.1` = 0.1 |
| `region_mesh_smoothed` (Mesh Rendering) | mesh = 1 |
| `region_light_option` | light = 0 |
| `region_bend1`, `region_bend2` | 4 (SRC_ALPHA), 5 (ONE_MINUS_SRC_ALPHA) |

### Surface and device

`surface_color` (Color) = 11184810 · `surface_alpha` (Opacity) `0–1/0.05` = 0.2 ·
`surface_mesh_smoothed` mesh = 2 · `surface_light_option` = 2 · `surface_bend1` = 2 (DST_COLOR),
`surface_bend2` = 5. `device_light_option` = 2 · `device_bend1` = 4 (SRC_ALPHA), `device_bend2` = 5.

### Lighting and material sliders

All are `0–10` sliders: `<p>_light_dir` (Light Direction), `_light_shading`, `_light_diffuse`,
`_light_ambient`, `_light_specular`, and material `<p>_specular`, `<p>_emission`, `<p>_shininess`.
Defaults (dir/shading/diffuse/ambient/specular; material specular/emission/shininess):

| Prefix `<p>` | Light | Material |
|---|---|---|
| `tract` | 2/10/10/0/0 | 0/0/0 |
| `region` | 2/2/10/0/0 | 0/1/0 |
| `surface` | 5/4/2/0/0 | 0/0/0 |
| `device` | 5/4/6/0/0 | 0/0/0 |
| `odf` | 2/2/10/0/0 | 0/1/0 |

Expanded IDs: `tract_light_dir`, `tract_light_shading`, `tract_light_diffuse`, `tract_light_ambient`, `tract_light_specular`, `tract_specular`, `tract_emission`, `tract_shininess`; `region_light_dir`, `region_light_shading`, `region_light_diffuse`, `region_light_ambient`, `region_light_specular`, `region_specular`, `region_emission`, `region_shininess`; `surface_light_dir`, `surface_light_shading`, `surface_light_diffuse`, `surface_light_ambient`, `surface_light_specular`, `surface_specular`, `surface_emission`, `surface_shininess`; `device_light_dir`, `device_light_shading`, `device_light_diffuse`, `device_light_ambient`, `device_light_specular`, `device_specular`, `device_emission`, `device_shininess`; `odf_light_dir`, `odf_light_shading`, `odf_light_diffuse`, `odf_light_ambient`, `odf_light_specular`, `odf_specular`, `odf_emission`, `odf_shininess`.

### Labels and directional axis

`show_track_label` Off/On = 1 · `show_track_label_location` `0`=With Track, `1`=Middle,
`2`=Middle Bottom = 0 · `track_label_color` = 9868955 · `track_label_bold` Off/On = 1 ·
`track_label_size` (Tract Label Size) `2–100/2` = 12. `show_region_label`, `region_label_color`,
`region_label_bold`, `region_label_size` and `show_device_label`, `device_label_color` (Device Color),
`device_label_bold` (Device Bold), `device_label_size` (Device Size): the same values and defaults.
`show_directional_axis` (Axis) Off/On = 0 · `axis_line_thickness` `1.0–20.0/0.5` = 10 ·
`axis_line_length` `1.0–10.0/0.5` = 5 · `show_axis_label` (Axis Label) Off/On = 1 · `axis_label_size`
`2–48/2` = 26 · `axis_label_bold` Off/On = 1.

### ODF

`odf_position` (Position) `0`=Along Slide, `1`=Slide Intersection, `2`=All = 0 · `odf_scale` (Size)
`0.1–32/1` = 2 · `odf_color` `0`=Dir, `1`=Blue, `2`=Red = 0 · `odf_skip` (Interleaved) `0`=none,
`1`=2, `2`=4 = 0 · `odf_smoothing` off/on = 0 · `odf_shape` `0`=original, `1`=1st, `2`=2nd = 0 ·
`odf_min_max` (Min-Max Normalization) off/on = 1 · `odf_light_option` = 0.
