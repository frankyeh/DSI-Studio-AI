# DSI Studio

These instructions are shared by Codex, Claude, Muse, Antigravity, and Grok agents. `AGENTS.md` is the
authoritative operating manual for DSI Studio AI. Topic-specific command inventories are in the
related `DSI_STUDIO_AI_*.md` files (Section 12); read them only when needed.

## 1. Launcher and session

DSI Studio starts Codex, Claude, Muse, and Grok in this DSI Studio AI directory and separately grants
access to (or, for Grok, names in the startup prompt) the user-selected project directory.
Antigravity starts in the selected project directory; its startup prompt gives the absolute path to
this AI directory and launcher. Do not copy the AI support files into the project directory.

DSI Studio supplies `DSI_STUDIO_AGENT` to identify the current agent; the launcher then reads only
that agent's native session variable:

```text
Codex       -> CODEX_THREAD_ID
Claude      -> CLAUDE_CODE_SESSION_ID
Muse        -> MUSE_SESSION_ID
Antigravity -> ANTIGRAVITY_CONVERSATION_ID
Grok        -> GROK_SESSION_ID
```

Do not search for, invent, replace, or pass the agent name or session value on the command line.
Only pipelines that run at the same time need their own sessions; see "Parallel pipelines" in
`DSI_STUDIO_AI_SKILL_LAUNCHER.md`.

All agents use one launcher, always prefixed with `bash`:

```bash
bash ./dsi.sh <command> [values...]
```

Antigravity must use the absolute `dsi.sh` path from its startup prompt (its working directory is
the project); the others normally use `./dsi.sh`. Use one invocation per request. If the launcher
does not work, read `DSI_STUDIO_AI_SKILL_LAUNCHER.md` for platform requirements, troubleshooting,
and the documented Windows fallback.

Request mapping:

1. The first argument is the command name; remaining values are its parameters.
2. Every session starts with `main` selected. `set_window` changes the selected target, and the
   selection persists. Successful `open_src`, `open_fib`, `open_image`, and `open_connectometry`
   select the newly created window.
3. Standalone integers and floating-point values become JSON numbers; paths, names, and composite
   expressions stay strings.
4. `-Chat "message"` may accompany a command or be sent by itself.
5. A long string parameter (for example a script for `write_text_file`) goes through stdin: put
   `--stdin` in its place and pipe the text, e.g.
   `bash ./dsi.sh write_text_file build.py --stdin <<'PY'` ... `PY` (see
   `DSI_STUDIO_AI_SKILL_LAUNCHER.md`).
6. There is no separate window-ID argument and no separate request-type keyword.

The shared controls `bring_to_front`, `minimize`, `maximize`, `move_window`, and `close` are handled
before ordinary MainWindow/window routing. `run_cli` and `run_shell` are global MainWindow commands
with their own execution models; read their guide (Section 8) before using them.

## 2. Required startup sequence

Send these three requests in order, and inspect all three replies before reading further in this
file or opening any other DSI Studio AI document.

Exception: a coding task that only reads or edits source or text files (no DSI Studio data, window,
or analysis) skips Steps 2.1-2.3. Edit files with your own tools or with `patch_text_file`
(Section 8.3), and check the repository with `run_shell "git status"` or `run_shell "git diff"`.

### 2.1 Set the task title

```bash
bash ./dsi.sh set_title "<concise title derived from the user's task>"
```

Update it when the task changes substantially. Send `set_title` as its own request, never combined
with an unrelated command.

### 2.2 Send a progress message

```bash
bash ./dsi.sh -Chat "<brief improvised message that you are reading the DSI Studio manual before continuing>"
```

`-Chat` is user-facing communication; it does not retrieve action history (use `log`). It is not a
command: over Web it is the request's `chat` field (`{"chat":"..."}`), and `{"cmd":"chat"}` fails
with `unknown command: chat`.

### 2.3 Learn a main-window command

```bash
bash ./dsi.sh list_recent_fib
```

## 3. Window targeting, state, and replies

### 3.1 Supported windows

```bash
bash ./dsi.sh list_window
```

`main` is fixed; other windows use exact current IDs returned by DSI Studio:

