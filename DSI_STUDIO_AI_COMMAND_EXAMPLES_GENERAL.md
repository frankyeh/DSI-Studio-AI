# DSI Studio AI General Command Examples and Inventory

These commands target the fixed `main` window. `main` is the default selection for
a new session; if a `set_window` call has since switched to another window, return
to `main` first:

```bash
bash ./dsi.sh set_window main
```

Command names and text or path parameters are strings. Send standalone numeric
parameters as JSON numbers.

Do not send a filesystem path by itself as a named-pipe request. Supply paths
only as parameters of the documented commands below.

## Main-window commands

| Command | Common example | Exact behavior |
|---|---|---|
| `list_recent_fib` | `["list_recent_fib"]` | List valid saved recent FIB/FZ paths using forward slashes. If none of the saved paths currently exists, print `no recent files`. Takes no arguments. |
| `list_recent_src` | `["list_recent_src"]` | List valid saved recent SRC/SZ paths using forward slashes. If none of the saved paths currently exists, print `no recent files`. Takes no arguments. |
| `reset_settings` | `["reset_settings"]` | Clear all application settings and synchronize them. Takes no arguments. |
| `set_work_dir` | `["set_work_dir","C:/work"]` | Add the supplied directory to the work-directory list. Without a parameter, open a directory picker. |
| `rename_dicom` | `["rename_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]` | Rename one or more DICOM files in their current parent directories. Each file is a separate command element. Without file parameters, open a file picker. |
| `rename_dicom_dir` | `["rename_dicom_dir","C:/dicom"]` | Rename DICOM files recursively at the supplied directory. Without a parameter, open a directory picker. |
| `convert_dicom_dir` | `["convert_dicom_dir","C:/dicom"]` | Recursively convert DICOM series in the supplied directory to SRC/SZ or NIfTI output without overwriting existing output. Without a parameter, open a directory picker. |
| `bids_to_src` | `["bids_to_src","C:/bids","C:/bids/derivatives"]` | Search the supplied BIDS folder for diffusion NIfTI data and create SRC/SZ files in the supplied output folder, creating it first if it does not exist. Without an input parameter, first open a BIDS-folder picker. Without an output parameter (a second element), ask the local user to choose one (always an existing folder). |
| `nifti_dir_to_src` | `["nifti_dir_to_src","C:/nifti"]` | Find diffusion NIfTI data in the supplied directory and create SRC/SZ files there. Existing outputs may prompt for overwrite decisions. Without a parameter, open a directory picker. |
| `collect_network_measures` | `["collect_network_measures","C:/net/a.txt","C:/net/b.txt"]` | Collect one or more network-measure text files into `<first-file>.collected.txt`. Each file is a separate command element. Without file parameters, open a file picker. |
| `open_src` | `["open_src","C:/data/a.sz","C:/data/b.sz"]` | Open one or more SRC/SZ or histology inputs in one reconstruction window. Each file is a separate command element. A successful command selects the new reconstruction window and reports `recon window created, id: recon...` in `output`. Without file parameters, open a file picker. |
| `open_dwi_nifti` | `["open_dwi_nifti","C:/data/dwi.nii.gz"]` | Open one or more diffusion NIfTI inputs through `open_DWI`. Without file parameters, open a NIfTI picker. |
| `open_dwi_dicom` | `["open_dwi_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]` | Open one or more DICOM inputs through `open_DWI`. Each file is a separate command element. Without file parameters, open a DICOM picker. |
| `open_dwi_2dseq` | `["open_dwi_2dseq","C:/scan/2dseq"]` | Open one or more 2dseq, FDF, or NRRD diffusion inputs through `open_DWI`. Without file parameters, open a picker. |
| `open_src_dir` | `["open_src_dir","C:/src"]` | Search the supplied directory for `*src.gz` and `.sz` files and load them into one reconstruction window. A successful command reports its `recon...` ID. Without a parameter, open a directory picker. |
| `open_fib` | `["open_fib","C:/data/subject.fz"]` | Open the supplied `.fz`, `*fib.gz`, or `.dz` file and create and select a tracking window. Without a parameter, open a FIB picker. |
| `open_structural_tracking` | `["open_structural_tracking","C:/data/T1w.nii.gz"]` | Pass the supplied NIfTI or 2dseq structural image to `loadFib`. Without a parameter, open a structural-image picker. |
| `open_template` | `["open_template","<template-name>"]` | Open the exact built-in population/species template FIB as a tracking window. An invalid name returns an error. Without a parameter, open the template currently selected in the main-window list. |
| `create_db` | `["create_db"]` | Open the connectometry database-creation dialog. Takes no arguments. |
| `create_average` | `["create_average"]` | Open the average-database creation dialog. Takes no arguments. |
| `open_db` | `["open_db","C:/data/group.db.fz"]` | Load the supplied connectometry database and create a database window. Database-loading failures are returned through `error`. Without a parameter, open a database picker. |
| `open_connectometry` | `["open_connectometry","C:/data/group.db.fz"]` | Load the supplied connectometry database and create a group-connectometry window. Database-loading failures are returned through `error`. Without a parameter, open a database picker. |
| `open_auto_track` | `["open_auto_track"]` | Create and show the main AutoTrack window. Takes no arguments. |
| `open_nonlinear_registration` | `["open_nonlinear_registration"]` | Create and show the nonlinear-registration toolbox. Takes no arguments. |
| `open_xnat` | `["open_xnat"]` | Create and show the XNAT dialog. Takes no arguments. |
| `open_console` | `["open_console"]` | Show the singleton application console. Takes no arguments. |
| `clear_recent_src` | `["clear_recent_src"]` | Immediately clear the recent SRC/SZ table and saved `recentSrcFileList`. Takes no arguments and asks for no confirmation. |
| `clear_recent_fib` | `["clear_recent_fib"]` | Immediately clear the recent FIB/FZ table and saved `recentFibFileList`. Takes no arguments and asks for no confirmation. |
| `show_qc_nii` | `["show_qc_nii","C:/data/a.nii.gz","C:/data/b.nii.gz"]` | Run NIfTI quality checks. Each file is a separate command element. Without file parameters, open a file picker. AI callers get the report text directly in `output`; a local user instead sees it in a dialog. |
| `show_qc_src` | `["show_qc_src","C:/data/a.sz","C:/data/b.sz"]` | Same as `show_qc_nii` for SRC/SZ files. |
| `show_qc_fib` | `["show_qc_fib","C:/data/a.fz","C:/data/b.fz"]` | Same as `show_qc_nii` for FIB/FZ files. |
| `save_qc_nii` | `["save_qc_nii","C:/report.txt","C:/data/a.nii.gz"]` | Same checks as `show_qc_nii`, but writes the report to the given path (first parameter) instead of returning it or showing a dialog. Without file parameters after the path, open a file picker. |
| `save_qc_src` | `["save_qc_src","C:/report.txt","C:/data/a.sz"]` | Same as `save_qc_nii` for SRC/SZ files. |
| `save_qc_fib` | `["save_qc_fib","C:/report.txt","C:/data/a.fz"]` | Same as `save_qc_nii` for FIB/FZ files. |
| `run_cli` | `["run_cli","--action=vis --source=C:/data/subject.fz --cmd=list_tract"]` | Parse and execute one DSI Studio command-line string inside the running process. Missing `--action` defaults to `vis`; wildcard looping and each action's own requirements apply. |
| `run_shell` | `["run_shell","cd \"C:\\data\""]` | Execute one shell command string. `cd` changes this AI session's own current directory (remembered per chat, reapplied on later calls) with no confirmation dialog; every other command shows the local user a confirmation dialog first, then `dir`-like commands run synchronously and `curl` runs asynchronously as a synthetic `curlN` task. |
| `open_image` | `["open_image","C:/data/T1w.nii.gz","C:/data/T2w.nii.gz"]` | Open one or more supported medical image volumes in a new `view_image` window and select it. Each file is a separate command element. Image-opening failures are returned through `error`. Without file parameters, open an image picker. Do not use this command for FIB tracking or ordinary JPG/PNG screenshots. |
| `open_ai` | `["open_ai"]` | Show, raise, and activate the AI Agent window. Takes no arguments. |
| `open_hub` | `["open_hub"]` | Show, raise, and activate the Fiber Data Hub without running a query. Takes no arguments. |
| `hub_repo` | `["hub_repo"]` | Show the Fiber Data Hub and list available repositories. |
| `hub_tags` | `["hub_tags","<repo>"]` | List release tags for the exact repository returned by `hub_repo`. |
| `hub_files` | `["hub_files","<repo>","",".*\\.fz$",0,20]` | Search files across every tag matching the case-insensitive tag regular expression. The filename filter is also a case-insensitive regular expression; empty tag or filename patterns match all. Offset and limit apply to the combined matches. |
| `hub_open` | `["hub_open","<repo>","<exact-tag>",12]` | Download to temporary cache when needed and open one selected Hub file. The tag must be one exact tag; the file may be the returned row index or exact filename. |
| `hub_show` | `["hub_show","<repo>","<exact-tag>"]` or `["hub_show","<repo>","<exact-tag>","subjects.tsv"]` | Without a file: return the tag's GitHub release note (explaining what the dataset is) directly in the response. With a file: download that `.tsv` release file and return its raw tab-separated content instead, rather than opening it as the release-note table in the Hub window. The tag must be one exact tag; the file may be the returned row index or exact filename; fails if a given file does not end in `.tsv`. |
| `hub_download` | `["hub_download","<repo>","^HCP.*$","*.qsdr.fz","C:/data"]` | Download every file matching the wildcard pattern (`*`, `?`, `[...]`) in every tag matching the case-insensitive tag regular expression, so one call can fetch many files across many tags/subjects at once. |

