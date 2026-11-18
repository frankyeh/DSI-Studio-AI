# DSI Studio AI Reconstruction Commands and Examples

`bash ./dsi.sh open_src "C:/data/subject.sz"` replies `recon window created, id: recon...` and selects
the new window, so the commands below act on it directly (`set_window` only to switch). The shared
`bring_to_front`, `minimize`, `maximize`, and `close` are dispatcher-level, not reconstruction
operations (`DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md`); after `close`, verify with `list_window` and
select `main` or another valid ID, since the session keeps the closed `recon...` ID.

The reconstruction dispatcher accepts one command name and at most one parameter; keep several
values or assignments in one quoted composite string. Public operations use concise names without the
old `src_` prefix (`recon`, `list_param`, `set_param`, `set_params`, `mask_from_unet`, `resample`,
`bias_field_correction`); never use `reconstruction`, `src_recon`, `src_reconstruction`, or old
`src_` names.

## GUI versus AI commands

The dialog's **2a Mask**, **2b Preprocessing**, and **2c Methods** pages and **Edit...** (Edit DWI,
Edit B-table) are GUI navigation. Mask Open/Save are **File → Open Mask...** and
**File → Save Mask...**; AI `mask_open` still works, and there is no `save_mask` AI command. **Align
Selected DWI...** rigidly aligns the selected 3D DWI to the first DWI and rotates its b-vector; it is
not `align_acpc`. The Preprocessing page's nine Yes/No questions (T1w-based distortion correction, signal drift correction, and scheme balance shown only under **Advanced...**) and **Run Preprocessing** choose a
branch from reverse-PE and shell/DSI information (conditional TOPUP/EDDY, motion, T1w distortion,
bias-field correction, resampling), mark recorded corrections, and skip recognized completed steps.
**There is no `run_preprocessing` command:** inspect the SRC data and processing record, run the
appropriate *individual* commands below, and never reapply corrections. Question-by-question behavior
and sequencing cautions are in
[`DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md`](DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md).

## Parameters

```bash
bash ./dsi.sh list_param
bash ./dsi.sh list_param method
bash ./dsi.sh set_param "method=4"
bash ./dsi.sh set_params "method=4&param=1.25&thread_count=8"
```

`list_param` lists all parameters and values, or one exact name. `set_param` and `set_params` take
the same `name=value[&name=value...]` composite.

| Parameter | Meaning |
|---|---|
| `method` | `1` DTI, `4` GQI, `7` QSDR |
| `thread_count` | Reconstruction thread count |
| `other_output` | Comma-separated output metric IDs. `dwi` writes template-space DWI beside a QSDR `.fz` as `<output>_dwi.nii.gz` with `.bval`/`.bvec` (shell schemes only); `--action=tmp` averages a group of these into one `.sz`. `fixel` stores fiber directions as `fixelN` (GQI/QSDR refine peaks analytically instead of the default `indexN`; DTI writes `fixel0` instead of the default `dir0`), readable only by DSI Studio builds from 2026-10 on. `all` excludes `dwi`, `fixel`, and `debug`. |
| `dti_ignore_high_b` | Ignore high-b-value data for tensor metrics |
| `r2_weighted` | R2-weighted reconstruction |
| `param` | GQI/QSDR diffusion sampling length ratio |
| `template` | Zero-based template index |
| `qsdr_reso` | QSDR output resolution (mm) |
| `reg_resolution`, `reg_speed`, `reg_smoothing` | Registration resolution, speed, and smoothing |
| `hist_downsampling`, `hist_raw_smoothing`, `hist_tensor_smoothing`, `hist_resolution` | Histology downsampling level, raw-image smoothing, tensor smoothing, and isotropic resolution |

## Command inventory

Commands marked "path" open a local dialog or picker when the parameter is omitted.

