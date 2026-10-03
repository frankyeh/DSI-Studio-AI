# DSI Studio AI Slice Command Examples and Inventory

Use these with a `tracking<hex-address>` window. Select it once before sending
any command below:

```bash
bash ./dsi.sh set_window tracking<hex-address>
```

The selection persists for the session until changed by another `set_window` call.
Command names and text, path, or composite parameters are strings. Send standalone
numeric parameters as JSON numbers.

This file contains the complete slice and segmentation inventory confirmed in the current source.

| Command | Common example | Important behavior |
|---|---|---|
| `list_slice` | `["list_slice"]` | List `index`, `current`, `name`, and one readable `status`: `available`, `registering`, or `ready`. |
| `set_slice` | `["set_slice",7]` | Select a slice by numeric index, loading/registering it when needed. |
| `set_slice_by_name` | `["set_slice_by_name","T1w"]` | Select a slice by exact displayed name. |
| `move_slice` | `["move_slice","80 100 80"]` | Move the shared crosshair to voxel coordinates in current slice space. The three coordinates remain one composite string. |
| `enable_slice` | `["enable_slice","1 1 0"]` | Set sagittal, coronal, and axial visibility in that order. The three flags remain one composite string. |
| `set_slice_contrast` | `["set_slice_contrast","0 1"]` | Set the current slice minimum and maximum display values. An optional third composite string sets packed Qt minimum and maximum colors. |
| `set_slice_dir_color` | `["set_slice_dir_color",7,1]` | Enable or disable directional coloring for one slice index. |
| `set_slice_overlay` | `["set_slice_overlay",7,1]` | Enable or disable overlay mode for one slice index. |
| `set_slice_stay` | `["set_slice_stay",7,1]` | Add or remove one slice from the persistent display list. |
| `set_roi_view` | `["set_roi_view",2]` | Select ROI editing view: `0` sagittal, `1` coronal, `2` axial. |
| `add_slice` | `["add_slice","C:/data/T1w.nii.gz"]` | Add a native/custom slice; comma-separated files may define one multi-file image. |
| `add_mni_slice` | `["add_mni_slice","C:/data/atlas.nii.gz"]` | Add a custom slice interpreted in MNI space; mapping is required. |
| `skull_strip_slice` | `["skull_strip_slice",7]` | Apply the template mask to a custom slice; built-in slices are rejected. |
| `save_roi_screen` | `["save_roi_screen","C:/output/roi_view.png"]` | Save the current full-resolution 2D ROI/slice scene. Prefer this over the text-only preview when a saved human-review image is requested or an output destination is available. |
| `preview_screen` | `["preview_screen","roi"]` | Read the 2D ROI/slice scene as coarse text (digit-grid art plus stats) without saving a file; useful for gross agent QC but not equivalent to full-resolution visual review. See the "Reading `preview_screen` output" section in the rendering examples file for the full format and the `"3d"` mode. |
| `save_slice_image` | `["save_slice_image","C:/output/qa.nii.gz","qa"]` | Export the named metric/data map in current subject space; arguments are output path then data-map name. |
| `save_slice_mni_image` | `["save_slice_mni_image","C:/output/qa_mni.nii.gz","qa"]` | Export the named metric/data map in template/MNI space; a valid subject-to-template mapping is required. |
| `save_slice_mapping` | `["save_slice_mapping","C:/output/T1w.linear_reg.txt",7]` | Save registration mapping for a custom slice. |
| `open_slice_mapping` | `["open_slice_mapping","C:/output/T1w.linear_reg.txt",7]` | Stop registration and load a mapping for a custom slice. |
| `save_slice_volume` | `["save_slice_volume","C:/output/T1w.nii.gz",7]` | Save the bound custom-slice volume as NIfTI. |
| `mark_tracts_on_slices` | `["mark_tracts_on_slices",1.0]` | Burn the currently **checked** tracts into the current custom slice at the given intensity ratio (× slice maximum). Fails with `no tract is selected; use show_only_tracts first` when no tract is checked. A GUI-supplied ratio is written back into the recorded command for replay. |
| `mark_region_on_slices` | `["mark_region_on_slices",5,1.2]` | Burn one region (region-table index) into the current custom slice at the given intensity ratio. GUI-supplied region/ratio are written back into the recorded command for replay. |
| `save_slices_to_dicom` | `["save_slices_to_dicom","C:/output/dicom"]` | Write the marked slice as DICOM (`mod_*.dcm`). **Requires the current slice to be loaded from original DICOM files** (`add_slice` with DICOMs) — a NIfTI-loaded slice is rejected. |
| `delete_slice` | `["delete_slice",7]` | Delete one custom slice; built-in slices cannot be deleted. |
| `list_unet` | `["list_unet"]` | List segmentation model index, live `available` flag, internal model ID, display name, and description for the **currently selected slice**. Treat this live availability as authoritative; a known model ID is not necessarily callable on every current slice. |
| `segment_brain` | `["segment_brain","<model-ID-from-list_unet>",7]` | Run a model whose current `available` flag is true, using the exact `model` column value, on a slice index or exact slice name, and create label regions. See footnote 1. |

