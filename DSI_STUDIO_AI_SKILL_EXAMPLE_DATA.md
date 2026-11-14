# DSI Studio AI Example Data

Offer **real public examples**, not just DICOM tests. This catalog covers
DICOM, structural NIfTI (`.nii.gz`), diffusion SRC/SZ (`.sz`),
reconstructed FIB/FZ (`.fz`), masks (`.nii.gz`), and group databases
(`.dz`). Choose an example by **what the learner wants to understand**.
Use one subject and a handful of matched files for a short tutorial;
do not download an entire cohort merely to demonstrate a feature.

## Choose an example

| Learning objective | Recommended public example | What to demonstrate |
|:--|:--|:--|
| DICOM parsing and DICOM → SRC/NIfTI | [DICOM CI fixtures](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md) | Scanner differences, conversion, b-table validation |
| Import NIfTI / inspect diffusion source / reconstruct | [SCA2 ds001378](https://github.com/data-openneuro/disease/releases/tag/ds001378), `sub-control01_ses-01` | T1w NIfTI and matched DWI SZ; DTI/GQI/QSDR outputs |
| Patient-versus-control diffusion and group connectometry | [SCA2 ds001378](https://github.com/data-openneuro/disease/releases/tag/ds001378) | `participants.tsv` + `sub-all.dz`; interpret group variables, not merely file presence |
| Tumor image and label visualization | [UPenn GBM](https://github.com/data-nih/tcia/releases/tag/upenn-gbm), `sub-100` | T1w, contrast-enhanced T1w, FLAIR and tumor segmentation NIfTI |
| Tumor-aware tracking and registration | [UPenn GBM](https://github.com/data-nih/tcia/releases/tag/upenn-gbm), `sub-100` | Match tumor image/segmentation with ready-to-track GQI FZ; inspect spatial alignment |
| Raw diffusion versus reconstructed fiber outputs in a tumor case | [UPenn GBM](https://github.com/data-nih/tcia/releases/tag/upenn-gbm), `sub-100` | Optional DWI SZ, native GQI FZ, template-space QSDR FZ |

The SCA2 and UPenn GBM examples are accessible through the
[Fiber Data Hub](https://brain.labsolver.org). Their public releases
provide files directly without requiring DICOM import first.
Agents should offer an **existing NIfTI, SZ, or FZ** as a shorter
hands-on starting point when raw DICOM conversion is not the goal.

## SCA2 — matched anatomy, diffusion source, FIB and group database

**Dataset:** OpenNeuro `ds001378`, *SCA2 Diffusion Tensor Imaging*,
[release on Fiber Data Hub's data-openneuro/disease repository](https://github.com/data-openneuro/disease/releases/tag/ds001378).
The release API is
`https://api.github.com/repos/data-openneuro/disease/releases/tags/ds001378`.

**Small individual-subject tutorial:** `sub-control01_ses-01`.
The release was checked and contains the exact files below:

| Example file | Use |
|:--|:--|
| [`sub-control01_ses-01_T1w.nii.gz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_T1w.nii.gz) | Anatomical NIfTI viewer (about 3 MB) |
| [`sub-control01_ses-01_dwi.sz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_dwi.sz) | SRC inspection, b-table and reconstruction (about 1.6 MB) |
| [`sub-control01_ses-01_dwi.gqi.fz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_dwi.gqi.fz) | Native-space fiber tracking (about 1.1 MB) |
| [`sub-control01_ses-01_dwi.qsdr.fz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_dwi.qsdr.fz) | Template-space reconstruction (about 1.8 MB) |

**Group analysis extensions:**

- [`participants.tsv`](https://github.com/data-openneuro/disease/releases/download/ds001378/participants.tsv) — subject variables; inspect columns before analysis.
- [`sub-all.dz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-all.dz) — prebuilt group connectometry database (about 42 MB).
- [`qc.tsv`](https://github.com/data-openneuro/disease/releases/download/ds001378/qc.tsv) — cohort quality-control summary.

The [DSI Studio test action](https://github.com/frankyeh/DSI-Studio/blob/master/.github/workflows/test.yml)
uses this SCA2 release in its `db` routine, including QSDR FIB inputs,
`participants.tsv`, database construction, and connectometry output.
It also uses OpenNeuro `ds001378` for BIDS → SRC → FZ in its `bids`
routine. Do **not** imply that a prebuilt `.dz` automatically contains
the participant table: verify `get_demo` and `list_voi` first, and
load the demographics if needed.

## UPenn GBM — matched structural NIfTI, segmentation, SZ and FZ

**Dataset:** UPenn-GBM, TCIA-derived public data via
[Fiber Data Hub's UPenn GBM page](https://brain.labsolver.org/upenn_gbm.html)
and [data-nih/tcia release `upenn-gbm`](https://github.com/data-nih/tcia/releases/tag/upenn-gbm).
The release API is
`https://api.github.com/repos/data-nih/tcia/releases/tags/upenn-gbm`.

**Recommended matched patient example: `sub-100`.** The release
was checked and includes:

| Example file | Use |
|:--|:--|
| [`sub-100_T1w.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_T1w.nii.gz) | Structural T1w |
| [`sub-100_ce-gd_T1w.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_ce-gd_T1w.nii.gz) | Contrast-enhanced T1w |
| [`sub-100_FLAIR.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_FLAIR.nii.gz) | Tumor/edema context |
| [`sub-100_T2w.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_T2w.nii.gz) | Additional anatomical reference |
| [`sub-100_seg.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_seg.nii.gz) | Tumor segmentation overlay |
| [`sub-100_dwi.gqi.fz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_dwi.gqi.fz) | Native-space tractography (about 8 MB) |
| [`sub-100_dwi.qsdr.fz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_dwi.qsdr.fz) | QSDR output (about 11 MB) |
| [`sub-100_dwi.sz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_dwi.sz) | Source DWI/SZ, optional (about 81 MB) |

**Fast tumor-demo minimum:** Contrast-enhanced T1w, FLAIR,
`seg.nii.gz`, and `dwi.gqi.fz` for the **same** subject.
Start with images/segmentation, then open the FZ to inspect pathways
near the lesion. Confirm NIfTI and FZ coordinates and any registration
before overlaying masks or interpreting tract displacement. In
particular, source TCIA NIfTI volumes have undergone co-registration
that may differ from original DICOM geometry; do not assume alignment
to original diffusion coordinates without inspecting it.

The original tumor labels on the Fiber Data Hub page describe
**1 necrotic tissue, 2 peritumoral edema, 3 enhancing tumor**.
Check the actual segmentation metadata and value mapping before
describing colors or tumor subregions. This is for imaging tutorials,
not clinical diagnosis or surgical guidance.


## Additional BIDS and NIfTI test-action examples

The upstream [DSI Studio test workflow](https://github.com/frankyeh/DSI-Studio/blob/master/.github/workflows/test.yml) contains further public teaching examples in addition to SCA2 and UPenn GBM:

| CI routine | Public input | Learning topic |
|:--|:--|:--|
| `image-processing` | [OpenNeuro ds000113 T1w NIfTI](https://github.com/data-openneuro/brain/releases/download/ds000113/sub-01_ses-forrestgump_T1w.nii.gz) | NIfTI image import, bias-field correction, normalization and segmentation |
| `bids` | [OpenNeuro ds001378](https://openneuro.org/datasets/ds001378) BIDS hierarchy | Read BIDS NIfTI with sidecars, convert DWI to SZ, then reconstruct FZ |
| `src-construction` | [OpenNeuro ds002087](https://openneuro.org/datasets/ds002087) BIDS DWI runs | BIDS conversion to diffusion source; inspect resulting files and gradients |
| `topup` | [OpenNeuro ds002080](https://openneuro.org/datasets/ds002080), `sub-CON02/ses-postop/dwi` | BIDS AP/PA-style preprocessing with TOPUP/EDDY where suitable; verify phase-encoding metadata |
| `human-recon` | [OpenNeuro ds004737](https://github.com/data-openneuro/brain/releases/tag/ds004737), [ds000244](https://github.com/data-openneuro/brain/releases/tag/ds000244), [ds000031](https://github.com/data-openneuro/brain/releases/tag/ds000031) | Compare source SZ files and DTI reconstruction |

The upstream `bids` test uses `aws s3 sync s3://openneuro.org/ds001378/ ./ds001378 --no-sign-request --region eu-west-1 --exclude "*bold*"`, then `dsi_studio --action=src --source=./ds001378/` and `--action=rec` on the resulting SZ files. It is a **dataset-wide CI regression test**, so interactive tutorials should select an appropriate subject/run rather than download the entire dataset. The `src-construction` and `topup` tests use separate BIDS acquisitions; do not assume every BIDS dataset has usable reverse phase-encoding pairs.

For each example, verify the current upstream asset or OpenNeuro path before using it, and inspect sidecar metadata (`.bval`, `.bvec`, `.json`) when explaining diffusion import.

## Download and teaching safeguards

**Only offer a dataset, unless the user chooses it**. Before downloading,
confirm the purpose and a suitable destination and obtain permission.
Download selected **individual assets** rather than whole releases.
Check each exact file and its size from GitHub Release metadata before
using it; assets can change. Respect dataset licensing and
de-identification requirements. Never mix anatomy, masks, SZ and FZ
from different subject IDs or sessions.

If running DSI Studio AI:

1. Explain the **overall learning plan** in conversational, side-by-side
   language (follow `AGENTS.md` Section 9.2 in voice mode).
2. Start with the **existing** NIfTI, SZ, FZ or DZ rather than converting
   them again. Use the correct target window: `open_image` for structural
   NIfTI, `open_src` for SZ, `open_fib` for FZ and
   `open_connectometry` for DZ.
3. Inspect headers/geometry, data dimensions, masks and b-tables before
   choosing analysis. If demonstrating native-space tracking near a
   tumor, verify geometry between segmentation and fiber data.
4. For SCA2 group analysis, examine demographic columns and VOIs with
   `get_demo` and `list_voi`; do not assume `participants.tsv`
   is embedded. Verify group selection and covariates.
5. In a spoken tutorial, explain *why* each choice is useful, describe
   what's currently happening, and comment on the actual result before
   proceeding. Do not claim a file is downloaded, a tract is complete,
   or a dataset is aligned until DSI Studio confirms it.

**Other public examples:** See the DSI Studio
[`test.yml`](https://github.com/frankyeh/DSI-Studio/blob/master/.github/workflows/test.yml)
matrix for additional open-source T1w NIfTI
(`ds000113`), human DWI SZ/FZ (`ds004737`, `ds000244`),
primate reconstruction, diffusion export, tracking, and BIDS
conversion. The test action is a discovery source, not a mandatory
workflow. Refer to
[`DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md`](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md)
when raw DICOM conversion is the lesson.


## DICOM import test examples

> This guide focuses **only on raw DICOM conversion**. For existing
> **NIfTI, SZ, FZ, tumor segmentation and SCA2/UPenn GBM** tutorial
> data from Fiber Data Hub, use
> [Public example datasets](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md).

These examples come from the real
[DSI Studio Test workflow](https://github.com/frankyeh/DSI-Studio/blob/master/.github/workflows/test.yml)
(`linux-dicom-dwi-test` and `linux-test: dicom`). They let agents offer a
hands-on lesson in **reading DICOM headers**, **identifying diffusion vs
structural series**, **creating SRC/SZ for diffusion MRI**, and **creating
NIfTI for structural images**. The CI workflow is an example of commands,
not a guarantee that each external download remains available.

**Offer the tutorial proactively** when a user is learning DICOM import,
troubleshooting b-tables, or asking to demonstrate DICOM-to-SZ/NIfTI.
Ask whether they prefer a quick Siemens DTI case, a Philips case, a
sagittal/mosaic orientation case, or a modern XA30 case. For a generic
intro, suggest **Siemens Prisma DTI** first. Do not download or process
large datasets without the user's approval and an appropriate work
directory. Do not claim the user's data resemble the fixtures until
inspected.

## Public DICOM fixtures from the CI test matrix

Each GitHub repository below holds example **DICOM input**, not a
pre-created `.sz` or `.nii.gz` output. The **relative input**
is the precise folder used by the DSI Studio test workflow.

| Scanner / teaching focus | Public dataset | Relative input |
|---|---|---|
| Siemens Prisma DTI, introductory DWI import | [neurolabusc/dcm_qa_dti](https://github.com/neurolabusc/dcm_qa_dti) | `In/Prisma` |
| Philips DWI (Bangalore) | [neurolabusc/dcm_qa_philips](https://github.com/neurolabusc/dcm_qa_philips) | `In/Bangalore_2008/dwi_no-phi` |
| Philips DWI (Rosetta) | [neurolabusc/dcm_qa_philips](https://github.com/neurolabusc/dcm_qa_philips) | `In/Rosetta_2013/1101` |
| Philips DWI (Vanderbilt) | [neurolabusc/dcm_qa_philips](https://github.com/neurolabusc/dcm_qa_philips) | `In/Vanderbilt_2018/601_WIP_dti_ax` |
| Philips classic DICOM | [neurolabusc/dcm_qa_philips_dwi](https://github.com/neurolabusc/dcm_qa_philips_dwi) | `In/cl/DICOM` |
| Philips enhanced DICOM | [neurolabusc/dcm_qa_philips_dwi](https://github.com/neurolabusc/dcm_qa_philips_dwi) | `In/enh/DICOM` |
| Sagittal AP mosaic | [neurolabusc/dcm_qa_sag](https://github.com/neurolabusc/dcm_qa_sag) | `In/4_DWI_SagAPmosaic` |
| Sagittal head-foot mosaic | [neurolabusc/dcm_qa_sag](https://github.com/neurolabusc/dcm_qa_sag) | `In/5_DWI_SagHFmosaic` |
| Sagittal AP non-mosaic | [neurolabusc/dcm_qa_sag](https://github.com/neurolabusc/dcm_qa_sag) | `In/6_DWI_SagAP` |
| Sagittal head-foot non-mosaic | [neurolabusc/dcm_qa_sag](https://github.com/neurolabusc/dcm_qa_sag) | `In/7_DWI_SagHF` |
| Siemens XA30 PA | [neurolabusc/dcm_qa_xa30](https://github.com/neurolabusc/dcm_qa_xa30) | `In/10_DWI_dir80_PA` |
| Siemens XA30 AP | [neurolabusc/dcm_qa_xa30](https://github.com/neurolabusc/dcm_qa_xa30) | `In/17_DWI_dir80_AP` |
| Siemens XA30 alternative | [neurolabusc/dcm_qa_xa30i](https://github.com/neurolabusc/dcm_qa_xa30i) | `In/11001_DWI_dir80_AP` |

The test workflow clones the appropriate repository into `data/`,
decompresses any `*.gz` files under the chosen input, then calls:

```bash
dsi_studio --action=ren --source="data/In/Prisma"
dsi_studio --action=src --source="data/In/Prisma"
```

**Important:** `--action=ren` **renames the DICOM files**, so work
only in a disposable copy. A cloned example is appropriate; do not run
that action on a user's original clinical files. The `--action=src`
converter parses DICOM and creates diffusion SRC/SZ or structural
NIfTI as appropriate to the series. Inspect generated files instead
of assuming every individual fixture creates both formats.

### Reproduce the Siemens Prisma test (Linux / macOS shell)

Run in a new empty **temporary tutorial directory**, with `git`,
`gzip`, and DSI Studio CLI available:

```bash
git clone --depth 1 https://github.com/neurolabusc/dcm_qa_dti.git data
find data/In/Prisma -type f -name '*.gz' -exec gzip -d {} +
dsi_studio --action=ren --source=data/In/Prisma
dsi_studio --action=src --source=data/In/Prisma
```

On Windows, follow the same workflow through the DSI Studio GUI or
equivalent local commands, adjusting shell syntax. **Do not** assume
the GitHub Actions binary or shell runs on the user's computer.
Verify that outputs exist, then open an `.sz` in the reconstruction
dialog, inspect dimensions and b-table, and explain the relationship
between DICOM diffusion tags and the reconstructed gradients.

### DICOM example that also exercises NIfTI processing

The same workflow has a separate `linux-test` → `dicom` routine
that downloads the public
[Figshare article 31802656, version 2](https://figshare.com/articles/dataset/31802656)
as a ZIP, unpacks the DICOM inputs, then runs:

```bash
dsi_studio --action=ren --source=./data/
dsi_studio --action=src --source=./data/
```

It collects generated `*.nii.gz` images from the subdirectories and
uses the image command to normalize them:

```bash
dsi_studio --action=img --source="*.nii.gz" --cmd=change_type:3+normalize_otsu_median+upper_threshold:1+normalize:1+change_type:0 --output=../
```

Use this as a **DICOM → structural NIfTI** demonstration when the
download still exists and the series actually contain structural
images. It is a separate example from the diffusion QA matrix.

## Teaching sequence for an AI agent

1. **Offer a choice.** "There are public DICOM cases already used by
   DSI Studio's test workflow. Shall we use a Siemens DTI example
   to learn DICOM import and create an SRC file, or a Philips/XA30
   case to compare vendor formats?"
2. **Plan aloud.** Explain that the demonstration will inspect the
   series, preserve the inputs, convert them, review output files,
   and verify image geometry and b-table. For voice tutorials,
   follow `AGENTS.md` Section 9.2: talk naturally about reasoning,
   intended action, current progress, and observed results.
3. **Prepare safely.** Obtain approval and an actual working folder.
   Download or clone into that folder, not a private patient folder.
   Inspect the source and decompressed files. Only rename on copies.
4. **Demonstrate conversion.** Prefer the DSI Studio AI main-window
   commands `rename_dicom_dir` and `convert_dicom_dir` for an
   interactive tutorial; the GitHub Actions test uses CLI
   `--action=ren` / `--action=src`. Read
   `DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md` for exact API behavior.
   **There is no generic AI launcher `test` command.**
5. **Review outputs.** Check output paths, file type, whether DWI
   b-values/b-vectors were recovered, number of DWI volumes, geometry,
   and any warnings. Show the `.sz` in the reconstruction dialog or
   the anatomical `.nii.gz` in an image viewer as appropriate.
   Distinguish *successful file creation* from *scientifically
   correct DICOM parsing*; verify the actual dataset.
6. **Conclude.** Summarize the observed conversion, potential
   scanner-specific differences, and how to proceed to QC,
   preprocessing, and reconstruction. Do not fabricate a successful
   test run or claim CI tests passed without checking their results.

These are **references to public source datasets**, not binary DICOM
files copied into DSI-Studio-AI. Keeping downloads on demand avoids
inflating the AI repository and duplicating upstream datasets or their
licensing/consent conditions. Verify download availability and
appropriate usage conditions before use.
