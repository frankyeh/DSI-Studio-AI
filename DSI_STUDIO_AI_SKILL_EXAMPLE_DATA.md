# DSI Studio AI Example Data

Offer **real public examples**, not just DICOM tests: DICOM, structural NIfTI (`.nii.gz`), diffusion
SRC/SZ (`.sz`), reconstructed FIB/FZ (`.fz`), masks (`.nii.gz`), and group databases (`.dz`). Choose by
**what the learner wants to understand**; use one subject and a few matched files for a short tutorial,
never a whole cohort just to demonstrate a feature. These are **references to public source
datasets**, not files copied into DSI-Studio-AI: downloading on demand avoids inflating the repository
and duplicating upstream data or its licensing/consent conditions.

## Choose an example

| Learning objective | Public example | What to demonstrate |
|:--|:--|:--|
| DICOM parsing, DICOM → SRC/NIfTI | [DICOM CI fixtures](#dicom-import-test-examples) | Scanner differences, conversion, b-table validation |
| Import NIfTI / inspect diffusion source / reconstruct | [SCA2 ds001378](https://github.com/data-openneuro/disease/releases/tag/ds001378), `sub-control01_ses-01` | T1w NIfTI and matched DWI SZ; DTI/GQI/QSDR outputs |
| Patient-vs-control diffusion, group connectometry | [SCA2 ds001378](https://github.com/data-openneuro/disease/releases/tag/ds001378) | `participants.tsv` + `sub-all.dz`; interpret group variables, not just file presence |
| Tumor image and label visualization | [UPenn GBM](https://github.com/data-nih/tcia/releases/tag/upenn-gbm), `sub-100` | T1w, contrast-enhanced T1w, FLAIR, tumor segmentation NIfTI |
| Tumor-aware tracking and registration | UPenn GBM `sub-100` | Tumor image/segmentation with the ready-to-track GQI FZ; inspect alignment |
| Raw diffusion vs reconstructed outputs in a tumor case | UPenn GBM `sub-100` | Optional DWI SZ, native GQI FZ, template-space QSDR FZ |

SCA2 and UPenn GBM are on the [Fiber Data Hub](https://brain.labsolver.org); their releases provide
files directly, so offer an **existing NIfTI, SZ, or FZ** as a shorter hands-on start when DICOM
conversion is not the goal.

## SCA2: matched anatomy, diffusion source, FIB, and group database

OpenNeuro `ds001378`, *SCA2 Diffusion Tensor Imaging*, on Fiber Data Hub's
[data-openneuro/disease release](https://github.com/data-openneuro/disease/releases/tag/ds001378)
(API `https://api.github.com/repos/data-openneuro/disease/releases/tags/ds001378`). The release was
checked for these files of `sub-control01_ses-01`:

| File | Use |
|:--|:--|
| [`sub-control01_ses-01_T1w.nii.gz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_T1w.nii.gz) | Anatomical NIfTI viewer (about 3 MB) |
| [`sub-control01_ses-01_dwi.sz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_dwi.sz) | SRC inspection, b-table, reconstruction (about 1.6 MB) |
| [`sub-control01_ses-01_dwi.gqi.fz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_dwi.gqi.fz) | Native-space fiber tracking (about 1.1 MB) |
| [`sub-control01_ses-01_dwi.qsdr.fz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-control01_ses-01_dwi.qsdr.fz) | Template-space reconstruction (about 1.8 MB) |

Group extensions: [`participants.tsv`](https://github.com/data-openneuro/disease/releases/download/ds001378/participants.tsv)
(subject variables; inspect columns first),
[`sub-all.dz`](https://github.com/data-openneuro/disease/releases/download/ds001378/sub-all.dz)
(prebuilt connectometry database, about 42 MB), and
[`qc.tsv`](https://github.com/data-openneuro/disease/releases/download/ds001378/qc.tsv) (cohort QC
summary). The [DSI Studio test action](https://github.com/frankyeh/DSI-Studio/blob/master/.github/workflows/test.yml)
uses this release in its `db` routine (QSDR FIB inputs, `participants.tsv`, database construction,
connectometry) and `ds001378` for BIDS → SRC → FZ in its `bids` routine. A prebuilt `.dz` does not
necessarily contain the participant table: check `get_demo` and `list_voi`, and load demographics if
needed.

## UPenn GBM: matched structural NIfTI, segmentation, SZ, and FZ

TCIA-derived UPenn-GBM via [Fiber Data Hub's UPenn GBM page](https://brain.labsolver.org/upenn_gbm.html)
and the [data-nih/tcia `upenn-gbm` release](https://github.com/data-nih/tcia/releases/tag/upenn-gbm)
(API `https://api.github.com/repos/data-nih/tcia/releases/tags/upenn-gbm`). Checked files for `sub-100`:

| File | Use |
|:--|:--|
| [`sub-100_T1w.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_T1w.nii.gz) | Structural T1w |
| [`sub-100_ce-gd_T1w.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_ce-gd_T1w.nii.gz) | Contrast-enhanced T1w |
| [`sub-100_FLAIR.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_FLAIR.nii.gz) | Tumor/edema context |
| [`sub-100_T2w.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_T2w.nii.gz) | Additional anatomical reference |
| [`sub-100_seg.nii.gz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_seg.nii.gz) | Tumor segmentation overlay |
| [`sub-100_dwi.gqi.fz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_dwi.gqi.fz) | Native-space tractography (about 8 MB) |
| [`sub-100_dwi.qsdr.fz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_dwi.qsdr.fz) | QSDR output (about 11 MB) |
| [`sub-100_dwi.sz`](https://github.com/data-nih/tcia/releases/download/upenn-gbm/sub-100_dwi.sz) | Source DWI/SZ, optional (about 81 MB) |

**Fast tumor demo:** contrast-enhanced T1w, FLAIR, `seg.nii.gz`, and `dwi.gqi.fz` of the **same**
subject; show images/segmentation first, then open the FZ to inspect pathways near the lesion. Confirm
NIfTI/FZ coordinates and any registration before overlaying masks or interpreting displacement: the
TCIA NIfTI volumes were co-registered, possibly differently from the original DICOM geometry, so never
assume alignment to diffusion coordinates without inspecting it. The Fiber Data Hub page labels
**1 necrotic tissue, 2 peritumoral edema, 3 enhancing tumor**; check the actual segmentation values
before describing colors or subregions. For imaging tutorials only, not diagnosis or surgical guidance.

## Additional BIDS and NIfTI test-action examples

| CI routine | Public input | Learning topic |
|:--|:--|:--|
| `image-processing` | [OpenNeuro ds000113 T1w NIfTI](https://github.com/data-openneuro/brain/releases/download/ds000113/sub-01_ses-forrestgump_T1w.nii.gz) | NIfTI import, bias-field correction, normalization, segmentation |
| `bids` | [OpenNeuro ds001378](https://openneuro.org/datasets/ds001378) BIDS hierarchy | BIDS NIfTI with sidecars → SZ → FZ |
| `src-construction` | [OpenNeuro ds002087](https://openneuro.org/datasets/ds002087) DWI runs | BIDS → diffusion source; inspect files and gradients |
| `topup` | [OpenNeuro ds002080](https://openneuro.org/datasets/ds002080), `sub-CON02/ses-postop/dwi` | AP/PA-style TOPUP/EDDY where suitable; verify phase-encoding metadata |
| `human-recon` | [ds004737](https://github.com/data-openneuro/brain/releases/tag/ds004737), [ds000244](https://github.com/data-openneuro/brain/releases/tag/ds000244), [ds000031](https://github.com/data-openneuro/brain/releases/tag/ds000031) | Compare source SZ files and DTI reconstruction |

The `test.yml` matrix also covers primate reconstruction, diffusion export, and tracking; it is a
discovery source, not a mandatory workflow. The `bids` test runs
`aws s3 sync s3://openneuro.org/ds001378/ ./ds001378 --no-sign-request --region eu-west-1 --exclude "*bold*"`,
then `dsi_studio --action=src --source=./ds001378/` and `--action=rec` on the SZ files: a
**dataset-wide CI regression test**, so a tutorial picks one subject/run instead. `src-construction`
and `topup` use separate acquisitions; not every BIDS dataset has usable reverse phase-encoding pairs.
Verify the current asset or OpenNeuro path, and inspect sidecars (`.bval`, `.bvec`, `.json`) when
explaining diffusion import.

## Download and teaching safeguards

- **Only offer a dataset** until the user chooses it; confirm purpose, a suitable destination, and
  permission before downloading. Fetch selected **individual assets**, not whole releases, checking
  each exact file and size in GitHub Release metadata (assets change). Respect licensing and
  de-identification. Never mix anatomy, masks, SZ, and FZ across subject IDs or sessions.
- Explain the **overall learning plan** conversationally (in voice mode follow `AGENTS.md`
  Section 9.2), then start from the **existing** file in the right window: `open_image` for NIfTI,
  `open_src` for SZ, `open_fib` for FZ, `open_connectometry` for DZ.
- Inspect headers/geometry, dimensions, masks, and b-tables before choosing an analysis; verify
  segmentation/fiber geometry before native-space tracking near a tumor. For SCA2 group analysis check
  `get_demo`/`list_voi`, group selection, and covariates.
- In a spoken tutorial explain *why* each choice matters, what is happening, and the actual result
  before moving on. Never claim a download, tract, or alignment until DSI Studio confirms it.

## DICOM import test examples

From the real [DSI Studio Test workflow](https://github.com/frankyeh/DSI-Studio/blob/master/.github/workflows/test.yml)
(`linux-dicom-dwi-test` and `linux-test: dicom`): hands-on lessons in **reading DICOM headers**,
**telling diffusion from structural series**, **creating SRC/SZ for diffusion**, and **creating NIfTI
for structural images**. The workflow shows commands; it does not guarantee downloads stay available.

**Offer it proactively** when a user is learning DICOM import, troubleshooting b-tables, or wants
DICOM-to-SZ/NIfTI shown. Ask which they prefer: a quick Siemens DTI case (default for a generic intro:
**Siemens Prisma DTI**), Philips, sagittal/mosaic orientation, or modern XA30. Never download or process
large data without approval and a work directory, and never claim the user's data resemble the fixtures
until inspected.

Each repository holds **DICOM input** only (no `.sz`/`.nii.gz`); the relative input is the exact
folder the workflow uses:

| Scanner / focus | Dataset | Relative input |
|---|---|---|
| Siemens Prisma DTI (intro) | [neurolabusc/dcm_qa_dti](https://github.com/neurolabusc/dcm_qa_dti) | `In/Prisma` |
| Philips DWI (Bangalore, Rosetta, Vanderbilt) | [neurolabusc/dcm_qa_philips](https://github.com/neurolabusc/dcm_qa_philips) | `In/Bangalore_2008/dwi_no-phi`, `In/Rosetta_2013/1101`, `In/Vanderbilt_2018/601_WIP_dti_ax` |
| Philips classic / enhanced DICOM | [neurolabusc/dcm_qa_philips_dwi](https://github.com/neurolabusc/dcm_qa_philips_dwi) | `In/cl/DICOM`, `In/enh/DICOM` |
| Sagittal AP / head-foot mosaic | [neurolabusc/dcm_qa_sag](https://github.com/neurolabusc/dcm_qa_sag) | `In/4_DWI_SagAPmosaic`, `In/5_DWI_SagHFmosaic` |
| Sagittal AP / head-foot non-mosaic | [neurolabusc/dcm_qa_sag](https://github.com/neurolabusc/dcm_qa_sag) | `In/6_DWI_SagAP`, `In/7_DWI_SagHF` |
| Siemens XA30 PA / AP | [neurolabusc/dcm_qa_xa30](https://github.com/neurolabusc/dcm_qa_xa30) | `In/10_DWI_dir80_PA`, `In/17_DWI_dir80_AP` |
| Siemens XA30 alternative | [neurolabusc/dcm_qa_xa30i](https://github.com/neurolabusc/dcm_qa_xa30i) | `In/11001_DWI_dir80_AP` |

The workflow clones into `data/`, decompresses `*.gz` under the input, then runs `--action=ren` and
`--action=src`. To reproduce the Prisma case in a new empty **temporary tutorial directory** (Linux /
macOS, with `git`, `gzip`, and the DSI Studio CLI):

```bash
git clone --depth 1 https://github.com/neurolabusc/dcm_qa_dti.git data
find data/In/Prisma -type f -name '*.gz' -exec gzip -d {} +
dsi_studio --action=ren --source=data/In/Prisma
dsi_studio --action=src --source=data/In/Prisma
```

**`--action=ren` renames the DICOM files**: use it only on a disposable copy (a clone is fine), never
on a user's original clinical files. `--action=src` creates diffusion SRC/SZ or structural NIfTI as the
series dictates; inspect outputs rather than assume both appear. On Windows use the GUI or equivalent
local commands; never assume the GitHub Actions binary or shell runs on the user's computer. Then open
an `.sz` in the reconstruction dialog, inspect dimensions and b-table, and relate DICOM diffusion tags
to the reconstructed gradients.

**DICOM → structural NIfTI.** The `linux-test` → `dicom` routine downloads
[Figshare article 31802656, version 2](https://figshare.com/articles/dataset/31802656) as a ZIP, unpacks
it, runs `dsi_studio --action=ren --source=./data/` and `dsi_studio --action=src --source=./data/`,
collects the `*.nii.gz` outputs, and normalizes them:

```bash
dsi_studio --action=img --source="*.nii.gz" --cmd=change_type:3+normalize_otsu_median+upper_threshold:1+normalize:1+change_type:0 --output=../
```

Use it only when the download exists and the series really contain structural images.

### Teaching sequence

1. **Offer a choice**, e.g. "Shall we use a Siemens DTI case from DSI Studio's test workflow to learn
   DICOM import and create an SRC file, or a Philips/XA30 case to compare vendors?"
2. **Plan aloud**: inspect the series, preserve inputs, convert, review outputs, verify geometry and
   b-table (voice: `AGENTS.md` Section 9.2: reasoning, intended action, progress, results).
3. **Prepare safely**: approval and a real working folder (never a private patient folder); inspect
   the decompressed source; rename only copies.
4. **Convert**: prefer the main-window commands `rename_dicom_dir` and `convert_dicom_dir` (exact
   behavior in `DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md`); CI uses `--action=ren` / `--action=src`.
   **There is no generic AI launcher `test` command.**
5. **Review**: output paths and types, recovered b-values/b-vectors, DWI volume count, geometry, and
   warnings; show the `.sz` in the reconstruction dialog or the `.nii.gz` in an image viewer.
   Successful file creation is not proof of correct DICOM parsing.
6. **Conclude**: the observed conversion, scanner-specific differences, and next steps (QC,
   preprocessing, reconstruction). Never fabricate a run or claim CI passed without checking.
