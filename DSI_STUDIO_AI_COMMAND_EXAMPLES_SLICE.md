# DSI Studio AI Slice Command Examples and Inventory

Complete slice and segmentation inventory confirmed in the current source. Use these in a
`tracking<hex-address>` window, selected once with `bash ./dsi.sh set_window tracking<hex-address>`
(it persists until changed). Names and text, path, or composite parameters are strings; send
standalone numbers as JSON numbers.

| Command | Example | Behavior |
|---|---|---|
| `list_slice` | `["list_slice"]` | `index`, `current`, `name`, and `status` (`available`, `registering`, or `ready`; below). |
| `set_slice` | `["set_slice",7]` | Select a slice by index, loading/registering it when needed; may return before that finishes. |
| `set_slice_by_name` | `["set_slice_by_name","T1w"]` | Select a slice by exact displayed name. |
| `move_slice` | `["move_slice","80 100 80"]` | Move the shared crosshair to voxel coordinates in current slice space (one composite string). |
| `enable_slice` | `["enable_slice","1 1 0"]` | Sagittal, coronal, and axial visibility, in that order (one composite string). |
| `set_slice_contrast` | `["set_slice_contrast","0 1"]` | Current slice minimum and maximum display values; an optional third composite string sets packed Qt minimum and maximum colors. |
| `load_color_map` | `["load_color_map","C:/data/color_map/hot.txt"]` | Load a color-map text file onto the **current** slice view (select it with `set_slice` first), like the GUI's Load Color Map. AI callers must supply the file (omitting it is a usage error); a local user picks it in a dialog (default folder `color_map/`), recorded for replay. An unreadable file fails with `invalid color map format`. |
| `set_slice_dir_color`, `set_slice_overlay`, `set_slice_stay` | `["set_slice_dir_color",7,1]` | For one slice index, enable or disable directional coloring, overlay mode, or membership in the persistent display list. |
| `set_roi_view` | `["set_roi_view",2]` | ROI editing view: `0` sagittal, `1` coronal, `2` axial. |
| `add_slice` | `["add_slice","C:/data/T1w.nii.gz"]` | Add a native/custom slice; comma-separated files form one multi-file image. |
| `add_mni_slice` | `["add_mni_slice","C:/data/atlas.nii.gz"]` | Add a custom slice in MNI space (mapping required). |
| `skull_strip_slice` | `["skull_strip_slice",7]` | Apply the template mask to a custom slice; built-in slices are rejected. |
| `save_roi_screen` | `["save_roi_screen","C:/output/roi_view.png"]` | Save the full-resolution 2D ROI/slice scene; prefer it to the text preview when a human-review image is requested or a destination exists. |
| `preview_screen` | `["preview_screen","roi"]` | Read the 2D scene as coarse text (digit-grid art plus stats) without saving; good for gross agent QC, not full visual review. Format and the `"3d"` mode: "Reading `preview_screen` output" in the rendering examples. |
| `save_slice_image` | `["save_slice_image","C:/output/qa.nii.gz","qa"]` | Export a named metric/data map in subject space: `command[1]` is the output file, `command[2]` the data-map name (not a row index). |
| `save_slice_mni_image` | `["save_slice_mni_image","C:/output/qa_mni.nii.gz","qa"]` | The same in template/MNI space; needs a valid subject-to-template mapping. |
| `save_slice_mapping`, `open_slice_mapping` | `["save_slice_mapping","C:/output/T1w.linear_reg.txt",7]`, `["open_slice_mapping","C:/output/T1w.linear_reg.txt",7]` | Save a custom slice's registration mapping, or stop its registration and load one. |
| `save_slice_volume` | `["save_slice_volume","C:/output/T1w.nii.gz",7]` | Save the bound custom-slice volume as NIfTI. |
| `mark_tracts_on_slices` | `["mark_tracts_on_slices",1.0]` | Burn the **checked** tracts into the current custom slice at the intensity ratio (× slice maximum); fails with `no tract is selected; use show_only_tracts first` when none is checked. A GUI-supplied ratio is written back into the recorded command. |
| `mark_region_on_slices` | `["mark_region_on_slices",5,1.2]` | Burn one region (region-table index) at the intensity ratio; GUI-supplied values are written back for replay. |
| `save_slices_to_dicom` | `["save_slices_to_dicom","C:/output/dicom"]` | Write the marked slice as DICOM (`mod_*.dcm`); **the slice must be loaded from original DICOM files** (`add_slice` with DICOMs). |
| `delete_slice` | `["delete_slice",7]` | Delete one custom slice; built-in slices cannot be deleted. |
| `list_unet` | `["list_unet"]` | Segmentation models for the **currently selected slice**: `index`, live `available`, internal `model` ID, `name`, `description`. |
| `segment_brain` | `["segment_brain","<model-ID-from-list_unet>",7]` | Run a model whose `available` is 1, by its exact `model` value, on a slice index or exact name, creating label regions. Synchronous. |