## Built-in template-space analysis

`open_template` opens a built-in population/species FIB as a normal tracking window;
use the template matching the data population. Installed names are determined by the
packaged atlas/tract set and commonly include `human`, `human-neonate`, `rhesus`,
`marmoset`, `rat`, and `mouse`.

For common-space analysis, load scalar NIfTI maps into that template window with
`add_mni_slice`. For `human`, this means MNI-space NIfTI; for other templates, use the
corresponding template space. DSI Studio uses the NIfTI header transform for alignment,
so the NIfTI may have a different voxel size or matrix from the template FIB. The
loaded map becomes a regular slice and can be used for threshold/ROI creation, region
statistics, tractography, atlas analysis, and rendering together with the template FIB
metrics.

```bash
bash ./dsi.sh open_template human
bash ./dsi.sh add_mni_slice "C:/data/mni_result.nii.gz"
bash ./dsi.sh list_slice
```

After `open_template`, the new `tracking<hex-address>` is already selected; do not
send `set_window` unless switching between already-open windows.

## Multiple-file parameter format

Commands that accept multiple files use one command-array element per file:

```json
["open_src","C:/data/a.sz","C:/data/b.sz"]
["show_qc_fib","C:/data/a.fz","C:/data/b.fz"]
["rename_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]
```

