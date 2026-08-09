# DSI Studio

These instructions are shared by Codex and Claude agents. `AGENTS.md` is the
authoritative operating manual for DSI Studio AI. Topic-specific command inventories
remain in the related `DSI_STUDIO_AI_*.md` files and should be read only when needed.

## 1. Launcher and session

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
bash ./dsi.sh <command> [values...]
```

Always include `bash` before `./dsi.sh`. Use one invocation per request. If this
launcher does not work, read `DSI_STUDIO_AI_SKILL_LAUNCHER.md` for platform requirements,
troubleshooting, and the documented Windows fallback.

The launcher maps requests as follows:

1. The first argument is the command name; remaining values are its parameters.
2. Every session starts with `main` selected. `set_window` changes the selected
   target and that selection persists. Successful `open_src`, `open_fib`,
   `open_image`, and `open_connectometry` commands automatically select the newly
   created window.
3. Standalone integers and floating-point values become JSON numbers. Paths, names,
   and composite expressions remain strings.
4. `-Chat "message"` may accompany a command or may be sent by itself.
5. There is no separate window-ID argument and no separate request-type keyword.

Shared `bring_to_front`, `minimize`, `maximize`, and `close` controls are handled
before ordinary MainWindow/window routing. `run_cli` and `run_shell` are global
MainWindow commands with different execution models. Read their dedicated guides
before using them.

## 2. Required startup sequence

Learn DSI Studio by performing the following three requests in order. Complete and
inspect all three replies before reading further in this file or opening any other
DSI Studio AI document.

### 2.1 Set the task title

```bash
bash ./dsi.sh set_title "<concise title derived from the user's task>"
```

Set a concise task title and update it when the task changes substantially.
`set_title` must be sent as its own request; never combine it with an unrelated
command.

### 2.2 Send a progress message

```bash
bash ./dsi.sh -Chat "<brief improvised message that you are reading the DSI Studio manual before continuing>"
```

`-Chat` is user-facing communication. It does not retrieve action history; use
`log` for that purpose.

### 2.3 Learn a main-window command

```bash
bash ./dsi.sh list_recent_fib
```

After receiving and inspecting the replies to Steps 2.1-2.3, continue below.

## 3. Window targeting, state, and replies

### 3.1 Supported windows

```bash
bash ./dsi.sh list_window
```

`main` is fixed. Other supported windows use exact current IDs returned by DSI
Studio:

| Window | Purpose |
|---|---|
| `main` | Recent files, Fiber Data Hub, opening files, templates, databases, QC, main tools, confirmation-gated shell access, and Windows desktop speech |
| `recon<hex-address>` | SRC/SZ masks, source geometry, b-table operations, corrections, exports, parameters, and reconstruction |
| `tracking<hex-address>` | Slices, segmentation, regions, tracts, tracking, rendering, devices, settings, and workspaces |
| `image<hex-address>` | Standalone medical-image inspection and processing |
| `connectometry<hex-address>` | Correlational tractography, demographics/cohort selection, permutation analysis, and result display |

Successful `open_src`, `open_fib`, `open_image`, and `open_connectometry` commands
normally report the new ID directly:

```text
recon window created, id: recon...
tracking window created, id: tracking...
image window created, id: image...
connectometry window created, id: connectometry...
```

They also make that newly created window the session's current target, so following
commands can act on it directly without `set_window`. Copy the exact returned ID for
later switching. Do not construct an ID, replace it with a filename, or reuse it
after the window closes. Use `list_window` to confirm an ID or discover another
already-open supported window, not merely to rediscover a window whose ID was just
returned.

`set_window` accepts only `main` or an exact current window ID returned by
`list_window` or an open command. It does not resolve a window by title, filename,
file basename, or bare window type. `set_window` with no parameter returns to `main`.

`list_window` reports `idle`, `busy`, or `waiting`. `waiting` means a modal local
dialog is awaiting the user's decision.

### 3.2 Select another window when needed

```bash
bash ./dsi.sh set_window tracking<hex-address>
bash ./dsi.sh list_region
```

```bash
bash ./dsi.sh set_window recon<hex-address>
bash ./dsi.sh recon 4
```

Use `set_window main` (or `set_window` with no parameter) to switch back. Send
standalone numeric parameters without quotes. Keep multiple values or assignments in
one quoted composite parameter when the command expects one string:

```bash
bash ./dsi.sh set_params "fa_threshold=0.08&min_length=20"
bash ./dsi.sh set_voxel_size "1.5 1.5 2.0"
```

For commands accepting multiple files, pass one path per argument. Never send a
filesystem path by itself as the complete request.

### 3.3 Shared window controls

`bring_to_front`, `minimize`, and `maximize` take no arguments and act on the
currently selected supported window:

```bash
bash ./dsi.sh bring_to_front
bash ./dsi.sh minimize
bash ./dsi.sh maximize
```

`bring_to_front` restores the selected window to normal state before raising and
activating it. These controls change only visibility, focus, or window state.

`close` also takes no argument. It closes the selected reconstruction, tracking,
standalone image, or connectometry window; AI cannot close `main`:

```bash
bash ./dsi.sh close
```

A tracking-window close issued by AI bypasses the local `Tractography not saved`
prompt. Confirm the operation before sending it whenever unsaved tracts may exist.
After any successful close, immediately select `main` or another valid current ID;
the session still remembers the now-invalid closed target. Put `close` last in a
multi-command request.

For ChatGPT (Web), a command named `close` closes the selected DSI Studio window,
while an issue-session `request:"close"` disconnects the GitHub issue channel. See
`DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md` and `DSI_STUDIO_AI_SKILL_GITHUB_ISSUE_SESSION.md`.

### 3.4 Read the log when state changed outside the agent

```bash
bash ./dsi.sh log
```

Use `log` after the user demonstrates a workflow, changes settings manually, retries
a failed action, or performs GUI operations the agent needs to learn. It returns only
new console/action output since the session's previous log position and advances that
position.

The first-ever `log` call initializes the cursor at the current end of the console
and intentionally returns no older output. Call it before starting an asynchronous
operation when its later output must be captured.

Pass anything as `command[1]` (or `command[2]`) — the value itself is ignored — to instead
pull everything still retained in the console buffer (e.g. `["log","all"]`), rather than only
what's new since this session's cursor. Useful for catching up on another agent's or the
user's earlier actions in the same running instance. This still advances this session's log
cursor and is still capped (see below), so it cannot recover output older than what the
console buffer still retains, and repeating it immediately afterward returns nothing new.

### 3.5 Interpret replies conservatively

Every reply has top-level `status` and one result per executed command. Results
contain `cmd` and `status`; text-producing commands may include `output`; failed
commands include `error`.

Success means the handler returned without an immediate error. A long synchronous
operation may exceed the client's waiting period while continuing inside DSI Studio.
Do not immediately resend it; inspect `list_window`, `log`, or the relevant status
command first.

## 4. Opening data and local input

### 4.1 Open user-supplied or recent source files

Open an SRC/SZ reconstruction window:

```bash
bash ./dsi.sh open_src "C:/data/subject.sz"
```

If no path is supplied by the user:

```bash
bash ./dsi.sh list_recent_src
bash ./dsi.sh open_src "<exact relevant path returned by list_recent_src>"
```

Open a FIB/FZ tracking window:

```bash
bash ./dsi.sh open_fib "C:/data/subject.fz"
```

When no path is supplied, use an exact relevant path returned by
`list_recent_fib`. Do not invent paths.

Open a supported medical image:

```bash
bash ./dsi.sh open_image "C:/data/T1w.nii.gz"
```

`open_image` is for supported medical-image volumes. Do not use it to open or verify
ordinary screenshots or pictures such as JPG, PNG, BMP, GIF, WEBP, TIF, or TIFF.
Verify screenshot output through the filesystem or an external image viewer.

`open_src`, `open_fib`, and `open_image` each create a data window. Close that window
when the task no longer needs it, then select `main` or another valid window, to keep
the workspace uncluttered.

### 4.2 Local dialogs are valid user input

Parameterless main-window or reconstruction commands may open a local picker or
dialog. Cancellation can return without an immediate error, so verify whether the
expected file, window, or setting was created.

When a command supports a local dialog, omitting the parameter can be intentional:

```bash
bash ./dsi.sh mask_open -Chat "Please choose the reconstruction mask in DSI Studio."
bash ./dsi.sh save_nifti -Chat "Please choose where to save the diffusion NIfTI."
bash ./dsi.sh resample -Chat "Please choose the isotropic output resolution."
```

While the dialog is open, `list_window` may report `waiting`. Continue only after
the user selects a value or cancels. When the exact value is already known, pass it
directly.

## 5. SRC/SZ reconstruction workflow

If reconstruction does not apply to the task, study this section without running
materially altering commands.

### 5.1 Reconstruction window targeting

A successful `open_src` automatically selects the newly created
`recon<hex-address>` window. Use `set_window` only when switching to another already
open window.

### 5.2 Inspect and set parameters

```bash
bash ./dsi.sh list_param
bash ./dsi.sh list_param method
bash ./dsi.sh set_param "method=4"
bash ./dsi.sh set_params "method=4&param=1.25&thread_count=8"
```

`set_param` and `set_params` both accept one
`name=value[&name=value...]` composite parameter.

### 5.3 Use concise reconstruction operation names

```bash
bash ./dsi.sh mask_unet
bash ./dsi.sh bias_field_correction
bash ./dsi.sh resample 2
bash ./dsi.sh recon 4
```

Use `recon`, not `reconstruction`, `src_recon`, or `src_reconstruction`. Optional
method values are `1` for DTI, `4` for GQI, and `7` for QSDR. Omitting the method
uses the current `method` parameter.

A successful reconstruction prints each generated path as:

```text
reconstruction output: <path>
```

Generated FIB/FZ paths are added to the recent-FIB list. For a multi-file
reconstruction window, inspect all returned output paths.

For AI-originated `topup` or `topup_eddy` without a parameter, DSI Studio uses its
automatic reverse-phase-encoding search. Pass an explicit `.rz`, `.sz`, `src.gz`, or
NIfTI path when the correct reverse-PE source is known.

Corrections, b-table changes, source geometry changes, mask operations, resampling,
and reconstruction can materially alter results. Do not run them merely to learn the
interface. Read `DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md` before changing
source data or running reconstruction.

## 6. FIB/FZ tracking workflow

If tracking does not apply to the task, study this section without running materially
altering commands.

### 6.1 Tracking window targeting

A successful `open_fib` automatically selects the newly created
`tracking<hex-address>` window. Use `set_window` only when switching to another
already open window.

### 6.2 Inspect and load slices

```bash
bash ./dsi.sh list_slice
bash ./dsi.sh set_slice <slice-index>
bash ./dsi.sh list_slice
```

Use an index returned by `list_slice`. A URL-backed Hub slice may initially report
`available` or `registering`. Poll until the selected row reports `ready` before
using it.

### 6.3 Segment a brain

```bash
bash ./dsi.sh list_unet
bash ./dsi.sh segment_brain "<model-ID>" <slice-index>
bash ./dsi.sh list_region
```

Use the internal `model` value from a `list_unet` row with `available=1`, not its
display name. For the common SynthSeg exercise, use `human_synthseg` only when that
exact model ID is available.

### 6.4 Add atlas regions

```bash
bash ./dsi.sh list_atlas
bash ./dsi.sh list_atlas "<atlas name or index>"
bash ./dsi.sh add_region_from_atlas "<template-index> <atlas-index> <label-index>"
bash ./dsi.sh list_region
```

`list_atlas` with no argument lists atlases for the current template only, giving
each atlas's index. Follow up with that name or index to list the atlas's exact
region names and indices -- use those returned indices for `<label-index>`, not a
guess or a value from an unrelated source. Join multiple label indices with `&`.
In the current BrainSeg teaching example, `template=0`, `atlas=1`, and labels
`3&4` correspond to left and right thalamus, confirmed via `list_atlas 1`.

### 6.5 Inspect tracking parameters and run tracking

```bash
bash ./dsi.sh list_param tracking
bash ./dsi.sh run_tracking "Whole Brain"
bash ./dsi.sh list_tract status
```

Repeat `list_tract status` until it reports `status=done`, then inspect the result:

```bash
bash ./dsi.sh list_tract
```

Use `list_param` before changing tracking or rendering values:

```bash
bash ./dsi.sh list_param
bash ./dsi.sh set_param fa_threshold 0.08
bash ./dsi.sh set_params "fa_threshold=0.08&min_length=20"
```

### 6.6 Device-index limitation

The device interface currently has no `list_device`. Numeric device indices follow
current table order. Prefer current-row operations when the correct row is already
selected; otherwise ask the user to identify the target before an indexed mutation.

## 7. Fiber Data Hub

All Hub commands target `main`. Switch back first when necessary:

```bash
bash ./dsi.sh set_window main
bash ./dsi.sh hub_repo
```

### 7.1 Discover repositories and tags

```bash
bash ./dsi.sh hub_repo
bash ./dsi.sh hub_tags "<exact repository returned by hub_repo>"
```

Use the exact repository string returned by `hub_repo`.

### 7.2 List matching files

```bash
bash ./dsi.sh hub_files "<exact repository>" "<exact tag>" ".fz" 0 20
```

`hub_files` can use case-insensitive regular-expression tag and filename filters; an
empty pattern matches all. It searches across matching tags and returns `index`,
`tag`, `file`, `size`, and `downloaded`. Offset and limit apply to the combined
matches.

### 7.3 Open or download Hub data

```bash
bash ./dsi.sh hub_open "<exact repository>" "<exact tag>" <file-row-index>
```

Use the row index or exact filename returned by `hub_files`. If the reply directly
contains `tracking window created, id: tracking...`, use that exact ID. A
network-backed open may finish after the immediate reply; if no ID is returned, use
`list_window` to discover the newly opened window.

To learn what a tag's dataset actually is, read its GitHub release note first:

```bash
bash ./dsi.sh hub_show "<exact repository>" "<exact tag>"
```

To read a `.tsv` release file's content directly instead, without opening it as the
release-note table in the Hub window, add the file:

```bash
bash ./dsi.sh hub_show "<exact repository>" "<exact tag>" "subjects.tsv"
```

Same row-index-or-exact-filename rule as `hub_open`. Either form's reply is the
release note or the file's raw tab-separated text directly, not a status line;
the file form fails if the resolved file does not end in `.tsv`.

For downloads:

```bash
bash ./dsi.sh hub_download "<exact repository>" "<tag-regex>" "*.qsdr.fz" "C:/data"
```

`hub_download`'s file parameter is a wildcard pattern (`*`, `?`, `[...]`), not a
regex, and matches every file in every matching tag -- one call can download many
files across many tags/subjects. A plain exact filename still matches only that one
file, since the wildcard is anchored to the full name. Verify the destination
directory's contents after network-backed work.

## 8. Internal CLI and confirmation-gated shell

Read `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md` before using either command.

### 8.1 Use `run_cli` only for DSI Studio CLI actions

Keep the complete command line in one string:

```bash
bash ./dsi.sh run_cli "--action=vis --source=C:/data/subject.fz --cmd=list_tract"
```

`run_cli` executes the internal CLI action in the current DSI Studio process; it
does not start another executable. Missing `--action` defaults to `vis`. CLI actions
do not use the session's `set_window` selection. Relative paths use this AI
session's own current directory (remembered per chat, not process-wide), and CLI
actions may modify global application state.

Never send an operating-system command through `run_cli`.

### 8.2 `run_shell`: `cd` is free, everything else needs local user approval

```bash
bash ./dsi.sh run_shell "cd \"C:/data\""
bash ./dsi.sh run_shell "cd"
bash ./dsi.sh run_shell "dir \"*.fz\" /s /b"
```

`cd` changes this AI session's own current directory (remembered per chat, not
process-wide) and therefore affects later relative `run_shell` and `run_cli` paths
in the same chat; it runs with no confirmation dialog and no external process.
Every other `run_shell` command shows the local user a
confirmation dialog with the exact command text and only runs if they approve it —
there is no whitelist or character restriction anymore, the dialog is the only gate.
This means `run_shell` cannot complete unattended with nobody at the DSI Studio
machine to respond, and a batched command array containing `run_shell` pauses at
that dialog before continuing. `dir` (and any other approved, non-`curl` command)
runs synchronously once approved.

`curl` runs asynchronously once approved:

```bash
bash ./dsi.sh log
bash ./dsi.sh run_shell "curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""
```

The initial reply returns a synthetic `curlN` task ID and does not prove transfer
completion. Initialize the log cursor before the first asynchronous curl. Poll
`list_window` until the `curlN` entry disappears, then call `log` again to retrieve
output or errors. Do not place a command that depends on the downloaded file after
`curl` in the same command array.

For ChatGPT (Web), initialize logging with a prior `log` request or
`include_log:true` on the curl-start request.

Never send credentials, tokens, or other sensitive text in a `run_shell` command —
the local user sees the exact text in the confirmation dialog either way. Never send
a DSI Studio `--action=...` line through `run_shell`.

## 9. Windows speech and demo mode

### 9.1 Desktop speech

On Windows, use `voice` for one concise non-empty spoken message:

```bash
bash ./dsi.sh voice "Reconstruction is complete."
```

A successful reply means the PowerShell speech process started, not that speech has
finished. Each call starts a separate process, so rapid calls may overlap. Keep
spoken messages concise. Continue to provide durable user-facing information through
`-Chat`, and do not speak sensitive content unless the user explicitly asks.

### 9.2 Demo mode

Use demo mode only when the user asks for a demonstration, presentation, guided
walkthrough, or spoken narration.

Before each major user-visible action, speak one concise sentence describing what
will happen next and, when useful, why it matters. Major actions include opening or
selecting data, choosing an image or model, starting registration, reconstruction,
segmentation, or tracking, changing the displayed result, and completing the task.
Do not narrate routine discovery commands or every minor UI change.

Run `voice` immediately before the corresponding action as its own invocation:

```bash
bash ./dsi.sh voice "The T1 weighted image is ready. I will now run tumor segmentation."
bash ./dsi.sh segment_brain human_tumor_T1w 8
bash ./dsi.sh list_region
```

Before a potentially long operation, state what is starting and what result is
expected. For asynchronous work, provide brief meaningful progress narration while
checking status. After synchronous long work returns, announce the verified result
before the next major action.

Spoken narration must sound like the presentation itself. Do not expose internal
orchestration details such as cooldowns, polling mechanics, issue updates, request
IDs, command arrays, or transport behavior. Base every progress statement on
verified state and never announce completion before results confirm it.

## 10. Operational safeguards

1. Use one `bash ./dsi.sh` invocation per request.
2. Use `-Chat` for user-visible progress and results.
3. Copy exact paths, window IDs, indices, model IDs, and parameter IDs from the user,
   current command output, or another verified source.
4. Confirm destructive operations, overwrites, saved-history clearing, wildcard CLI
   actions, and tracking-window closes that may discard unsaved tracts.
5. After closing a selected window, immediately use `set_window main` or another
   valid current ID.
6. A local modal dialog is supported user input; do not answer it remotely or treat
   `waiting` as failure.
7. A timeout does not prove failure; verify state before retrying.
8. If a window disappears, call `list_window`; do not reopen it automatically.
9. Use `open_image` only for supported medical image volumes, never to verify
   screenshots.
10. When the user demonstrates, changes, or retries something manually, inspect
    `log` rather than relying on memory.
11. Before `run_cli` or `run_shell`, read
    `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md` and follow its completion-verification
    rules.
12. Read only the topic-specific files needed for the current task.

## 11. Related documents

- [Launcher selection and troubleshooting](DSI_STUDIO_AI_SKILL_LAUNCHER.md)
- [Shared window controls](DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md)
- [Internal CLI actions and confirmation-gated shell commands](DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md)
- [Direct GitHub issue control](DSI_STUDIO_AI_SKILL_GITHUB_ISSUE_SESSION.md)
- [Command index](DSI_STUDIO_AI_COMMAND_EXAMPLES.md)
- [Main window and Fiber Data Hub](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Reconstruction commands and examples](DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md)
- [Standalone image-window processing](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Parameters, rendering, camera, surfaces, workspace, settings, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- [Fiber-tracking workflow](DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md)

Read only the files relevant to the current task, then continue using
`bash ./dsi.sh`.