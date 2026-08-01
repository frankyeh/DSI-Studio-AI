# DSI Studio AI Reconstruction Command Examples and Inventory

Use these commands with a `recon<hex-address>` window ID. Open an SRC/SZ file from
`main`:

```bash
bash ./dsi.sh main open_src "C:/data/subject.sz"
```

DSI Studio returns the new ID in
`recon window created, id: recon...` from the command `output`. Use that exact ID
for follow-up commands. Top-level `LIST` can confirm the ID or discover another
already-open reconstruction window.

The reconstruction-window dispatcher accepts one command name and at most one
parameter. Keep multiple values or assignments together as one quoted composite
string.

## Reconstruction parameters

Inspect current values before changing them:

```bash
bash ./dsi.sh recon<hex-address> src_list_param
bash ./dsi.sh recon<hex-address> src_list_param method
```

Set one or several parameters using `name=value` syntax:

```bash
bash ./dsi.sh recon<hex-address> src_set_param "method=4"
bash ./dsi.sh recon<hex-address> src_set_params "method=4&param=1.25&thread_count=8"
```

Both `src_set_param` and `src_set_params` use the same single composite parameter.

| Parameter | Meaning |
|---|---|
| `method` | Reconstruction method: `1` DTI, `4` GQI, `7` QSDR |
| `thread_count` | Reconstruction thread count |
| `other_output` | Comma-separated output metric IDs |
| `dti_ignore_high_b` | Ignore high-b-value data for tensor metrics |
| `odf_resolving` | Enable ODF resolving |
| `r2_weighted` | Enable R2-weighted reconstruction |
| `param` | GQI/QSDR diffusion sampling length ratio |
| `template` | Zero-based template index |
| `qsdr_reso` | QSDR output resolution in millimeters |
| `reg_resolution` | Registration resolution |
| `reg_speed` | Registration speed |
| `reg_smoothing` | Registration smoothing |
| `hist_downsampling` | Histology downsampling level |
| `hist_raw_smoothing` | Histology raw-image smoothing |
| `hist_tensor_smoothing` | Histology tensor smoothing |
| `hist_resolution` | Isotropic histology resolution |

## Commands