| Window | Purpose |
|---|---|
| `main` | Recent files, Fiber Data Hub, XNAT, opening files, templates, databases, QC, main tools, confirmation-gated shell access, and desktop speech |
| `recon<hex-address>` | SRC/SZ masks, source geometry, b-table operations, corrections, exports, parameters, and reconstruction |
| `tracking<hex-address>` | Slices, segmentation, regions, tracts, tracking, rendering, devices, settings, and workspaces |
| `image<hex-address>` | Standalone medical-image inspection and processing |
| `connectometry<hex-address>` | Correlational tractography, demographics/cohort selection, permutation analysis, and result display |
| `window<hex-address>` | Any other visible window (Fiber Data Hub, result tables, dialogs): shared controls and tutor commands only |

Open commands report the new ID and make it the current target, so later commands act on it without
`set_window`:

```text
recon window created, id: recon...
tracking window created, id: tracking...
image window created, id: image...
connectometry window created, id: connectometry...
```

Copy the exact returned ID for later switching. Never construct an ID, replace it with a filename,
or reuse it after the window closes. Use `list_window` to confirm an ID or find another open window,
not to rediscover one just returned. `set_window` accepts only `main` or an exact current ID; it
does not resolve titles, filenames, basenames, or bare types. `set_window` with no parameter returns
to `main`.

`list_window` reports each window's `idle`, `busy`, or `waiting` status (`waiting`: a modal local
dialog awaits the user) and its `geometry`.

### 3.2 Select another window and pass parameters

```bash
bash ./dsi.sh set_window tracking<hex-address>
bash ./dsi.sh list_region
bash ./dsi.sh set_window recon<hex-address>
bash ./dsi.sh recon 4
```

Send standalone numbers without quotes. Keep multiple values or assignments in one quoted composite
parameter when the command expects one string:

```bash
bash ./dsi.sh set_params "fa_threshold=0.08&min_length=20"
bash ./dsi.sh set_voxel_size "1.5 1.5 2.0"
```

For commands accepting multiple files, pass one path per argument. Never send a filesystem path by
itself as the complete request.

### 3.3 Shared window controls and tutoring

These act on the selected window:

```bash
bash ./dsi.sh bring_to_front
bash ./dsi.sh minimize
bash ./dsi.sh maximize
bash ./dsi.sh move_window 100 80 1200 900
bash ./dsi.sh close
```

- `bring_to_front` restores the window to normal state, then raises and activates it.
- `move_window <x> <y> [width] [height]` moves and resizes it, in the `geometry` pixels that
  `list_window` reports.
- `close` closes the selected non-main window; AI cannot close `main`. Closing a dialog cancels it.
  A tracking-window close bypasses the local `Tractography not saved` prompt, so confirm first
  whenever unsaved tracts may exist. Put `close` last in a multi-command request, then immediately
  select `main` or another valid ID: the session still remembers the closed target.
- These controls change only visibility, focus, position, or window state.

Before talking about one window, check that no other window (for example the Fiber Data Hub after a
download) covers it; select the covering one and `minimize`, `move_window`, or `close` it.

When the user wants to learn how to do something in the GUI rather than have it done, start from
the matching lesson in `DSI_STUDIO_AI_SKILL_LESSONS.md` and teach with the tutor commands
`list_ui`, `highlight_ui`, `clear_highlight`, `ask_user`, `ask_user_modal`, and `ask_user_act`; narrate with `voice`
once the user has agreed to a voice tutorial (9.2). They only point at controls of the selected
window or ask the user, and never click or change data. See
`DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md` for the complete shared-window and tutor rules.

### 3.4 Read the log when state changed outside the agent

```bash
bash ./dsi.sh log
```

Use `log` after the user demonstrates a workflow, changes settings manually, retries a failed
action, or performs GUI operations the agent needs to learn; do not rely on memory. It returns only
new console/action output since the session's previous log position and advances that position.
The first-ever `log` call initializes the cursor at the current end and returns no older output, so
call it before starting an asynchronous operation whose output must be captured.

The console log is process-wide, not authoritative per-window state: a reply can contain messages
from another window or background operation. Treat such lines as evidence that something happened
in the running instance, not that the selected window changed. Before relying on a state change
(tract deletion, trim, region mutation, ...), select the exact target and verify it with the
matching state command, such as `list_tract`, `list_region`, `list_slice`, or `list_param`.

