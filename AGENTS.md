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

### 4.3 Verify connectometry demographics before analysis

After `open_connectometry`, never assume the database contains demographics merely
because it opens successfully or lists subjects. Before selecting a variable of
interest, selecting a cohort, or starting correlational tractography, inspect both:

```bash
bash ./dsi.sh get_demo
bash ./dsi.sh list_voi
```

`get_demo` should show the demographic columns needed by the planned model in
addition to the subject identifier, and `list_voi` should list the required study
variable and covariates. If `get_demo` shows only subjects with no usable demographic
columns, or `list_voi` is empty or missing required variables, load the external
demographics table before continuing:

```bash
bash ./dsi.sh open_mr_files "C:/data/participants.tsv"
bash ./dsi.sh get_demo
bash ./dsi.sh list_voi
```

Use an exact demographics path supplied by the user or discovered from verified
local/dataset information; do not invent one. If the required demographics file is
not available, stop before `set_voi`, cohort selection, or `run` and report the
missing input.

Repeat this check after creating or opening a derived database, including a
longitudinal difference database. Do not infer that demographics from the source
database or a neighboring `participants.tsv`/CSV file were embedded or carried into
the derived database.

## 5. Quick fiber tracking: map the arcuate fasciculi

After opening a FIB/FZ file, AutoTrack provides a quick way to map a standard
white-matter bundle. Inspect the available tract names first:

```bash
bash ./dsi.sh list_auto_tract
```

AutoTrack names are hierarchical. When the user asks for the whole tract family,
select its parent entry rather than a branch-specific descendant. For example, use
`Association_CingulumL` for the entire left cingulum and the corresponding parent
entry for the corpus callosum; select a child entry only when a specific subdivision
or branch is requested.

Set a practical tracking size and topology-informed pruning (TIP):

```bash
bash ./dsi.sh set_params "max_tract_count=10000&max_seed_count=50000000&tip_iteration=4"
```

Use exact tract names returned by `list_auto_tract`. For example, map the left
arcuate fasciculus:

```bash
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh list_tract status
```

`run_auto_track` is asynchronous. Repeat `list_tract status` until it reports
`done`, then inspect the result:

```bash
bash ./dsi.sh list_tract
```

Map the right arcuate the same way:

```bash
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusR"
bash ./dsi.sh list_tract status
bash ./dsi.sh list_tract
```

TIP pruning is a bundle-cleanup operation. Apply this recommendation to a visually
coherent tract bundle, including a named AutoTrack bundle or a previously loaded or
recognized bundle result. If such a bundle can reach roughly 5,000–10,000 or more
tracts before pruning, cleanup is desired and `tip_iteration` should normally remain
at 3–4 (4 is a good default). Do not set `tip_iteration=0` merely to preserve tract
count or because the user did not explicitly request cleanup. Use `tip_iteration=0`
only when intentionally examining an unpruned bundle or when the bundle is too sparse
for pruning to be appropriate.

Do not apply this TIP recommendation to ordinary whole-brain tractography. Whole-brain
tracking is not a single visually coherent bundle, so topology-informed pruning is
usually not appropriate as a generic cleanup step there. TIP removes trajectories
from a bundle based on its topology, and the final bundle count is therefore
data-dependent and lower than the pre-pruning count.

AutoTrack already uses built-in anatomical region constraints for each named bundle.
For standard AutoTrack, do not add ROI, ROA, END, NotEND, Limiting, Terminating, or
other user region constraints by default; extra regions can unnecessarily restrict
or distort the intended bundle. Add an additional region constraint only for a
specific anatomical purpose, such as isolating a minor branch or selectively
restricting a known component of the bundle.

For a simple anatomical 3D view, hide slices and add the built-in white-matter
surface:

```bash
bash ./dsi.sh set_params "show_slice=0&show_tract=1&show_surface=1"
bash ./dsi.sh add_surface 0 25
```

For manual ROI tracking, segmentation, atlas regions, parameter tuning, tract
editing, quality control, or advanced analysis, read
`DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` and the relevant command-example document.

## 6. Batch processing multiple subjects: tutorial example

Build a pipeline once against one subject with ordinary commands, then replay it
with `run_command_history` instead of repeating every command per subject.

```bash
bash ./dsi.sh open_fib "C:/data/sub-01.qsdr.fz"
bash ./dsi.sh run_tracking "WholeBrain"
bash ./dsi.sh list_tract status
bash ./dsi.sh save_lr_screen "C:/data/sub-01_wholebrain.png" "1600 900"
```

Check exactly what was recorded before replaying it -- an earlier polling loop or
other side command can leave noise in the history:

```bash
bash ./dsi.sh list_history
```

