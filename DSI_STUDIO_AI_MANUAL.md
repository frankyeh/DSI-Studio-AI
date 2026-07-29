# DSI Studio AI Command Manual

## Agent environment and wrapper

DSI Studio starts the current agent in this DSI Studio AI directory and adds the
user-selected project directory separately for project access. Do not copy the AI
support files into the project directory.

`DSI_STUDIO_AGENT` identifies the current provider. Codex supplies its thread ID
through `CODEX_THREAD_ID`; DSI Studio sets the same variable to the Claude session
UUID before launching Claude. Do not search for, guess, generate, or replace either
value.

Use the same launcher for both providers:

```powershell
./dsi <TITLE|LIST|LOG|CHAT|window-id> [command/values...]
```

`dsi.cmd` passes the provider and session to `dsi_agent.ps1`, applies a
process-scoped PowerShell execution-policy bypass, opens one named-pipe connection,
sends one request, reads the complete reply, and closes it. Use one invocation per
request. Never access the pipe directly, inspect or bypass the wrappers, launch
another DSI Studio instance, or modify GitHub Actions to operate these instructions.

The wrapper maps the command line as follows:

- `TITLE` joins later values as title text.
- `CHAT` joins later values as chat text.
- `LIST` and `LOG` are top-level requests.
- Any other target creates `CMD`; the first later value is the command name and the
  remaining values are parameters in command order.
- Standalone integers and floating-point values become JSON numbers. Paths, names,
  and composite values remain strings.
- `-Chat "message"` may accompany a meaningful command. Silent status polling may
  omit it.

The wrapper intentionally sends one command per invocation even though the server
can execute command arrays. Use separate `./dsi` calls rather than bypassing the
wrapper to batch requests.

## Request types

### `TITLE`

Send one concise title after understanding the task and another when the active task
changes substantially:

```powershell
./dsi TITLE "Corticospinal tract analysis"
```

Emitted JSON:

```json
{"agent":"<Codex|Claude>","session":"<session-uuid>","request":"TITLE","title":"Corticospinal tract analysis"}
```

The `title` field is valid only for `TITLE`.

### `CHAT`

Use standalone `CHAT` when no command is needed:

```powershell
./dsi CHAT "Tracking completed and the output was verified."
```

Emitted JSON:

```json
{"agent":"<Codex|Claude>","session":"<session-uuid>","request":"CHAT","chat":"Tracking completed and the output was verified."}
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

Tracking and image keys append a lowercase hexadecimal window address without `0x`.
Copy the current key; never construct one, substitute a title or filename, or reuse
an ID after its window closes.

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

Emitted JSON:

```json
{"agent":"<Codex|Claude>","session":"<session-uuid>","request":"CMD","window":"tracking7ff6ab123410","command":{"cmd":"list_region"}}
```

Send standalone numeric parameters without quotes:

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

Use `LOG` only when the direct `CMD` reply and targeted discovery commands cannot
explain a failure.

## Reply format

Every reply has top-level `status`. A `CMD` reply contains one result per executed
command, with `cmd` and `status` in each result.

Text-producing command:

```json
{"status":"success","result":[{"cmd":"list_region","status":"success","output":"<command output>"}]}
```

Successful command without captured text:

```json
{"status":"success","result":[{"cmd":"set_slice","status":"success"}]}
```

Failed command:

```json
{"status":"error","result":[{"cmd":"set_slice","status":"error","error":"<reason>"}]}
```

`output` appears only when text was captured. Success means the handler returned
without an immediate error; asynchronous or GUI-backed work may still be running.
Use the relevant discovery or status command to confirm completion before a
dependent operation.

## Opening files

Never send a filesystem path by itself. Supply it as a documented command parameter.

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

Use the tracking-window route for segmentation related to an open FIB so the created
regions remain in the tractography workflow. Use an image window for standalone
image editing or batch processing.

Many parameterless main-window commands open local pickers. Picker cancellation may
return without an immediate error; check whether the expected window or file was
created.

## Fiber Data Hub

All Hub commands target `main`:

```powershell
./dsi main hub_repo
./dsi main hub_tags "<exact-repository>"
./dsi main hub_files "<exact-repository>" "<exact-tag>" ".fz" 0 20
./dsi main hub_open "<exact-repository>" "<exact-tag>" 12
```

In `hub_files`, the filter is applied first, `0` is the matching-file offset, and
`20` is the maximum number of rows returned. The first reply column remains the
actual file-table row index used by `hub_open` and `hub_download`.

`hub_open` and `hub_download` also accept an exact filename. `hub_download` requires
a destination directory. Network-backed work may continue after the immediate
command reply; check the opened window or destination file.

## Critical discovery and status commands

### Slices

```powershell
./dsi tracking7ff6ab123410 list_slice
./dsi tracking7ff6ab123410 set_slice 7
./dsi tracking7ff6ab123410 list_slice
```

`list_slice` columns:

```text
index    current    name    status
```

- `available` — a URL-backed slice is listed but not loaded locally.
- `registering` — loading or registration is running.
- `ready` — ready for a dependent operation.

`current` is only the selected-state flag. After `set_slice`, poll until the selected
row reports `ready`.

### Segmentation

```powershell
./dsi tracking7ff6ab123410 list_unet
./dsi tracking7ff6ab123410 segment_brain "<model-ID>" 7
./dsi tracking7ff6ab123410 list_region
```

`list_unet` columns:

```text
index    available    model    name    description
```

Use the internal `model` value, not the display `name`, and only a row with
`available=1`. The optional slice argument accepts an exact slice name or numeric
index. Segmentation is synchronous, but a client timeout does not prove inference
stopped; do not immediately resend it.

### Atlases and regions

```powershell
./dsi tracking7ff6ab123410 list_atlas
./dsi tracking7ff6ab123410 add_region_from_atlas "<template-index> <atlas-index> <label-index>"
./dsi tracking7ff6ab123410 list_region
```

`add_region_from_atlas` takes one quoted composite parameter. Join multiple label
indices with `&`. Omitting label indices adds every label from the selected atlas.

`list_atlas` reports template index, atlas index, atlas name, and region count, but
not individual label IDs or names. Use label indices only when supplied by the user
or another verified source. The verified BrainSeg thalamus example is shown in
`AGENTS.md`.

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

`status=done` means no tracking thread remains active. `bundles` is the total number
of tract rows, not the number of running jobs. Poll until `done` before a dependent
step.

`run_tracking` requires a nonempty new bundle name:

```powershell
./dsi tracking7ff6ab123410 list_param tracking
./dsi tracking7ff6ab123410 run_tracking "CST"
```

This form uses the current tracking parameters and checked regions. Call
`list_region` only when the workflow uses regions. Follow
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

Use `list_param` before changing tracking or rendering values. `set_param` takes one
numeric or textual value. `set_params` keeps its assignment expression as one
string.

## Current discovery limitations

The device interface currently has no `list_device`. Numeric device indices follow
the current table order and cannot be discovered through a dedicated command.
Prefer current-row operations when the correct row is already selected; otherwise
ask the user to identify the target before an indexed mutation.

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
| Atlases and region counts | `list_atlas` | tracking |
| Tracts and per-bundle status | `list_tract` | tracking |
| Tracking completion | `list_tract status` | tracking |
| Parameter IDs and values | `list_param` | tracking |
| AutoTrack names | `list_auto_tract` | tracking |

## Operational rules

- Use one `./dsi` invocation per request.
- Do not alter the provider or session environment variables.
- Send `TITLE` first and update it when the task changes substantially.
- Target fixed `main` directly; call `LIST` only for tracking or image IDs.
- Copy command names, paths, window IDs, indices, model IDs, and parameter IDs from
  the user, current command output, or another verified source.
- Confirm destructive operations, overwrites, and saved-history clearing.
- Do not answer modal dialogs remotely; tell the user what must be selected.
- A client timeout does not prove failure; use the relevant status command before
  retrying.
- A disappeared window requires a new `LIST`; do not reopen it automatically.

## Related documents

Use `DSI_STUDIO_AI_SKILL_*.md` for task workflows and
`DSI_STUDIO_AI_COMMAND_EXAMPLES_*.md` for exact command syntax and inventories. Read
only files relevant to the current task.

- [Fiber-tracking workflow](DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md)
- [Main window and Fiber Data Hub](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Parameters, rendering, camera, surfaces, workspace, settings, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Standalone image-window processing](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)