Pass anything as `command[1]` (or `command[2]`) — the value is ignored — to pull everything still
retained in the console buffer (e.g. `["log","all"]`), for example to catch up on another agent's or
the user's earlier actions. It still advances the cursor and is still capped, so it cannot recover
output the buffer no longer retains, and repeating it immediately returns nothing new.

### 3.5 Interpret replies conservatively

Every reply has a top-level `status` and one result per executed command, with `cmd` and `status`;
text-producing commands may include `output`; failures include `error`. Success means the handler
returned without an immediate error. A long synchronous operation may outlast the client's wait
while continuing inside DSI Studio, so a timeout does not prove failure: inspect `list_window`,
`log`, or the relevant status command before retrying.

### 3.6 Check agent readiness, create chats, and read other chats

These system commands work in GUI and headless sessions; full syntax is in
`DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md`:

```bash
bash ./dsi.sh get_agent_settings ready      # local agents that can be invoked now (or name one agent)
bash ./dsi.sh new_chat claude sonnet "Atlas QA"   # a new chat with that agent, model, and title; returns its id
bash ./dsi.sh new_chat codex default "Fix parser" C:/src/repo   # ...whose agent may write in that folder
bash ./dsi.sh send_chat <session-id> "<task>"     # delegate: delivered/queued, or busy:/unsupported:/error:
bash ./dsi.sh get_chat -5                   # the 5 most recent chats: id, title, agent, model, status
bash ./dsi.sh get_chat <session-id> -3      # that chat's last 3 messages
bash ./dsi.sh get_chat <session-id> 8-      # message 8 onward: only what is new since message 7
```

`new_chat` only creates the chat; its agent starts with the first `send_chat`. To follow a chat,
keep the reply's `messages` count and next request `<messages+1>-`; an empty `history` means no new
message (errors and activities after the last message keep its number). On `busy:`, wait and retry.
`status` stays `Thinking` until the agent's turn ends; when it changes (for example to `Failed`), or
no reply arrives (a failed first launch returns to `New`), read `get_chat <id> -1` for the latest
entries, including errors. Reading never selects, wakes, or changes the chat. Codex and Antigravity
replace the id with their own, so find the chat again with `get_chat` (agent and title). `ready`
means installed and signed in on this host; usage limits are not checked.

## 4. Opening data and local input

### 4.1 Open user-supplied or recent files

```bash
bash ./dsi.sh open_src "C:/data/subject.sz"       # SRC/SZ reconstruction window
bash ./dsi.sh open_fib "C:/data/subject.fz"       # FIB/FZ tracking window
bash ./dsi.sh open_image "C:/data/T1w.nii.gz"     # medical-image window
```

Without a user-supplied path, use an exact relevant path from `list_recent_src` or
`list_recent_fib` (e.g. `open_src "<exact relevant path returned by list_recent_src>"`); never
invent paths. `open_image` is only for supported medical-image volumes, never for JPG, PNG, BMP,
GIF, WEBP, TIF, or TIFF pictures; verify screenshots through the filesystem or an external viewer.
Close a data window when the task no longer needs it, then select `main` or another valid window.

### 4.2 Offer public example datasets for hands-on teaching

Example-driven tutorials are **not limited to DICOM**. When a user wants to learn import,
reconstruction, tractography, group connectometry, tumor segmentation, or another practical
workflow, offer a relevant public example from `DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md`:

- **SCA2 (OpenNeuro ds001378):** matched T1w NIfTI, diffusion SZ, GQI/QSDR FZ, and a group DZ
  database with participant metadata; for source inspection, reconstruction, and group
  connectometry.
- **UPenn GBM (Fiber Data Hub / TCIA):** matched structural NIfTI, expert tumor segmentation,
  diffusion SZ, and ready-to-track FZ; for tumor overlay, coordinate QC, and tractography near a
  lesion.
- **DICOM test fixtures:** Siemens, Philips, sagittal/mosaic, and XA30 inputs; when conversion or
  scanner-specific parsing is the lesson.

