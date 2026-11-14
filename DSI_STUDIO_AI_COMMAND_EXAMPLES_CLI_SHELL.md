# DSI Studio AI CLI and Shell Commands

`run_cli` and `run_shell` are global MainWindow commands, handled before fallback to the selected
data window and available while a reconstruction, tracking, or image window is selected. Prefer
ordinary AI commands; use `run_cli` for a DSI Studio command-line action with no direct AI command,
and `run_shell` for operating-system commands, each of which the local user must approve. In a GUI
session never send a DSI Studio `--action=...` line through `run_shell` (use `run_cli`), and never
send an operating-system command through `run_cli`. `run_cli` is GUI-only: a headless Web session
(`dsi_studio --action=ai`) rejects it, runs DSI Studio command lines through `run_shell` as their own
process, and sends long work through the scheduler (`DSI_STUDIO_AI_SKILL_WEB.md`).

## `run_cli`

Exactly one non-empty command-line string; never split its options into a parameter array:

```bash
bash ./dsi.sh run_cli "--action=vis --source=C:/data/subject.fz --cmd=list_tract"
```

Web: `{"command":{"cmd":"run_cli","param":"--action=vis --source=C:/data/subject.fz --cmd=list_tract"}}`.

- The exact lowercase prefix `dsi_studio ` is accepted and removed (omitting it is preferred); a full
  executable path, `./dsi_studio`, or other capitalization is not removed.
- `tipl::program_option` parses the string. Without `--action`, `--action=vis` is inserted. Actions:
  `rec trk src ana exp atl db tmp cnt cnt_cl vis ren qc reg atk xnat img`. Each enforces its own
  options: `vis` needs `--cmd`, and `--source` when no tracking window is open (otherwise it uses the
  most recently created tracking window, not the `set_window` selection).
- It runs inside the current process, not another executable. Relative paths use the chat's working
  directory (`run_shell "cd ..."` does not change it). Actions may use or change global state:
  `--thread_count` changes the process-global TIPL thread limit and is not restored.
- The request normally stays active until the action returns. A failure reports
  `command line failed`, with details in the captured output. Unused options are reported as warnings
  and do not turn success into an error.

### Atlas overlap statistics (`--overlap`)

`--overlap=<atlas-name>` takes an exact built-in atlas name such as `CHA`, `Brodmann`, or `HCP-MMP`
and intersects a region or tract with every nonempty atlas label, without materializing atlas
regions; zero-overlap labels are omitted.

```bash
bash ./dsi.sh run_cli "--action=ana --source=C:/data/subject.fz --region=C:/data/tumor.nii.gz --overlap=CHA --output=C:/data/tumor_CHA.txt"
bash ./dsi.sh run_cli "--action=ana --source=C:/data/subject.fz --tract=C:/data/CST.tt.gz --overlap=HCP-MMP"
bash ./dsi.sh run_cli "--action=trk --source=C:/data/subject.fz --tract_count=10000 --overlap=HCP-MMP"
bash ./dsi.sh run_cli "--action=atk --source=C:/data/subject.fz --track_id=Corticos --overlap=HCP-MMP"
```

| Use | Output |
|---|---|
| `ana` with exactly one region | The region-statistics path: default `<source>.statistics.txt`; `--output` may name a file or directory, `.txt` appended when needed. |
| `ana` with one tract (voxelized) | `<tract-file>.overlap.txt` from the shared post-tracking routine (e.g. `CST.tt.gz.overlap.txt`); `--output` does not redirect it. |
| `trk` (new tractography) | Named from the source-derived pre-save tract filename, so it may not follow a later `--output`. |
| `atk` (AutoTrack) | `<bundle-tract-file>.overlap.txt` beside each completed bundle's output. |

With a tracking window open, the direct nonmutating commands are simpler for existing rows; use CLI
`--overlap` for files, batch CLI work, or post-tracking output:

```bash
bash ./dsi.sh show_region_overlap_statistics <region-index> <atlas-name>
bash ./dsi.sh show_tract_overlap_statistics <tract-index> <atlas-name>
```

### AutoTrack diagnostics (`--debug`)

