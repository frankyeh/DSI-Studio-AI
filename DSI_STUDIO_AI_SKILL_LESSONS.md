# DSI Studio Interactive Lessons for New Users

Use these lessons when a user asks to be taught a workflow ("teach me how to ...").
They follow the website's [How to Analyze dMRI](https://dsi-studio.labsolver.org/doc/how_to_analyze_dmri.html)
page: the pipeline (acquire, preprocess, import and reconstruct, analyze) and its
"Choose by question" table. Each lesson links the website guide for the user and the
detailed skill for you.

## How to run a lesson

Follow "Teaching from a skill" and the tutor protocol in `DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md`,
and offer a voice tutorial first unless the user asked for one (`AGENTS.md` 9.2). Each step is one human
action, one explanation, and one check:

1. Select the window (`set_window`) and highlight the control in **Point at** (a ring and, if listed, a
   gesture; the highlight has no text, the instruction goes in the dialog of step 3).
2. Explain the step in your own words from **Why** (voice or chat). The tour is a UX tutorial: voice
   only the action and what it does, and run the checks silently. Lessons 1 to 11 are analysis
   tutorials: also give the plan and teach at checkpoints (`AGENTS.md` 9.2).
3. Show the action with `ask_user_act "<action>"`, which closes by itself when the user acts on the
   highlighted control. When the action is not on it (*(say)* steps, work inside a dialog), use
   `ask_user "<action>" Done Cancel`.
4. After `done` (or `Done`), do the **Check**; if it fails, explain what went wrong and repeat the step.

- **Point at** is a `highlight_ui` target: `run:<command>` finds the control sending that command, a
  plain id is an object name, and *(say)* means nothing can be highlighted, so describe it by label and
  position.
- `user operation` lines in `log` show what the user clicked; confirm results with the **Check** state
  commands (`list_window`, `list_slice`, `list_region`, `list_tract`) or a screenshot.
- Before each step, check `list_window` for a window covering the one being taught (e.g. the Fiber Data
  Hub after a download, or a result table) and `minimize`, `move_window`, or `close` it (`AGENTS.md`
  3.3).
- Before a main-window step that opens a file or folder dialog, run
  `set_work_dir <folder holding the lesson data>` so the dialog starts in the main window's **Work Dir**, and name the file to pick.
- Tutor commands wait while a dialog or "Finished." message is open: ask the user to close it first.
- The atlas list (`addRegionFromAtlas`) is a modeless window that stays open, so tutor commands keep
  working; its controls cannot be highlighted, so describe them by label (atlas drop-down, region
  list, **Search**, **Add**, **Close**).
- Never rename, overwrite, or delete the user's files in a lesson; suggest a copy or public example data
  (`DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md`).
- The first time a lesson opens a tracking window, offer the **Tracking window tour** with
  `ask_user "Quick tour of the tracking window?" Yes Skip`, run it on Yes, then continue the lesson.
- Mouse actions have no command: add a gesture to the highlight (`click`, `double`, `right` on a
  control; `rotate`, `zoom`, `pan`, `roll`, `wheel` in the 3D view; `freehand`, `rect`, `drag` in the
  ROI window; see the gesture table in the window manual).
- End every analysis lesson with Lesson 11 (Before interpreting results).

## Lesson map

