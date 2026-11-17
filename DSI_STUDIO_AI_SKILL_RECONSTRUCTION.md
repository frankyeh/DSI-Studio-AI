# DSI Studio Reconstruction Guide for AI Agents

Reconstruction turns diffusion signals into fiber orientations and metrics:
`DICOM or NIfTI + bval/bvec → SZ → reconstruction → FZ`.

## Starting points (two routes; do not mix them)

**From DICOM.** Convert with `convert_dicom_dir` (GUI: File → Open Source Images), pointed at the
parent folder holding all series (it recurses). b-values and b-vectors come from the DICOM headers, so
there are no separate bval/bvec files. A full multi-series exam takes minutes (e.g. 250+ s for 30+
series including multi-shell DWI). DWI series become `.sz`, structural series `.nii.gz`. Most DICOM
files have generic or duplicate names and need `rename_dicom_dir` first, which **permanently destroys
the original names**: warn the user and suggest backing up or copying the folder if names matter.

**From NIfTI.** A 4D DWI NIfTI plus matching `.bval` and `.bvec`, corresponding volume-for-volume,
opened with `open_dwi_nifti` (or `save_nifti` on an open source). BIDS naming
(`sub-<label>[_ses-<label>]_dwi.nii.gz` with `.bval`/`.bvec`/`.json`; spot the `_dwi.nii.gz` suffix in a
`dir` listing) → `bids_to_src` on the folder converts all DWI sets at once. Check the dataset README
before deciding on preprocessing: a supplied reverse-encoding DWI means TOPUP/eddy still has to run;
data documented as corrected go straight to reconstruction. Assume neither.

Either way the first product is `subject_raw.sz`; **never overwrite it**. Keep each important stage
(`subject_raw.sz`, `subject_preprocessed.sz`, `subject_gqi.fz`, `subject_qsdr.fz`). A successfully
written FZ can still be anatomically wrong.

## Example data and tutorials

