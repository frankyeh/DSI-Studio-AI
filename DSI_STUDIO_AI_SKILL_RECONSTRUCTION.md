# DSI Studio Reconstruction Guide for AI Agents

Reconstruction converts diffusion signals into fiber orientations and metrics:

```text
DICOM or NIfTI + bval/bvec → SZ → reconstruction → FZ
```

## Starting points

There are two entry routes. Do not mix them up.

**From DICOM:** Convert first with `convert_dicom_dir` (or File → Open
Source Images). Point it at the parent folder containing all series, not at
an individual series folder; it converts recursively. DSI Studio reads
b-values and b-vectors directly from the DICOM headers during conversion. Do
not look for separate bval/bvec files; they do not exist for a DICOM start.
Expect conversion to take minutes for a full multi-series exam (e.g. 250+
seconds for 30+ series including multi-shell DWI). DWI series become `.sz`;
structural series become `.nii.gz`.

Warning: DICOM files pulled from a PACS/server often arrive with generic or
duplicate filenames and may need renaming (`rename_dicom_dir`) before
conversion. Renaming destroys the original filenames permanently. Warn the
user before renaming, and suggest backing up or copying the DICOM folder
first if the original names matter to them.

**From NIfTI:** The starting point is a 4D DWI NIfTI plus its matching
`.bval` and `.bvec` files (BIDS layout). All three must be present and
correspond volume-for-volume before opening. Use `open_dwi_nifti` or
`save_nifti` on an already-open source.

NIfTI data may or may not be preprocessed already. Check the dataset README
or description before deciding: if a reverse-encoding DWI is supplied
alongside (e.g. a second NIfTI with opposite phase encoding), TOPUP/eddy
still needs to run. If the data is documented as already corrected, skip
preprocessing and go straight to reconstruction. Do not assume either way.

In both cases the first saved product is `subject_raw.sz`. Never overwrite it.

Preserve the raw input and each important processing stage:

```text
subject_raw.sz
subject_preprocessed.sz
subject_gqi.fz
subject_qsdr.fz
```

Never overwrite the only raw SZ file. A successfully written FZ can still be
anatomically wrong.

## Tutorials

