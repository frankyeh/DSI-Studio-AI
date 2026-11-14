# DSI Studio AI General Command Examples and Inventory

These commands target the fixed `main` window, the default selection of a new session; after
switching elsewhere, return with `bash ./dsi.sh set_window main`. Command names and text or path
parameters are strings; send standalone numbers as JSON numbers. Never send a filesystem path by
itself as a request; supply paths only as parameters of the commands below.

Commands accepting multiple files take one command-array element per file, never one `&`-separated
string (the router treats every element after the command name as a path):

```json
["open_src","C:/data/a.sz","C:/data/b.sz"]
["show_qc_fib","C:/data/a.fz","C:/data/b.fz"]
["rename_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]
```

Unless noted, a command without its file or folder parameter opens a local picker, and "no args"
means it takes no arguments.

## DICOM import lessons

The DSI Studio repository's `.github/workflows/test.yml` contains real DICOM conversion tests. Offer
its public Siemens, Philips, sagittal, and XA30 fixtures and a reproducible walkthrough from
[`DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md`](DSI_STUDIO_AI_SKILL_EXAMPLE_DATA.md). Interactive AI sessions
use `rename_dicom_dir` / `convert_dicom_dir`; the workflow uses CLI `--action=ren` / `--action=src`. A
DICOM `test` command is **not** part of the AI launcher. Rename only a disposable example copy, and
inspect the output before declaring success.

## Main-window commands

### Files, import, and settings

| Command | Example | Behavior |
|---|---|---|
| `list_recent_fib`, `list_recent_src` | `["list_recent_fib"]`, `["list_recent_src"]` | List valid saved recent FIB/FZ or SRC/SZ paths with forward slashes, or `no recent files` when none exists. No args. |
| `clear_recent_src`, `clear_recent_fib` | `["clear_recent_src"]`, `["clear_recent_fib"]` | Immediately clear the recent SRC/SZ or FIB/FZ table and saved `recentSrcFileList` / `recentFibFileList`, without confirmation. No args. |
| `reset_settings` | `["reset_settings"]` | Clear and synchronize all application settings. No args. |
| `set_work_dir` | `["set_work_dir","C:/work"]` | Change the chat's working directory (remembered per chat): the current directory for relative paths in `run_shell`, `run_cli`, `write_text_file`, `patch_text_file`, and `web_upload`, added to the main window's work-directory list, where its file dialogs open. The directory must exist. It is also where a local agent may write with its own tools: Codex gets the new folder with the next message; other agents keep their starting folder until the chat restarts. |
| `rename_dicom` | `["rename_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]` | Rename DICOM files in their parent directories. |
| `rename_dicom_dir` | `["rename_dicom_dir","C:/dicom"]` | Rename DICOM files recursively in the directory. |
| `convert_dicom_dir` | `["convert_dicom_dir","C:/dicom"]` | Recursively convert DICOM series to SRC/SZ or NIfTI, never overwriting existing output. |
| `bids_to_src` | `["bids_to_src","C:/bids","C:/bids/derivatives"]` | Find diffusion NIfTI in the BIDS folder and create SRC/SZ files in the output folder (created if missing). Without input it opens a BIDS-folder picker; without output it asks the user for an existing folder. |
| `nifti_dir_to_src` | `["nifti_dir_to_src","C:/nifti"]` | Find diffusion NIfTI in the directory and create SRC/SZ files there; existing outputs may prompt for overwrite decisions. |
| `open_dwi_nifti`, `open_dwi_dicom`, `open_dwi_2dseq` | `["open_dwi_nifti","C:/data/dwi.nii.gz"]`, `["open_dwi_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]`, `["open_dwi_2dseq","C:/scan/2dseq"]` | Enter the DWI-import workflow for diffusion NIfTI, DICOM, or 2dseq/FDF/NRRD inputs through `open_DWI`; no reconstruction-window ID is guaranteed. |
| `open_src` | `["open_src","C:/data/a.sz","C:/data/b.sz"]` | Open SRC/SZ or histology inputs in one reconstruction window, select it, and report `recon window created, id: recon...`; continue with `DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md`. |
| `open_src_dir` | `["open_src_dir","C:/src"]` | Load the directory's `*src.gz` and `.sz` files into one reconstruction window and report its `recon...` ID. |
| `open_fib` | `["open_fib","C:/data/subject.fz"]` | Open a `.fz`, `*fib.gz`, or `.dz` file in a new, selected tracking window. |
| `open_structural_tracking` | `["open_structural_tracking","C:/data/T1w.nii.gz"]` | Pass a NIfTI or 2dseq structural image to `loadFib`. |
| `open_template` | `["open_template","<template-name>"]` | Open the exact built-in population/species template FIB as a tracking window; an invalid name errors; without a parameter, the template selected in the main-window list. |
| `open_image` | `["open_image","C:/data/T1w.nii.gz","C:/data/T2w.nii.gz"]` | Open supported medical-image volumes in a new, selected `view_image` window; failures return in `error`. Never for FIB tracking or JPG/PNG screenshots. |
| `collect_network_measures` | `["collect_network_measures","C:/net/a.txt","C:/net/b.txt"]` | Collect network-measure text files into `<first-file>.collected.txt`. |

