# DSI Studio AI Image Command Examples and Inventory

A successful `open_image` returns `image window created, id: image...` and selects that
`image<hex-address>` window, so the commands below act on it directly; use `set_window` only to switch
to another open image window (`list_window` confirms or discovers IDs). Names and text, path, or
composite parameters are strings; send a standalone number as a JSON number.

The image-window handler accepts only a command name and **at most one parameter** (checked against
`view_image::command()`, `variant_image::command()`, and TIPL `command()`). Parameterless commands
below are real commands: add no dummy value. `bring_to_front`, `minimize`, `maximize`, and `close` are
shared dispatcher-level controls intercepted earlier (not subject to that limit; see
`DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md`). After `close`, confirm with `list_window`, then
`set_window main` or another valid ID: the session keeps the closed `image...` target until changed.

## Type, AI models, and registration

| Command | Example | Behavior |
|---|---|---|
| `change_type` | `["change_type",3]` | Voxel type: `0`=uint8, `1`=uint16, `2`=uint32, `3`=float32. |
| `bias_field_correction` | `["bias_field_correction"]` | Iteratively estimate and remove the bias field using the positive-value mask. |
| `brain_extraction` | `["brain_extraction","<model-ID>"]` | Run the model (¹) and multiply the image by its foreground probability. |
| `segmentation` | `["segmentation","<model-ID>"]` | Run the model (¹) and replace the image with its uint8 label output. |
| `deface` | `["deface","<model-ID>"]` | Run the model (¹) and suppress voxels in the facial mask, preserving nearby brain tissue. |
| `rotate_to_image` | `["rotate_to_image","C:/data/template.nii.gz"]` | Rigid mutual-information registration to the NIfTI, then resample into target space. |
| `warp_to_image` | `["warp_to_image","C:/data/template.nii.gz"]` | Affine (correlation) then nonlinear registration, then resample into target space. |
| `apply_to_image` | `["apply_to_image","C:/data/other.nii.gz"]` | Load another image and apply the mapping kept from the preceding `rotate_to_image`/`warp_to_image` (both replace the current image with the resampled result); fails with no mapping. |

¹ `<model-ID>` must exactly match the downloaded `.nz` filename stem: `download_unet_model()` requires
it, and each GUI model action stores `std::filesystem::path(model_url).stem()`. The catalog is loaded
at startup from the packaged `unet/README.md`, not this repository. The image window has no
model-list command; read the ID from a tracking window's `["list_unet"]` `model` column, or from the
packaged catalog.

## Morphology and filters (parameterless unless shown)

| Command | Behavior |
|---|---|
| `morphology_defragment` | Keep the principal connected component (floating images: first a positive-value mask, then preserved by it). |
| `morphology_defragment_by_size` | `["morphology_defragment_by_size",0.05]`: remove components below the size ratio (default `0.05`; pass it explicitly). |
| `morphology_fill_holes`, `morphology_fill_holes_by_slice` | Fill enclosed holes in 3D, or independently per slice. |
| `morphology_dilation`, `morphology_erosion`, `morphology_opening`, `morphology_closing` | Apply to each nonzero label independently. |
| `morphology_edge`, `morphology_edge_xy`, `morphology_edge_xz` | Label edges in 3D, within XY planes, or within XZ planes. |
| `morphology_smoothing` | Smooth a binary mask, or multi-region smoothing when values exceed `0/1`. |
| `sobel_filter`, `gaussian_filter`, `mean_filter`, `smoothing_filter` | TIPL Sobel, Gaussian, mean, or anisotropic-diffusion filtering. |
| `normalize`, `normalize_otsu_median` | Convert to float32 if needed, then normalize intensity (plain, or by Otsu/median statistics). |

## Values and thresholds

