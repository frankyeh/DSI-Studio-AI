# DSI Studio AI Reconstruction Commands and Examples

Open an SRC/SZ file with:

```bash
bash ./dsi.sh open_src "C:/data/subject.sz"
```

A successful reply includes:

```text
recon window created, id: recon...
```

It also automatically selects that new reconstruction window, so commands below can
act on it directly. Use `set_window` only when switching to another already-open
window.

`bring_to_front`, `minimize`, `maximize`, and `close` are shared dispatcher-level
window controls, not reconstruction-window operations. Read
`DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md` for their authoritative behavior. In particular,
after closing this window, select `main` or another valid current window ID because
the session retains the closed `recon...` ID.

The reconstruction-window dispatcher accepts one command name and at most one
parameter. Keep multiple values or assignments in one quoted composite string.

## Naming rule

All public reconstruction operations use concise names without the old `src_`
prefix:

```text
recon
list_param
set_param
set_params
mask_unet
resample
bias_field_correction
```

Do not use `reconstruction`, `src_recon`, `src_reconstruction`, or old `src_`
operation names. Use the concise names documented below.

## Reconstruction parameters

Inspect current values before changing them:

```bash
bash ./dsi.sh list_param
bash ./dsi.sh list_param method
```

Set one or more values with one composite `name=value` parameter:

```bash
bash ./dsi.sh set_param "method=4"
bash ./dsi.sh set_params "method=4&param=1.25&thread_count=8"
```

Both setters accept `name=value[&name=value...]`.

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

## Reconstruction command inventory

