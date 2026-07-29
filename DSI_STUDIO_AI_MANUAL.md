# DSI Studio AI Command Manual

Read `DSI_STUDIO_AI_SETUP.md` first. This manual keeps only protocol and
high-risk syntax. Retrieve one topic-specific example file when its commands are
needed.

## Start with `TITLE`

After understanding the task, send one concise title:

```json
{"session":"<session-uuid>","request":"TITLE","title":"Corticospinal tract analysis"}
```

Send another `TITLE` whenever the active task changes substantially. The
`title` field is valid only for `TITLE`; do not include it in another request.

## Window IDs

`main` is fixed and can be targeted directly. Call top-level `LIST` only when a
tracking or image window ID is needed:

```json
{"session":"<session-uuid>","request":"LIST"}
```

Example:

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
| `main` | Recent files, Hub, opening the first FIB/FZ, reconstruction, templates, databases, QC, and main tools. |
| `tracking<hex-address>` | Slices, segmentation, regions, tracts, tracking, devices, rendering, settings, workspace, and additional FIBs. |
| `image<hex-address>` | Standalone image inspection and processing. |

Commands are accepted only by the window type that implements them.

## Opening files

Never send a filesystem path by itself. Supply it as a documented command
parameter.

Open the first FIB/FZ from `main`:

```json
["open_fib","C:/data/subject.fz"]
```

Open an additional FIB/FZ from an existing tracking window:

```json
{"session":"<session-uuid>","request":"CMD","window":"tracking7ff6ab123410","command":{"cmd":"open_fib","param":"C:/data/second_subject.fz"}}
```

Open ordinary images from `main`:

```json
["open_image","C:/data/T1w.nii.gz"]
```

Use the tracking-window route for segmentation related to an open FIB so the
resulting regions remain in the tractography workflow. Use an image window for
standalone image editing or batch processing.

Many parameterless main-window commands open local pickers. Picker cancellation
may return without an immediate command error; verify the resulting window,
file, or application state.

## Request formats

Reuse the exact nonempty session UUID. An optional top-level `chat` may accompany
any request.

### `CMD`

```json
{"session":"<session-uuid>","request":"CMD","window":"tracking7ff6ab123410","command":{"cmd":"list_region"}}
```

`command` accepts one command object or an array of command objects. Each object
requires `cmd`. Omit `param` when there is no parameter. Use a scalar for one
parameter and an array for multiple parameters in command order.

Send standalone numeric parameters as JSON numbers:

```json
{"cmd":"set_slice","param":7}
```

Keep composite values as one string:

```json
{"cmd":"move_slice","param":"80 100 80"}
{"cmd":"set_params","param":"fa_threshold=0.08&min_length=20"}
```

For commands that accept multiple files, pass one path per array element:

```json
{"cmd":"open_src","param":["C:/data/a.sz","C:/data/b.sz"]}
```

Do not combine multiple file paths into an `&`-separated string.

Multiple commands execute sequentially in the same target and stop after the
first error:

```json
[
  {"cmd":"list_slice"},
  {"cmd":"set_slice","param":7}
]
```

### `CHAT`

```json
{"session":"<session-uuid>","request":"CHAT","chat":"Tracking completed and the output was verified."}
```

Use standalone `CHAT` only when no command is needed.

### `LOG`

```json
{"session":"<session-uuid>","request":"LOG"}
```

Use `LOG` only when the direct `CMD` response and targeted discovery cannot
explain a failure.

## Reply format

Every reply has top-level `status`. A `CMD` reply contains one result per
executed command. Each result has `cmd` and `status`.

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
error. Success means the handler returned without an immediate error; it does
not prove asynchronous or GUI-backed work finished. Verify the expected window,
file, region, tract, slice status, or other state.

## Critical discovery and status commands

### Slices

```json
["list_slice"]
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

```json
["list_unet"]
["segment_brain","<model-ID>",7]
```

`list_unet` returns:

```text
index    available    model    name    description
```

Use the internal `model` value, not the display `name`, and use only a row with
`available=1`. The optional third element selects a slice by exact name or
numeric index. Segmentation may outlast the client wait time; do not immediately
resend it. Verify with `list_slice` and `list_region`.

### Fiber Data Hub

All Hub commands target `main`:

```json
["hub_repo"]
["hub_tags","<repo>"]
["hub_files","<repo>","<tag>",".fz",0,20]
["hub_open","<repo>","<tag>",12]
```

Use exact repositories, tags, filenames, and returned row indices. `hub_files`
filters before offset and limit, while its first column remains the actual file
row index. `hub_download` additionally requires a destination directory.

### Tracts

```json
["list_tract"]
["list_tract","status"]
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

```json
["list_param","tracking"]
["run_tracking","CST"]
```

The two-element form uses current tracking parameters and checked regions. Use
`list_region` only when the workflow actually uses regions. Follow
`DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` for strategy, parameters, cleanup, and
quality control.

### Parameters

```json
["list_param"]
["list_param","tracking"]
["list_param","fa_threshold"]
["set_param","fa_threshold",0.08]
["set_params","fa_threshold=0.08&min_length=20"]
```

Use `list_param` before changing tracking or rendering values. `set_param` takes
one numeric or textual value. `set_params` keeps its assignment expression as
one string.

## Current discovery limitations

`list_atlas` reports template index, atlas index, atlas name, and region count.
It does not list label IDs or label names. Do not claim that atlas label IDs can
be discovered through the current command interface; use only IDs supplied by
the user or another verified source.

The device command interface currently has no `list_device`. Numeric device
indices follow current table order and cannot be discovered remotely through a
dedicated command. Prefer current-row operations when the correct row is already
selected; otherwise ask the user to identify the target before an indexed
mutation.

## Discovery quick reference

| Need | Command | Window |
|---|---|---|
| Tracking or image window IDs | top-level `LIST` | none |
| Recent FIB/FZ paths | `["list_recent_fib"]` | main |
| Recent SRC/SZ paths | `["list_recent_src"]` | main |
| Hub repositories | `["hub_repo"]` | main |
| Hub tags | `["hub_tags","<repo>"]` | main |
| Hub files and row indices | `["hub_files","<repo>","<tag>"]` | main |
| Slices and readiness | `["list_slice"]` | tracking |
| Segmentation model IDs | `["list_unet"]` | tracking |
| Regions and roles | `["list_region"]` | tracking |
| Tracts and per-bundle status | `["list_tract"]` | tracking |
| Tracking completion | `["list_tract","status"]` | tracking |
| Parameter IDs and values | `["list_param"]` | tracking |
| Atlases and region counts | `["list_atlas"]` | tracking |
| AutoTrack names | `["list_auto_tract"]` | tracking |

## Operational rules

- Use one wrapper invocation and one named-pipe connection per request.
- Reuse the exact session UUID.
- Send `TITLE` first and update it when the task changes substantially.
- Target fixed `main` directly; call `LIST` only for tracking/image IDs.
- Copy exact command names, IDs, indices, model IDs, and parameter IDs.
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

Read only the relevant topic file.
