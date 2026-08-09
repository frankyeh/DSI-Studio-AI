# DSI Studio AI Command Examples Index

`AGENTS.md` is the authoritative operating manual. This file is the index/root for
the topic manuals. Topic manuals use two filename families:

- `DSI_STUDIO_AI_COMMAND_EXAMPLES_<TOPIC>.md` — command, interface, parameter, and
  dispatcher references with source-verified examples.
- `DSI_STUDIO_AI_SKILL_<WORKFLOW>.md` — procedural workflows that combine multiple
  commands or transports to accomplish a task.

`DSI_STUDIO_AI_COMMAND_EXAMPLES.md` is the deliberate family index and therefore has
no topic suffix. `AGENTS.md` is the authoritative entrypoint, and `CLAUDE.md` is only
an alias to `AGENTS.md`; neither is a topic manual.

Use DSI Studio commands through the launcher documented in
`DSI_STUDIO_AI_SKILL_LAUNCHER.md`:

```bash
bash ./dsi.sh <command> [values...]
```

Successful `open_src`, `open_fib`, `open_image`, and `open_connectometry` commands
automatically select the newly created window. Use `set_window` only when switching
to another already-open window; the selection persists until changed again.

## Command references

Each command/interface area has one authoritative `COMMAND_EXAMPLES` document:

- [Shared window selection and controls](DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md)
- [CLI actions and confirmation-gated shell commands](DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md)
- [Main window, Fiber Data Hub, FIB, workspace, settings, and parameters](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Reconstruction commands and examples](DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Rendering, camera, surfaces, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Standalone image-window and TIPL image operations](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)

The shared window commands are dispatcher-level controls rather than duplicate
implementations in each data window. `run_cli` and `run_shell` are global MainWindow
commands with their own execution and completion rules; read their dedicated command
reference before using them.

## Workflow skills

Use `SKILL` documents when the task is procedural rather than a command lookup:

- [Launcher and session transport](DSI_STUDIO_AI_SKILL_LAUNCHER.md)
- [ChatGPT Web GitHub issue session](DSI_STUDIO_AI_SKILL_GITHUB_ISSUE_SESSION.md)
- [Reconstruction](DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md)
- [Fiber tracking](DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md)
- [Differential tractography](DSI_STUDIO_AI_SKILL_DIFFERENTIAL_TRACTOGRAPHY.md)
- [Correlational tractography](DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md)
- [T2R connectome](DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md)

## Chat alongside a command

For a meaningful command, add `-Chat "..."` to tell the user what was verified and
what the command is about to do:

```bash
bash ./dsi.sh segment_brain human_synthseg 7 -Chat "I verified that the T1w slice is loaded and ready. I'm starting SynthSeg now; it may take a while to finish."
```

`-Chat` is shown to the user and does not alter command execution. Routine polling
and trivial discovery commands may omit it to avoid repetitive updates.
