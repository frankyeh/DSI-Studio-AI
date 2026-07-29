# DSI Studio AI Command Manual

## Agent environment and wrapper

DSI Studio starts the current agent in this DSI Studio AI directory and adds the
user-selected project directory separately for project access. Do not copy the AI
support files into the project directory.

DSI Studio supplies:

- `DSI_STUDIO_AGENT` — the current provider name.
- `CODEX_THREAD_ID` — the exact current DSI Studio session UUID.

Never search for, guess, generate, or replace either value.

Use the same launcher for Codex and Claude:

```powershell
./dsi <TITLE|LIST|LOG|CHAT|window-id> [command/values...]
```

`dsi.cmd` passes the provider and session to `dsi_agent.ps1`, applies a
process-scoped PowerShell execution-policy bypass, opens one named-pipe
connection, sends one request, reads the complete reply, and closes it. Use one
invocation per request. Never access or reuse the pipe directly, inspect either
wrapper, launch another DSI Studio instance, or modify GitHub Actions to operate
these instructions.

The wrapper maps the command line as follows:

- `TITLE` joins later values as the title text.
- `CHAT` joins later values as the chat text.
- `LIST` and `LOG` are top-level requests.
- Any other target creates `CMD`; the first later value is the command name and
  remaining values are parameters in command order.
- Standalone integers and floating-point values become JSON numbers. Paths,
  names, and composite values remain strings.
- `-Chat "message"` may accompany a meaningful command. Silent polling may omit
  it.

## Request types

### `TITLE`

After understanding the task, send one concise title:

```powershell
./dsi TITLE "Corticospinal tract analysis"
```

Equivalent JSON:

```json
{"session":"<session-uuid>","request":"TITLE","title":"Corticospinal tract analysis"}
```

Send another `TITLE` whenever the active task changes substantially. The `title`
field is valid only for `TITLE`.

### `CHAT`

Use standalone `CHAT` when no command is needed:

```powershell
./dsi CHAT "Tracking completed and the output was verified."
```

Equivalent JSON:

```json
{"session":"<session-uuid>","request":"CHAT","chat":"Tracking completed and the output was verified."}
```

### `LIST`

`main` is fixed and can be targeted directly. Call top-level `LIST` only when a
tracking or image window ID is needed:

```powershell
./dsi LIST
```

Example reply:

```json
{
  "status":"success",
  "application":{"status":"busy"},
  "windows":{
    "main":{"status":"idle","title":"DSI Studio"},
    "tracking7ff6ab123410":{"status":"busy","title":"subject.fz"},
    "image7ff6ab456780":{"status":"idle","title":"T1w.nii.gz"}
  }
}
```

Tracking and image keys append a lowercase hexadecimal window address without
`0x`. Copy the exact current key. Never construct an ID, substitute a title or
filename, or reuse a stale ID after a window closes.

| Window | Commands |
|---|---|
| `main` | Recent files, Fiber Data Hub, opening the first FIB/FZ, reconstruction, templates, databases, QC, and main tools. |
| `tracking<hex-address>` | Slices, segmentation, regions, tracts, tracking, devices, rendering, settings, workspace, and additional FIBs. |
| `image<hex-address>` | Standalone image inspection and processing. |

Commands are accepted only by the window type that implements them.

### `CMD`

```powershell
./dsi tracking7ff6ab123410 list_region
```

Equivalent JSON:

```json
{"session":"<session-uuid>","request":"CMD","window":"tracking7ff6ab123410","command":{"cmd":"list_region"}}
```

The JSON `command` field accepts one command object or an array of command
objects. Each object requires `cmd`. Omit `param` when there is no parameter. Use
a scalar for one parameter and an array for multiple parameters in command order.

Send standalone numeric parameters as numbers:

```powershell
./dsi tracking7ff6ab123410 set_slice 7
```

Keep composite values as one quoted string:

```powershell
./dsi tracking7ff6ab123410 move_slice "80 100 80"
./dsi tracking7ff6ab123410 set_params "fa_threshold=0.08&min_length=20"
```

For commands accepting multiple files, pass one path per argument. Do not combine
multiple paths into an `&`-separated string.

### `LOG`

```powershell
./dsi LOG
```

Use `LOG` only when the direct `CMD` response and targeted discovery cannot
explain a failure.

## Reply format

Every reply has top-level `status`. A `CMD` reply contains one result per executed
command. Each result has `cmd` and `status`.

Text-producing command:

```json
{"status":"success","result":[{"cmd":"list_region","status":"success","output":"<command output>"}]}
```

Successful command with no captured text:

```json
{"status":"success","result":[{"cmd":"set_slice","status":"success"}]}
```

Failed command:

```json
{"status":"error","result":[{"cmd":"set_slice","status":"error","error":"<reason>"}]}
```

`output` is present only when text was captured. A batch stops after the first
error. Success means the handler returned without an immediate error; it does not
prove asynchronous or GUI-backed work finished. Verify the expected window,
file, region, tract, slice status, or other state.

## Opening files

Never send a filesystem path by itself. Supply it as a documented command
parameter.

Open the first FIB/FZ from `main`:

```powershell
./dsi main open_fib "C:/data/subject.fz"
```

Open an additional FIB/FZ from an existing tracking window:

```powershell
./dsi tracking7ff6ab123410 open_fib "C:/data/second_subject.fz"
```