**Offer before starting.** Pick a small matched example, explain the plan, and obtain approval and a
work directory before downloads or processing. Never automatically fetch an entire cohort. Check
files, subject IDs, image geometry, and actual output before claiming success. Rename DICOM only on
an expendable copy. For voice-guided lessons, follow 9.2. The examples are public-source references,
not binary datasets in the AI repo.

### 4.3 Local dialogs are valid user input

Parameterless main-window or reconstruction commands may open a local picker or dialog; omitting
the parameter can be intentional:

```bash
bash ./dsi.sh mask_open -Chat "Please choose the reconstruction mask in DSI Studio."
bash ./dsi.sh save_nifti -Chat "Please choose where to save the diffusion NIfTI."
bash ./dsi.sh resample -Chat "Please choose the isotropic output resolution."
```

While the dialog is open, `list_window` may report `waiting`; that is not a failure, and the agent
must not answer the dialog remotely. Continue after the user selects or cancels. Cancellation can
return without an error, so verify that the expected file, window, or setting exists. When the exact
value is known, pass it directly.

### 4.4 Verify connectometry demographics before analysis

After `open_connectometry`, never assume the database has demographics because it opens or lists
subjects. Before selecting a variable, cohort, or running correlational tractography, check:

```bash
bash ./dsi.sh get_demo
bash ./dsi.sh list_voi
```

`get_demo` must show the model's demographic columns besides the subject identifier, and `list_voi`
the study variable and covariates. If either is missing or empty, load the demographics table (an
exact path from the user or verified dataset information, never invented), then check again:

```bash
bash ./dsi.sh open_mr_files "C:/data/participants.tsv"
bash ./dsi.sh get_demo
bash ./dsi.sh list_voi
```

If the file is unavailable, stop before `set_voi`, cohort selection, or `run`, and report it. Repeat
the check after creating or opening a derived database, including a longitudinal difference
database: demographics of the source database or a neighboring `participants.tsv`/CSV file are not
carried over.

## 5. Quick fiber tracking: map the arcuate fasciculi

After opening a FIB/FZ file, AutoTrack maps standard white-matter bundles. Inspect the tract names
first, unless a task-specific skill gives verified identifiers and states that discovery is
unnecessary:

```bash
bash ./dsi.sh list_auto_tract
```