| Command | Complete example | Behavior |
|---|---|---|
| `list_param` | `bash ./dsi.sh list_param` | List all reconstruction parameters and current values. Supply one exact parameter name to list only it. |
| `set_param` | `bash ./dsi.sh set_param "method=4"` | Set one or more assignments in one composite parameter. |
| `set_params` | `bash ./dsi.sh set_params "method=4&param=1.25"` | Same assignment syntax as `set_param`; useful when setting several values. |
| `recon` | `bash ./dsi.sh recon 4` | Run reconstruction synchronously. Optional method: `1` DTI, `4` GQI, or `7` QSDR. Omission uses the current `method`. |
| `save_src` | `bash ./dsi.sh save_src "C:/output/subject.sz"` | Save the current source data. Omit the path to let the user choose it locally. |
| `save_nifti` | `bash ./dsi.sh save_nifti "C:/output/dwi.nii.gz"` | Save a 4D diffusion NIfTI plus bval/bvec files. Omit the path for a local save dialog. |
| `save_b0` | `bash ./dsi.sh save_b0 "C:/output/b0.nii.gz"` | Save the first b0 volume. Omit the path for a local save dialog. |
| `save_dwi_sum` | `bash ./dsi.sh save_dwi_sum "C:/output/dwi_sum.nii.gz"` | Save the summed diffusion image. Omit the path for a local save dialog. |
| `mask_open` | `bash ./dsi.sh mask_open "C:/data/mask.nii.gz"` | Replace the reconstruction mask using a supplied file. Omit the path to let the user choose it locally. |
| `mask_unet` | `bash ./dsi.sh mask_unet` | Generate a mask using the packaged U-Net model. Inspect the mask before reconstruction. |
| `mask_from_template` | `bash ./dsi.sh mask_from_template 0` | Generate a mask using a zero-based template index. Omission uses the current template setting. |
| `mask_threshold` | `bash ./dsi.sh mask_threshold 100` | Create a mask using an integer signal threshold. Omit the threshold to let the user choose it locally. |
| `mask_erosion` | `bash ./dsi.sh mask_erosion` | Erode the current mask. |
| `mask_dilation` | `bash ./dsi.sh mask_dilation` | Dilate the current mask. |
| `mask_defragment` | `bash ./dsi.sh mask_defragment` | Keep the principal connected mask component. |
| `mask_slice_defragment` | `bash ./dsi.sh mask_slice_defragment` | Apply slice-wise mask cleanup. |
| `mask_smoothing` | `bash ./dsi.sh mask_smoothing` | Smooth the current mask. |
| `mask_fit` | `bash ./dsi.sh mask_fit` | Fit the current mask to the diffusion-sum image. |
| `mask_negate` | `bash ./dsi.sh mask_negate` | Invert the current mask. |
| `mask_remove_background` | `bash ./dsi.sh mask_remove_background` | Permanently zero signals outside the current mask. |
| `probabilistic_masking` | `bash ./dsi.sh probabilistic_masking "C:/data/probability.nii.gz"` | Multiply diffusion signals by a same-dimension probability image. Omit the path for a local picker. |
| `set_voxel_size` | `bash ./dsi.sh set_voxel_size "1.5 1.5 2.0"` | Replace the three voxel-size values without resampling. Supply all three values. |
| `smooth_signals` | `bash ./dsi.sh smooth_signals` | Smooth diffusion signals. |
| `crop_background` | `bash ./dsi.sh crop_background 5` | Crop background with an optional voxel border. Omission uses zero. |
| `resample` | `bash ./dsi.sh resample 2` | Resample to the supplied isotropic millimeter resolution. Omit it to let the user choose locally. |
| `align_acpc` | `bash ./dsi.sh align_acpc 2` | Align to AC-PC space at the supplied output resolution. Omit it to let the user choose locally. |
| `flip_x` | `bash ./dsi.sh flip_x` | Flip diffusion images and b-vector X. |
| `flip_y` | `bash ./dsi.sh flip_y` | Flip diffusion images and b-vector Y. |
| `flip_z` | `bash ./dsi.sh flip_z` | Flip diffusion images and b-vector Z. |
| `swap_xy` | `bash ./dsi.sh swap_xy` | Swap image X/Y axes, voxel sizes, and matching b-vector components. |
| `swap_yz` | `bash ./dsi.sh swap_yz` | Swap image Y/Z axes, voxel sizes, and matching b-vector components. |
| `swap_xz` | `bash ./dsi.sh swap_xz` | Swap image X/Z axes, voxel sizes, and matching b-vector components. |
| `check_btable` | `bash ./dsi.sh check_btable` | Check b-table orientation against the current template when available; if template loading is unavailable it falls back to the no-template method. Applies the best detected b-vector permutation/flip when it improves the score. |
| `check_btable2` | `bash ./dsi.sh check_btable2` | Check b-table orientation without a template. It temporarily reconstructs DTI internally, scores 24 axis permutation/flip candidates, and applies the best detected b-vector orientation when it improves the score. |
| `flip_bx` | `bash ./dsi.sh flip_bx` | Flip only b-vector X. |
| `flip_by` | `bash ./dsi.sh flip_by` | Flip only b-vector Y. |
| `flip_bz` | `bash ./dsi.sh flip_bz` | Flip only b-vector Z. |
| `swap_bxby` | `bash ./dsi.sh swap_bxby` | Swap b-vector X/Y. |
| `swap_bybz` | `bash ./dsi.sh swap_bybz` | Swap b-vector Y/Z. |
| `swap_bxbz` | `bash ./dsi.sh swap_bxbz` | Swap b-vector X/Z. |
| `topup` | `bash ./dsi.sh topup "C:/data/reverse_pe.rz"` | Run TOPUP using an explicit reverse-PE source. With no parameter, an AI command uses automatic reverse-PE discovery. |
| `topup_eddy` | `bash ./dsi.sh topup_eddy "C:/data/reverse_pe.rz"` | Run TOPUP when possible, followed by EDDY. With no parameter, an AI command uses automatic reverse-PE discovery. |
| `eddy` | `bash ./dsi.sh eddy` | Run EDDY without an explicit TOPUP source. |
| `motion_correction` | `bash ./dsi.sh motion_correction` | Run motion correction. |
| `bias_field_correction` | `bash ./dsi.sh bias_field_correction` | Correct signal inhomogeneity. |
| `correct_by_t2w` | `bash ./dsi.sh correct_by_t2w "C:/data/T2w.nii.gz"` | Correct distortion using a T2-weighted image. Omit the path for a local picker. |
| `orientation_correction` | `bash ./dsi.sh orientation_correction` | Apply automatic volume-orientation correction. |
| `partial_fov` | `bash ./dsi.sh partial_fov "-36 -30 -20 36 30 24"` | Set the QSDR partial-FOV MNI coordinate range and record it for replay on additional SRC files. |

## Pre-reconstruction QC and b-table orientation

Before reconstruction, run SRC/SZ QC on the acquisition group and review neighboring
DWI correlation (NDC), masked NDC, DWI contrast, bad slices, and the outlier flag:

```bash
bash ./dsi.sh show_qc_src "scan1.sz" "scan2.sz" "scan3.sz"
```

Use QC to identify poor acquisitions before choosing data for b-table orientation
checking. The automatic `outlier` flag is based on masked NDC; inspect DWI contrast
separately for unusually poor values. A low-SNR or artifact-heavy SRC can make
b-table inference unreliable.

For acquisitions expected to share the same b-table orientation convention, choose
one representative `.sz` with good NDC, good signal/contrast, and no major QC
problem, then run the no-template check:

```bash
bash ./dsi.sh open_src "good_representative.sz"
bash ./dsi.sh check_btable2
```