| User question | Lesson | Website guide | Detailed skill |
|---|---|---|---|
| How do I get my scans into DSI Studio? | 1 Import DICOM | [Import](https://dsi-studio.labsolver.org/doc/gui_t1.html) | `DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md` |
| How do I reconstruct fiber orientations? | 2 Reconstruct | [Reconstruct](https://dsi-studio.labsolver.org/doc/gui_t2.html) | `DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md` |
| How do I use the tracking window? | Tracking window tour | | `DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md` |
| Which pathways run through this brain? | 3 Whole-brain tracking, 4 Region-guided tracking | [Whole brain](https://dsi-studio.labsolver.org/doc/gui_t3_whole_brain.html), [ROI](https://dsi-studio.labsolver.org/doc/gui_t3_roi_tracking.html) | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` |
| What are the measures in a region? | 5 Region-based analysis | [Atlas regions](https://dsi-studio.labsolver.org/doc/gui_t3_roi_tracking.html#load-regions-from-built-in-atlases) | `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` |
| Where is the same named bundle, and how do measures vary along it? | 6 AutoTrack and tractometry | [AutoTrack](https://dsi-studio.labsolver.org/doc/gui_t3_atk.html) | `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` |
| Which regions are connected, and by which bundles? | 7 Connectome (R2R and T2R) | [Connectome](https://dsi-studio.labsolver.org/doc/gui_connectome.html) | `DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md` |
| Where did a subject change? | 8 Differential tractography | [Differential](https://dsi-studio.labsolver.org/doc/gui_t3_dt.html) | `DSI_STUDIO_AI_SKILL_DIFFERENTIAL_TRACTOGRAPHY.md` |
| Which pathways relate to a clinical variable? | 9 Correlational tractography | [Correlational](https://dsi-studio.labsolver.org/doc/gui_cx.html) | `DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md` |
| How do I evaluate a brain tumor? | 10 Brain tumor | | `DSI_STUDIO_AI_SKILL_BRAIN_TUMOR.md` |

Lessons 3 to 10 work in the tracking window; a user new to it takes the **Tracking window tour**
first. A first-time user who has DICOM data usually takes Lessons 1, 2, 3, then the analysis
lesson that matches the question.

## Lesson 1: Import DICOM to an SRC file

Goal: create the source file (`.sz`) that holds the diffusion images and b-table.
Before: ask with `ask_user` whether the user has one DWI series (files) or a whole
exam (a folder). Remind them that the original DICOM files stay untouched; do not
teach the Rename DICOM controls unless asked, because they move and rename files.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | main | `nav_rail` | Open the **Tractography** page; the numbered cards follow the pipeline: Import, Reconstruct, Track. | `list_ui tract_fmt` returns controls |
| 2 | main | `tract_fmt_dicom` | Under **Import**, choose **DICOM**. | `list_ui convert_dicom_dir` finds a visible control |
| 3a | main | `run:convert_dicom_dir` | For a whole exam: **DICOM folder...**, then select the parent folder. DSI Studio converts every series; DWI series become `.sz`, structural series `.nii.gz`. It reads b-values and b-vectors from the DICOM headers. A full exam can take minutes. | `user operation` with `convert_dicom_dir`, then the conversion messages in `log`; the `.sz` files exist |
| 3b | main | `run:open_dwi_dicom` | For one series: **DICOM file(s)...**, select its files. A **B-table** window opens *(say)*: check that the b-values and directions look plausible, set the output file name, and click **OK**. | `log` and a "SRC file created" message; the `.sz` file exists |
| 4 | main | `run:show_qc_src` *(under Reconstruct, after More...)* | Optional for one subject, recommended for a study: SRC quality control flags subjects that differ from the rest, using neighboring DWI correlation and diffusion contrast. | The QC table appears; discuss any `low-quality outlier` |

Explain: the `.sz` file is the raw starting point. Keep it, and save later stages as
new files.

## Lesson 2: Reconstruct SRC to FIB

Goal: estimate fiber orientations and diffusion metrics into a FIB file (`.fz`).
Before: ask whether the study is one subject in native space (GQI) or a cohort in
template space (QSDR), as on the website pipeline step 3.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | main | `run:open_src` | **SRC File(s) (*.sz)** opens the reconstruction window. | `list_window` shows a `recon...` window; `set_window` to it |
| 2 | recon | `nav_rail` (**Mask** page) | The mask limits reconstruction to brain tissue. Look through the slices: it should cover the brain without large gaps or much background. Use **U-Net** or **Template** if it does not. | A screenshot of the mask, or ask the user to confirm it covers the brain |
| 3 | recon | `nav_rail` (**Preprocessing** page) | Answer the questions about the acquisition; DSI Studio highlights only the corrections the data needs (How to preprocess dMRI). Defaults are suggested from the data; already applied steps show ✓. | The highlighted path matches the acquisition |
| 4 | recon | `btn_Run_Preprocessing` | Runs the selected corrections in order and stops on failure. Skip it when nothing is selected. | `user operation` lines for each correction; the processing report lists them |
| 5 | recon | `nav_rail` (**Methods** page), then `GQI` or `QSDR` | Choose the method. GQI keeps native space for one subject; QSDR maps to a template for group analysis. Both also save tensor metrics. Keep the default sampling length ratio (1.25) unless there is a reason to change it. **More...** shows the options and output metrics. | Screenshot, or ask which method is selected |
| 6 | recon | `run:recon` (**Run Reconstruction**) | Creates the `.fz` file. It can take minutes. | `user operation` with `recon`; `list_window` turns idle; the `.fz` file exists |

Explain: a written FIB can still be wrong. Lesson 3 checks it with tracking.

## Tracking window tour

Goal: a quick orientation to the tracking window's panels, mouse controls, and menus, so later lessons
can say "in the region list" or "in the 3D window" without explaining them. Keep each explanation to
one or two sentences; this is an overview, not a manual. Before: a FIB is open (`list_window` shows a
`tracking...` window; `set_window` to it). Use `list_ui panel` to confirm the panel ids, and skip any
panel the window does not show. Steps with a gesture or `click` end with `ask_user_act "<what to try>"`; panel overviews end with
`ask_user "<what to try>" Next Stop`.

- **Preflight.** If `list_ui panel` misses a panel because the user closed or moved docks, highlight
  `actionRestore_window_layout` (**Layout > Restore Window Layout**) with `ask_user_act` to bring back
  the default layout first.
- **ROI layout.** In the 3-slice or mosaic layout a click lands on whichever slice is under the
  cursor, so show drawing tools only in the single-slice layout: highlight `option:roi_layout` and ask
  the user to choose **Single Slice**, or offer `set_param roi_layout 0`.

| # | Point at | Gesture | Why | Check |
|---|---|---|---|---|
| 1 | `glAxiCheck`, then `glSagCheck`, `glCorCheck` | `click` | A newly opened FIB shows nothing in the 3D window: its slices are off. These checkboxes show the axial, sagittal, and coronal slices of the current image in 3D. If the user prefers, run `enable_slice "1 1 1"`. | The slices appear (`preview_screen 3d` has a `slice` block) |
| 2 | *(agent)* | | Optionally add a brain surface for context: `set_slice 0`, then `add_surface 0 25` (warps the template; a native-space FIB may take a moment the first time; check it with `preview_screen 3d`, see the rendering manual). | `preview_screen 3d` has a `surface` block |
| 3 | `GLWidget` | `rotate` | **3D window**: shows slices, regions, tracts, and devices together. Drag with the left button to rotate. | The user rotates (`ask_user_act`) |
| 4 | `GLWidget` | `zoom`, then `pan` | Right-drag up (or scroll) zooms; middle-drag moves the scene; Shift + left drag only tilts and Ctrl makes any drag finer. Starting a drag in a corner rolls the view (`roll`). | `ask_user_act` |
| 5 | `ROIdockWidget` | | **ROI window** ("Draw Regions"): the 2D slice used to draw and check regions. The drop-down above it (`SliceModality`) switches the image; scrolling zooms (`graphicsView` with `wheel`). | Next |
| 6 | `tool1` | `click` | The tool buttons choose how to draw: rectangle, freehand, sphere, cube, polygon, and more. Click one to select it. | `ask_user_act` |
| 7 | `graphicsView` | `freehand` | With the freehand tool, hold the left button and draw around an area; right-click or Shift erases. Drawing creates or edits the current region, which also appears in 3D. | `list_region` |
| 8 | `regionDockWidget` | | **Region list** ("Assign Regions"): every region with its checkbox, type (ROI, ROA, Seed, ...), and color. Checked regions are the ones shown, used for tracking, and measured. | Next |
| 9 | `addRegionFromAtlas` | `click` | Regions can also come from a built-in atlas instead of drawing. The atlas list opens beside the window and stays open while the user works; choose a region, click **Add**, and **Close** when done (the button shows the same list again). | `ask_user_act`, then `list_region` |
| 10 | `renderingWidgetHolder` | | **Options**: tracking parameters at the top, then how slices, tracts, regions, and surfaces are drawn. `highlight_ui option:<id>` points at one setting. | Next |
| 11 | `TractWidgetHolder` | | **Tract list**: every bundle with its checkbox and tract count. Like regions, checked tracts are the ones shown, saved, measured, or edited. | Next |
| 12 | `perform_tracking` | `click` | **Fiber Tracking** starts tracking with the current regions and options (with the drawn region checked, only tracts through it); the result appears as a new row in the tract list and in 3D. | `list_tract` shows the row `done` |
| 13 | `GLWidget` | `double` | Rotate to see the tracts, then double-click a tract or region in 3D: its row is selected in its list. | `ask_user_act` |
| 14 | `DeviceDockWidget` *(if shown)* | | **Devices**: electrodes and other devices placed in the brain. | Next |
| 15 | `menu_File`, then each menu below | | **Menus**, one highlight each, one sentence each (the menu opens; say the name too). | Next after each |

Menus, from left to right:

| Menu id | Title | Say |
|---|---|---|
| `menu_File` | File | Open and save data for this window. |
| `menuRegions`, `menuRegion_Edit`, `menuRegion_Move`, `menuRegions_Misc` | Regions, Region Edit, Region Move, Regions Misc | Create, load, edit, move, and measure regions. |
| `menuTracts`, `menu_Edit`, `menuTracts_Cluster`, `menuTracts_Misc` | Tracts, Tract Edit, Tracts Cluster, Tracts Misc | Load, save, edit, cluster, and measure tracts, including AutoTrack. |
| `menu_Slices`, `menuSegment` | Slices, Slices Segment | Add other images as slices and segment them. |
| `menuDevices` | Devices | Add and manage devices. |
| `menuScreen` | Screen | Save or copy screenshots of the views. |
| `menuView` | View | Camera views and display. |
| `menuE_xport` | Export | Export data from the window. |
| `menuLayout` | Layout | Arrange the 3D and ROI views. |
| `menuTools` | Records | Command history, to repeat the same steps on other data. |

Close with `clear_highlight` and a one-line summary: regions are drawn in the ROI window and listed
in the region list, Options control tracking and display, Fiber Tracking adds rows to the tract list,
and checked rows are what commands act on.

## Lesson 3: Whole-brain fiber tracking

Goal: an exploratory overview of all pathways, and a check of the reconstruction.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | main | `run:open_fib` | **FIB File (*.fz)** opens the tracking window. | `list_window` shows a `tracking...` window; `set_window` to it |
| 2 | tracking | `option:fa_threshold` | Tracking parameters live in the Options tree. `0` means randomized or automatic defaults; keep them for a first run. | Ask the user to confirm they see **Tracking Parameters** |
| 3 | tracking | `perform_tracking` | **Fiber Tracking** generates streamlines from the whole brain. | `list_tract` shows a bundle with streamlines and `done` |
| 4 | tracking | `GLWidget` | Rotate and look: major pathways (corpus callosum, corticospinal tract, arcuate) should follow the anatomy. Few tracts or odd shapes point to mask, b-table, or reconstruction problems. | Screenshot; ask what the user sees |
| 5 | tracking | `run:save_tract` | Save the tracts for later use. | `user operation` with `save_tract`; the file exists |

Explain: streamlines estimate plausible trajectories; they are not axons, and their
count is not connection strength.

## Lesson 4: Region-guided (ROI) tracking

Goal: isolate one pathway with regions. Before: complete Lesson 3 on the same FIB.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | tracking | `run:delete_all_tracts` | Start from an empty tract list so the new pathway is clear. | `list_tract` is empty |
| 2 | tracking | `addRegionFromAtlas` | Load an anatomical region from a built-in atlas instead of drawing it. | `list_region` shows the new region |
| 3 | tracking | *(say)* the region's type in the region list | Set its role. **ROI** keeps tracks passing through it; **ROA** removes them; **Seed** sets where tracking starts. Start with one well-supported ROI. | `list_region` shows the role |
| 4 | tracking | `run:new_region`, then `graphicsView` with a gesture | To draw a region instead, create one and draw on the slice (see the gesture table in the window manual). | `list_region` shows the drawn region with voxels |
| 5 | tracking | `perform_tracking` | Track with the region constraints. | `list_tract` shows the bundle and `done` |
| 6 | tracking | `GLWidget` | Review against anatomy. Add a second ROI or an ROA only to remove a known competing pathway. | Screenshot; ask |

Explain: the result depends on where the regions are and on the tracking thresholds.

## Lesson 5: Region-based analysis

Goal: a table of diffusion measures (for example FA, MD, QA) for each region.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | tracking | `addRegionFromAtlas` | Load atlas regions; they must be in the same space as the data. DSI Studio maps atlases to the subject. | `list_region` shows the regions |
| 2 | tracking | `run:add_slice` *(optional)* | Insert another registered image (DKI, NODDI, PET) to measure it in the same regions. Wait for its registration to finish. | `list_slice` shows the new image |
| 3 | tracking | `run:show_region_statistics` | Shows the measures for each region. | The table appears; ask the user to close it when done |
| 4 | tracking | `run:save_region_info` *(optional)* | Save region information for later analysis. | The file exists |

Explain: for a cohort in template space, the same regions can be applied to a
connectometry database instead.

## Lesson 6: AutoTrack and tractometry

Goal: the same named bundle in each subject, with its statistics and profile.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | tracking | `perform_tracking` | Check whole-brain tracking first (Lesson 3); AutoTrack depends on good data and registration. | Whole-brain tracts look plausible |
| 2 | tracking | `run:enable_auto_tract` | **Tracts > Autotrack...** enables atlas-based recognition. | The target lists appear (screenshot) |
| 3 | tracking | *(say)* the target tract lists | Choose the bundle; a parent entry maps the whole family, a child only a branch. Do not add extra regions by default. | Ask which bundle was chosen |
| 4 | tracking | `perform_tracking` | Generates the named bundle. | `list_tract` shows it and `done` |
| 5 | tracking | `GLWidget` | Review in several views. A missing or incomplete bundle is not evidence of anatomical absence. | Screenshot; ask |
| 6 | tracking | `run:show_tract_statistics` | Tract statistics: length, volume, shape, and mean measures such as QA and FA. | The table appears |
| 7 | tracking | `actionTract_Analysis_Report` | **Tract Profile...** shows how a measure changes along the bundle. Keep the profile definition the same across subjects. | The profile appears |

For several subjects, the main window's **Automatic tracking** (`run:open_auto_track`)
runs AutoTrack in batch; test a small subset first.

## Lesson 7: Connectome (R2R and T2R)

Goal: R2R maps connections between region pairs; T2R maps which regions each named
bundle reaches. Before: whole-brain tracts for R2R (Lesson 3), named bundles for T2R
(Lesson 6). The parcellation must be in the same space as the tracts.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | tracking | `run:open_connectivity_matrix` | **R2R**: choose a parcellation atlas, **end** or **pass**, and the matrix value, then **Recalculate** *(say)*. | The matrix appears |
| 2 | tracking | *(say)* threshold and export in that window | Thresholding changes the network and should be reported. Export the matrix, connectogram, or network measures. | The exported file exists |
| 3 | tracking | `addRegionFromAtlas` | **T2R**: load the parcellation (or a lesion region) as regions. | `list_region` shows the parcels |
| 4 | tracking | `run:show_t2r` | **Regions > Tract-To-Region Connectome** computes, for each checked bundle, the streamlines that pass through each checked region. | The table appears; ask the user to close it when done |

Explain: T2R works on the original streamlines. Converting a tract into a region
(`tract_to_region`) is for drawing or editing a region, not for connectivity
statistics. Keep the tract set and parcellation identical across subjects.

## Lesson 8: Differential tractography

Goal: tracts showing segments whose measures changed between two scans of one subject
(or against a reference). Before: reconstruct both scans with the same settings and
check whole-brain tracking on the baseline (Lessons 2 and 3). Scanner or protocol
differences can mimic change.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | tracking | `run:add_slice` | Insert the follow-up metric map exported from the follow-up FIB, and wait for registration. | `list_slice` shows it |
| 2 | tracking | `option:dt_index1` | **Metrics1 (m1)**: the baseline metric, such as `dti_fa`. | Ask |
| 3 | tracking | `option:dt_index2` | **Metrics2 (m2)**: the inserted follow-up map. | Ask |
| 4 | tracking | `option:dt_threshold_type`, then `option:dt_threshold` | **Type** selects the formula, for example `(m1-m2)/m1` for a decrease; **Threshold** 0.2 maps changes above 20%. | Ask |
| 5 | tracking | `perform_tracking` | Tracks only segments meeting the change criterion. | `list_tract` shows the result |
| 6 | tracking | `run:show_tract_statistics` | Report volume and length of the changed segments. | The table appears |

## Lesson 9: Correlational tractography (connectometry)

Goal: tracts associated with a study variable across a cohort, with a false discovery
rate. Before: every subject reconstructed with QSDR at the same resolution.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | main | `nav_rail` | Open the **Correlational** page. | `list_ui create_db_files` finds it |
| 2 | main | `run:create_db_files` | **FIB File(s) (*.fz)...** creates the connectometry database (`.dz`) from the subjects' QSDR files. | The `.dz` file exists |
| 3 | main | `run:open_connectometry` | **Database (*.dz)** opens the analysis window. | `list_window` shows a `connectometry...` window; `set_window` to it |
| 4 | connectometry | `open_mr_files` (the demographics button) | Load the demographics file and check every subject's values. | Ask the user to confirm the subject count matches |
| 5 | connectometry | *(say)* study variable, covariates, threshold | Choose the variable to study, control for covariates, and keep the default effect-size threshold for a first run. | Ask |
| 6 | connectometry | `run` | Runs the permutation test; it can take a while. | Its `progress` command reaches `finished`; `list_window` turns idle |
| 7 | connectometry | `show_result` | Review the tracts with positive and negative association and their FDR. | Ask the user what the report shows |

The connectometry window does not log user operations; use `progress` and
`list_window` to follow it.

## Lesson 10: Brain tumor evaluation

Goal: segment the lesion, map eloquent pathways, and measure their involvement. Read
`DSI_STUDIO_AI_SKILL_BRAIN_TUMOR.md` before teaching; this lesson is the guided
version of its presurgical steps 1 to 6. The result supports, and never replaces,
clinical review.

| # | Window | Point at | Why | Check |
|---|---|---|---|---|
| 1 | tracking | `run:add_slice` | Insert the structural images (T1w, contrast T1w, FLAIR) that show the lesion. | `list_slice` shows them |
| 2 | tracking | `graphicsView` | Check alignment in three planes before using any image: the lesion and ventricles must line up with the diffusion data. | Screenshot; ask |
| 3 | tracking | the human tumor model item from `list_ui segment_brain` (`run:segment_brain=<model>`) | **Slices > Segment** with the human tumor model gives Enhancing Tumor, Necrosis, and Peritumoral Edema. A model needing another contrast is disabled. | `list_region` shows the lesion labels by name |
| 4 | tracking | `graphicsView` | Review the segmentation on every plane. Tumor core is enhancing tumor plus necrosis; edema stays separate. A missing label is unavailable, not zero. | Screenshot; ask |
| 5 | tracking | `run:enable_auto_tract`, then `perform_tracking` | Map the eloquent pathways near the lesion on both sides (motor, language, vision; see the skill's table). Never use the lesion as a tracking region. | `list_tract` shows the named bundles |
| 6 | tracking | `run:show_t2r` | With the bundles and lesion regions checked, T2R counts the streamlines of each bundle passing through each lesion region. | The table appears; record counts against each bundle's total |
| 7 | tracking | `GLWidget` | Review each pathway against the lesion: displacement, involvement, and the healthy side. Discuss the findings as observations for clinical review. | Ask what the user concludes |

The PPTX report and its figures stay agent-side (skill section 7); there is no GUI
button for them.

## Lesson 11: Before interpreting results

Close every analysis lesson with these checks from the website:

- **Same space:** data, regions, and parcellations are aligned in the same image space.
- **Same settings:** reconstruction, tracking, and measurement settings are consistent
  across subjects.
- **Visual review:** tracts and registrations are checked against the anatomy.
- **Streamlines are not axons:** tracking estimates plausible trajectories, and
  streamline counts do not directly measure connection strength.

Point the user to [How to interpret dMRI](https://dsi-studio.labsolver.org/doc/how_to_interpret_dmri.html)
and [How tractography works](https://dsi-studio.labsolver.org/doc/how_tractography_works.html),
and mention **Records > Command History** to repeat the same steps on other datasets.