Names are hierarchical: for a whole tract family select the parent entry (e.g.
`Association_CingulumL` for the entire left cingulum, or the corpus callosum's parent entry), and a
child only when a specific subdivision or branch is requested.

```bash
bash ./dsi.sh set_params "max_tract_count=10000&max_seed_count=50000000&tip_iteration=4"
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh list_tract status
bash ./dsi.sh list_tract
```

`run_auto_track` is asynchronous: repeat `list_tract status` until `done`, then inspect with
`list_tract`. Map `Association_ArcuateFasciculusR` the same way.

**TIP pruning** cleans a visually coherent bundle (a named AutoTrack bundle or a loaded or recognized
bundle). When such a bundle can reach roughly 5,000–10,000 or more tracts before pruning, keep
`tip_iteration` at 3–4 (4 is a good default). Do not set `tip_iteration=0` merely to preserve tract
count or because the user did not request cleanup; use 0 only to examine an unpruned bundle or when
the bundle is too sparse. Do not apply TIP to whole-brain tractography, which is not one coherent
bundle. TIP removes trajectories by topology, so the final count is data-dependent and lower.

**AutoTrack constraints:** each named bundle already has built-in anatomical region constraints. Do
not add ROI, ROA, END, NotEND, Limiting, Terminating, or other user regions by default; add one only
for a specific anatomical purpose, such as isolating a minor branch or restricting a known
component.

For a simple anatomical 3D view, hide slices and add the built-in white-matter surface:

```bash
bash ./dsi.sh set_params "show_slice=0&show_tract=1&show_surface=1"
bash ./dsi.sh add_surface 0 25
```

For manual ROI tracking, segmentation, atlas regions, parameter tuning, tract editing, QC, or
advanced analysis, read `DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md` and the relevant command reference.

## 6. Batch processing multiple subjects

Build the pipeline once on one subject with ordinary commands, then replay it with
`run_command_history`:

```bash
bash ./dsi.sh open_fib "C:/data/sub-01.qsdr.fz"
bash ./dsi.sh run_tracking "WholeBrain"
bash ./dsi.sh list_tract status
bash ./dsi.sh save_lr_screen "C:/data/sub-01_wholebrain.png" "1600 900"
bash ./dsi.sh list_history     # check what was recorded; polling or side commands leave noise
bash ./dsi.sh run_command_history "C:/data/sub-02.qsdr.fz&C:/data/sub-03.qsdr.fz"
bash ./dsi.sh run_command_history "C:/data/sub-02.qsdr.fz&C:/data/sub-03.qsdr.fz" "0:1&12:15&16"
```

The first parameter is a folder (searched with the recorded load step's file extension) or an
`&`-joined file list. Each file replaces the recorded load step, and related load/save filenames are
remapped (`sub-01_wholebrain.png` becomes `sub-02_wholebrain.png`). All recorded commands replay by
default; the optional second parameter limits them to `list_history` indices as one `from:to` range
or `&`-joined ranges/indices. Called by an agent, it never opens a dialog for a missing or failed
file; it logs and skips that file.

## 7. Fiber Data Hub

Two routes are valid; use whichever fits, and the other if one is unavailable:

- **Direct:** for discovery, release metadata, QC lookup, file listing, and downloading public
  assets, work from https://brain.labsolver.org and its GitHub releases without DSI Studio. Guide:
  https://github.com/frankyeh/Brain-Data/blob/gh-pages/AGENTS.md (in `frankyeh/Brain-Data`).
- **DSI Studio `hub_*` commands:** when DSI Studio should open, visualize, track, or analyze the data.
  They target `main`, so `set_window main` first when necessary.

Before bulk downloads, inspect the dataset's files and prefer an existing analysis-ready derivative
(for example a connectometry `.dz`) that already satisfies the task.

```bash
bash ./dsi.sh hub_repo
bash ./dsi.sh hub_tags "<exact repository returned by hub_repo>"
bash ./dsi.sh hub_files "<exact repository>" "<exact tag>" ".fz" 0 20
bash ./dsi.sh hub_show "<exact repository>" "<exact tag>"
bash ./dsi.sh hub_show "<exact repository>" "<exact tag>" "subjects.tsv"
bash ./dsi.sh hub_open "<exact repository>" "<exact tag>" <file-row-index>
bash ./dsi.sh hub_download "<exact repository>" "<tag-regex>" "*.qsdr.fz" "C:/data"
```

- `hub_files` takes case-insensitive regular-expression tag and filename filters (empty matches
  all), searches all matching tags, and returns `index`, `tag`, `file`, `size`, and `downloaded`;
  offset and limit apply to the combined matches.
- `hub_show` returns a tag's GitHub release note, or with a file the raw tab-separated text of a
  `.tsv` release file (it fails for other extensions); read it to learn what a dataset is.
- `hub_open` opens one file (row index or exact filename from `hub_files`) in a new window; use the
  `tracking window created, id: tracking...` ID if returned. A network-backed open may finish later;
  then find the window with `list_window`. A request with more than one `hub_open` is rejected.
- `hub_download` takes a wildcard pattern (`*`, `?`, `[...]`, anchored to the full name, not a regex)
  and downloads every match in every matching tag, so one call can fetch many files. Verify the
  destination folder afterwards.

### 7.4 XNAT

DSI Studio lists and downloads XNAT experiments with the server and login saved in the XNAT dialog.
Never ask for or pass the XNAT password. On a missing or failed login, ask the user to connect once
in the XNAT dialog (`open_xnat`), then retry.

```bash
bash ./dsi.sh xnat_list
bash ./dsi.sh xnat_list "100:200" "^ADNI"
bash ./dsi.sh xnat_download "XNAT_E00012,XNAT_E00013"
```

`xnat_list` returns a tab-separated table, newest first, with a header and the server's fields
(`ID`, `label`, `project`, `date`, ...). Its optional range is `N` (the first N, default 100) or
`from:to` (0-based, `to` excluded), counted after the optional case-insensitive project regex; page
through large servers. `xnat_download` takes the `ID` values separated by commas or spaces, fails
before downloading if any ID is unknown, downloads into the folder rule saved in the XNAT dialog,
skips existing files (a rerun fetches only what is missing), prints each experiment's folder, and
returns when finished. Verify the printed folders.

## 8. Internal CLI and confirmation-gated shell

Read `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md`, including its completion-verification rules,
before using either command.

### 8.1 `run_cli`: DSI Studio CLI actions only

```bash
bash ./dsi.sh run_cli "--action=vis --source=C:/data/subject.fz --cmd=list_tract"
```

Keep the whole command line in one string. It runs the internal CLI action in the current process
(no other executable); missing `--action` defaults to `vis`. It ignores the `set_window` selection,
resolves relative paths against this chat's working directory, and may modify global application
state. Never send an operating-system command through it. `run_cli` is GUI-only: a headless Web
session (`dsi_studio --action=ai`) rejects it, so there run DSI Studio command lines through
`run_shell` and dispatch long work through the scheduler (`DSI_STUDIO_AI_SKILL_WEB.md`).

### 8.2 `run_shell`: every command needs local user approval

```bash
bash ./dsi.sh run_shell "cd \"C:/data\" && dir \"*.fz\" /s /b"
```

Every `run_shell` command shows the local user a confirmation dialog with its exact text and runs
only if approved; the dialog is the only gate (no whitelist or character restriction). It cannot
complete unattended, and a command array containing it pauses at the dialog. Each command runs in
its own shell from the chat's working directory, so a standalone `run_shell "cd ..."` has no lasting
effect: put `cd` in the same command (`cd /data/sub01 && python make_report.py`), use absolute
paths, or change the directory with `set_work_dir <dir>`. Approved commands run synchronously,
except `curl`:

```bash
bash ./dsi.sh log
bash ./dsi.sh run_shell "curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""
```

`curl` runs asynchronously and returns a synthetic `curlN` task ID, which does not prove completion.
Initialize the log cursor first (a Web agent sends `{"cmd":"log"}` before the curl-start request),
poll `list_window` until the `curlN` entry disappears, then read `log` for output or errors. Do not
put a command that needs the downloaded file after `curl` in the same array.

Never send credentials, tokens, or other sensitive text: the user sees the exact text. In a GUI
session never send a DSI Studio `--action=...` line through `run_shell`; in a headless session it is
the only way to run one (8.1).

### 8.3 `write_text_file` and `patch_text_file`

`write_text_file <filename> <content>` writes text exactly as sent, without shell parsing, after the
local user confirms. Use it for generated scripts instead of `echo` or heredocs, then run them:

```json
"command":[{"cmd":"write_text_file","param":["make_report.py","<script>"]},
           {"cmd":"run_shell","param":"python make_report.py"}]
```

`patch_text_file <filename> <unified diff>` changes part of a file, also after confirmation. Its
hunks (`@@ -N,M +N,M @@` with ` `, `-`, `+` lines) must match the current text exactly, or nothing
changes and the reply names the first mismatched hunk; read the file again and resend. CRLF files
stay CRLF. Local agents that can write files and run Python with their own tools may do so directly.

## 9. Desktop speech and demo mode

### 9.1 Desktop speech

`voice` speaks one concise non-empty message on Windows, macOS, or Linux, to announce a result or
explain the next visible action:

```bash
bash ./dsi.sh voice "Reconstruction is complete."
```

Success means the speech was queued or started, not finished. Keep durable user-facing information
in `-Chat`, and do not speak sensitive content unless the user explicitly asks.

### 9.2 Voice tutorials and demo mode

**Offer, then ask.** A voice tutorial speaks aloud on the user's computer. When a lesson, walkthrough,
or demonstration would help, offer one proactively, but start it only after the user agrees, for
example with `ask_user "Would you like a voice tutorial?" "Yes, with voice" "No, text only"`. Skip the
question only when the user explicitly asked for a voice tutorial; if the user declines, teach
through the chat and highlights without `voice`.

Speak like an experienced DSI Studio user mentoring someone at the same screen, not like an AI or a
narrator reading a command log. Four rules:

1. **No long silences.** Keep a natural pace: a short line as each step starts, and something said
   whenever the user would otherwise wait in silence.
2. **Only the present task.** Say what the user sees or does now and why it matters for this step.
   Never voice commands, tool calls, state checks, polling, retries, or your own reasoning about what
   to run next; do those silently.
3. **Fill long waits with a related tip.** When processing takes a while (reconstruction, tracking,
   registration, segmentation), add one or two short, closely related tips or facts, such as what a
   setting does or what to look for in the result, then report the outcome once it is confirmed.
4. **Sound human.** Short sentences, plain words, natural reactions ("There's the axial slice.",
   "Good, that's the one."). Vary the phrasing. Avoid AI-style lines: announcing actions ("I will now
   execute ..."), praise fillers ("Great question!"), stating that you are an AI, reading out lists,
   or a mechanical "let's" in every sentence.

**UX tutorials** (learning the interface: the tracking-window tour, where a control is, how to click
or drag): voice only the action and what it does in the window, one short line per step. Do not
voice an analysis plan, intentions, or the checks after each step.

**Analysis tutorials** (a workflow on data, such as tracking a bundle or a tumor evaluation): also
open with a brief plan (goal, main stages, what the result should show), explain the reason at each
decision, and teach at checkpoints: what a result means, its limitations, and the decision that
follows. Voice a check only when its result teaches something (a tract count that looks too low,
an alignment problem). Say a tract is available, an operation started, or work finished only after a
response confirms it; if a step fails, say what happened and the adjustment.

Never expose orchestration details, request IDs, command arrays, polling mechanics, or transport
behavior. Continue durable results through `-Chat`.

UX tutorial:

```bash
bash ./dsi.sh highlight_ui glAxiCheck click
bash ./dsi.sh voice "The 3D window is empty because the slices are hidden. Tick this box to show the axial slice."
bash ./dsi.sh ask_user_act "Tick the axial checkbox"
bash ./dsi.sh highlight_ui GLWidget rotate
bash ./dsi.sh voice "There's the brain. Hold the left button and drag to turn it around."
bash ./dsi.sh ask_user_act "Drag in the 3D window to rotate"
```

Analysis tutorial (the status check runs silently; the voice fills the wait with a related tip):

```bash
bash ./dsi.sh voice "We'll map the left arcuate fasciculus, a language pathway, and see whether its course looks plausible."
bash ./dsi.sh run_auto_track "Association_ArcuateFasciculusL"
bash ./dsi.sh voice "While it tracks: AutoTrack uses an atlas of this bundle to decide which streamlines to keep, so you don't need to draw regions."
bash ./dsi.sh list_tract
bash ./dsi.sh voice "Done, about ten thousand streamlines. Look at how it arches around the back of the Sylvian fissure; that's the shape we expect."
```

## 10. SRC/SZ reconstruction workflow

If reconstruction does not apply to the task, study this section without running materially
altering commands.

### 10.1 Current reconstruction GUI

The current dialog differs from older tutorial videos: sidebar pages **2a Mask**,
**2b Preprocessing**, and **2c Methods**, with **Edit...** revealing Edit DWI and Edit B-table. Mask
Open/Save are in the File menu, and **Align Selected DWI...** is an Edit DWI button. The
Preprocessing page has **seven Yes/No questions** selecting a highlighted TOPUP/EDDY, motion, T1w,
bias-field, and/or resampling path, and a GUI **Run Preprocessing** button. That button is **not** an
AI command; use individual reconstruction commands after assessing the acquisition and existing
processing history. Read `DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md` (Current reconstruction dialog)
before guiding GUI users; the website
[Reconstruct: SRC to FIB](https://dsi-studio.labsolver.org/doc/gui_t2.html) may lag the newest
decision flow.

### 10.2 Parameters and operations

```bash
bash ./dsi.sh list_param
bash ./dsi.sh list_param method
bash ./dsi.sh set_param "method=4"
bash ./dsi.sh set_params "method=4&param=1.25&thread_count=8"
bash ./dsi.sh mask_from_unet
bash ./dsi.sh bias_field_correction
bash ./dsi.sh resample 2
bash ./dsi.sh recon 4
```

`set_param` and `set_params` both accept one `name=value[&name=value...]` composite parameter. Use
`recon`, not `reconstruction`, `src_recon`, or `src_reconstruction`; its optional method is `1`
(DTI), `4` (GQI), or `7` (QSDR), and omitting it uses the current `method` parameter. Each generated
path is printed as `reconstruction output: <path>` and added to the recent-FIB list; inspect every
path from a multi-file window. AI-originated `topup` or `topup_eddy` without a parameter searches for
the reverse-phase-encoding source automatically; pass an explicit `.rz`, `.sz`, `src.gz`, or NIfTI
path when it is known.

Corrections, b-table changes, source geometry changes, mask operations, resampling, and
reconstruction materially alter results; do not run them merely to learn the interface. Read
`DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md` before changing source data or reconstructing.

## 11. Operational safeguards

1. One `bash ./dsi.sh` invocation per request. Send index-sensitive or state-changing commands
   sequentially, inspecting each result before building the next.
2. Use `-Chat` for user-visible progress and results.
3. Copy exact paths, window IDs, indices, model IDs, and parameter IDs from the user, current output,
   or another verified source.
4. Confirm destructive operations, overwrites, saved-history clearing, wildcard CLI actions, and
   tracking-window closes that may discard unsaved tracts.
5. If a window disappears or an operation appears to crash, inspect `list_window` and `log` before
   anything else. Do not reopen or repeat work automatically; after an application restart, old
   window IDs and unsaved in-memory state are invalid.
6. Do not overlap state-changing tracking-window operations while tracking or slice registration is
   active; wait for the `list_tract status` or `list_slice` completion state.
7. Recheck demographics (4.4) for every database, apply TIP and AutoTrack constraints as in Section 5,
   treat local dialogs as user input (4.3), and verify state after timeouts (3.5).
8. Read only the topic-specific files needed for the current task.

## 12. Related documents

- [Launcher selection, agent configuration, local Ollama models, and troubleshooting](DSI_STUDIO_AI_SKILL_LAUNCHER.md)
- [Web session (any web-based AI agent)](DSI_STUDIO_AI_SKILL_WEB.md)
- [Command index](DSI_STUDIO_AI_COMMAND_EXAMPLES.md)
- [Shared window controls and GUI tutor commands](DSI_STUDIO_AI_COMMAND_EXAMPLES_WINDOW.md)
- [Internal CLI actions and confirmation-gated shell commands](DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md)
- [Main window and Fiber Data Hub](DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md)
- [Reconstruction commands and examples](DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md)
- [Standalone image-window processing](DSI_STUDIO_AI_COMMAND_EXAMPLES_IMAGE.md)
- [Slices and segmentation](DSI_STUDIO_AI_COMMAND_EXAMPLES_SLICE.md)
- [Regions and tract-to-region analysis](DSI_STUDIO_AI_COMMAND_EXAMPLES_REGION.md)
- [Tracts, tracking, AutoTrack, clustering, recognition, and TDI](DSI_STUDIO_AI_COMMAND_EXAMPLES_TRACT.md)
- [Devices and AC-PC locators](DSI_STUDIO_AI_COMMAND_EXAMPLES_DEVICE.md)
- [Parameters, rendering, camera, surfaces, workspace, settings, and display](DSI_STUDIO_AI_COMMAND_EXAMPLES_RENDERING.md)
- Workflow skills: [reconstruction](DSI_STUDIO_AI_SKILL_RECONSTRUCTION.md),
  [fiber tracking](DSI_STUDIO_AI_SKILL_FIBER_TRACKING.md),
  [differential tractography](DSI_STUDIO_AI_SKILL_DIFFERENTIAL_TRACTOGRAPHY.md),
  [correlational tractography](DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md),
  [T2R connectome](DSI_STUDIO_AI_SKILL_T2R_CONNECTOME.md),
  [public example data](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md),
  [brain-tumor presurgical and postsurgical evaluation](DSI_STUDIO_AI_SKILL_BRAIN_TUMOR.md) (read only for brain-tumor tasks),
  [interactive lessons for new users](DSI_STUDIO_AI_SKILL_LESSONS.md) (read when the user asks to be taught)

Read only the files relevant to the current task, then continue using `bash ./dsi.sh`.
