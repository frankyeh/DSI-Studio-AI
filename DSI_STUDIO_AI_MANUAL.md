# DSI Studio AI Command Manual

## Launcher and session

DSI Studio starts the agent in this DSI Studio AI directory and separately grants
access to the user-selected project directory. Do not copy the AI support files into
the project directory.

The launchers derive the current agent and session from:

```text
CLAUDE_CODE_SESSION_ID
CODEX_THREAD_ID
```

Claude takes precedence if both variables are set. Do not search for, invent,
replace, or pass either session value on the command line.

Use the same launcher for Codex and Claude:

```bash
bash ./dsi.sh <TITLE|CHAT|LIST|LOG|window-id> [command/values...]
```

Always include `bash` before `./dsi.sh`. Use one invocation per request. If this
route fails, read `DSI_STUDIO_AI_LAUNCHER.md` and use its documented fallback.

The launcher maps arguments as follows:

- `TITLE` joins later values as title text.
- `CHAT` joins later values as chat text.
- `LIST` and `LOG` are top-level requests.
- Any window ID creates `CMD`; the first later value is the command name and the
  remaining values are command parameters.
- Standalone integers and floating-point values become JSON numbers. Paths, names,
  and composite expressions remain strings.
- `-Chat "message"` may accompany a meaningful command.

## Request types

### `TITLE`

```bash
bash ./dsi.sh TITLE "Corticospinal tract analysis"
```

Set a concise task title and update it when the task changes substantially.

### `CHAT`

```bash
bash ./dsi.sh CHAT "The source file is open. I am checking reconstruction settings."
```

`CHAT` is user-facing communication. It does not retrieve action history; use `LOG`
for that purpose.

### `LIST`

```bash
bash ./dsi.sh LIST
```

`main` is fixed. Other supported windows use the exact current keys returned by
DSI Studio:

| Window | Purpose |
|---|---|
| `main` | Recent files, Fiber Data Hub, opening files, templates, databases, QC, CLI actions, main tools, and Windows desktop speech |
| `recon<hex-address>` | SRC/SZ masks, source geometry, b-table operations, corrections, exports, parameters, and reconstruction |
| `tracking<hex-address>` | Slices, segmentation, regions, tracts, tracking, rendering, devices, settings, and workspaces |
| `image<hex-address>` | Standalone image inspection and processing |

Successful `open_src`, `open_fib`, and `open_image` commands normally report the
new ID directly in their command `output`:

```text
recon window created, id: recon...
tracking window created, id: tracking...
image window created, id: image...
```

Copy the exact returned ID. Do not construct an ID, replace it with a filename, or
reuse it after the window closes. Use `LIST` to confirm an ID or discover another
already-open supported window, not merely to rediscover a window whose ID was just
returned.

`LIST` reports each window as `idle`, `busy`, or `waiting`. `waiting` means a modal
local dialog is awaiting the user's decision.

### `CMD`

```bash
bash ./dsi.sh tracking7ff6ab123410 list_region
bash ./dsi.sh recon7ff6ab111000 recon 4
```

Send standalone numeric parameters without quotes. Keep multiple values or
assignments in one quoted composite parameter when the command expects one string:

```bash
bash ./dsi.sh tracking7ff6ab123410 set_params "fa_threshold=0.08&min_length=20"
bash ./dsi.sh recon7ff6ab111000 set_params "method=4&param=1.25"
bash ./dsi.sh recon7ff6ab111000 set_voxel_size "1.5 1.5 2.0"
```

For commands accepting multiple files, pass one path per argument. Never send a
filesystem path by itself as the complete request.

### `LOG`

```bash
bash ./dsi.sh LOG
```

Use `LOG` after the user demonstrates a workflow, changes settings manually, retries
a failed action, or performs GUI operations the agent needs to learn. It returns only
new console and action output since the session's previous log position and then
advances that position. Call it regularly during long demonstrations because output
is size-limited.

## Reply format

Every reply has top-level `status`. A `CMD` reply contains one result per executed
command, with `cmd` and `status`. Text-producing commands also include `output`;
failed commands include `error`.

Success means the handler returned without an immediate error. A long synchronous
operation may exceed the client's waiting period while continuing in DSI Studio. Do
not immediately resend it; inspect `LIST`, `LOG`, or the relevant status command.

## Opening files

Open an SRC/SZ reconstruction window:

```bash
bash ./dsi.sh main open_src "C:/data/subject.sz"
```

Open a FIB/FZ tracking window:

```bash
bash ./dsi.sh main open_fib "C:/data/subject.fz"
```

Open an ordinary image window:

```bash
bash ./dsi.sh main open_image "C:/data/T1w.nii.gz"
```