### Quality control

| Command | Example | Behavior |
|---|---|---|
| `show_qc_nii`, `show_qc_src`, `show_qc_fib` | `["show_qc_nii","C:/data/a.nii.gz","C:/data/b.nii.gz"]`, `["show_qc_src","C:/data/a.sz","C:/data/b.sz"]` | Run quality checks on NIfTI, SRC/SZ, or FIB/FZ files. AI callers get the report in `output`; a local user sees a dialog. |
| `save_qc_nii`, `save_qc_src`, `save_qc_fib` | `["save_qc_nii","C:/report.txt","C:/data/a.nii.gz"]`, `["save_qc_src","C:/report.txt","C:/data/a.sz"]`, `["save_qc_fib","C:/report.txt","C:/data/a.fz"]` | The same checks, writing the report to the first parameter's path; without files after it, a file picker opens. |

### Databases, tools, and windows

| Command | Example | Behavior |
|---|---|---|
| `create_db`, `create_average` | `["create_db"]`, `["create_average"]` | Open the connectometry database-creation or average-database dialog. No args. |
| `open_db` | `["open_db","C:/data/group.db.fz"]` | Load a connectometry database in a new database window; loading failures return in `error`. |
| `open_connectometry` | `["open_connectometry","C:/data/group.db.fz"]` | Load a connectometry database in a new group-connectometry window; loading failures return in `error`. |
| `open_auto_track`, `open_nonlinear_registration`, `open_xnat`, `open_console` | `["open_auto_track"]`, `["open_nonlinear_registration"]`, `["open_xnat"]`, `["open_console"]` | Create and show the AutoTrack window, nonlinear-registration toolbox, XNAT dialog, or singleton console. No args. |
| `open_ai` | `["open_ai"]` | Show, raise, and activate the AI Agent window. No args. |
| `open_hub` | `["open_hub"]` | Show, raise, and activate the Fiber Data Hub without a query. No args. |

### Fiber Data Hub and XNAT

| Command | Example | Behavior |
|---|---|---|
| `hub_repo` | `["hub_repo"]` | Show the Hub and list repositories. |
| `hub_tags` | `["hub_tags","<repo>"]` | List release tags of the exact repository returned by `hub_repo`. |
| `hub_files` | `["hub_files","<repo>","",".*\\.fz$",0,20]` | Search files across every tag matching the case-insensitive tag regex; the filename filter is also a case-insensitive regex; empty patterns match all. Offset and limit apply to the combined matches. |
| `hub_open` | `["hub_open","<repo>","<exact-tag>",12]` | Download to the temporary cache when needed and open one file (returned row index or exact filename) of one exact tag. |
| `hub_show` | `["hub_show","<repo>","<exact-tag>"]`, `["hub_show","<repo>","<exact-tag>","subjects.tsv"]` | Return the tag's GitHub release note, or with a file (row index or exact filename, must end in `.tsv`) its raw tab-separated content instead of opening it in the Hub window. |
| `hub_download` | `["hub_download","<repo>","^HCP.*$","*.qsdr.fz","C:/data"]` | Download every file matching the wildcard (`*`, `?`, `[...]`) in every tag matching the case-insensitive tag regex: one call can fetch many files across tags and subjects. |
| `xnat_list` | `["xnat_list"]`, `["xnat_list","100:200","^ADNI"]` | XNAT experiments as a tab-separated table, header first (fields include `ID`, `label`, `project`, `date`), newest first. Range `N` (first N, default 100) or `from:to` (0-based, `to` excluded), counted within projects matching the optional case-insensitive regex (empty: all). Uses the server and login saved in the XNAT dialog; if none or the login fails, ask the user to connect once there (`open_xnat`). |
| `xnat_download` | `["xnat_download","XNAT_E00012,XNAT_E00013"]` | Download the listed experiments' scans (one parameter, IDs separated by commas or spaces) into the folder and sub-folder rule saved in the XNAT dialog, printing each output folder and returning when finished; fails before downloading if any ID is unknown. Same login requirement. |

