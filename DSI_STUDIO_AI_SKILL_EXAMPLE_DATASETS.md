# Public example datasets for DSI Studio AI hands-on tutorials

Offer **real public examples**, not just DICOM tests. This catalog covers
DICOM, structural NIfTI (`.nii.gz`), diffusion SRC/SZ (`.sz`),
reconstructed FIB/FZ (`.fz`), masks (`.nii.gz`), and group databases
(`.dz`). Choose an example by **what the learner wants to understand**.
Use one subject and a handful of matched files for a short tutorial;
do not download an entire cohort merely to demonstrate a feature.

## Choose an example

| Learning objective | Recommended public example | What to demonstrate |
|:--|:--|:--|
| DICOM parsing and DICOM → SRC/NIfTI | [DICOM CI fixtures](DSI_STUDIO_AI_SKILL_DICOM_TEST_EXAMPLES.md) | Scanner differences, conversion, b-table validation |
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
[`DSI_STUDIO_AI_SKILL_DICOM_TEST_EXAMPLES.md`](DSI_STUDIO_AI_SKILL_DICOM_TEST_EXAMPLES.md)
when raw DICOM conversion is the lesson.