Do not combine multiple paths into one `&`-separated string. The current router
collects every command element after the command name as a separate file path.

After `open_src`, the new `recon<hex-address>` is already selected; follow
`DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md`.

## Internal `run_cli` actions

`run_cli` accepts exactly one non-empty command-line string:

```json
["run_cli","--action=vis --source=C:/data/subject.fz --cmd=list_tract"]
["run_cli","--action=rec --source=C:/data/*.sz"]
```

- Keep the entire command line in one string.
- The optional exact lowercase prefix `dsi_studio ` is removed before parsing.
- Missing `--action` defaults to `vis`.
- The action runs inside the current DSI Studio process, not in a new executable.
- Relative paths use DSI Studio's current directory.
- `run_cli` does not target the AI session's `set_window` selection; each CLI action
  uses its own global command-line behavior.
- The wildcard-aware action dispatcher is used. A source wildcard may run the action
  repeatedly, and `--continue_on_error` controls whether a loop stops at its first
  failed item.
- A failed action returns `command line failed`; inspect captured output for the more
  specific action message.

See `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md` before using CLI actions, especially
wildcards, global thread settings, overwrites, or actions that depend on open windows.

## Confirmation-gated `run_shell` commands

`run_shell` accepts exactly one non-empty command string. The first token is matched
case-insensitively; `cd` is a built-in special case with no confirmation dialog,
everything else is passed to the operating system shell after local user approval:

```json
["run_shell","cd \"C:\\data\""]
["run_shell","cd"]
["run_shell","dir \"*.fz\" /s /b"]
["run_shell","curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""]
```

- Send the entire command as one command-array element.
- `cd <path>` changes this AI session's own current directory. It is remembered per
  chat and reapplied automatically before every later `run_shell`, `run_cli`, and
  relative-path call in the same session -- a different chat's `cd` never affects
  it, and it survives across separate requests in the same chat. Enclose a path
  containing spaces in one pair of double quotes.
- `cd` without a path reports the current directory. Do not use `cd /d`; the
  remaining text is interpreted as the path.
- `cd` runs with no confirmation dialog and no external process. Every other
  `run_shell` command shows the local user a confirmation dialog with the exact
  command text and only runs if they approve it; there is no whitelist or character
  restriction anymore, the dialog is the only gate. `run_shell` therefore cannot
  complete unattended with nobody present to approve it, and a batched command array
  containing `run_shell` pauses at that dialog before continuing.
- Approved non-`curl` commands run synchronously with a 10-minute maximum wait; a
  timeout kills the process and fails the command. On Windows they use `cmd.exe /c`;
  on Unix they use `/bin/sh -c`. Standard output is returned and standard error is
  logged. The external exit code is checked and a non-zero exit fails with
  `command exited with code <N>`.
- `curl` runs asynchronously once approved. DSI Studio always inserts ` -s -S`
  right after `curl` before showing the confirmation dialog, so no need to include
  them: `-s` suppresses curl's `\r`-redrawn progress meter (it would otherwise flood
  the log, since there is no terminal to redraw a line in), `-S` still surfaces real
  curl errors. Its initial reply reports `started curlN: curl -s -S ...`; this means
  the task was registered, not that the transfer completed.
- Initialize the session log cursor before the first asynchronous curl. With the
  launcher, call `log` once before `run_shell curl`; the first log may be empty. With
  ChatGPT (Web), send a prior `log` request or set `include_log:true` on the curl-start
  request.
- While curl is active, `list_window` reports its synthetic `curlN` ID as `busy`.
  Poll until the entry disappears, then call `log` again to retrieve output or errors.
- There is currently no AI command for cancelling a `curlN` task, and no completion
  timeout.
- Relative `dir` and `curl` paths use this session's own directory selected by `cd`.
- Use `curl -o` or `curl -O` instead of output redirection.
- `run_shell` does not accept DSI Studio `--action=...` command lines. Use `run_cli`
  for a DSI Studio CLI action.
- Do not place credentials, tokens, protected data, or untrusted command text in
  `run_shell` — the local user sees the exact text in the confirmation dialog either
  way.

Read `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md` for platform behavior, wildcard rules,
working-directory effects, and completion verification.

## Fiber Data Hub workflow

Hub commands are routed before the regular main-window command handling, so they
may use their full documented argument lists:

```json
["hub_repo"]
["hub_tags","<repo>"]
["hub_files","<repo>","",".*\\.fz$",0,20]
["hub_open","<repo>","<exact-tag>",12]
["hub_show","<repo>","<exact-tag>"]
["hub_show","<repo>","<exact-tag>","subjects.tsv"]
["hub_download","<repo>","^HCP.*$","*.qsdr.fz","C:/data"]
```