Open ordinary images from `main`:

```powershell
./dsi main open_image "C:/data/T1w.nii.gz"
```

Use the tracking-window route for segmentation related to an open FIB so the
resulting regions remain in the tractography workflow. Use an image window for
standalone image editing or batch processing.

Many parameterless main-window commands open local pickers. Picker cancellation
may return without an immediate command error; verify the resulting window,
file, or application state.

## Fiber Data Hub

All Hub commands target `main`:

```powershell
./dsi main hub_repo
./dsi main hub_tags "<exact-repository>"
./dsi main hub_files "<exact-repository>" "<exact-tag>" ".fz" 0 20
./dsi main hub_open "<exact-repository>" "<exact-tag>" 12
```

Use exact repositories, tags, filenames, and returned row indices. `hub_files`
filters before applying offset and limit, while its first column remains the
actual file-table row index. `hub_open` and `hub_download` accept an exact
filename or returned row index. `hub_download` additionally requires a
destination directory. Verify the created window or destination file after
GUI-backed network work.

## Critical discovery and status commands

### Slices

```powershell
./dsi tracking7ff6ab123410 list_slice
```

Columns:

```text
index    current    name    status
```

Interpret `status` directly:

- `available` — listed but not loaded locally.
- `registering` — loading or registration is running.
- `ready` — ready for a dependent operation.

`current` is only the selected-state flag. After `set_slice`, poll until the
selected row reports `ready`.

### Segmentation

```powershell
./dsi tracking7ff6ab123410 list_unet
./dsi tracking7ff6ab123410 segment_brain "<model-ID>" 7
```

`list_unet` returns:

```text
index    available    model    name    description
```

Use the internal `model` value, not the display `name`, and use only a row with
`available=1`. The optional slice value selects an exact name or numeric index.
Segmentation may outlast the client wait time; do not immediately resend it.
Verify with `list_slice` and `list_region`.

### Tracts

```powershell
./dsi tracking7ff6ab123410 list_tract
./dsi tracking7ff6ab123410 list_tract status
```

Full columns:

```text
index    status    shown    name    tracts    deleted    seeds
```

Compact columns:

```text
status    bundles
```

`status=done` means no tracking thread remains active. `bundles` is the total
number of tract rows, not the number of running jobs. Poll until `done` before a
dependent step.

`run_tracking` requires a nonempty new bundle name:

```powershell
./dsi tracking7ff6ab123410 list_param tracking
./dsi tracking7ff6ab123410 run_tracking "CST"
```

The two-value form uses current tracking parameters and checked regions. Use
`list_region` only when the workflow actually uses regions. Follow
`DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` for strategy, parameters, cleanup, and
quality control.

### Parameters

```powershell
./dsi tracking7ff6ab123410 list_param
./dsi tracking7ff6ab123410 list_param tracking
./dsi tracking7ff6ab123410 list_param fa_threshold
./dsi tracking7ff6ab123410 set_param fa_threshold 0.08
./dsi tracking7ff6ab123410 set_params "fa_threshold=0.08&min_length=20"
```

Use `list_param` before changing tracking or rendering values. `set_param` takes
one numeric or textual value. `set_params` keeps its assignment expression as one
string.

## Current discovery limitations

`list_atlas` reports template index, atlas index, atlas name, and region count. It
does not list label IDs or label names. Do not claim that atlas label IDs can be
discovered through the current command interface; use only IDs supplied by the
user or another verified source.

The device command interface currently has no `list_device`. Numeric device
indices follow current table order and cannot be discovered remotely through a
dedicated command. Prefer current-row operations when the correct row is already
selected; otherwise ask the user to identify the target before an indexed
mutation.

## Discovery quick reference

| Need | Command | Window |
|---|---|---|
| Tracking or image window IDs | `./dsi LIST` | none |
| Recent FIB/FZ paths | `list_recent_fib` | main |
| Recent SRC/SZ paths | `list_recent_src` | main |
| Hub repositories | `hub_repo` | main |
| Hub tags | `hub_tags` | main |
| Hub files and row indices | `hub_files` | main |
| Slices and readiness | `list_slice` | tracking |
| Segmentation model IDs | `list_unet` | tracking |
| Regions and roles | `list_region` | tracking |
| Tracts and per-bundle status | `list_tract` | tracking |
| Tracking completion | `list_tract status` | tracking |
| Parameter IDs and values | `list_param` | tracking |
| Atlases and region counts | `list_atlas` | tracking |
| AutoTrack names | `list_auto_tract` | tracking |

## Operational rules

- Use one `./dsi` invocation and one named-pipe connection per request.
- Reuse the exact provider and session supplied by DSI Studio.
- Send `TITLE` first and update it when the task changes substantially.
- Target fixed `main` directly; call `LIST` only for tracking or image IDs.
- Inspect each reply before deciding the next request.
- Copy exact command names, paths, IDs, indices, model IDs, and parameter IDs.
- Confirm destructive operations, overwrites, and saved-history clearing.
- Do not answer modal dialogs remotely; tell the user what must be selected.
- A client timeout does not prove failure; verify state before retrying.
- A disappeared window requires a new `LIST`; do not reopen it automatically.

## Topic-specific command references

- [Main window and Fiber Data Hub](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Parameters, rendering, camera, surfaces, workspace, settings, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Standalone image-window processing](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)

Read only the topic file needed for the current task.