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
| `list_recent_fib` | `["list_recent_fib"]` | List saved recent FIB/FZ paths using forward slashes. Takes no arguments. |
| `list_recent_src` | `["list_recent_src"]` | List saved recent SRC/SZ paths using forward slashes. Takes no arguments. |
| `reset_settings` | `["reset_settings"]` | Clear all application settings, synchronize them, and show a confirmation message. Takes no arguments. |
| `set_work_dir` | `["set_work_dir","C:/work"]` | Add the supplied directory to the work-directory list. Without a parameter, open a directory picker. |
| `rename_dicom` | `["rename_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]` | Rename one or more DICOM files in their current parent directories. Each file is a separate command element. Without file parameters, open a file picker. |
| `rename_dicom_dir` | `["rename_dicom_dir","C:/dicom"]` | Rename DICOM files recursively at the supplied directory. Without a parameter, open a directory picker. |
| `convert_dicom_dir` | `["convert_dicom_dir","C:/dicom"]` | Recursively convert DICOM series in the supplied directory to SRC/SZ or NIfTI output without overwriting existing output. Without a parameter, open a directory picker. |
| `bids_to_src` | `["bids_to_src","C:/bids"]` | Search the supplied BIDS folder for diffusion NIfTI data, ask the local user to choose an output folder, and create SRC/SZ files. Without an input parameter, first open a BIDS-folder picker. |
| `nifti_dir_to_src` | `["nifti_dir_to_src","C:/nifti"]` | Find diffusion NIfTI data in the supplied directory and create SRC/SZ files there. Existing outputs may prompt for overwrite decisions. Without a parameter, open a directory picker. |
| `collect_network_measures` | `["collect_network_measures","C:/net/a.txt","C:/net/b.txt"]` | Collect one or more network-measure text files into `<first-file>.collected.txt`. Each file is a separate command element. Without file parameters, open a file picker. |
| `open_src` | `["open_src","C:/data/a.sz","C:/data/b.sz"]` | Open one or more SRC/SZ or histology inputs in one reconstruction window. Each file is a separate command element. A successful command reports `recon window created, id: recon...` in `output`. Without file parameters, open a file picker. |
| `open_dwi_nifti` | `["open_dwi_nifti","C:/data/dwi.nii.gz"]` | Open one or more diffusion NIfTI inputs through `open_DWI`. Without file parameters, open a NIfTI picker. |
| `open_dwi_dicom` | `["open_dwi_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]` | Open one or more DICOM inputs through `open_DWI`. Each file is a separate command element. Without file parameters, open a DICOM picker. |
| `open_dwi_2dseq` | `["open_dwi_2dseq","C:/scan/2dseq"]` | Open one or more 2dseq, FDF, or NRRD diffusion inputs through `open_DWI`. Without file parameters, open a picker. |
| `open_src_dir` | `["open_src_dir","C:/src"]` | Search the supplied directory for `*src.gz` and `.sz` files and load them into one reconstruction window. A successful command reports its `recon...` ID. Without a parameter, open a directory picker. |
| `open_fib` | `["open_fib","C:/data/subject.fz"]` | Open the supplied `.fz`, `*fib.gz`, or `.dz` file and create a tracking window. Without a parameter, open a FIB picker. |
| `open_structural_tracking` | `["open_structural_tracking","C:/data/T1w.nii.gz"]` | Pass the supplied NIfTI or 2dseq structural image to `loadFib`. Without a parameter, open a structural-image picker. |
| `open_template` | `["open_template","<template-name>"]` | Open the exact built-in template name. An invalid name returns an error. Without a parameter, open the template currently selected in the main-window list. |
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
| `qc_nii` | `["qc_nii","C:/data/a.nii.gz","C:/data/b.nii.gz"]` | Run NIfTI quality checks and display a report. Each file is a separate command element. Without file parameters, open a file picker. |
| `qc_src` | `["qc_src","C:/data/a.sz","C:/data/b.sz"]` | Run SRC/SZ quality checks and display a report. Each file is a separate command element. Without file parameters, open a file picker. |
| `qc_fib` | `["qc_fib","C:/data/a.fz","C:/data/b.fz"]` | Run FIB/FZ quality checks and display a report. Each file is a separate command element. Without file parameters, open a file picker. |
| `run_cli` | `["run_cli","--action=vis --source=C:/data/subject.fz --cmd=list_tract"]` | Parse and execute one DSI Studio command-line string inside the running process. Missing `--action` defaults to `vis`; wildcard looping and each action's own requirements apply. |
| `run_shell` | `["run_shell","cd \"C:\\data\""]` | Execute one restricted command string. `cd` changes DSI Studio's process-wide current directory, `dir` runs synchronously, and `curl` runs asynchronously as a synthetic `curlN` task. |
| `open_image` | `["open_image","C:/data/T1w.nii.gz","C:/data/T2w.nii.gz"]` | Open one or more supported medical image volumes in a `view_image` window. Each file is a separate command element. Image-opening failures are returned through `error`. Without file parameters, open an image picker. Do not use this command for FIB tracking or ordinary JPG/PNG screenshots. |
| `open_ai` | `["open_ai"]` | Show, raise, and activate the AI Agent window. Takes no arguments. |
| `open_hub` | `["open_hub"]` | Show, raise, and activate the Fiber Data Hub without running a query. Takes no arguments. |
| `hub_repo` | `["hub_repo"]` | Show the Fiber Data Hub and list available repositories. |
| `hub_tags` | `["hub_tags","<repo>"]` | List release tags for the exact repository returned by `hub_repo`. |
| `hub_files` | `["hub_files","<repo>","",".*\\.fz$",0,20]` | Search files across every tag matching the case-insensitive tag regular expression. The filename filter is also a case-insensitive regular expression; empty tag or filename patterns match all. Offset and limit apply to the combined matches. |
| `hub_open` | `["hub_open","<repo>","<exact-tag>",12]` | Download to temporary cache when needed and open one selected Hub file. The tag must be one exact tag; the file may be the returned row index or exact filename. |
| `hub_download` | `["hub_download","<repo>","^HCP.*$","subject.fz","C:/data"]` | Download the exact filename, or a row index, from every tag matching the case-insensitive tag regular expression. Use an exact filename when matching multiple tags. |