## `list_slice` output

The reply columns are:

```text
index    current    name    status
```

Interpret `status` directly:

- `available` — a URL-backed custom slice is listed but has not yet been loaded locally. Select it with `set_slice`; DSI Studio will download and register it when needed.
- `registering` — custom-slice registration is still running. Poll `list_slice` again and do not start a dependent operation.
- `ready` — the slice is local or built in and is not registering. It is ready for segmentation, display, or export.

The `current` column only identifies the selected slice (`1` or `0`); it does not indicate readiness. After `set_slice`, poll until that selected row reports `ready`.

## `list_unet` availability

The reply columns include:

```text
index    available    model    name    description
```

`available=1` means the model action is enabled for the currently selected slice and
may be passed to `segment_brain`. `available=0` means do not call that model for the
current slice. Availability is live state and can change after selecting a different
slice, loading data, or completing registration, so call `list_unet` after the target
slice is selected and ready rather than relying on a previous subject/window.

## Marking tracts/regions on slices and exporting DICOM

For the basic AI-agent workflow that burns evaluated anatomy into a DICOM series
(e.g. tract overlays for surgical navigation):

```bash
bash ./dsi.sh add_slice "<dicom1>,<dicom2>,..."   # original DICOM series; comma-separated files form one image
bash ./dsi.sh set_slice <dicom-slice-index>       # poll list_slice until status is ready
bash ./dsi.sh show_only_tracts "<idx1>&<idx2>&..." # check exactly the tracts to mark
bash ./dsi.sh mark_tracts_on_slices 1.0           # burn checked tracts at 1.0 × slice max
bash ./dsi.sh mark_region_on_slices <region-index> 1.2  # optional: burn a region at 1.2 × max
bash ./dsi.sh save_slices_to_dicom "<output-directory>" # writes mod_*.dcm
```

Rules and limitations:

- `mark_tracts_on_slices` operates on **checked tracts only**. It fails when none are
  checked, so always establish the selection with `show_only_tracts` first — a silent
  no-op must never produce apparently successful DICOMs.
- `save_slices_to_dicom` requires the current slice to have been loaded from the
  **original DICOM series** (`source_files`). A NIfTI structural image such as
  `sub-..._T1w.nii.gz` is rejected with `save_slices_to_dicom requires original DICOM
  files loaded from the Slices menu`. There is currently no path from NIfTI-only data
  to this type of modified DICOM.
- Marking is **cumulative in memory**: every mark modifies the in-memory slice pixels.
  There is no command to restore the original pixels yet; reload the slice to start over.
- Output files are named `mod_<original-stem>.dcm`. If the output already exists, a
  non-User (agent) call fails instead of overwriting.
- Compressed DICOM input is not supported (`compressed DICOM is not supported`).
- The recorded history keeps the GUI-supplied region index and intensity ratio, so a
  GUI-driven marking replays deterministically (e.g. `mark_region_on_slices,5,1.200000`).

## Source-confirmed cautions

- `set_slice` may return before loading or registration finishes; use the `status` column rather than interpreting several boolean columns.
- `ready` means loading/registration has completed; it does not establish that the registration is anatomically correct. Inspect alignment before segmentation or other anatomy-dependent analysis.
- `segment_brain` is synchronous; a client timeout does not prove inference stopped.
- A successful `segment_brain` call establishes command completion, not anatomical segmentation validity; inspect the generated regions before quantitative interpretation.
- Use `list_slice` to discover the exact data-map name before export.
- `save_slice_image` and `save_slice_mni_image` use `command[1]` as the output filename and `command[2]` as the metric/data-map name, not a slice-row index.
- The export source also supports special data names such as `fiber`, `dirs`, `dir0` through the available fiber count, `odfs`, and `color`; use these only when the loaded data supports them.

## Footnotes

1. The earlier example used the display name `SynthSeg V2`. The source passes `command[1]` directly to `download_unet_model()`, which matches the `.nz` filename stem. Therefore the correct argument is the internal value in the `model` column returned by `list_unet`, not the human-readable `name` column.