## `list_slice` status

- `available`: a URL-backed custom slice not yet loaded; `set_slice` downloads and registers it.
- `registering`: registration is running; poll again and start no dependent operation.
- `ready`: local or built in and not registering; ready for segmentation, display, or export. It does
  not prove the registration is anatomically correct: inspect alignment before anatomy-dependent
  analysis.

`current` (`1`/`0`) only marks the selected slice; after `set_slice`, poll until that row is `ready`.
The selected slice is shown in the 2D view and on the 3D planes and is the default source for
slice-based commands such as `add_surface`. For example, `set_slice 0` selects the first built-in
metric (usually `qa`) and `enable_slice "1 1 1"` shows it on all three planes. Use `list_slice` for
exact data-map names before export; exports also accept special names `fiber`, `dirs`, `dir0` through
the available fiber count, `odfs`, and `color` when the data supports them.

## `list_unet` and `segment_brain`

`available=1` means the model is enabled for the selected slice and may be passed to `segment_brain`;
`available=0` means do not call it. Availability is live (it changes with the selected slice, loaded
data, and registration), so call `list_unet` after the target slice is selected and ready; a known
model ID is not callable on every slice. Pass the `model` column, not the `name` column: the source
hands `command[1]` to `download_unet_model()`, which matches the `.nz` filename stem (an earlier
example wrongly used the display name `SynthSeg V2`). A timeout does not prove inference stopped, and
completion does not prove a valid segmentation: inspect the regions before quantitative use.

## Marking tracts and regions, and exporting DICOM

Burning evaluated anatomy into a DICOM series (e.g. tract overlays for surgical navigation):

```bash
bash ./dsi.sh add_slice "<dicom1>,<dicom2>,..."   # original DICOM series; comma-separated files form one image
bash ./dsi.sh set_slice <dicom-slice-index>       # poll list_slice until status is ready
bash ./dsi.sh show_only_tracts "<idx1>&<idx2>&..." # check exactly the tracts to mark
bash ./dsi.sh mark_tracts_on_slices 1.0           # burn checked tracts at 1.0 × slice max
bash ./dsi.sh mark_region_on_slices <region-index> 1.2  # optional: burn a region at 1.2 × max
bash ./dsi.sh save_slices_to_dicom "<output-directory>" # writes mod_*.dcm
```

- Always establish the tract selection with `show_only_tracts` first, so a silent no-op never yields
  apparently successful DICOMs.
- A NIfTI-loaded slice (e.g. `sub-..._T1w.nii.gz`) is rejected with
  `save_slices_to_dicom requires original DICOM files loaded from the Slices menu`; there is no path
  from NIfTI-only data to this modified DICOM. Compressed DICOM input fails with
  `compressed DICOM is not supported`.
- Marking is **cumulative in memory**, with no command to restore the original pixels; reload the
  slice to start over.
- Outputs are `mod_<original-stem>.dcm`; an agent call fails instead of overwriting an existing file.
- The recorded history keeps GUI-supplied values, so GUI marking replays deterministically (e.g.
  `mark_region_on_slices,5,1.200000`).