| Command | Complete example | Important behavior |
|---|---|---|
| `src_list_param` | `bash ./dsi.sh recon<hex-address> src_list_param` | List all reconstruction parameters and current values. Supply one exact parameter name to list only that value. |
| `src_set_param` | `bash ./dsi.sh recon<hex-address> src_set_param "method=4"` | Set one `name=value` assignment. |
| `src_set_params` | `bash ./dsi.sh recon<hex-address> src_set_params "method=4&param=1.25"` | Set multiple `&`-separated assignments. |
| `src_recon` | `bash ./dsi.sh recon<hex-address> src_recon 4` | Run reconstruction synchronously. Optional method is `1` DTI, `4` GQI, or `7` QSDR; omission uses the current `method` value. |
| `src_save_src` | `bash ./dsi.sh recon<hex-address> src_save_src "C:/output/subject.sz"` | Save the current source data. |
| `src_save_nifti` | `bash ./dsi.sh recon<hex-address> src_save_nifti "C:/output/dwi.nii.gz"` | Save a 4D diffusion NIfTI plus bval/bvec files. |
| `src_save_b0` | `bash ./dsi.sh recon<hex-address> src_save_b0 "C:/output/b0.nii.gz"` | Save the first b0 volume. |
| `src_save_dwi_sum` | `bash ./dsi.sh recon<hex-address> src_save_dwi_sum "C:/output/dwi_sum.nii.gz"` | Save the summed diffusion image. |
| `src_mask_open` | `bash ./dsi.sh recon<hex-address> src_mask_open "C:/data/mask.nii.gz"` | Replace the reconstruction mask using a supplied mask file. |
| `src_mask_unet` | `bash ./dsi.sh recon<hex-address> src_mask_unet` | Generate a mask using the packaged U-Net model. Inspect the mask before reconstruction. |
| `src_mask_from_template` | `bash ./dsi.sh recon<hex-address> src_mask_from_template 0` | Generate a mask using a zero-based template index. |
| `src_mask_threshold` | `bash ./dsi.sh recon<hex-address> src_mask_threshold 100` | Create a mask using an explicit integer signal threshold. |
| `src_mask_erosion` | `bash ./dsi.sh recon<hex-address> src_mask_erosion` | Erode the current mask. |
| `src_mask_dilation` | `bash ./dsi.sh recon<hex-address> src_mask_dilation` | Dilate the current mask. |
| `src_mask_defragment` | `bash ./dsi.sh recon<hex-address> src_mask_defragment` | Keep the principal connected mask component. |
| `src_mask_slice_defragment` | `bash ./dsi.sh recon<hex-address> src_mask_slice_defragment` | Apply the current slice-wise mask cleanup implementation. |
| `src_mask_smoothing` | `bash ./dsi.sh recon<hex-address> src_mask_smoothing` | Smooth the current mask. |
| `src_mask_fit` | `bash ./dsi.sh recon<hex-address> src_mask_fit` | Fit the current mask to the diffusion-sum image. |
| `src_mask_negate` | `bash ./dsi.sh recon<hex-address> src_mask_negate` | Invert the current mask. |
| `src_mask_remove_background` | `bash ./dsi.sh recon<hex-address> src_mask_remove_background` | Permanently zero signals outside the current mask. |
| `src_probabilistic_masking` | `bash ./dsi.sh recon<hex-address> src_probabilistic_masking "C:/data/probability.nii.gz"` | Multiply diffusion signals by a same-dimension probability image. |
| `src_set_voxel_size` | `bash ./dsi.sh recon<hex-address> src_set_voxel_size "1.5 1.5 2.0"` | Replace the three voxel-size values without resampling. |
| `src_smooth_signals` | `bash ./dsi.sh recon<hex-address> src_smooth_signals` | Smooth diffusion signals. |
| `src_crop_background` | `bash ./dsi.sh recon<hex-address> src_crop_background 0` | Crop background with an optional voxel border. |
| `src_resample` | `bash ./dsi.sh recon<hex-address> src_resample 2` | Resample to the supplied isotropic millimeter resolution. |
| `src_align_acpc` | `bash ./dsi.sh recon<hex-address> src_align_acpc 2` | Align to AC-PC space at the supplied output resolution. |
| `src_flip_x` | `bash ./dsi.sh recon<hex-address> src_flip_x` | Flip diffusion images and the corresponding b-vector X component. |
| `src_flip_y` | `bash ./dsi.sh recon<hex-address> src_flip_y` | Flip diffusion images and the corresponding b-vector Y component. |
| `src_flip_z` | `bash ./dsi.sh recon<hex-address> src_flip_z` | Flip diffusion images and the corresponding b-vector Z component. |
| `src_swap_xy` | `bash ./dsi.sh recon<hex-address> src_swap_xy` | Swap image X/Y axes, voxel sizes, and matching b-vector components. |
| `src_swap_yz` | `bash ./dsi.sh recon<hex-address> src_swap_yz` | Swap image Y/Z axes, voxel sizes, and matching b-vector components. |
| `src_swap_xz` | `bash ./dsi.sh recon<hex-address> src_swap_xz` | Swap image X/Z axes, voxel sizes, and matching b-vector components. |
| `src_check_btable` | `bash ./dsi.sh recon<hex-address> src_check_btable` | Check and correct b-table orientation using the primary implementation. |
| `src_check_btable2` | `bash ./dsi.sh recon<hex-address> src_check_btable2` | Check and correct b-table orientation using the alternate implementation. |
| `src_flip_bx` | `bash ./dsi.sh recon<hex-address> src_flip_bx` | Flip only b-vector X. |
| `src_flip_by` | `bash ./dsi.sh recon<hex-address> src_flip_by` | Flip only b-vector Y. |
| `src_flip_bz` | `bash ./dsi.sh recon<hex-address> src_flip_bz` | Flip only b-vector Z. |
| `src_swap_bxby` | `bash ./dsi.sh recon<hex-address> src_swap_bxby` | Swap b-vector X/Y. |
| `src_swap_bybz` | `bash ./dsi.sh recon<hex-address> src_swap_bybz` | Swap b-vector Y/Z. |
| `src_swap_bxbz` | `bash ./dsi.sh recon<hex-address> src_swap_bxbz` | Swap b-vector X/Z. |
| `src_topup` | `bash ./dsi.sh recon<hex-address> src_topup "C:/data/reverse_pe.rz"` | Run TOPUP using an explicit reverse-phase-encoding source. |
| `src_topup_eddy` | `bash ./dsi.sh recon<hex-address> src_topup_eddy "C:/data/reverse_pe.rz"` | Run TOPUP when possible, followed by EDDY. |
| `src_eddy` | `bash ./dsi.sh recon<hex-address> src_eddy` | Run EDDY without an explicit TOPUP source. |
| `src_motion_correction` | `bash ./dsi.sh recon<hex-address> src_motion_correction` | Run motion correction. |
| `src_bias_field_correction` | `bash ./dsi.sh recon<hex-address> src_bias_field_correction` | Correct signal inhomogeneity. |
| `src_correct_by_t2w` | `bash ./dsi.sh recon<hex-address> src_correct_by_t2w "C:/data/T2w.nii.gz"` | Correct distortion using an explicit T2-weighted image. |
| `src_orientation_correction` | `bash ./dsi.sh recon<hex-address> src_orientation_correction` | Apply automatic volume-orientation correction. |
| `src_partial_fov` | `bash ./dsi.sh recon<hex-address> src_partial_fov "-36 -30 -20 36 30 24"` | Set the QSDR partial-FOV MNI coordinate range. |

## Minimal reconstruction workflow

```bash
bash ./dsi.sh main list_recent_src
bash ./dsi.sh main open_src "<exact path returned by list_recent_src>"
bash ./dsi.sh recon<hex-address> src_list_param
bash ./dsi.sh recon<hex-address> src_set_params "method=4&param=1.25"
bash ./dsi.sh recon<hex-address> src_recon
```

Use the exact `recon<hex-address>` returned by `open_src`. Before `src_recon`, inspect
the source images, mask, b-table, and any corrections that materially affect the
result. Do not apply orientation, b-table, motion, TOPUP/EDDY, resampling, masking,
or background-removal commands merely because they are available.

## Source-confirmed cautions

- Supply explicit parameters for file selection, thresholds, output paths,
  resolutions, and reverse-PE data. Omitting them may open a local modal dialog.
- `src_recon` is the reconstruction-window operation. Do not use
  `src_reconstruction`; the current lower-level handler treats that name as a
  compatibility no-op.
- Reconstruction and corrections are synchronous from the relay's perspective. A
  client timeout does not prove processing stopped; do not immediately resend the
  command.
- A successful AI reconstruction currently may not explicitly return the final FIB
  path or add it to the recent-FIB list. Inspect captured command output and confirm
  the generated file before opening it.
- Commands modify the loaded source state and are recorded for replay on additional
  SRC files. Preserve the original data or obtain approval before irreversible
  signal or mask changes.
- For reproducibility, record the source file, mask source, every correction,
  reconstruction method, parameter values, output metrics, template, and output
  path.