- [Acquisition and pipeline](https://www.youtube.com/watch?v=Sn2eH07axF4)
- [Reconstruction tutorial](https://www.youtube.com/watch?v=-J8qBMiHQHk)
- [DTI quality control](https://www.youtube.com/watch?v=stL4GMeTC1I)
- [Diffusion models and metrics](https://www.youtube.com/watch?v=wbrMJHD5mKs)
- [NIfTI to tractography](https://www.youtube.com/watch?v=iuBtgGLohsg)

## Required Workflow

### 1. Define the analysis

Choose the reconstruction from the downstream goal:

| Method | Use when |
|---|---|
| **GQI** | Native-space tractography, crossing fibers, tractometry, or subject-specific connectomes |
| **DTI** | Tensor metrics are required or the acquisition cannot support robust crossing-fiber reconstruction |
| **QSDR** | Group analysis, connectometry, or another workflow requiring a common template space |

Do not choose QSDR merely for convenience. Native-space GQI is preferable for
individual anatomy, lesions, distortion, and presurgical work.

### 2. Inspect the source before reconstruction

Do not ask the user to describe their files. Ask only for the data location,
then inspect it yourself with `run_shell` (`dir "<path>"` on Windows,
`ls "<path>"` elsewhere). Identify DICOM series folders vs NIfTI+bval/bvec
sets from the listing before deciding the starting route.

Confirm:

- dimensions, voxel size, volume count, b-values, and b-vector count;
- brain coverage and image orientation;
- motion, distortion, slice dropout, signal spikes, and background noise;
- neighboring-DWI correlation;
- correspondence between every image volume and b-table row.

Stop and report severe corruption. Reconstruction parameters cannot recover
missing slices, inadequate coverage, very low SNR, insufficient directions, or
susceptibility information that was never acquired.

### 3. Apply only justified corrections

Decide from what data is available, not from habit:

- **Reverse-phase b0 available** → run TOPUP for susceptibility distortion,
  then EDDY for eddy currents and motion.
  (`--rev_pe=<rev_b0> --save_src=subject_preprocessed.sz`, then
  `--cmd="[Step T2][Corrections][EDDY]"`)

  How to spot the reverse-phase series in a DICOM listing: in the common
  AP-PA pattern, only one phase-encoding direction carries the full DWI;
  the reversed direction has only b0 (or a few b0 volumes) for TOPUP. Look
  for a second run of the same protocol (e.g. `dir258_2` next to `dir258_1`)
  that is much smaller than the full run. SBRef images paired with each run
  also hint at the run structure.

  Do not try to determine whether it is AP/PA or LR/RL yourself. As long as
  the two runs have opposite phase-encoding directions, DSI Studio figures
  out the pair automatically (it also reads phase direction from NIfTI JSON
  sidecars when present). `--rev_pe` accepts `.nii.gz` or `.sz`.

  Reverse-phase patterns seen in practice (see DSI-Studio-Test/topup):

  - **AP/PA** (most common): full DWI one way, b0-only the other.
    Example: `s12_dMRI_dir258_1_HDFT` (full AP) + `s14_dMRI_dir258_2_HDFT`
    (b0 PA). The reverse may be named `DWIB0REVPE`.
  - **PA/AP** (flipped): same as above with directions swapped.
    Example: full `HCPDTI` (PA) + `DWIB0REVPE_b0` (AP).
  - **LR/RL** (HCP-style, less common): full DWI both ways or full + b0.
    Example: `100206_3T_DWI_dir95_3mm` (LR) + `.rz` reverse file (RL).
  - **Full + Full**: both directions carry the full protocol (larger, slower).
  - **Full + multiple b0**: reversed side has several b0 volumes.

  File clues: DSI Studio uses the `.rz` extension for reverse-phase data.
  After TOPUP it writes `<name>.topup.AP_PA.nii.gz` (or `.topup.RL_LR.nii.gz`),
  `<name>.topup.acqparams.txt`, and a `.topup_log`. Presence of these outputs
  means TOPUP already ran — do not run it again.

- **No reverse-phase data** → EDDY alone for motion and eddy currents.
  Accept that susceptibility distortion cannot be fully corrected; do not
  claim otherwise.
- **Clean single-shell data, minimal motion** → EDDY is optional. Inspect
  first; do not preprocess by default.

Rules:

- Avoid repeated interpolation, registration, smoothing, or resampling.
- Isotropic resampling is recommended for anisotropic data; see section 6.
  It does not create true spatial resolution.
- Save corrected data as a new SZ file (`subject_preprocessed.sz`).
- State which artifact each operation addresses.

### 4. Verify image and b-table orientation

Check left-right, anterior-posterior, superior-inferior, laterality, and template
compatibility. Image flips or axis swaps must transform b-vectors consistently.
After any orientation operation, recheck anatomical landmarks and record the
change; an apparently plausible image may still be mirrored.

Automatic b-table checking is evidence, not proof. Confirm its result using
anatomy, local fiber directions, and whole-brain tractography. Be cautious with
low-SNR, low-direction, partial-coverage, animal, or severely pathological data.

### 5. Inspect the mask

The mask should include the entire brain and peripheral white matter without
admitting excessive background or disconnected fragments. Inspect axial,
coronal, and sagittal views.

- A small mask truncates pathways and cortical endpoints.
- A broad mask adds background orientations and wastes computation.

### 6. Select reconstruction settings

#### Resampling to isotropic (recommended)

Anisotropic voxels are bad for tractography. Many scanners acquire high
in-plane resolution (e.g. 0.5 mm) with thick slices (e.g. 5 mm). Resample to
isotropic at a resolution between the in-plane and slice thickness — e.g.
1 mm or 2 mm for 0.5×0.5×5 mm data. This does not create true spatial
resolution, but it gives tractography consistent step geometry. Check the
voxel size during source inspection (section 2) and resample before
reconstruction if the slice thickness is much larger than the in-plane
resolution.

#### GQI

Start near:

- **1.25** for typical in-vivo human diffusion MRI;
- **0.6** for typical ex-vivo diffusion MRI.

These are starting points, not constants. When optimization is needed, compare
several sampling-length ratios. Select the highest value that resolves expected
crossings without producing false secondary fibers in coherent regions such as
the corpus callosum. A low value may merge crossings; an excessive value may
create spurious orientations.

#### DTI

Use DTI for FA, MD, AD, RD, tensor elements, and principal eigenvectors. A
single tensor cannot resolve multiple fiber populations. For multishell data,
consider restricting conventional tensor fitting to suitable lower b-values
and record the shells used.

#### QSDR

Select the correct species template and a resolution appropriate to the
acquisition and brain size. Smaller output voxels increase computation and file
size but do not restore missing information. Verify nonlinear registration,
laterality, and attached T1w/T2w alignment.

### 7. Request only needed outputs

Possible outputs include `fa`, `md`, `ad`, `rd`, `tensor`, `gfa`, `rdi`, and
`odf`. Full ODF storage can greatly enlarge the FZ file and is unnecessary for
ordinary tractography unless a downstream method explicitly needs it.

### 8. Validate the FZ

Open the result and inspect:

- anisotropy contrast and laterality;
- dominant directions in coherent white matter;
- plausible multiple directions in known crossing regions;
- the mask boundary;
- QSDR alignment when applicable;
- whole-brain tractography and major commissural/projection pathways.

Do not validate reconstruction from one QA, FA, or color map alone. Widespread
tract failure usually indicates source quality, b-table, orientation, mask, or
reconstruction problems rather than one tract definition.

### 9. Batch only compatible inputs

Use one batch only when every dataset should receive the same corrections,
orientation operations, mask strategy, reconstruction method, template,
sampling length, resolution, and outputs. Separate heterogeneous acquisitions,
species, orientations, or subjects needing unique corrections.

## Common Failures

| Observation | Check first |
|---|---|
| Major tracts have globally wrong directions | Image orientation and b-table flips/swaps |
| Implausible secondary directions in coherent white matter | Sampling length, noise, and b-table |
| Crossings are not resolved | Sampling length and acquisition angular sampling |
| Fibers appear outside the brain | Mask extent and background noise |
| Peripheral pathways are missing | Restrictive mask |
| QSDR anatomy is distorted | Template, orientation, registration, and pathology |
| Many AutoTrack bundles fail | SRC quality, motion, b-table, mask, and whole-brain tracking |
| Left and right are reversed | Flip/swap history and handedness |
| FZ is unexpectedly large | Full ODF or unused metrics |

Do not repeatedly tune parameters to make a poor acquisition look attractive.

## Example Commands

Default native-space GQI:

```bash
dsi_studio --action=rec --source=subject.sz --method=4 --param0=1.25 --output=subject_gqi.fz
```

Batch GQI:

```bash
dsi_studio --action=rec --source=*.sz --method=4 --param0=1.25 --output=fib/
```

EDDY followed by GQI:

```bash
dsi_studio --action=rec --source=subject.sz --cmd="[Step T2][Corrections][EDDY]" --method=4 --param0=1.25 --output=subject_gqi.fz
```

TOPUP/EDDY preparation using reverse-phase data:

```bash
dsi_studio --action=rec --source=subject_raw.sz --rev_pe=subject_rev_b0.nii.gz --save_src=subject_preprocessed.sz
```

QSDR:

```bash
dsi_studio --action=rec --source=subject.sz --method=7 --output=subject_qsdr.fz
```

Available parameters may vary by version. Prefer commands captured from the
current GUI command history when reproducing an interactive workflow.

## Record for Reproducibility

Record:

- DSI Studio version and all input/output filenames;
- acquisition dimensions, voxel size, volumes, shells, and phase encoding;
- reverse-phase input, TOPUP, EDDY, motion, and bad-slice results;
- neighboring-DWI correlation;
- every image and b-table flip or axis swap;
- mask source and edits;
- resampling;
- reconstruction method and GQI sampling length;
- QSDR template and resolution;
- DTI shell selection;
- requested metrics, ODF setting, and attached images;
- post-reconstruction and whole-brain tracking QC.