### Scripts, shell, and CLI

Read `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md` before use (wildcards, global thread settings,
overwrites, actions depending on open windows, platform behavior, completion verification).

| Command | Example | Behavior |
|---|---|---|
| `run_cli` | `["run_cli","--action=vis --source=C:/data/subject.fz --cmd=list_tract"]`, `["run_cli","--action=rec --source=C:/data/*.sz"]` | One DSI Studio command-line string run inside the current process (GUI only). The optional exact lowercase `dsi_studio ` prefix is removed; missing `--action` defaults to `vis`; relative paths use the chat's working directory (`set_work_dir`); it ignores `set_window`. Wildcard looping applies (`--continue_on_error` keeps a loop going after a failed item); a failure returns `command line failed`, with details in the captured output. |
| `run_shell` | `["run_shell","cd \"C:\\data\" && dir *.fz"]`, `["run_shell","curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""]` | One shell command string, shown to the local user for approval first. Others run synchronously (10-minute limit, `cmd.exe /c` or `/bin/sh -c`, non-zero exit fails with `command exited with code <N>`); `curl` runs asynchronously as a `curlN` task (`started curlN: curl -s -S ...`; `-s -S` added automatically). Each runs from the chat's working directory, so a standalone `cd` has no lasting effect. Use `curl -o` or `curl -O` instead of output redirection. Never include credentials, tokens, protected data, or untrusted text. In a GUI session run DSI Studio CLI actions with `run_cli`; a headless Web session runs them here (`DSI_STUDIO_AI_SKILL_WEB.md`). |
| `write_text_file` | `["write_text_file","make_report.py","<script text>"]` | Write text exactly as sent (UTF-8, no BOM, overwrite), without shell parsing, after the local user confirms; returns the path and byte count. Then run it, e.g. `run_shell "python make_report.py"`. |
| `patch_text_file` | `["patch_text_file","src/main.cpp","@@ -12,2 +12,2 @@\n context\n-old line\n+new line"]` | Edit one text file with a unified diff (`---`/`+++` headers optional). Each hunk applies nearest its stated line where its context and `-` lines match exactly; if any hunk does not match, nothing is written and the error names it. CRLF files stay CRLF. The user confirms with the diff shown. Also in headless mode. |

### Agents and chats (also in headless mode)