`check_btable2` reconstructs DTI internally and compares 24 b-vector axis
permutation/flip candidates; a separate `recon` is not required. If it reports a
b-vector flip or swap, apply the identical **b-table-only** transformation to all
acquisitions in the same group using `flip_bx`, `flip_by`, `flip_bz`, `swap_bxby`,
`swap_bybz`, and/or `swap_bxbz` as appropriate. This assumes the scanner/export
pipeline used the same b-table orientation convention consistently across that group.
Do not infer group-wide orientation from a poor-SNR outlier.

As an alternative, CLI QC can check every `.sz` independently against a selected
template:

```bash
bash ./dsi.sh run_cli "--action=qc --source=C:/data/group/*.sz --check_btable=1 --template=<template> --output=C:/data/group/qc.tsv"
```

For `--action=qc`, `--check_btable=1` enables b-table checking for each matched SRC;
providing `--template` uses template-based checking, while omitting `--template`
uses the no-template method. Template-based checking can also be unreliable when
registration is poor; DSI Studio warns when template registration correlation is
low. Prefer a good-quality representative when applying one orientation convention
to a whole acquisition group.

## Isotropic resolution before reconstruction

Isotropic voxel size is important for reliable fiber tracking. If an SRC/SZ has
non-isotropic resolution, resample it to an appropriate isotropic resolution before
reconstruction:

```bash
bash ./dsi.sh resample 2
```

The scalar parameter is the target voxel size in millimeters, so `resample 2`
produces 2 mm isotropic sampling. Resampling should usually be one of the last
preprocessing steps before `recon`. Keep the original DWI sampling while performing
b-table checks and corrections that may depend on the original diffusion data or
geometry, such as TOPUP/EDDY, motion correction, or distortion correction; then
resample after those steps and before reconstruction.

## Post-correction quality control

After `eddy`, `motion_correction`, or another correction, compare saved files with the
MainWindow QC commands:

```bash
bash ./dsi.sh show_qc_src "raw.sz" "corrected.sz"
bash ./dsi.sh show_qc_fib "raw.gqi.fz" "corrected.gqi.fz"
```

Both accept multiple files and remain available regardless of the selected window.
`show_qc_src` reports DWI contrast, neighboring DWI correlation (including masked),
bad slices, and outlier status. Compare before and after correction; higher
neighboring DWI correlation indicates better inter-volume consistency, while DWI
contrast should not be treated as simply higher-is-better. `show_qc_fib` reports
Coherence Index (and QSDR R2 when applicable), not DWI contrast or neighboring DWI
correlation.

The verified teaching dataset `ds002087` is under `data-openneuro/others` and contains
raw, `eddy_corrected`, and `motion_corrected` `.sz`/`.gqi.fz` pairs for two runs.

## Worked example: GQI reconstruction

First discover and open an exact recent SRC/SZ path:

```bash
bash ./dsi.sh list_recent_src
bash ./dsi.sh open_src "<exact path returned by list_recent_src>"
```

The new reconstruction window is already selected by `open_src`. Inspect the current
configuration, set the intended GQI values, and reconstruct:

```bash
bash ./dsi.sh list_param
bash ./dsi.sh set_params "method=4&param=1.25&other_output=fa,md,rd,rdi"
bash ./dsi.sh recon 4
```

A successful reply includes one line for each generated file:

```text
reconstruction output: C:/data/subject.gqi.fz
```

Use the exact returned path for any later `open_fib` call. Do not infer it from the
source filename.

## Worked example: let the user choose a mask

The agent may intentionally invoke a local picker instead of deciding the path:

```bash
bash ./dsi.sh mask_open -Chat "Please choose the reconstruction mask in DSI Studio."
```

While the picker is open, DSI Studio may report the window or application as
`waiting`. The command completes after the user chooses a file or cancels. Then
inspect the visible mask before continuing.

## Cautions

- Reconstruction-window operations are synchronous from the relay's perspective. A
  client timeout does not prove processing stopped; do not immediately resend.
- The shared `close` command is not a reconstruction handler. It closes the selected
  window through the central dispatcher. Verify with `list_window`, then reset the
  target with `set_window main` or another valid ID.
- The AI path does not show the user-only pre-reconstruction confirmation sequence.
  Apply resampling, bias-field correction, or orientation correction only when the
  workflow or user calls for it.
- Commands modify the loaded source state and are replayed on additional SRC files
  in a multi-file reconstruction window. Preserve original data or obtain approval
  before irreversible signal or mask changes.
- Record the source file, mask source, corrections, method, parameter values, output
  metrics, template, resolution, and exact returned output paths for reproducibility.