| Command | Example | Behavior |
|---|---|---|
| `recon` | `bash ./dsi.sh recon 4` | Reconstruct synchronously; optional method `1`/`4`/`7`, default the current `method`. |
| `save_src` | `bash ./dsi.sh save_src "C:/output/subject.sz"` | Save the current source data (path). |
| `save_nifti` | `bash ./dsi.sh save_nifti "C:/output/dwi.nii.gz"` | 4D diffusion NIfTI plus bval/bvec (path). |
| `save_b0`, `save_dwi_sum` | `bash ./dsi.sh save_b0 "C:/output/b0.nii.gz"`, `bash ./dsi.sh save_dwi_sum "C:/output/dwi_sum.nii.gz"` | First b0 volume, or the summed diffusion image (path). |
| `save_b_table`, `save_bval`, `save_bvec` | `bash ./dsi.sh save_b_table "C:/output/subject.b_table.txt"`, `bash ./dsi.sh save_bval "C:/output/subject.bval"`, `bash ./dsi.sh save_bvec "C:/output/subject.bvec"` | The b-table (b-value and b-vector per DWI), FSL b-values, or FSL b-vectors (y flipped to FSL convention) (path). |
| `mask_open` | `bash ./dsi.sh mask_open "C:/data/mask.nii.gz"` | Replace the mask from a file (path). |
| `mask_from_unet` | `bash ./dsi.sh mask_from_unet` | Mask from the U-Net tissue model of the current template's species (b0 foreground probability > 0.5); old name `mask_unet` still accepted. Inspect before reconstruction. |
| `mask_from_template` | `bash ./dsi.sh mask_from_template 0` | Mask from a zero-based template index (default: current template). |
| `mask_threshold` | `bash ./dsi.sh mask_threshold 100` | Mask from an integer signal threshold (omitted: the user chooses). |
| `mask_erosion`, `mask_dilation`, `mask_smoothing`, `mask_negate` | `bash ./dsi.sh mask_erosion` | Erode, dilate, smooth, or invert the mask. |
| `mask_defragment`, `mask_slice_defragment` | `bash ./dsi.sh mask_defragment` | Keep the principal connected component, or clean up slice-wise. |
| `mask_fit` | `bash ./dsi.sh mask_fit` | Fit the mask to the diffusion-sum image. |
| `mask_remove_background` | `bash ./dsi.sh mask_remove_background` | Permanently zero signals outside the mask. |
| `mask_background_signals` | `bash ./dsi.sh mask_background_signals "C:/data/probability.nii.gz"` | **Masking Background Signals**: multiply every DWI voxelwise by an external 3D NIfTI weight map of matching dimensions and set the mask where the map is > 0; this changes DWI signals, not only the mask (path). Legacy `probabilistic_masking` accepted. |
| `set_voxel_size` | `bash ./dsi.sh set_voxel_size "1.5 1.5 2.0"` | Replace all three voxel sizes without resampling (omitted: the user enters them). |
| `remove` | `bash ./dsi.sh remove "0,3:5,60:end"` | Remove DWIs by comma-separated zero-based index or range (`a:b`, `a:end`) or b-value (`b>3000`, `b<100`); fails if nothing matches or every DWI would go. Recorded as a step; same syntax as CLI `--remove`. |
| `add_other_image` | `bash ./dsi.sh add_other_image "t1w:C:/data/T1w.nii.gz"` | Register another NIfTI to the DWI and store it in the FIB under the optional `name:` prefix (default: file name); same as CLI `--other_image` (path). |
| `smooth_signals` | `bash ./dsi.sh smooth_signals` | Smooth diffusion signals. |
| `crop_background` | `bash ./dsi.sh crop_background 5` | Crop background with an optional voxel border (default 0). |
| `resample` | `bash ./dsi.sh resample 2` | Resample to the isotropic resolution in mm (omitted in the GUI: the value in the box beside **Resample to Isotropic**, default the in-plane voxel size). |
| `align_acpc` | `bash ./dsi.sh align_acpc 2` | Align to AC-PC space at the output resolution (omitted: the user chooses). |
| `flip_x`, `flip_y`, `flip_z` | `bash ./dsi.sh flip_x` | Flip images and the b-vector component. |
| `swap_xy`, `swap_yz`, `swap_xz` | `bash ./dsi.sh swap_xy` | Swap image axes, voxel sizes, and matching b-vector components. |
| `flip_bx`, `flip_by`, `flip_bz`, `swap_bxby`, `swap_bybz`, `swap_bxbz` | `bash ./dsi.sh flip_bx` | Flip or swap b-vector components only. |
| `check_btable` | `bash ./dsi.sh check_btable` | Check b-table orientation against the current template (falling back to the no-template method if it cannot load); apply the best permutation/flip when it improves the score. |
| `check_btable2` | `bash ./dsi.sh check_btable2` | No-template check: reconstruct DTI internally, score 24 axis permutation/flip candidates, and apply the best when it improves the score. |
| `load_bval`, `load_bvec` | `bash ./dsi.sh load_bval "C:/data/new.bval"`, `bash ./dsi.sh load_bvec "C:/data/new.bvec"` | Replace b-values (count must equal the DWI count) or b-vectors (three rows or one row per DWI; y flipped as on import) from FSL files; same as CLI `--bval`/`--bvec` on `--action=rec`. |
| `regenerate_btable` | `bash ./dsi.sh regenerate_btable`, `bash ./dsi.sh regenerate_btable "C:/data/reference.sz"` | Rebuild lost or corrupted b-vectors from a single- or multi-shell reference SRC (default: the template's reference `<template>.sz`, e.g. `human.sz`). DWIs with b ≥ 500 are grouped into shells by recorded b-value. Each shell of this SRC and of the reference gets an equivalent b-value estimated from its signal alone (no b-vectors: per-voxel mean and variance, WM/GM/CSF fractions, core-WM over pure-GM signal); each target shell is matched to the reference shell with the nearest equivalent b-value, whose DWIs are converted to the target's equivalent b-value. The reference b0 is affinely aligned to this b0; each DWI gets the correlation-weighted direction of its three best-correlated converted reference DWIs and its shell's equivalent b-value (rounded). The log lists each shell's recorded and equivalent b-value and each DWI's new b-value and best correlation (`dwi <i> b=<b> best r=<r>`) for quality checks. DWIs with b < 500 are unchanged, and the b-table is untouched on failure. A DSI SRC (q-space grid) needs a DSI reference (the template reference is not DSI, so pass one); each DWI with b ≥ 100 then takes both the b-value and the b-vector of its one best-correlated reference DWI. CLI: `--cmd=regenerate_btable` or `--cmd=regenerate_btable=<reference.sz>`. |
| `convert_btable` | `bash ./dsi.sh convert_btable "C:/data/target.sz"` | Convert shell DWI (not DSI; single shell allowed) to the b-table of a shell SRC (e.g. `human.sz`), to match another scan's scheme. Shells (b ≥ 500) of both the data and the target SRC get equivalent b-values from their signal (recorded b-values unused; both logged). Each target shell takes the data shell with the nearest equivalent b-value, converted to the target shell's equivalent b-value and interpolated to each target direction with scheme balance's angular Gaussian (uses the current b-vectors: check them first). The result has the target's b-vectors, its shells' equivalent b-values (rounded), and the mean b0 (b = 0) for its entries with b < 500. GUI: Edit DWI **Convert to B-table of SRC...**. CLI: `--cmd=convert_btable=<target.sz>`. |
| `correct_signal_drift` | `bash ./dsi.sh correct_signal_drift` | Preprocessing step for shell data, before `scheme_balance`: within each shell (b ≥ 500) and the b0 volumes, three passes divide each volume by its gain, its mean over core isotropic gray matter (P45 < mean < P90 with noise-subtracted dispersion ≤ P30 of that band, recomputed from the corrected volumes each pass) relative to the mean of all volumes there. Logs each volume's gain and adds "The signal drift was corrected..." to the report. GUI: Preprocessing **Advanced...** shows the question "Correct signal drift?" (default No) and **Signal Drift Correction**. Passes (no change) when already applied. CLI: `--cmd=correct_signal_drift`. |
| `scheme_balance` | `bash ./dsi.sh scheme_balance` | Optional preprocessing step: store the GQI balanced scheme as the DWI (each shell resampled to 181, 126, 81, or 46 directions by its mean b-value; the first b0 kept), changing the b-table, and add "The diffusion sampling scheme was balanced..." to the report. Without it, GQI and QSDR balance their own copy of the b-table during reconstruction and leave the SRC (b-table and DWI) unchanged. GUI: Preprocessing **Advanced...** shows "Balance the shell sampling?" (shell data, default No) and **Scheme Balance**. Fails for DSI-grid schemes; passes (no change) when already applied. CLI: `--cmd=scheme_balance`. |
| `topup`, `topup_eddy` | `bash ./dsi.sh topup "C:/data/reverse_pe.rz"`, `bash ./dsi.sh topup_eddy "C:/data/reverse_pe.rz"` | TOPUP with an explicit reverse-PE source, or TOPUP when possible followed by EDDY; without a parameter, an AI command discovers the reverse-PE source automatically. |
| `eddy` | `bash ./dsi.sh eddy` | EDDY without an explicit TOPUP source. |
| `motion_correction`, `bias_field_correction`, `orientation_correction` | `bash ./dsi.sh motion_correction` | Motion correction, signal inhomogeneity correction, or automatic volume-orientation correction. |
| `correct_by_t1w` | `bash ./dsi.sh correct_by_t1w "C:/data/T1w.nii.gz\|1.5"` | Correct AP–PA susceptibility distortion with the subject's T1w; optional `\|<mm>` sets the isotropic output resolution (`0` or none = native; in the GUI, the drop-down beside the T1w question, default 1.5 mm) (path). Legacy `correct_by_t2w` is an alias at native resolution. |
| `partial_fov` | `bash ./dsi.sh partial_fov "-36 -30 -20 36 30 24"` | Set the QSDR partial-FOV MNI coordinate range, recorded for replay on additional SRC files (omitted: the user enters it). |

## Pre-reconstruction QC and b-table orientation

Run SRC/SZ QC on the acquisition group and review neighboring DWI correlation (NDC), masked NDC, DWI
contrast, bad slices, and the outlier flag (based on masked NDC; inspect DWI contrast separately for
unusually poor values). Low-SNR or artifact-heavy SRC files make b-table inference unreliable.

```bash
bash ./dsi.sh show_qc_src "scan1.sz" "scan2.sz" "scan3.sz"
bash ./dsi.sh open_src "good_representative.sz"
bash ./dsi.sh check_btable2
```

For acquisitions sharing a b-table convention, run `check_btable2` (no separate `recon` needed) on one
representative `.sz` with good NDC and contrast and no major QC problem. If it reports a flip or swap,
apply the identical **b-table-only** transformation (`flip_bx`, `flip_by`, `flip_bz`, `swap_bxby`,
`swap_bybz`, `swap_bxbz`) to every acquisition in the group, assuming the scanner/export pipeline used
one convention. Never infer group orientation from a poor-SNR outlier.

If flips and swaps cannot fix the b-table, replace it: `load_bval`/`load_bvec` when the correct FSL
files exist, or `regenerate_btable` with a reference whose b-table is known correct (it replaces
the b-values of DWIs with b ≥ 500 by their shell's equivalent b-value, or for DSI data by the best-matched
reference DWI's b-value, and the b-vectors). Then run `check_btable2` and inspect fiber directions
before reconstruction.

- **Automatic reference:** without a parameter, DSI Studio downloads
  `https://github.com/data-others/atlas/releases/download/<template>/<template>.sz` once to
  `<temp>/data-others/atlas/<template>/` in the system temp folder, reuses it later (also offline),
  and downloads again if the cache is invalid. Only the human template's 2 mm reference
  (`human/human.sz`) is published. A missing asset (404), no network without a valid cache, a corrupt
  download, or a cancelled download reports an error and leaves the b-table unchanged. Do not use the
  old HCP1065 links.
- **Explicit reference:** `regenerate_btable=<reference.sz>` uses any SRC you supply (in the GUI,
  **Regenerate B-table from SRC...**, or `regenerate_btable src` to pick it there). DSI data always
  needs an explicit DSI reference: the template references are multishell, so the parameterless form
  (the GUI's **Template-Based** button) reports an error for a DSI SRC.
- **Parallel runs:** never start several parameterless runs while the cache may be missing or being
  replaced (they race on the same file); fetch and check the reference once, then pass every job the
  explicit path (`--cmd=regenerate_btable=<path>`).
- **Cluster or batch runs:** the temp folder is often per job (`$TMPDIR` on Slurm), so keep the
  template's `.sz` on persistent shared storage and pass that path.

Alternatively, CLI QC checks every `.sz` independently:

```bash
bash ./dsi.sh run_cli "--action=qc --source=C:/data/group/*.sz --check_btable=1 --template=<template> --output=C:/data/group/qc.tsv"
```

`--check_btable=1` enables the check per matched SRC; `--template` selects template-based checking,
omitting it the no-template method. Template-based checking can fail with poor registration (DSI
Studio warns at low registration correlation); prefer a good representative when applying one
convention to a whole group.

## Isotropic resolution

Isotropic voxels matter for reliable tracking. `resample 2` gives 2 mm isotropic sampling. Resample
non-isotropic data as one of the last steps before `recon`: keep the original sampling for b-table
checks and corrections that depend on the original data or geometry (TOPUP/EDDY, motion or
distortion correction), then resample.

## Post-correction QC

```bash
bash ./dsi.sh show_qc_src "raw.sz" "corrected.sz"
bash ./dsi.sh show_qc_fib "raw.gqi.fz" "corrected.gqi.fz"
```

These MainWindow commands take several files and work whatever window is selected. `show_qc_src`
reports DWI contrast, neighboring DWI correlation (including masked), bad slices, and outlier status:
higher neighboring DWI correlation means better inter-volume consistency, but DWI contrast is not
simply higher-is-better. `show_qc_fib` reports Coherence Index (and QSDR R2 when applicable), not DWI
contrast or neighboring DWI correlation. The verified teaching dataset `ds002087` in
`data-openneuro/others` has raw, `eddy_corrected`, and `motion_corrected` `.sz`/`.gqi.fz` pairs for two
runs.

## Worked examples

GQI reconstruction:

```bash
bash ./dsi.sh list_recent_src
bash ./dsi.sh open_src "<exact path returned by list_recent_src>"
bash ./dsi.sh list_param
bash ./dsi.sh set_params "method=4&param=1.25&other_output=fa,md,rd,rdi"
bash ./dsi.sh recon 4
```

Each generated file is reported as `reconstruction output: C:/data/subject.gqi.fz`; use that exact
path for `open_fib`, never one inferred from the source filename.

Letting the user choose a mask: `bash ./dsi.sh mask_open -Chat "Please choose the reconstruction mask in DSI Studio."`
While the picker is open, DSI Studio may report `waiting`; the command completes after the user
chooses or cancels. Then inspect the mask.

## Cautions

- Operations are synchronous from the relay's perspective; a client timeout does not prove processing
  stopped, so do not resend immediately.
- The AI path skips the user-only pre-reconstruction confirmations; apply resampling, bias-field
  correction, or orientation correction only when the workflow or user calls for it.
- Commands modify the loaded source and are replayed on every SRC of a multi-file window. Preserve
  original data or obtain approval before irreversible signal or mask changes.
- Record the source file, mask source, corrections, method, parameter values, output metrics,
  template, resolution, and exact returned output paths.