| Command | Example | Behavior |
|---|---|---|
| `select_value` | `["select_value",1]` | Binary mask of voxels equal to the value. |
| `add_value`, `multiply_value` | `["add_value",10]`, `["multiply_value",0.5]` | Add or multiply a scalar for every voxel. |
| `lower_threshold`, `upper_threshold` | `["lower_threshold",0]`, `["upper_threshold",1000]` | Clamp values below/above the threshold. |
| `threshold` | `["threshold",0.5]` | `1` where greater than the threshold, else `0`. |
| `otsu_threshold` | `["otsu_threshold",1.0]` | Binarize at `Otsu threshold × supplied ratio`. |
| `equation` | `["equation","x*2"]` | TIPL expression on the image (this example doubles it); operators `+`, `-`, `*`, `/`, `>`, `<`, `=`, with `*` and `/` first. |

## Geometry and header

`flip_*` changes voxel data only and `header_flip_*` metadata only; pair them only when that combined
change is intended.

| Command | Example | Behavior |
|---|---|---|
| `flip_x`, `flip_y`, `flip_z` | `["flip_x"]` | Flip voxel data along an axis; the header transformation is not changed. |
| `header_flip_x`, `header_flip_y`, `header_flip_z` | `["header_flip_x"]` | Flip only the header transformation. |
| `swap_xy`, `swap_xz`, `swap_yz` | `["swap_xy"]` | Swap voxel axes and voxel sizes. |
| `header_swap_xy`, `header_swap_xz`, `header_swap_yz` | `["header_swap_xy"]` | Swap axes in header metadata and voxel sizes, not voxel data. |
| `set_transformation` | `["set_transformation","1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"]` | Replace the 4×4 transformation (16 floats) and recalculate voxel size. |
| `set_translocation` | `["set_translocation","0 0 0"]` | Set translation entries `T[3]`, `T[7]`, `T[11]`. |
| `set_mni` | `["set_mni",1]` | MNI flag from the first character: `1`=true, other nonempty values false. |
| `upsampling`, `downsampling` | `["upsampling"]` | 2× up/down sampling of data or labels; halves/doubles voxel size. |
| `crop_to_fit` | `["crop_to_fit",2]` | Crop around the principal positive component with a 2-voxel margin on all axes (three margins go in one composite string). |
| `transform` | `["transform","1 0 0 0 0 1 0 0 0 0 1 0"]` | Resample/reorient to a target transformation (first 12 matrix values), resolving flips, voxel size, and translation. |
| `translocate` | `["translocate","1 0 0"]` | Shift data by voxel offsets (fractional: interpolated) and update translation. |
| `resize`, `resize_at_center` | `["resize","256 256 160"]` | Resize the canvas from the origin (overlap copied, transformation unchanged) or around the center. |
| `reshape` | `["reshape","256 256 160"]` | Reshape the voxel buffer to 3D dimensions (the wrapper has special 4D handling). |
| `regrid` | `["regrid","1 1 1"]` | Resample to one isotropic or three voxel sizes, updating dimensions and transformation. |

For a FIB (`.fz`, opened in the image window or with `--action=img`), `regrid`, `upsampling`,
`downsampling`, `transform`, and `translocate` use nearest-neighbor for every matrix, so a voxel's
fiber metrics and directions come from one source voxel; SRC (`.sz`) images keep linear interpolation,
with majority for the mask.

## Other images, open, and save

Commands ending in `_image` or `_label` need an existing file and map it into current space (linear
interpolation for images, majority for labels).

| Command | Example | Behavior |
|---|---|---|
| `concatenate_image` | `["concatenate_image","C:/data/second.nii.gz"]` | Append along Z (width and height must match); in a 4D window, append a volume. |
| `refine_label` | `["refine_label","C:/data/reference.nii.gz"]` | Map the reference in and refine the current labels. |
| `load_image` | `["load_image","C:/data/replacement.nii.gz"]` | Map in and replace current voxel data. |
| `multiply_image`, `add_image`, `minus_image`, `max_image`, `min_image` | `["multiply_image","C:/data/mask.nii.gz"]` | Map in and multiply, add, subtract, or keep the voxelwise maximum/minimum. |
| `open` | `["open","C:/data/replacement.nii.gz"]` | Load data and metadata through TIPL into the current image object. |
| `save` | `["save","C:/output/processed.nii.gz"]` | Save data with transformation, voxel size, and MNI flag. If the window was opened with extra batch files, a modal batch-processing prompt may appear: avoid unattended batch saves unless expected. |