Parameterless main-window commands may open a local picker. Cancellation may return
without an immediate error, so verify whether the expected window or file was
created.

## Windows desktop speech

Use the main-window `voice` command to speak one non-empty text parameter through
the Windows desktop's default system voice and audio output:

```bash
bash ./dsi.sh main voice "Reconstruction is complete."
```

`voice` is available only on Windows. DSI Studio starts `powershell.exe` without a
profile, creates `SAPI.SpVoice`, and passes the text through the `DSI_VOICE_TEXT`
environment variable rather than inserting it into PowerShell code.

A successful command reply means the PowerShell process started. It does not mean
speech has finished, and DSI Studio does not return a completion event. Each call
starts a separate process, so rapid calls may overlap. Keep spoken messages concise
and avoid repeated calls while another message is likely still playing.

Use `voice` as supplemental audible notification for user-requested speech or events
that need attention. Continue to provide durable user-facing information through
`CHAT` or `-Chat`, and do not speak sensitive content unless the user explicitly asks.

## Demo mode

Use demo mode only when the user asks for a demonstration, presentation, guided
walkthrough, or spoken narration.

Before every major user-visible action, speak one concise sentence describing what
will happen next and, when useful, why it matters. Major actions include opening or
selecting data, choosing an image or model, starting registration, reconstruction,
segmentation, or tracking, changing the displayed result, and completing the task.
Do not narrate routine discovery commands or every minor UI change.

Whenever supported, put `voice` first in the same ordered `CMD.command` array as the
corresponding action. This keeps the explanation and action in the intended order:

```json
{
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": [
    {
      "cmd": "voice",
      "param": "The T1 weighted image is ready. I will now run tumor segmentation."
    },
    {
      "cmd": "segment_brain",
      "param": ["human_tumor_T1w", 8]
    },
    {
      "cmd": "list_region"
    }
  ]
}
```

A demo must not leave a long operation unexplained. Before starting a potentially
long operation, state what is starting and what result is expected. For an
asynchronous operation, provide brief, meaningful progress narration while checking
its status. After a synchronous long operation returns, announce the verified result
before beginning the next major action. Do not fill every moment with speech or
start another message while the previous message is likely still playing.

Spoken narration must sound like the presentation itself. Never disclose internal
orchestration rules or implementation details in the voice text. In particular, do
not mention the no-silence rule, cooldowns, waiting silently, polling, issue updates,
request IDs, command arrays, batches, or that another voice command is being sent.

Do not say:

```text
I am checking its status without waiting silently.
To avoid a cooldown, I will send another voice command.
```

Instead, describe the scientific or operational state naturally:

```text
The T1 image is registering to the diffusion data. I will verify the alignment next.
Segmentation is processing the T1 image. The next step will isolate the tumor labels.
```

Base every progress statement on verified state. Do not announce completion before
the command result confirms it. If an operation fails, explain only the user-relevant
problem and the next corrective step; do not narrate internal transport or automation
details. Keep protected, identifying, credential, and other sensitive information out
of spoken messages.

## Reconstruction windows

Use the exact `recon<hex-address>` returned by `open_src`.

### Parameters

Reconstruction parameter commands use the same concise naming rule as the other
reconstruction-window operations:

```bash
bash ./dsi.sh recon7ff6ab111000 list_param
bash ./dsi.sh recon7ff6ab111000 list_param method
bash ./dsi.sh recon7ff6ab111000 set_param "method=4"
bash ./dsi.sh recon7ff6ab111000 set_params "method=4&param=1.25&thread_count=8"
```

`set_param` and `set_params` both accept one
`name=value[&name=value...]` composite parameter.

### Operation names

Reconstruction-window operations use concise names without the old `src_` prefix:

```bash
bash ./dsi.sh recon7ff6ab111000 mask_unet
bash ./dsi.sh recon7ff6ab111000 bias_field_correction
bash ./dsi.sh recon7ff6ab111000 resample 2
bash ./dsi.sh recon7ff6ab111000 recon 4
```

Use `recon`, not `reconstruction`, `src_recon`, or `src_reconstruction`. The optional
method is `1` for DTI, `4` for GQI, or `7` for QSDR. Omitting it uses the current
`method` parameter.

A successful `recon` prints every generated path as:

```text
reconstruction output: <path>
```

Each generated FIB/FZ path is also added to the recent-FIB list. For a multi-file
reconstruction window, inspect all returned output paths.

### User-selected input through local dialogs

Omitting a parameter is intentional for commands that support a local dialog. The
agent can invoke the operation and let the user decide the input or output locally:

```bash
bash ./dsi.sh recon7ff6ab111000 mask_open -Chat "Please choose the mask file in DSI Studio."
bash ./dsi.sh recon7ff6ab111000 save_nifti -Chat "Please choose where to save the diffusion NIfTI."
bash ./dsi.sh recon7ff6ab111000 resample -Chat "Please choose the isotropic output resolution."
```

The command remains active while the dialog is open, and `LIST` may report the
reconstruction window or application as `waiting`. Continue only after the user
selects a value or cancels. When the exact value is already known, pass it directly
to avoid unnecessary interaction.

For AI-originated `topup` or `topup_eddy` without a parameter, DSI Studio uses its
automatic reverse-phase-encoding search. Pass an explicit `.rz`, `.sz`, `src.gz`, or
NIfTI path when the correct reverse-PE source is known.

Corrections, b-table changes, source geometry changes, mask operations, and
reconstruction can materially alter results. Do not run them merely because they are
available. Read `DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md` for the complete
inventory and worked examples.

## Fiber Data Hub

All Hub commands target `main`:

```bash
bash ./dsi.sh main hub_repo
bash ./dsi.sh main hub_tags "<exact-repository>"
bash ./dsi.sh main hub_files "<exact-repository>" "<exact-tag>" ".fz" 0 20
bash ./dsi.sh main hub_open "<exact-repository>" "<exact-tag>" 12
```

Use exact repository and tag strings returned by the preceding commands. The first
`hub_files` column is the file-row index accepted by `hub_open` and `hub_download`.
Network-backed work may continue after the immediate reply; verify the opened window
or destination file.

## Tracking discovery and status

### Slices

```bash
bash ./dsi.sh tracking7ff6ab123410 list_slice
bash ./dsi.sh tracking7ff6ab123410 set_slice 7
bash ./dsi.sh tracking7ff6ab123410 list_slice
```

Poll until the selected URL-backed slice reports `ready`, rather than only
`available` or `registering`.

### Segmentation

```bash
bash ./dsi.sh tracking7ff6ab123410 list_unet
bash ./dsi.sh tracking7ff6ab123410 segment_brain "<model-ID>" 7
bash ./dsi.sh tracking7ff6ab123410 list_region
```

Use the internal `model` value from a row with `available=1`, not its display name.

### Atlases and regions

```bash
bash ./dsi.sh tracking7ff6ab123410 list_atlas
bash ./dsi.sh tracking7ff6ab123410 add_region_from_atlas "<template-index> <atlas-index> <label-index>"
bash ./dsi.sh tracking7ff6ab123410 list_region
```

Join multiple label indices with `&`. Use label indices only when supplied by the
user or another verified source.

### Tracts

```bash
bash ./dsi.sh tracking7ff6ab123410 list_param tracking
bash ./dsi.sh tracking7ff6ab123410 run_tracking "CST"
bash ./dsi.sh tracking7ff6ab123410 list_tract status
bash ./dsi.sh tracking7ff6ab123410 list_tract
```

Poll until `list_tract status` reports `status=done` before dependent operations.

### Tracking and rendering parameters

```bash
bash ./dsi.sh tracking7ff6ab123410 list_param
bash ./dsi.sh tracking7ff6ab123410 list_param tracking
bash ./dsi.sh tracking7ff6ab123410 set_param fa_threshold 0.08
bash ./dsi.sh tracking7ff6ab123410 set_params "fa_threshold=0.08&min_length=20"
```

Use `list_param` before changing a value.

## Current discovery limitation

The device interface currently has no `list_device`. Numeric device indices follow
current table order. Prefer current-row operations when the correct row is already
selected; otherwise ask the user to identify the target before an indexed mutation.

## Operational rules

- Send `TITLE` first and update it when the task changes substantially.
- Use `CHAT` or `-Chat` for user-visible progress and results.
- Use one `bash ./dsi.sh` invocation per request.
- When the user requests demo mode, follow the narration and progress rules in
  `Demo mode`.
- Copy exact paths, window IDs, indices, model IDs, and parameter IDs from the user,
  current command output, or another verified source.
- Confirm destructive operations, overwrites, and saved-history clearing.
- A local modal dialog is a supported way for the user to choose an input; do not
  answer it remotely or mistake `waiting` for failure.
- A timeout does not prove failure; verify state before retrying.
- If a window disappears, call `LIST`; do not reopen it automatically.

## Related documents

- [Launcher selection and troubleshooting](DSI_STUDIO_AI_LAUNCHER.md)
- [Reconstruction commands and examples](DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md)
- [Fiber-tracking workflow](DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md)
- [Main window and Fiber Data Hub](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Parameters, rendering, camera, surfaces, workspace, settings, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Standalone image-window processing](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)

Read only the files relevant to the current task.