Replay it across the remaining subjects, either a folder (searched using the
recorded load step's file extension) or an explicit `&`-joined file list:

```bash
bash ./dsi.sh run_command_history "C:/data/sub-02.qsdr.fz&C:/data/sub-03.qsdr.fz"
```

`run_command_history` substitutes each new file into the recorded load step and
remaps related load/save filenames (e.g. `sub-01_wholebrain.png` becomes
`sub-02_wholebrain.png`). It replays every recorded command by default; restrict it
to specific `list_history` indices when the recording contains noise, using a single
`from:to` range or several `&`-joined ranges/indices:

```bash
bash ./dsi.sh run_command_history "C:/data/sub-02.qsdr.fz&C:/data/sub-03.qsdr.fz" "0:1&12:15&16"
```

It never pops a dialog for a missing or failed file when called by an agent; it logs
and skips that file instead of blocking.

## 7. Fiber Data Hub

Fiber Data Hub supports two access routes: direct web/GitHub access and DSI Studio
`hub_*` commands. Both are valid. Choose the route that best fits the task and
available tools.

For dataset discovery, release metadata, QC lookup, file listing, and downloading
public assets, an agent may work directly from https://brain.labsolver.org and the
corresponding GitHub releases without routing through DSI Studio. The direct-access
guide is maintained in `frankyeh/Brain-Data`:
https://github.com/frankyeh/Brain-Data/blob/gh-pages/AGENTS.md

Use the DSI Studio route below when it is convenient or when the task needs DSI
Studio to open, visualize, track, or analyze Hub data. If one route is unavailable,
use the other when it can satisfy the same request. Do not force either route when
the other is simpler.

All DSI Studio Hub commands target `main`. Switch back first when necessary:

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

On Windows, use `voice` for one concise non-empty spoken message. It can announce a
result or explain the next visible action:

```bash
bash ./dsi.sh voice "Reconstruction is complete."
bash ./dsi.sh voice "I will now map the left arcuate fasciculus."
```

A successful reply means the PowerShell speech process started, not that speech has
finished. Each call starts a separate process, so rapid calls may overlap. Keep
spoken messages concise. Continue to provide durable user-facing information through
`-Chat`, and do not speak sensitive content unless the user explicitly asks.

### 9.2 Voice tutorials and demo mode

Users may ask for a **voice tutorial**, spoken tutorial, demonstration, presentation,
or guided walkthrough. Treat these requests as demo mode. A voice tutorial is a live
narrated DSI Studio workflow, not a verbal summary of commands.

**Do not run any DSI Studio command silently in voice tutorial mode.** Every command,
including discovery, setup, processing, inspection, and status checks, must be
preceded by a separate concise `voice` command explaining what is about to happen and,
when useful, why. Speak first, run the command, inspect its result, then narrate the
next command.

Example:

```bash
bash ./dsi.sh voice "I will first list the available automatic tract names."
bash ./dsi.sh list_auto_tract
bash ./dsi.sh voice "I will now map the left arcuate fasciculus."
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh voice "I will check whether the tractography has finished."
bash ./dsi.sh list_tract status
bash ./dsi.sh voice "I will inspect the resulting tract bundle and its tract count."
bash ./dsi.sh list_tract
```

This narration rule applies step-by-step for the entire tutorial. There must be no
unexplained DSI Studio command between narrated steps. Keep each spoken message short
and natural; explain the purpose of the action rather than reading command syntax.

Before a potentially long operation, state what is starting and what result is
expected. For asynchronous work, narrate every subsequent status check before sending
it. Announce completion only after the returned result confirms it.

Spoken narration must sound like the tutorial or presentation itself. Do not expose
internal orchestration details such as cooldowns, polling mechanics, issue updates,
request IDs, command arrays, or transport behavior. Base every progress statement on
verified state and never announce completion before results confirm it.

## 10. SRC/SZ reconstruction workflow

If reconstruction does not apply to the task, study this section without running
materially altering commands.

### 10.1 Reconstruction window targeting

A successful `open_src` automatically selects the newly created
`recon<hex-address>` window. Use `set_window` only when switching to another already
open window.

### 10.2 Inspect and set parameters

```bash
bash ./dsi.sh list_param
bash ./dsi.sh list_param method
bash ./dsi.sh set_param "method=4"
bash ./dsi.sh set_params "method=4&param=1.25&thread_count=8"
```

`set_param` and `set_params` both accept one
`name=value[&name=value...]` composite parameter.

### 10.3 Use concise reconstruction operation names

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

## 11. Operational safeguards

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
12. TIP pruning guidance applies to visually coherent tract bundles, including
    AutoTrack bundles and previously loaded or recognized bundle results. When such a
    bundle is sufficiently populated (roughly 5,000–10,000 or more tracts), cleanup
    with 3–4 TIP iterations is normally desired. Do not treat TIP as generic
    tract-count cleanup, and do not apply it by default to whole-brain tractography.
13. Standard named-bundle AutoTrack already has built-in anatomical region
    constraints. Do not add ROI/ROA/END/NotEND/Limiting/Terminating or other region
    constraints unless a specific anatomical question requires them, such as
    isolating a minor branch.
14. Before any connectometry analysis, complete the demographics preflight in
    Section 4.3. Recheck derived and longitudinal databases instead of assuming
    demographics were embedded or carried forward.
15. Read only the topic-specific files needed for the current task.

## 12. Related documents

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