- Use the exact `owner/repository` string returned by `hub_repo`.
- `hub_files` syntax is `hub_files <repo> [tag-regex] [filename-regex] [offset] [limit]`.
  Both patterns are case-insensitive regular expressions. An empty pattern matches
  all tags or filenames.
- `hub_files` searches all matching tags and returns
  `index`, `tag`, `file`, `size`, and `downloaded`. The index is the actual file-row
  index within the reported tag.
- Offset and limit apply after combining matching files across tags. Omit the limit
  to return every remaining match; an explicit limit of `0` returns no rows.
- `hub_open` requires one exact tag and accepts the exact filename or returned row
  index.
- `hub_show <repo> <tag>` (no file) returns that tag's GitHub release note --
  read this first to learn what a dataset actually contains before browsing or
  downloading its files.
- `hub_show <repo> <tag> <file>` requires one exact tag and accepts the exact
  filename or returned row index, same as `hub_open`. Unlike every other `hub_`
  command, its result is the downloaded file's raw tab-separated text, not a status
  line -- read it directly instead of treating it as a log message. Fails if the
  resolved file is not a `.tsv` release asset.
- `hub_download` treats its tag parameter as a case-insensitive regular expression
  and its file parameter as a wildcard pattern (`*`, `?`, `[...]`, e.g. `*.qsdr.fz`
  or `*.gqi.fz`), matching every file in every matching tag -- one call can download
  many files across many tags at once. A plain exact filename still matches only
  that one file, since the wildcard is anchored to the full name (not a row index;
  row indices only work for `hub_open`/`hub_show`). A tag with no matching file is
  reported as `skip`; the command succeeds when at least one matching download is
  started.
- Send offset, limit, and returned row indices as JSON numbers.
- `hub_download` requires its documented destination-directory parameter and creates
  the directory when needed.
- Verify the created window or destination file after GUI-backed network work.

## Important routing and response notes

- `run_cli` and `run_shell` are global MainWindow commands and remain available when
  a non-main window is selected. `run_cli` action handlers use their own state rather
  than the session's persistent window selection.
- Successful `open_src`, `open_fib`, and `open_image` commands automatically select
  the new reconstruction, tracking, or image window and normally return its exact ID
  in `output`. Follow-up commands target it directly; keep the ID for later switching.
  `list_window` can confirm an ID or discover another already-open supported window.
- Do not invent aliases. Use `list_recent_fib` and `list_recent_src` exactly.
- Supplying paths as documented command parameters is supported. Never send a
  path alone as the complete named-pipe request.
- Commands without parameters may open a local picker. Cancellation can return
  without an immediate command error, so verify the resulting window, file, or
  application state.
- A successful command result includes `output` only when text was captured. When
  no text was captured, the result contains `cmd` and `status` but no `output`.
- A successful asynchronous `curl` start is not download completion. Initialize the
  log cursor before the transfer, verify completion through `list_window`, then read
  the later incremental `log` output.
- Invalid template names, database-loading failures, and image-opening failures
  propagate through the `error` field.
- Confirm `reset_settings`, `clear_recent_src`, and `clear_recent_fib` before use
  because they immediately modify saved application state.
- Use `list_param` in a reconstruction window before changing reconstruction
  parameters. Use the appropriate `list_param` command in a tracking window before
  changing tracking or rendering parameters.

## GUI interaction notes

- `bids_to_src` asks the local user to select an output directory only when the
  output-folder parameter (the second element) is omitted; supply it to run
  unattended.
- `open_dwi_nifti`, `open_dwi_dicom`, and `open_dwi_2dseq` enter the DWI-import
  workflow; they do not directly guarantee a returned reconstruction-window ID.
- Picker-based commands require local GUI interaction and their cancellation may
  return without an immediate error.
- Verify opened windows and generated files rather than relying only on the lack
  of an `error` field.
