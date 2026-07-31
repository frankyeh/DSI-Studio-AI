# DSI Studio AI Command Manual

## Agent environment and launcher

DSI Studio starts the current agent in this DSI Studio AI directory and adds the
user-selected project directory separately for project access. Do not copy the AI
support files into the project directory.

The launchers identify the current agent and session from:

```text
CLAUDE_CODE_SESSION_ID
CODEX_THREAD_ID
```

When `CLAUDE_CODE_SESSION_ID` is set, the launcher uses `Claude` as the agent name
and that value as the session ID. Otherwise, when `CODEX_THREAD_ID` is set, it uses
`Codex` as the agent name and that value as the session ID. Claude takes precedence
if both variables are set. The launchers no longer read `DSI_STUDIO_AGENT`. Do not
search for, guess, generate, replace, or pass either session value on the command
line.

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

## Command-inventory notation

`DSI_STUDIO_AI_COMMAND_EXAMPLES_*.md` uses compact arrays only to document command
names and argument order. Do not send those arrays. Convert each entry to a complete
launcher command, for example:

```bash
bash ./dsi.sh tracking<hex-address> set_slice 7
```

## Request types

### `TITLE`

Send a concise title derived from the task and update it when the task changes
substantially:

```bash
bash ./dsi.sh TITLE "Corticospinal tract analysis"
```

### `CHAT`

Use `CHAT` to tell the user what the agent is doing, what it found, or what completed.
Use a standalone message when no command is needed:

```bash
bash ./dsi.sh CHAT "Tracking completed and the output was verified."
```

A message may accompany a meaningful command:

```bash
bash ./dsi.sh main list_recent_fib -Chat "Checking recent fiber files."
```

`CHAT` is user-facing communication. It does not retrieve DSI Studio action history;
use `LOG` for that purpose.

### `LIST`

`main` is fixed and can be targeted directly. Successful `open_fib` and `open_image`
replies report the ID of each newly created window. Call top-level `LIST` only to
discover another currently open tracking or image window:

```bash
bash ./dsi.sh LIST
```

A successful reply includes `status`, application state, and a `windows` object.
Tracking and image keys append a lowercase hexadecimal window address without `0x`,
for example `tracking7ff6ab123410` or `image7ff6ab456780`. Copy the exact current
key. Never construct one, substitute a title or filename, or reuse an ID after its
window closes.

When `open_fib` or `open_image` creates a window, its command-result `output` contains
`tracking window created, id: tracking...` or `image window created, id: image...`.
Copy that exact ID and target the new window directly; do not call `LIST` merely to
rediscover it.

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

Use `LOG` to retrieve new DSI Studio console and action output recorded since the
session's previous log position:

```bash
bash ./dsi.sh LOG
```

Call `LOG` after the user demonstrates a workflow, changes settings manually, retries
a failed action, or performs GUI operations the agent needs to learn. Inspect the
returned output to reconstruct the actual sequence, including failed attempts and
intermediate states, rather than relying on memory.

When the observed actions form a stable reusable workflow, summarize them into an AI
skill while preserving exact command names, parameters, prerequisites, verification
steps, and known failure paths.

`LOG` is incremental, not a complete permanent archive. The session's first request
sets the starting log position; each `LOG` returns only newer output and then advances
that position. Output is size-limited, so call `LOG` regularly during demonstrations
and long workflows. Use targeted `list_*` or status commands to verify current state.
Use `CHAT` or `-Chat` to tell the user what the agent is doing; do not use `LOG` as a
message transport.

## Reply format

Every reply has top-level `status`. A `CMD` reply contains one result per executed
command, with `cmd` and `status` in each result. Text-producing commands also include
`output`; failed commands include `error`. A successful command without captured text
contains only `cmd` and `status`.

Successful `open_fib` and `open_image` results include the newly created window ID in
`output`.

Success means the handler returned without an immediate error; asynchronous or
GUI-backed work may still be running. Use the relevant discovery or status command
to confirm completion before a dependent operation.

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

The successful reply reports `tracking window created, id: tracking...` for
`open_fib`, or `image window created, id: image...` for `open_image`. Copy the
reported ID and use it as the target of subsequent commands.

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

`list_slice` returns `index`, `current`, `name`, and `status`.

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

`list_unet` returns `index`, `available`, `model`, `name`, and `description`. Use the
internal `model` value, not the display `name`, and only a row with `available=1`.
The optional slice argument accepts an exact slice name or numeric index. A client
timeout does not prove inference stopped; do not immediately resend segmentation.

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

The full `list_tract` reply returns `index`, `status`, `shown`, `name`, `tracts`,
`deleted`, and `seeds`. The compact status reply returns `status` and `bundles`.

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
| Newly created tracking or image window ID | Returned in the successful `open_fib` or `open_image` command `output` |
| Other open tracking or image window IDs | `bash ./dsi.sh LIST` |
| New console and user-action history | `bash ./dsi.sh LOG` |
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
- Do not alter, invent, or pass `CLAUDE_CODE_SESSION_ID` or `CODEX_THREAD_ID`; the
  launcher derives the agent and session automatically.
- Send `TITLE` first and update it when the task changes substantially.
- Use `CHAT` or `-Chat` for user-visible progress and results.
- Use `LOG` regularly while learning user-demonstrated workflows; summarize stable,
  verified action sequences into reusable skills.
- Use a window ID returned by `open_fib` or `open_image`; call `LIST` only to discover
  another already-open tracking or image window.
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
