# DSI Studio AI Command Manual

## Agent environment and launcher

DSI Studio starts the current agent in this DSI Studio AI directory and adds the
user-selected project directory separately for project access. Do not copy the AI
support files into the project directory.

DSI Studio supplies:

```text
DSI_STUDIO_AGENT
CODEX_THREAD_ID
```

`DSI_STUDIO_AGENT` identifies the provider. `CODEX_THREAD_ID` contains the current
Codex thread ID or the Claude session UUID supplied by DSI Studio. Do not search for,
guess, generate, replace, or pass either value on the command line.

Use the same launcher for Codex and Claude:

```bash
bash ./dsi.sh <TITLE|CHAT|LIST|LOG|window-id> [command/values...]
```

Always include `bash` before `./dsi.sh`. Never invoke `./dsi.sh` directly. If this
route fails, read `DSI_STUDIO_AI_LAUNCHER.md` and use the documented platform
fallback.

The launcher opens one local pipe or socket connection, sends one request, reads the
complete reply, and closes the connection. Use one invocation per request. Never
access the pipe directly or launch another DSI Studio instance to operate these
instructions.

The launcher maps arguments as follows:

- `TITLE` joins later values as title text.
- `CHAT` joins later values as chat text.
- `LIST` and `LOG` are top-level requests.
- Any other target creates `CMD`; the first later value is the command name and the
  remaining values are parameters in command order.
- Standalone integers and floating-point values become JSON numbers. Paths, names,
  and composite values remain strings.
- `-Chat "message"` may accompany a meaningful command. Silent polling may omit it.

Use separate `bash ./dsi.sh` invocations rather than bypassing the launcher to batch
requests.

## Request types

### `TITLE`

Send a concise title derived from the task, and update it when the task changes
substantially:

```bash
bash ./dsi.sh TITLE "Corticospinal tract analysis"
```

### `CHAT`

Use standalone `CHAT` when no command is needed:

```bash
bash ./dsi.sh CHAT "Tracking completed and the output was verified."
```

A message may accompany a command:

```bash
bash ./dsi.sh main list_recent_fib -Chat "Checking recent fiber files."
```

### `LIST`

`main` is fixed and can be targeted directly. Call top-level `LIST` only when a
tracking or image window ID is needed:

```bash
bash ./dsi.sh LIST
```

Example output:

```text
{"status":"success","application":{"status":"busy"},"windows":{"main":{"status":"idle","title":"DSI Studio"},"tracking7ff6ab123410":{"status":"busy","title":"subject.fz"},"image7ff6ab456780":{"status":"idle","title":"T1w.nii.gz"}}}
```

Tracking and image keys append a lowercase hexadecimal window address without `0x`.
Copy the exact current key. Never construct one, substitute a title or filename, or
reuse an ID after its window closes.

| Window | Commands |
|---|---|
| `main` | Recent files, Fiber Data Hub, opening the first FIB/FZ, reconstruction, templates, databases, QC, and main tools. |
| `tracking<hex-address>` | Slices, segmentation, regions, tracts, tracking, devices, rendering, settings, workspace, and additional FIBs. |
| `image<hex-address>` | Standalone image inspection and processing. |

Commands are accepted only by the window type that implements them.

### `CMD`

```bash
bash ./dsi.sh tracking7ff6ab123410 list_region
```

Send standalone numeric parameters without quotes:

```bash
bash ./dsi.sh tracking7ff6ab123410 set_slice 7
```

Keep composite values as one quoted string:

```bash
bash ./dsi.sh tracking7ff6ab123410 move_slice "80 100 80"
bash ./dsi.sh tracking7ff6ab123410 set_params "fa_threshold=0.08&min_length=20"
```

For commands accepting multiple files, pass one path per argument. Do not combine
multiple paths into an `&`-separated string.

### `LOG`

```bash
bash ./dsi.sh LOG
```

Use `LOG` only when the direct `CMD` reply and targeted discovery commands cannot
explain a failure.

## Reply format

Every reply has top-level `status`. A `CMD` reply contains one result per executed
command, with `cmd` and `status` in each result.

Text-producing command output:

```text
{"status":"success","result":[{"cmd":"list_region","status":"success","output":"<command output>"}]}
```

Successful command without captured text:

```text
{"status":"success","result":[{"cmd":"set_slice","status":"success"}]}
```

Failed command:

```text
{"status":"error","result":[{"cmd":"set_slice","status":"error","error":"<reason>"}]}
```

`output` appears only when text was captured. Success means the handler returned
without an immediate error; asynchronous or GUI-backed work may still be running.
Use the relevant discovery or status command to confirm completion before a
dependent operation.

## Opening files

Never send a filesystem path by itself. Supply it as a documented command parameter.

Open the first FIB/FZ from `main`:

```bash
bash ./dsi.sh main open_fib "C:/data/subject.fz"
```

Open an additional FIB/FZ from an existing tracking window:

```bash
bash ./dsi.sh tracking7ff6ab123410 open_fib "C:/data/second_subject.fz"
```

Open ordinary images from `main`:

```bash
bash ./dsi.sh main open_image "C:/data/T1w.nii.gz"
```

Use the tracking-window route for segmentation related to an open FIB so created
regions remain in the tractography workflow. Use an image window for standalone
image processing.

Parameterless main-window commands may open local pickers. Picker cancellation can
return without an immediate error; verify whether the expected window or file was
created.