When a bundle is empty or implausible, `--debug` shows whether registration or tracking is
responsible. It only saves diagnostics; registration, tracking, bundles, and statistics are
unchanged. Bundles with results are skipped as usual, so add `--overwrite=1`:

```bash
bash ./dsi.sh run_cli "--action=atk --source=C:/data/subject.fz --track_id=Arcuate --debug=1 --overwrite=1"
```

- Once per FIB, in the output folder: `<fib>.debug.template_qa.nii.gz`,
  `<fib>.debug.template_iso.nii.gz` (when the template has an ISO image), and
  `<fib>.debug.atlas.tt.gz` with cluster names in `<fib>.debug.atlas.tt.gz.txt`: the template and
  tractography atlas warped into subject space by the run's own mapping.
- Per bundle, beside its tract file: `<bundle>.debug.tsv`, one row per tolerance attempt with
  `attempt`, `tolerance`, `effective_tolerance`, `min_length`, `max_length`, `tip_iteration`,
  `seeds`, `generated`, `pre_tip`, `post_tip`, `tip_undone`, `selected`, and `outcome` (`low_yield`,
  `no_tracks`, `tip_undone`, or `selected`).
- Per bundle and attempt: `<bundle>.debug<attempt>.<seed|limiting|not_end|roi|roa>.nii.gz`, the
  atlas-derived regions used.

If the warped template or atlas does not overlay the subject, registration is the problem. If it
overlays but every attempt is `low_yield` or `no_tracks`, inspect tracking parameters, tolerance, and
data quality. `tip_undone` means TIP removed the whole bundle and AutoTrack kept the untrimmed result.

### Wildcards

`run_cli` uses the wildcard-aware dispatcher of normal command-line startup. `--loop=<pattern>`
enables looping; without it, a `*` in `--source` becomes the loop pattern except for `atk`, `src`,
`qc`, `db`, and `tmp`. DSI Studio reports the matching file count, substitutes related wildcard
options, runs the action once per file, and stops at the first failure unless `--continue_on_error`
is present. Confirm the intended files and overwrite behavior first.

```bash
bash ./dsi.sh run_cli "--action=rec --source=C:/data/*.sz"
```

## `run_shell`

One non-empty command string, always passed to the operating-system shell (`cd` included):

```bash
bash ./dsi.sh run_shell "cd \"C:/data\" && dir \"*.fz\" /s /b"
bash ./dsi.sh run_shell "curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""
```

Web: `{"command":{"cmd":"run_shell","param":"dir \"*.fz\" /s /b"}}`.

- **Confirmation.** Every command shows the local user a dialog with its exact text and runs only if
  approved. There is no exemption (not even `dir`/`ls` or `python script.py`), because a compound
  string like `ls && rm file` runs everything. The request, and any command array containing it,
  blocks until a person at the DSI Studio machine responds, so it cannot complete unattended. A
  decline fails with `user declined to run this shell command`. Never send credentials, tokens,
  protected data, or untrusted text: the user sees it, and it is written to captured output and
  console history.
- **`cd`.** Each command runs in its own shell from the chat's working directory, so a standalone
  `run_shell "cd ..."` has no lasting effect. Put `cd` in the same command
  (`cd /data/sub01 && python make_report.py`), use absolute paths, or call `set_work_dir <dir>`.
- **Synchronous commands** (everything except `curl`) run through a real shell on every OS
  (`cmd.exe /c` on Windows, `/bin/sh -c` on macOS/Linux), so pipes, redirection, `&&`, and globs behave
  consistently. DSI Studio waits up to 10 minutes, then kills the command and fails with
  `command timed out after 10 minutes`; split longer work into an asynchronous `curl` step or shorter
  calls. Standard output is returned, standard error goes to the console, and a non-zero exit fails
  with `command exited with code <N>`.

### `curl` (asynchronous)