| Command | Example | Behavior |
|---|---|---|
| `get_agent_settings` | `["get_agent_settings"]`, `["get_agent_settings","Claude"]`, `["get_agent_settings","ready"]` | JSON array of local agent readiness on this host (Codex, Claude, Muse, Antigravity, Grok; one agent when named, case-insensitive; `ready`: only agents invocable now): `agent`, `host`, `scope` (`gui` or `headless`), `executable`, `status` (`ready`, `sign_in_required`, `not_installed`, `checking`, `error`, `unknown`), `account` (when ready) or `reason`, `models` (list, or `"unknown"` when not discovered), and `checked` time. Never signs in or sends a prompt. `ready` means installed and signed in by a noninteractive check; usage limits are not checked. The GUI reports cached checks; headless checks the requested agents in parallel and reuses results for 5 minutes. |
| `new_chat` | `["new_chat","Claude"]`, `["new_chat","Codex","gpt-5","Atlas QA"]`, `["new_chat","Codex","default","Fix parser","C:/src/repo"]` | Create a DSI-managed chat with a local agent (case-insensitive) and return JSON `id`, `agent`, `model`, `title`, `status` (`New`). Optional: a native model (`default` or omitted: the agent's default), with an optional `:<thinking level>` for Codex (`low`, `medium`, `high`, `xhigh`), Claude (`low`, `medium`, `high`, `xhigh`, `max`), or an Antigravity, Grok, or Muse model with levels (e.g. `gpt-5.5:high`, `gemini-4-argon:high`, `grok-4.7:xhigh`, `default:high`; without a level, `medium` where supported); a title; and an existing work directory (relative to the caller's; default: the GUI work directory or the headless start directory) that becomes the chat's `set_work_dir` folder and the folder its agent may write. The chat inherits the caller's approval setting (auto or manual). The agent must be `ready` (`get_agent_settings`) and, where this host lists its models, the model must be listed; otherwise a clear error. Headless mode does not discover models, so any name is accepted and a wrong one fails when the agent starts. Ollama models are not available here. The chat is saved at once and its agent starts with the first message; Codex and Antigravity then replace the id, so find it again with `get_chat`. Without parameters, `new_chat` keeps its launcher meaning (registering an external agent's session; `DSI_STUDIO_AI_SKILL_LAUNCHER.md`). |
| `send_chat` | `["send_chat","<session-id>","Summarize the arcuate results."]` | Send a message to another DSI-managed local agent chat (Codex, Claude, Muse, Antigravity, Grok), keeping its agent, model, and context. Returns JSON `id`, `status`, and `message` (the sent message's number): `delivered` (written to the running agent's input now) or `queued` (the agent is starting or resuming and receives it once connected). Errors begin with `busy:` (mid-turn, starting, or exiting: check `get_chat` and retry later), `unsupported:` (Web and external AgentServer chats have no delivery channel), or `error:` (the agent could not start; reason follows). The target first records "Message from <your chat> via send_chat." Follow the reply with `get_chat <id> "<message+1>-"`. |
| `get_chat` | `["get_chat"]`, `["get_chat",-5]`, `["get_chat","<session-id>"]`, `["get_chat","<session-id>",-3]`, `["get_chat","<session-id>","5-"]` | Without an ID: every chat this instance holds (saved chats load at startup), newest first (`-N`: the N most recent), as `id`, `title`, `agent`, `provider`, `model`, `status`, `window`, `last_activity`; every listed chat can be read and sent to. With an ID: its metadata, `messages` (number of user/assistant messages), and `history` for the range `all` (default), `-N` (last N), `N` (message N, 1 = first), `N-` (N onward), or `N-M`. Each message comes with the command/activity/error entries that follow it (an agent's message is recorded before the commands it sends); each entry carries its `message` number, and a failed command's entry its `error`. To follow progress, request `"<messages+1>-"`: an empty `history` means no new message, and an error or activity after the last message keeps that message's number. `status` stays `Thinking` until the turn ends; when it changes, or no reply arrives (a failed first launch returns to `New`), read `get_chat <id> -1` for the latest entries, including errors. Read only: never selects, wakes, or changes the chat. |

## Built-in template-space analysis

`open_template` opens a built-in population/species FIB as a normal tracking window, already selected
(no `set_window` needed); use the template matching the data population. Installed names depend on
the packaged atlas/tract set and commonly include `human`, `human-neonate`, `rhesus`, `marmoset`,
`rat`, and `mouse`. For common-space analysis, load scalar NIfTI maps with `add_mni_slice` (MNI space
for `human`, the corresponding template space otherwise). Alignment uses the NIfTI header transform,
so voxel size and matrix may differ from the template FIB. The map becomes a regular slice for
threshold/ROI creation, region statistics, tractography, atlas analysis, and rendering with the
template metrics.

```bash
bash ./dsi.sh open_template human
bash ./dsi.sh add_mni_slice "C:/data/mni_result.nii.gz"
bash ./dsi.sh list_slice
```

## Fiber Data Hub details

Hub commands are routed before regular main-window handling, so they take their full argument lists.

- Use the exact `owner/repository` string from `hub_repo`. Syntax:
  `hub_files <repo> [tag-regex] [filename-regex] [offset] [limit]`. It returns `index` (the file-row
  index within its tag), `tag`, `file`, `size`, and `downloaded`. Offset and limit apply after
  combining tags; omitting the limit returns every remaining match, and a limit of `0` returns no
  rows. Send offset, limit, and row indices as JSON numbers.
- `hub_open` requires one exact tag and a filename or row index, and opens one file in a new window.
  When it must download first, the open happens after the reply and may not happen at all, so confirm
  with `list_window` that a window title shows the file; otherwise `open_fib` the cached path, which
  the log reports as `download file to <path>`. Never fetch a cohort with it: a request with more than
  one `hub_open` fails with
  `multiple hub_open commands are not allowed in one request; use hub_download for bulk files`.
- `hub_show <repo> <tag>` returns the release note; read it first to learn what a dataset contains.
  `hub_show <repo> <tag> <file>` (filename or row index, like `hub_open`) returns the file's raw
  tab-separated text, unlike other `hub_` commands' status lines; it fails if the file is not a
  `.tsv` release asset.
- `hub_download` downloads or caches without opening. Its tag is a case-insensitive regex and its
  file a wildcard (e.g. `*.qsdr.fz` or `*.gqi.fz`) anchored to the full name, so an exact filename
  matches only that file; row indices work only for `hub_open`/`hub_show`. It requires the
  destination directory (created when needed), skips files already there (a rerun fetches only what
  is missing), reports a tag without a match as `skip`, and succeeds when at least one download
  starts. Example (session-01 QSDR files of one OpenNeuro dataset):
  `["hub_download","data-openneuro/disease","^ds001378$","*_ses-01_dwi.qsdr.fz","C:/data/ds001378"]`.
- Before bulk-downloading subject `.fz` files, prefer a derived file matching the analysis, such as a
  `.dz`/`.db.fz` connectometry database, over rebuilding it.
- Verify the created window or destination files after network-backed work.

**Finding a dataset.** OpenNeuro datasets are in the `data-openneuro/*` repositories, tagged by
dataset ID (e.g. `ds001378`). Filenames use BIDS subject IDs, not diagnoses, so searching for `sca2`
or `patient` finds nothing. Read the group labels with `hub_show <repo> <tag> participants.tsv` (here
`sub-SCA2xx` versus `sub-controlxx`), then select files by subject ID.

## XNAT details

`xnat_list [range] [project-regex]` and `xnat_download <IDs>` use the server, login, and download
folder saved in the XNAT dialog; never request or pass the password. On `no saved XNAT login` or
`XNAT login failed`, ask the user to connect once in the dialog (`open_xnat`). The range is counted
after the project filter; use the table's `ID` column for downloads. Unknown IDs fail before any
download, and reruns skip existing files.

## Routing and response notes

- `run_cli` and `run_shell` stay available while a non-main window is selected; `run_cli` actions use
  their own state, not the selection.
- Successful `open_src`, `open_fib`, and `open_image` select the new window and normally return its
  exact ID in `output`; keep it for later switching (`list_window` confirms IDs or finds other open
  windows, e.g. `recon<hex-address>`, `tracking<hex-address>`).
- Do not invent aliases: use `list_recent_fib` and `list_recent_src` exactly.
- `output` appears only when text was captured; otherwise a successful result has only `cmd` and
  `status`.
- Picker-based commands need local GUI interaction, and cancellation may return without an error.
  `bids_to_src` asks for an output folder only when the second element is omitted; supply it to run
  unattended. Verify opened windows and generated files rather than relying on the absence of
  `error`.
- An asynchronous `curl` start is not completion: initialize the log cursor first (`{"cmd":"log"}` on
  Web), verify completion with `list_window`, then read the new `log` output. Each `run_shell` runs
  from the chat's working directory, so put `cd` in the same command
  (`cd /data/sub01 && python make_report.py`) or use `set_work_dir <dir>`; a standalone
  `run_shell "cd ..."` has no lasting effect, and `run_shell curl` paths are relative to it too.
- Invalid template names, database-loading failures, and image-opening failures return in `error`.
- Confirm `reset_settings`, `clear_recent_src`, and `clear_recent_fib` first: they immediately modify
  saved state.
- Run `list_param` in a reconstruction window before changing reconstruction parameters, and the
  tracking window's `list_param` before changing tracking or rendering parameters.
