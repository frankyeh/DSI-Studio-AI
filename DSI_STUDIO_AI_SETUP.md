# DSI Studio AI Setup

Read this file once, then use `DSI_STUDIO_AI_MANUAL.md` and only the relevant
topic-specific example file from this DSI Studio AI directory.

## Identity and wrapper

DSI Studio starts Codex and Claude in this DSI Studio AI directory, where
`AGENTS.md`, `CLAUDE.md`, `dsi.cmd`, `dsi_agent.ps1`, the manual, examples, and
skills are located. The user-selected project directory is added separately for
project access; do not copy the AI support files into it.

DSI Studio supplies the current provider through `DSI_STUDIO_AGENT` and the exact
session UUID through `CODEX_THREAD_ID`. Never search for, guess, generate, or
replace either value.

Use the same launcher for both providers:

```powershell
./dsi <TITLE|LIST|LOG|CHAT|window-id> [command/values...]
```

`dsi.cmd` supplies the agent and session to `dsi_agent.ps1`, applies a
process-scoped PowerShell execution-policy bypass, opens one named-pipe
connection, sends one request, reads the complete reply, and closes it.
Use one invocation per request. Never access or reuse the pipe directly, inspect
either wrapper, launch another DSI Studio instance, or modify GitHub Actions to
operate these instructions.

## Initial requests

After understanding the task, send a concise title, a brief progress message,
and a recent-FIB query:

```powershell
./dsi TITLE "Corticospinal tract analysis"
./dsi CHAT "I am reading the DSI Studio instructions before continuing."
./dsi main list_recent_fib
```

Derive the title and message from the task; do not copy placeholders literally.
Send another `TITLE` when the active task changes substantially.

## Window routing

Use `main` directly. Call top-level `LIST` only when a tracking or image window
ID is needed.

| Window ID | Use it for |
|---|---|
| `main` | Recent files, Fiber Data Hub, opening the first FIB/FZ, reconstruction, templates, and main tools. |
| `tracking<hex-address>` | FIB/FZ slices, regions, tracts, tracking, devices, settings, rendering, and additional FIBs. |
| `image<hex-address>` | Standalone image viewing and image processing. |

Tracking and image IDs append a lowercase hexadecimal window address without
`0x`. Never construct or guess them. Copy the exact current key returned by
`LIST`; it is valid only while that window remains open.

```powershell
./dsi LIST
```

## Command parameters

The first value after the target is the command name. Later values are parameters
in command order. The wrapper converts standalone numbers to JSON numbers and
preserves text, paths, and composite values as strings.

```powershell
./dsi main hub_repo
./dsi main hub_tags data-hcp/lifespan
./dsi main hub_files data-hcp/lifespan tag 0 20
```

A useful `-Chat` may accompany a meaningful command. Silent polling may omit it.

```powershell
./dsi tracking7ff6ab123410 list_region -Chat "Checking the available regions before making changes."
```

## Replies

Every reply has top-level `status`. A `CMD` reply contains one result per
executed command. Each result has `cmd` and `status`.

A command that captured text includes `output`:

```json
{"status":"success","result":[{"cmd":"list_region","status":"success","output":"<command output>"}]}
```

A successful command with no captured text omits `output`:

```json
{"status":"success","result":[{"cmd":"set_slice","status":"success"}]}
```

A failed command includes `error`:

```json
{"status":"error","result":[{"cmd":"set_slice","status":"error","error":"<reason>"}]}
```

A batch stops after the first error. Success means the handler returned without
an immediate error; asynchronous and GUI-backed work still requires verification.

## Opening files

Open the first FIB/FZ from `main`:

```powershell
./dsi main open_fib C:/data/subject.fz
```

Open an additional FIB/FZ from an existing tracking window:

```powershell
./dsi tracking7ff6ab123410 open_fib C:/data/second_subject.fz
```

Use `open_image` only for ordinary image-window workflows, not for the FIB
tracking interface. Parameterless opening commands may show local pickers and
require user interaction.

## Readiness and completion

For slices:

```powershell
./dsi tracking7ff6ab123410 list_slice
```

`list_slice` reports `index`, `current`, `name`, and `status`. Use `status`
directly: `available`, `registering`, or `ready`. The `current` column is only a
selection flag. After `set_slice`, poll until the selected row reports `ready`.

For tracts:

```powershell
./dsi tracking7ff6ab123410 list_tract
./dsi tracking7ff6ab123410 list_tract status
```

The full table reports `index`, `status`, `shown`, `name`, `tracts`, `deleted`,
and `seeds`. Compact `status=done` means no tracking thread remains active.
`bundles` is the total number of tract rows, not the number of running jobs.

Do not resend a long-running command merely because the client timed out. Use
the targeted discovery command to verify state.

## Command references

- `DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md` — main window and Fiber Data Hub.
- `DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md` — slices and segmentation.
- `DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md` — regions and tract-to-region analysis.
- `DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md` — tracts, tracking, AutoTrack, clustering, recognition, and TDI.
- `DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md` — devices and AC-PC locators.
- `DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md` — parameters, camera, surfaces, workspace, settings, and display.
- `DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md` — standalone image-window processing.

Read only the topic needed for the current task.