After approval, `curl` returns immediately. DSI Studio inserts ` -s -S` after `curl` (the progress
meter's `\r` redraws flood a captured log; `-S` still shows errors), and the dialog and reply already
show them, so do not add them:

```text
started curl1: curl -s -S -L -o "atlas.zip" "https://example.org/atlas.zip"
```

This confirms registration, not transfer. While active, `list_window` lists a `curlN` entry with
`status:"busy"` and the command as title. To retrieve its output, the session's log cursor must
already exist (the first-ever `log` sets it at the console end and returns no history):

1. Launcher: `bash ./dsi.sh log`, then the curl request. Web: a `{"cmd":"log"}` request first (its
   reply may be empty). Skip this if the session already called `log`.
2. Poll `list_window` until `curlN` disappears, then call `log` again (Web: a later higher-ID request)
   for the output or error.
3. Never place a dependent open or processing command after `curl` in the same array.

There is no AI command to cancel a `curlN` task, and no completion timeout: a stalled transfer can
stay busy indefinitely, without blocking DSI Studio (it is a self-contained asynchronous task). Like
other commands it runs through a real shell. Relative output paths use this AI session's current
directory.

### Downloading from OpenNeuro

Public OpenNeuro objects are in the `openneuro.org` S3 bucket; use `curl` for selected files rather
than whole datasets. List objects under a path with the S3 query API (quote the URL; `&` in query
strings is supported); the reply is S3 XML with object keys and sizes:

```bash
bash ./dsi.sh run_shell "curl -s \"https://s3.amazonaws.com/openneuro.org/?list-type=2&prefix=ds001378%2Fsub-SCA201\""
```

For known files, curl brace expansion with `--create-dirs` downloads several objects in one
asynchronous command, keeping their relative paths:

```bash
bash ./dsi.sh run_shell "curl -fL --retry 3 --create-dirs -o \"ds001378/#1\" \"https://s3.amazonaws.com/openneuro.org/ds001378/{dataset_description.json,participants.tsv,sub-SCA201/ses-01/anat/sub-SCA201_ses-01_T1w.nii.gz}\""
```

For large or complete datasets, determine the object set first; S3 listings can be paginated, so one
response may be incomplete. Then follow the `curl` steps and verify representative output files.

## `write_text_file` and `patch_text_file`

`write_text_file <filename> <content>` writes generated text, such as a Python script, exactly as
sent. Use it instead of `echo`, heredocs, or redirection: the content never passes through a shell,
so quotes, `$`, `%`, `!`, `&`, `|`, `<`, `>`, backticks, backslashes, indentation, and newlines need no
escaping beyond the JSON string.

```json
{"cmd":"write_text_file","param":["make_report.py","import pptx\nprint('ok')\n"]}
```

From the launcher, send the content through stdin with `--stdin` (no shell escaping, one request and
one confirmation):

```bash
bash ./dsi.sh write_text_file make_report.py --stdin <<'PY'
import pptx
print('ok')
PY
bash ./dsi.sh run_shell "python make_report.py"
```

- Every AI call shows the local user a confirmation with the full path and byte count; declining
  fails with `user declined to write this file`.
- A relative path resolves against the chat's working directory. An existing file is overwritten,
  byte for byte as UTF-8 with the content's own newlines and no BOM.
- Success returns `wrote <bytes> bytes to <absolute path>`; failure returns `cannot write to <path>`.
- The command array is recorded in the console, so never write credentials or tokens.

`patch_text_file <filename> <unified diff>` changes part of an existing file, also after
confirmation: its hunks (`@@ -N,M +N,M @@` with ` `, `-`, `+` lines) must match the current text
exactly, or nothing changes and the reply names the first mismatched hunk. CRLF files stay CRLF.

### Running a Python script

Write it with `write_text_file`, then run it with `run_shell` (up to 10 minutes; returns standard
output):

```json
"command":[{"cmd":"write_text_file","param":["make_report.py","<script>"]},
           {"cmd":"run_shell","param":"python make_report.py"}]
```

On Windows, if `python` is not found, use `py make_report.py`. Install missing packages first, e.g.
`run_shell "python -m pip install --user python-pptx matplotlib pillow"`. A non-zero exit fails with
`command exited with code <N>`; read the error with `log`. Web agents then send the file with
`web_upload`.

## Command arrays

- `run_cli` is normally synchronous; `run_shell` commands other than `curl` are synchronous after
  confirmation, bounded to 10 minutes; `curl` returns once approved.
- Any `run_shell` pauses the whole array at its confirmation dialog until the user responds.
- Initialize `log` before an asynchronous `curl`, monitor it in later requests with `list_window` and
  `log`, and never put a dependent command after it in the same array.
