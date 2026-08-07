# DSI Studio AI Command Examples

Use these commands through the launcher documented in `DSI_STUDIO_AI_LAUNCHER.md`:

```bash
bash ./dsi.sh <command> [values...]
```

Successful `open_src`, `open_fib`, and `open_image` commands automatically select
the newly created window. Use `set_window` when switching to another already-open
window; the selection persists until changed again. Command names and text, path,
or composite parameters are strings. Send standalone numeric parameters as JSON
numbers.

The shared `bring_to_front`, `minimize`, `maximize`, and `close` commands are handled
centrally before ordinary MainWindow/window routing. Their authoritative behavior,
including post-close target recovery and the distinction from GitHub-channel close,
is documented here:

- [Shared window controls](DSI_STUDIO_AI_WINDOW_COMMANDS.md)

`run_cli` and `run_shell` are also global MainWindow commands, but they have very
different execution and completion rules. Their authoritative documentation is:

- [Internal CLI actions and restricted shell commands](DSI_STUDIO_AI_CLI_SHELL_COMMANDS.md)

Do not treat duplicate rows in an older per-window inventory as separate window
implementations. The shared-window document takes precedence.

The remaining command inventory is organized by command area so each command has one
authoritative documentation location:

- [Main window, Hub, FIB, workspace, settings, and parameters](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Reconstruction commands and examples](DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Rendering, camera, surfaces, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Image-window and TIPL generic image operations](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)

Rows with a common example have a recommended or source-verified example. Inspect
current source before using any command whose example remains blank.

## Chat alongside a command

For a meaningful command, add `-Chat "..."` to tell the user what was verified and
what the command is about to do:

```bash
bash ./dsi.sh segment_brain human_synthseg 7 -Chat "I verified that the T1w slice is loaded and ready. I'm starting SynthSeg now; it may take a while to finish."
```

`-Chat` is shown to the user and does not alter command execution. Routine polling
and trivial discovery commands may omit it to avoid repetitive updates.