## Multiple-file parameter format

Commands that accept multiple files use one command-array element per file:

```json
["open_src","C:/data/a.sz","C:/data/b.sz"]
["qc_fib","C:/data/a.fz","C:/data/b.fz"]
["rename_dicom","C:/dicom/a.dcm","C:/dicom/b.dcm"]
```

Do not combine multiple paths into one `&`-separated string. The current router
collects every command element after the command name as a separate file path.

After `open_src`, use the returned `recon<hex-address>` and follow
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
- A failed action returns `command line failed`; inspect captured output or `log` for
  the more specific action message.

See `DSI_STUDIO_AI_CLI_SHELL_COMMANDS.md` before using CLI actions, especially
wildcards, global thread settings, overwrites, or actions that depend on open windows.

## Restricted `run_shell` commands

`run_shell` accepts exactly one non-empty command string. The first token must be
`cd`, `dir`, or `curl`, matched case-insensitively:

```json
["run_shell","cd \"C:\\data\""]
["run_shell","cd"]
["run_shell","dir \"*.fz\" /s /b"]
["run_shell","curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""]
```

- Send the entire command as one command-array element.
- `cd <path>` changes DSI Studio's process-wide current directory directly. The new
  directory persists across later `run_shell`, `run_cli`, and relative-path calls.
  Enclose a path containing spaces in one pair of double quotes.
- `cd` without a path reports the current directory. Do not use `cd /d`; the
  remaining text is interpreted as the path.
- `dir` runs synchronously. On Windows it uses `cmd.exe /c` and waits without a
  timeout. Standard output is returned and standard error is logged. The external
  exit code is not checked.
