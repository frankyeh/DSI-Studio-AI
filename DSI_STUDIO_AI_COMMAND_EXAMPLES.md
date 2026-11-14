# DSI Studio AI Command Examples Index

`AGENTS.md` is the authoritative operating manual and entrypoint; `CLAUDE.md` is only an alias to
it. This file is the index of the topic manuals, which come in two families:

- `DSI_STUDIO_AI_COMMAND_EXAMPLES_<TOPIC>.md` — command, interface, parameter, and dispatcher
  references with source-verified examples. Each area has one authoritative document.
- `DSI_STUDIO_AI_SKILL_<WORKFLOW>.md` — procedural workflows combining several commands or
  transports.

Commands go through the launcher (`DSI_STUDIO_AI_SKILL_LAUNCHER.md`):
`bash ./dsi.sh <command> [values...]`. Successful `open_src`, `open_fib`, `open_image`, and
`open_connectometry` select the new window; use `set_window` only to switch to another open window
(the selection persists).

## Command references

- [Shared window selection, controls, and GUI tutoring](DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md) — dispatcher-level, not per window
- [CLI actions and confirmation-gated shell commands](DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md) — `run_cli` and `run_shell` have their own execution and completion rules; read before use
- [Main window, Fiber Data Hub, XNAT, FIB, workspace, settings, parameters, agent readiness, and chat history](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Reconstruction commands and examples](DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions, atlas-overlap statistics, and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, atlas-overlap statistics, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Rendering, camera, surfaces, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Standalone image-window and TIPL image operations](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)

## Workflow skills

- [Launcher and session transport](DSI_STUDIO_AI_SKILL_LAUNCHER.md)
- [Web session](DSI_STUDIO_AI_SKILL_WEB.md)
- [Reconstruction](DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md)
- [Fiber tracking](DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md)
- [Brain-tumor presurgical and postsurgical evaluation](DSI_STUDIO_AI_SKILL_BRAIN_TUMOR.md)
- [Differential tractography](DSI_STUDIO_AI_SKILL_DIFFERENTIAL_TRACTOGRAPHY.md)
- [Correlational tractography](DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md)
- [T2R connectome](DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md)
- [Public example data](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md)
- [Interactive lessons for new users](DSI_STUDIO_AI_SKILL_LESSONS.md)

## Chat alongside a command

Add `-Chat "..."` to a meaningful command to tell the user what was verified and what it is about to
do; it does not alter execution. Routine polling and trivial discovery may omit it.

```bash
bash ./dsi.sh segment_brain human_synthseg 7 -Chat "I verified that the T1w slice is loaded and ready. I'm starting SynthSeg now; it may take a while to finish."
```