Offer data to suit the goal ([`DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md`](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md)
lists verified Fiber Data Hub assets): **SCA2 (`ds001378`)** has matched T1w NIfTI, source DWI SZ,
ready-to-track GQI/QSDR FZ, and `sub-all.dz` (a small single control suits a first reconstruction or
b-table lesson); **UPenn GBM (`upenn-gbm`)** `sub-100` has T1w, contrast T1w, FLAIR, tumor segmentation,
SZ, and FZ (inspect alignment before mixing modalities); the Siemens/Philips/XA30 DICOM examples only
when DICOM parsing is the lesson. Sources: DSI Studio's
[`test.yml`](https://github.com/frankyeh/DSI-Studio/blob/master/.github/workflows/test.yml) and the
[Fiber Data Hub](https://brain.labsolver.org). Use a disposable workspace with approval, download
individual assets, inspect content and processing history, don't re-preprocess corrected public
derivatives, and don't assume a prebuilt DZ embeds its demographics.

Videos: [Acquisition and pipeline](https://www.youtube.com/watch?v=Sn2eH07axF4),
[Reconstruction tutorial](https://www.youtube.com/watch?v=-J8qBMiHQHk),
[DTI quality control](https://www.youtube.com/watch?v=stL4GMeTC1I),
[Diffusion models and metrics](https://www.youtube.com/watch?v=wbrMJHD5mKs),
[NIfTI to tractography](https://www.youtube.com/watch?v=iuBtgGLohsg) (older videos show older layouts).

## Current reconstruction dialog (November 2026)

GUI navigation labels, not AI commands. Open an SRC from **Tractography → 2 Reconstruct → SRC File(s)
(*.sz)**; the adjacent **More...** offers **Batch SRC → FIB** and **SRC quality control**. The dialog
sidebar (full height) has **2a Mask**, **2b Preprocessing**, **2c Methods**, and **Edit...** (exposing
**Edit DWI** and **Edit B-table**); the single-file output filename sits below the right-side pages and
**Run Reconstruction** runs the selected method. Moving or grouping buttons did not remove operations;
the **File**, **Edit**, **B-table**, **Corrections**, and **QSDR** menus remain. For the visible
workflow see [Reconstruct: SRC to FIB](https://dsi-studio.labsolver.org/doc/gui_t2.html); when web text
or videos lag, the live build and source win.

- **Mask (2a):** thresholding, smoothing, dilation/erosion, defragmentation, U-Net, or template. Open
  and Save are now **File → Open Mask...** / **File → Save Mask...** (the AI command `mask_open` is
  independent of the menu).
- **Preprocessing (2b):** seven Yes/No questions select a highlighted path, run by one **Run
  Preprocessing** button; completed steps show ✓ and steps the SRC report records as applied are
  skipped. Its suggestions are not proof a correction is needed.
- **Methods (2c):** DTI, GQI, or QSDR. GQI and QSDR show the diffusion sampling length ratio slider
  (0.10 to 3.00); QSDR adds Template and Resolution. **More...** adds Options (high-accuracy fixel
  output, tensor from b < 1750, ODF vectors), a **QSDR Registration** card (Manual Align, Partial FOV,
  T1W-based QSDR), and an **Output Metrics** card. Every method, including GQI and QSDR, saves tensor
  metrics. The editable output filename appears for one source and is hidden for a batch.
- **Edit DWI:** inspect volumes and b-values, remove bad volumes, edit geometry; **Align Selected
  DWI...** rigidly aligns the selected **3D DWI volume** to the first volume and rotates its b-vector
  (not slice-by-slice). Image and signal cards expand on demand.
- **Edit B-table:** inspect and correct b-values and directions.

**Preprocessing questions** (displayed order):

1. **Reverse phase-encoding b0?** Yes requests the opposite-encoding file; that path uses TOPUP,
   possibly with EDDY.
2. **Shell-based acquisition?** Few shells vs a DSI grid; a default is suggested from the b-values but
   confirm it.
3. **Try to save data with motion issues?** Optional motion correction; not routinely for clean data or
   after EDDY.
4. **Try T1w-based distortion correction?** Optional for a matching T1w on eligible paths without
   reverse-phase data; requests a T1w. Inspect the outcome.
5. **Bias field already corrected?** No selects bias-field correction unless the report records it.
6. **Need isotropic resolution?** Yes selects resampling for unequal voxel dimensions not already
   resampled (default suggested from voxel size).
7. **Correct eddy current distortion?** Shell-based only; chooses combined TOPUP/EDDY or TOPUP alone on
   the TOPUP path.

Questions 1 and 2 pick one of four paths (reverse-PE present/absent × shell/DSI). Steps: `topup_eddy`,
`topup`, `eddy`, `motion_correction`, `correct_by_t1w`, `scheme_balance` (shell data), `bias_field_correction`, `resample`, run in the
flow's order and stopping on failure. Completion detection reads report text and can be incomplete:
check the processing history rather than trusting a missing ✓. **Agents:** these are GUI features, not
launcher parameters, and there is no `run_preprocessing` command. Inspect the acquisition, report, and
b-table, then invoke individual documented corrections deliberately and in order; never apply every
suggested step automatically, and batch only subjects that truly share requirements.

## Required workflow

### 1. Define the analysis

| Method | Use when |
|---|---|
| **GQI** | Native-space tractography, crossing fibers, tractometry, subject-specific connectomes |
| **DTI** | Tensor metrics are required, or the acquisition cannot support robust crossing-fiber reconstruction |
| **QSDR** | Group analysis, connectometry, or other common-template-space workflows |

Never choose QSDR for convenience: native GQI is preferable for individual anatomy, lesions,
distortion, and presurgical work.

### 2. Inspect the source

Ask only for the data location, never for a description; inspect it with `run_shell`
(`dir "<path>"` on Windows, `ls "<path>"` elsewhere) and tell DICOM series folders from
NIfTI+bval/bvec sets. Confirm dimensions, voxel size, volume count, b-values, b-vector count, coverage,
orientation, motion, distortion, slice dropout, spikes, background noise, neighboring-DWI correlation,
and volume-to-b-table correspondence. Stop and report severe corruption: parameters cannot recover
missing slices, poor coverage, very low SNR, too few directions, or unacquired susceptibility data.

### 3. Apply only justified corrections, in order

`--action=rec` lays steps out in this sequence; follow it manually in the GUI:

1. **b-table flips/swaps** first (spatial operations transform b-vectors with the image).
2. **Image orientation** (rotation, flips); b-vectors follow.
3. **TOPUP**: susceptibility distortion (needs reverse-phase data).
4. **EDDY**: eddy currents and motion. Without reverse-phase data, **T1w distortion correction**
   (`correct_by_t1w`) replaces TOPUP and runs after EDDY or motion correction.
5. **Bias field correction**: smooth coil-sensitivity intensity variation biases QA; fix before
   reconstruction.
6. **Isotropic resampling** (section 6).
7. **Mask**, after all geometric changes.

Keep the original geometry for acquisition-dependent corrections (TOPUP/EDDY, motion, distortion), then
resample; never resample first. Decide by available data, not habit:

- **Reverse-phase b0** → TOPUP, then EDDY (`--rev_pe=<rev_b0> --save_src=subject_preprocessed.sz`,
  then `--cmd="[Step T2][Corrections][EDDY]"`), except DSI/HDFT.
  `--rev_pe=<file>` triggers TOPUP **followed by EDDY**; for TOPUP only use
  `--cmd="topup=<file>+motion_correction"`.
- **DSI/HDFT (23 b-values, e.g. 258 directions)** → TOPUP plus built-in motion correction, no EDDY
  (EDDY handles many distinct b-values poorly). Never run motion correction after EDDY; they overlap.
- **Single-shell (one b-value) or multi-shell (2–3)** → EDDY (with TOPUP when reverse-phase exists).
- **No reverse-phase, T1w available** → EDDY (or motion correction), then `correct_by_t1w=<T1w>|<mm>`
  (GUI **[Corrections][T1w Distortion Correction...]**). It converts the first b0 to T1-like contrast,
  brain-extracts and bias-corrects the T1w, rigidly aligns T1w to b0, estimates a nonlinear warp along
  the image y axis (AP–PA) only, warps all DWIs once from native data with T1-guided interpolation and
  Jacobian modulation, and rebuilds the mask. Only for AP/PA phase encoding (not LR/RL); volumes must
  already be aligned to the first b0 (hence EDDY first). The resolution (`|1.5`, `|1.0`, or `|0`
  native) replaces resampling: don't resample again. It errors on deformation folding or failed T1w
  brain extraction: report it, don't retry blindly. Inspect the corrected b0 against the attached T1w.
- **No reverse-phase, no T1w** → EDDY alone; susceptibility distortion stays uncorrected, so never
  claim otherwise.
- **Clean single-shell, minimal motion** → EDDY optional; inspect first, never preprocess by default.

**Finding the reverse-phase series.** Commonly one direction carries the full DWI and the reverse only
b0 (or a few b0s): look for a much smaller second run of the same protocol (e.g. `dir258_2` beside
`dir258_1`); SBRef images hint at run structure. Don't work out AP/PA vs LR/RL yourself: DSI Studio
pairs opposite directions automatically (also from NIfTI JSON sidecars), and `--rev_pe` takes `.nii.gz`
or `.sz`. The reverse data must match the main DWI's dimensions; pick the DWI whose geometry matches.
Patterns seen (DSI-Studio-Test/topup):

- **AP/PA** (most common): `s12_dMRI_dir258_1_HDFT` (full AP) + `s14_dMRI_dir258_2_HDFT` (b0 PA); the
  reverse may be named `DWIB0REVPE`.
- **PA/AP**: full `HCPDTI` (PA) + `DWIB0REVPE_b0` (AP).
- **LR/RL** (HCP-style): `100206_3T_DWI_dir95_3mm` (LR) + `.rz` reverse file (RL).
- **Full + Full** (both full protocol; slower) and **Full + multiple b0**.

`.rz` is DSI Studio's reverse-phase extension. TOPUP writes `<name>.topup.AP_PA.nii.gz` (or
`.topup.RL_LR.nii.gz`), `<name>.topup.acqparams.txt`, and a `.topup_log`; if present, TOPUP already ran.

Rules: avoid repeated interpolation, registration, smoothing, or resampling; save corrections as a new
SZ (`subject_preprocessed.sz`); state which artifact each operation addresses.

**QC the preprocessed SZ** (NDC = neighboring DWI correlation, and contrast). TOPUP fixes deformation
only, not NDC or contrast, and masks the background, which inflates unmasked NDC and contrast: compare
**masked NDC** only (a small drop is fine) and never credit contrast gains to EDDY/motion correction
unchecked. A substantial masked-NDC drop or bad slices: stop and investigate. NDC also reveals motion,
dropout, and spikes. For a group, preprocess everyone, then QC all `.sz` together and follow up every
outlier the report flags (outlier detection needs a group; one subject is never flagged).

### 4. Verify image and b-table orientation

Check left-right, anterior-posterior, superior-inferior, laterality, and template compatibility; flips
and axis swaps must transform b-vectors consistently. Recheck landmarks and record each orientation
change: a plausible image may still be mirrored. Flipped b-tables are common, especially from NIfTI and
in animals. Checks (CLI `--check_btable`):

- **Template-aware** (`--check_btable=1`, or `--cmd="check_btable"`): align to the template and compare
  major tract directions; when a template fits.
- **No-template** (`--check_btable=1` without `--template`, or `--cmd="check_btable2"`): 24-candidate
  permutation/flip check.
- Batch: `dsi_studio --action=qc --source=*.sz --check_btable=1` (add `--template=<name>` for the
  template-aware check).

A convention found on a good representative scan (e.g. `021fx`) can be applied as a **b-table-only**
correction to scans sharing it, e.g. `--cmd="swap_bybz+flip_bx"` (swap y/z, then flip x; chain with
`+`); never infer a group correction from a low-SNR or artifact-heavy outlier.

**Lost or corrupted bval/bvec**: replace them with `--bval=<file> --bvec=<file>` on `--action=rec` (or
`load_bval` / `load_bvec`), or `--cmd=regenerate_btable` (`regenerate_btable`), which gives each shell
of DWIs with b ≥ 500 its equivalent b-value estimated from the signal and rebuilds the b-vectors from the
reference shell converted to that b-value; check the logged best correlation of each DWI (DSI data needs an
explicit DSI reference, since the template references are multishell, and each DWI with b ≥ 100 takes the b-value and b-vector of its best-correlated reference
DWI). The parameterless
form downloads
`https://github.com/data-others/atlas/releases/download/<template>/<template>.sz` once to the system
temp folder and reuses it; only the human 2 mm reference (`human/human.sz`) is published so far. A
missing asset, no network without cache, or a corrupt/cancelled download errors and leaves the b-table
unchanged; never use the retired HCP1065 links. `--cmd=regenerate_btable=<reference.sz>` takes an
explicit reference. **Never run several parameterless `regenerate_btable` jobs in parallel** while the
cache may be missing (they race on one file): download and check it once, put it on persistent shared
storage (not per-job `$TMPDIR` on Slurm), and pass that path to every job. Then check orientation.

**Matching another scheme**: `--cmd=convert_btable=<target.sz>` (`convert_btable`) converts shell
data (not DSI) to the b-table of a shell SRC: both get equivalent b-values from their signal, each
target shell takes the data shell with the nearest one, converted to the target's equivalent b-value and
interpolated to the target directions; target b < 500 entries get the mean b0. It relies on the current
b-vectors, so check or regenerate them first.

Exclude corrupted volumes with `--remove=<indices or b>value>` on `--action=rec` or the `remove`
command (e.g. `3,10:12` or `b>3000`); it is recorded in the steps and report.

Automatic checks are evidence, not proof: confirm with anatomy, local fiber directions, and whole-brain
tractography, cautiously for low-SNR, low-direction, partial-coverage, animal, or pathological data.

**Agent limits, handled without asking the user to inspect:** a brain not in axial view (common in
animals; dimensions may hint, e.g. the longest axis is not superior-inferior; humans rarely flip, mainly
an occasional z-flip), and mask quality, which metrics cannot judge. The b-table check's template R²
covers both (CLI `--export_r` writes a `.rXX` file): if poor, state that wrong orientation or a bad mask
is likely and what it implies.

### 5. Inspect the mask

It should include the whole brain and peripheral white matter without excess background or fragments;
inspect all three planes. Too small truncates pathways and cortical endpoints; too broad adds
background orientations and computation.

**Masking Background Signals** (`mask_background_signals`; old name `probabilistic_masking` still
accepted) is an optional signal-weighting step: it multiplies every DWI voxelwise by a 3D NIfTI map of
the DWI's dimensions (weights not clamped to [0, 1]) and sets the binary mask where the map > 0. It is
not simple background masking or probability estimation. Use it only when that multiplication is
intended, and preserve the original SZ first.

### 6. Select reconstruction settings

**Isotropic resampling (recommended).** Anisotropic voxels (e.g. 0.5 mm in-plane, 5 mm slices) hurt
tractography: resample between in-plane and slice thickness (e.g. 1 or 2 mm for 0.5×0.5×5 mm) before
reconstruction. It gives consistent step geometry, not true resolution.

**GQI.** Start near **1.25** (in-vivo human) or **0.6** (ex-vivo). These are starting points: when
optimizing, compare several ratios and take the highest that resolves expected crossings without false
secondary fibers in coherent regions such as the corpus callosum (too low merges crossings; too high
creates spurious orientations).

**DTI.** FA, MD, AD, RD, tensor elements, principal eigenvectors; one tensor cannot resolve multiple
populations. For multishell data consider fitting only suitable lower b-values and record the shells.

**QSDR.** Correct species template; resolution suited to acquisition and brain size (smaller voxels cost
time and space and restore nothing). Verify nonlinear registration, laterality, and attached T1w/T2w
alignment. For multishell or single-shell data, `dwi` in `other_output` also writes the template-space
DWI beside the ordinary `.fz`: `<output>_dwi.nii.gz` (4D float) with `<output>_dwi.bval` and
`<output>_dwi.bvec` (e.g. `subject.qsdr_dwi.nii.gz`), under the subject's current b-table (balanced if
`scheme_balance` ran). DSI grids ignore it. The `.fz` itself holds no DWI.

### 7. Request only needed outputs

Options: `fa`, `md`, `ad`, `rd`, `tensor`, `gfa`, `rdi`, `odf`, and `dwi` (QSDR, shell schemes). Full
ODF storage greatly enlarges the FZ and is unnecessary for ordinary tractography.

### 8. Validate the FZ

`open_fib` the `.fz` and `add_slice` all available structural contrasts (T1w, T2w, FLAIR, others), not
just T1w. Inspect anisotropy contrast and laterality, dominant directions in coherent white matter,
plausible crossings, the mask boundary, QSDR alignment, and whole-brain tractography with major
commissural/projection pathways. Never validate from one QA, FA, or color map; widespread tract failure
points to source quality, b-table, orientation, mask, or reconstruction, not one tract definition.

### 9. Batch only compatible inputs

One batch only when all datasets share corrections, orientation operations, mask strategy, method,
template, sampling length, resolution, and outputs; separate heterogeneous acquisitions, species,
orientations, or subjects needing unique fixes.

## Common failures

| Observation | Check first |
|---|---|
| Globally wrong tract directions | Image orientation, b-table flips/swaps |
| Implausible secondary directions in coherent WM | Sampling length, noise, b-table |
| Crossings unresolved | Sampling length, angular sampling |
| Fibers outside the brain | Mask extent, background noise |
| Peripheral pathways missing | Restrictive mask |
| QSDR anatomy distorted | Template, orientation, registration, pathology |
| Many AutoTrack bundles fail | SRC quality, motion, b-table, mask, whole-brain tracking |
| Left and right reversed | Flip/swap history and handedness |
| FZ unexpectedly large | Full ODF or unused metrics |

Never keep tuning parameters to make a poor acquisition look attractive.

## Example commands

```bash
# native GQI; batch
dsi_studio --action=rec --source=subject.sz --method=4 --param=1.25 --output=subject_gqi.fz
dsi_studio --action=rec --source=*.sz --method=4 --param=1.25 --output=fib/
# EDDY then GQI
dsi_studio --action=rec --source=subject.sz --cmd="[Step T2][Corrections][EDDY]" --method=4 --param=1.25 --output=subject_gqi.fz
# TOPUP/EDDY preparation with reverse-phase data
dsi_studio --action=rec --source=subject_raw.sz --rev_pe=subject_rev_b0.nii.gz --save_src=subject_preprocessed.sz
# QSDR
dsi_studio --action=rec --source=subject.sz --method=7 --output=subject_qsdr.fz
# QSDR with template-space DWI, then GQI or an SRC from that .fz
dsi_studio --action=rec --source=subject.sz --method=7 --other_output=fa,md,rd,rdi,dwi --output=subject_qsdr.fz
dsi_studio --action=rec --source=subject_qsdr.fz --method=4 --param=1.25 --output=subject_qsdr_gqi.fz
dsi_studio --action=rec --source=subject_qsdr.fz --save_src=subject_qsdr.sz
```

Parameters vary by version; prefer commands from the current GUI command history when reproducing an
interactive workflow.

## Record for reproducibility

DSI Studio version and all filenames; acquisition dimensions, voxel size, volumes, shells, phase
encoding; reverse-phase input, TOPUP, EDDY, motion, bad-slice results; neighboring-DWI correlation;
every image and b-table flip or swap; mask source and edits; resampling; method and GQI sampling length;
QSDR template and resolution; DTI shell selection; requested metrics, ODF setting, attached images;
post-reconstruction and whole-brain tracking QC.