- `curl` runs asynchronously. Its initial reply reports `started curlN: ...`; this
  means the task was registered, not that the transfer completed.
- While curl is active, `list_window` reports its synthetic `curlN` ID as `busy`.
  Poll until the entry disappears, then call `log` to inspect output or errors.
- There is currently no AI command for cancelling a `curlN` task, and no completion
  timeout.
- Relative `dir` and `curl` paths use the persistent directory selected by `cd`.
- The exact first token must be `cd`, `dir`, or `curl`; other programs and aliases
  are rejected.
- For `dir` and `curl`, ampersand, vertical bar, semicolon, angle brackets, caret,
  backtick, carriage return, and newline are rejected anywhere in the command.
- Use `curl -o` or `curl -O` instead of output redirection.
- `run_shell` does not accept DSI Studio `--action=...` command lines. Use `run_cli`
  for a DSI Studio CLI action.
- Do not place credentials, tokens, protected data, or untrusted command text in
  `run_shell`.

Read `DSI_STUDIO_AI_CLI_SHELL_COMMANDS.md` for platform behavior, wildcard rules,
working-directory effects, and completion verification.

## Fiber Data Hub workflow

Hub commands are routed before the regular main-window command handling, so they
may use their full documented argument lists:

```json
["hub_repo"]
["hub_tags","<repo>"]
["hub_files","<repo>","",".*\\.fz$",0,20]
["hub_open","<repo>","<exact-tag>",12]
["hub_download","<repo>","^HCP.*$","subject.fz","C:/data"]
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
- `hub_download` treats its tag parameter as a case-insensitive regular expression
  and attempts the requested file in every matching tag. Use the exact filename
  rather than a row index when matching multiple tags. A missing filename in one tag
  is reported as `skip`; the command succeeds when at least one matching download is
  started.
- Send offset, limit, and returned row indices as JSON numbers.
- `hub_download` requires its documented destination-directory parameter and creates
  the directory when needed.
- Verify the created window or destination file after GUI-backed network work.

## Important routing and response notes

- `run_cli` and `run_shell` are global MainWindow commands and remain available when
  a non-main window is selected. `run_cli` action handlers use their own state rather
  than the session's persistent window selection.
- Target fixed `main` directly. After opening a reconstruction, tracking, or image
  window, DSI Studio normally returns its `recon<hex-address>`,
  `tracking<hex-address>`, or `image<hex-address>` ID in the command `output`; use
  that returned ID for follow-up commands. Top-level `list_window` can confirm an ID
  or discover another already-open supported window.
- Do not invent aliases. Use `list_recent_fib` and `list_recent_src` exactly.
- Supplying paths as documented command parameters is supported. Never send a
  path alone as the complete named-pipe request.
- Commands without parameters may open a local picker. Cancellation can return
  without an immediate command error, so verify the resulting window, file, or
  application state.
- A successful command result includes `output` only when text was captured. When
  no text was captured, the result contains `cmd` and `status` but no `output`.
- A successful asynchronous `curl` start is not download completion. Verify through
  `list_window`, then inspect `log`.
- Invalid template names, database-loading failures, and image-opening failures
  propagate through the `error` field.
- Confirm `reset_settings`, `clear_recent_src`, and `clear_recent_fib` before use
  because they immediately modify saved application state.
- Use `list_param` in a reconstruction window before changing reconstruction
  parameters. Use the appropriate `list_param` command in a tracking window before
  changing tracking or rendering parameters.

## GUI interaction notes

- `bids_to_src` always asks the local user to select an output directory, even
  when the input BIDS path is supplied.
- `open_dwi_nifti`, `open_dwi_dicom`, and `open_dwi_2dseq` enter the DWI-import
  workflow; they do not directly guarantee a returned reconstruction-window ID.
- Picker-based commands require local GUI interaction and their cancellation may
  return without an immediate error.
- Verify opened windows and generated files rather than relying only on the lack
  of an `error` field.