## Fiber Data Hub

All Hub commands target `main`:

```bash
bash ./dsi.sh main hub_repo
bash ./dsi.sh main hub_tags "<exact-repository>"
bash ./dsi.sh main hub_files "<exact-repository>" "<exact-tag>" ".fz" 0 20
bash ./dsi.sh main hub_open "<exact-repository>" "<exact-tag>" 12
```

In `hub_files`, the filter is applied first, `0` is the matching-file offset, and
`20` is the maximum number of rows returned. The first reply column remains the
actual file-table row index used by `hub_open` and `hub_download`.

`hub_open` and `hub_download` also accept an exact filename. `hub_download` requires
a destination directory. Network-backed work may continue after the immediate
reply; verify the opened window or destination file.

## Critical discovery and status commands

### Slices

```bash
bash ./dsi.sh tracking7ff6ab123410 list_slice
bash ./dsi.sh tracking7ff6ab123410 set_slice 7
bash ./dsi.sh tracking7ff6ab123410 list_slice
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

```bash
bash ./dsi.sh tracking7ff6ab123410 list_unet
bash ./dsi.sh tracking7ff6ab123410 segment_brain "<model-ID>" 7
bash ./dsi.sh tracking7ff6ab123410 list_region
```

`list_unet` columns:

```text
index    available    model    name    description
```

Use the internal `model` value, not the display `name`, and only a row with
`available=1`. The optional slice argument accepts an exact slice name or numeric
index. A client timeout does not prove inference stopped; do not immediately resend
segmentation.

### Atlases and regions

```bash
bash ./dsi.sh tracking7ff6ab123410 list_atlas
bash ./dsi.sh tracking7ff6ab123410 add_region_from_atlas "<template-index> <atlas-index> <label-index>"
bash ./dsi.sh tracking7ff6ab123410 list_region
```

`add_region_from_atlas` takes one quoted composite parameter. Join multiple label
indices with `&`. Omitting label indices adds every label from the selected atlas.

`list_atlas` reports template index, atlas index, atlas name, and region count, but
not individual label IDs or names. Use label indices only when supplied by the user
or another verified source. The verified BrainSeg thalamus example is in
`AGENTS.md`.

### Tracts

```bash
bash ./dsi.sh tracking7ff6ab123410 list_tract
bash ./dsi.sh tracking7ff6ab123410 list_tract status
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

```bash
bash ./dsi.sh tracking7ff6ab123410 list_param tracking
bash ./dsi.sh tracking7ff6ab123410 run_tracking "CST"
```

This uses the current tracking parameters and checked regions. Call `list_region`
only when the workflow uses regions. Follow
`DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` for strategy, parameters, cleanup, and
quality control.

### Parameters

```bash
bash ./dsi.sh tracking7ff6ab123410 list_param
bash ./dsi.sh tracking7ff6ab123410 list_param tracking
bash ./dsi.sh tracking7ff6ab123410 list_param fa_threshold
bash ./dsi.sh tracking7ff6ab123410 set_param fa_threshold 0.08
bash ./dsi.sh tracking7ff6ab123410 set_params "fa_threshold=0.08&min_length=20"
```

Use `list_param` before changing tracking or rendering values. `set_param` takes one
numeric or textual value. `set_params` keeps its assignment expression as one
string.

## Current discovery limitations

The device interface currently has no `list_device`. Numeric device indices follow
current table order and cannot be discovered through a dedicated command. Prefer
current-row operations when the correct row is selected; otherwise ask the user to
identify the target before an indexed mutation.

## Discovery quick reference

| Need | Complete command |
|---|---|
| Tracking or image window IDs | `bash ./dsi.sh LIST` |
| Recent FIB/FZ paths | `bash ./dsi.sh main list_recent_fib` |
| Recent SRC/SZ paths | `bash ./dsi.sh main list_recent_src` |
| Hub repositories | `bash ./dsi.sh main hub_repo` |
| Hub tags | `bash ./dsi.sh main hub_tags "<exact-repository>"` |
| Hub files and row indices | `bash ./dsi.sh main hub_files "<exact-repository>" "<exact-tag>" ".fz" 0 20` |
| Slices and readiness | `bash ./dsi.sh tracking<hex-address> list_slice` |
| Segmentation model IDs | `bash ./dsi.sh tracking<hex-address> list_unet` |
| Regions and roles | `bash ./dsi.sh tracking<hex-address> list_region` |
| Atlases and region counts | `bash ./dsi.sh tracking<hex-address> list_atlas` |
| Tracts and per-bundle status | `bash ./dsi.sh tracking<hex-address> list_tract` |
| Tracking completion | `bash ./dsi.sh tracking<hex-address> list_tract status` |
| Parameter IDs and values | `bash ./dsi.sh tracking<hex-address> list_param` |
| AutoTrack names | `bash ./dsi.sh tracking<hex-address> list_auto_tract` |

## Operational rules

- Use one `bash ./dsi.sh` invocation per request.
- Always include `bash` before `./dsi.sh`.
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

- [Launcher selection and troubleshooting](DSI_STUDIO_AI_LAUNCHER.md)
- [Fiber-tracking workflow](DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md)
- [Main window and Fiber Data Hub](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Parameters, rendering, camera, surfaces, workspace, settings, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Standalone image-window processing](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)

Read only the files relevant to the current task.