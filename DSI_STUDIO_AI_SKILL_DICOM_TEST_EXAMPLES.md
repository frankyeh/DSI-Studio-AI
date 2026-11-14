# DSI Studio DICOM example datasets for hands-on AI tutorials

> This guide focuses **only on raw DICOM conversion**. For existing
> **NIfTI, SZ, FZ, tumor segmentation and SCA2/UPenn GBM** tutorial
> data from Fiber Data Hub, use
> [Public example datasets](DSI_STUDIO_AI_SKILL_EXAMPLE_DATASETS.md).

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
