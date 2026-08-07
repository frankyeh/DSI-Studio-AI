# DSI Studio AI CLI and Restricted Shell Commands

`run_cli` and `run_shell` are global MainWindow commands. They remain available even when the AI session has selected a reconstruction, tracking, or image window.

Use ordinary AI commands whenever possible. Use `run_cli` for a DSI Studio command-line action that has no direct AI command. Use `run_shell` for operating-system shell commands; every `run_shell` command other than `cd` requires the local user to approve a confirmation dialog before it runs.

## `run_cli`

`run_cli` requires exactly one non-empty command-line string:

```bash
bash ./dsi.sh run_cli "--action=vis --source=C:/data/subject.fz --cmd=list_tract"
```

ChatGPT (Web) form:

```json
{"command":{"cmd":"run_cli","param":"--action=vis --source=C:/data/subject.fz --cmd=list_tract"}}
```

Keep the complete DSI Studio command line in one string. Do not split its options into a parameter array.

The implementation accepts and removes the exact lowercase prefix `dsi_studio `. The prefix is optional; omitting it is preferred. A full executable path, `./dsi_studio`, or different capitalization is not removed.

The string is parsed by `tipl::program_option`. If `--action` is absent, DSI Studio inserts `--action=vis`. The current action map recognizes:

```text
rec trk src ana exp atl db tmp cnt cnt_cl vis ren qc reg atk xnat img
```

An action still enforces its own required options. For example, `vis` requires `--cmd`. If no tracking window is open it also requires `--source`; otherwise it uses the most recently created tracking window. `run_cli` does not use the AI session's `set_window` selection.

`run_cli` executes inside the current DSI Studio process. It does not launch another DSI Studio executable. Relative paths use DSI Studio's current directory. A prior `run_shell "cd ..."` therefore affects later relative CLI paths. CLI actions may use or change global application state. `--thread_count` changes the process-global TIPL thread limit and is not restored after the action.

The request normally remains active until the internal action returns. A failed action produces `command line failed`; the captured command output may contain the detailed cause. Unused options are reported as warnings after execution and do not by themselves change a successful result into an error.

### Wildcards

`run_cli` uses the same wildcard-aware dispatcher as normal command-line startup. An explicit `--loop=<pattern>` enables looping. Without `--loop`, a `*` in `--source` becomes the loop pattern automatically except for `atk`, `src`, `qc`, `db`, and `tmp`.

For a loop, DSI Studio finds matching files, reports the count, substitutes related wildcard options, and runs the action once per file. It stops on the first failure unless `--continue_on_error` is present.

```bash
bash ./dsi.sh run_cli "--action=rec --source=C:/data/*.sz"
```

Confirm the intended files and overwrite behavior before using a wildcard action.

## `run_shell`

`run_shell` requires one non-empty command string. Its first space-delimited token is matched case-insensitively; `cd` is a built-in special case, everything else is passed to the operating system shell.

```bash
bash ./dsi.sh run_shell "cd \"C:/data\""
bash ./dsi.sh run_shell "cd"
bash ./dsi.sh run_shell "dir \"*.fz\" /s /b"
bash ./dsi.sh run_shell "curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""
```

ChatGPT (Web) form:

```json
{"command":{"cmd":"run_shell","param":"dir \"*.fz\" /s /b"}}
```

Keep the entire command in one string.

### Local user confirmation

Every `run_shell` command other than `cd` shows the local user a confirmation dialog with the exact command text before it runs, and only proceeds if they approve it. There is no character restriction or command whitelist anymore — the confirmation dialog is the only gate. This means:

- `run_shell` (other than `cd`) blocks until a human at the DSI Studio machine responds to the dialog. It cannot complete in a fully unattended session with no local user present to approve it.
- If the user declines, the command fails with `user declined to run this shell command`.
- Never send credentials, tokens, or other sensitive text in a `run_shell` command, since the local user sees the exact text in the confirmation dialog and it is written to captured output/console history either way.

### `cd`

`cd` is implemented directly with `QDir::setCurrent()` rather than by starting a shell, and does not show a confirmation dialog (it changes DSI Studio's own working directory only, no external process is started). The new directory is process-wide and persists across later `run_shell`, `run_cli`, and relative-path operations. One pair of double quotes around the entire path is removed. `cd` with no path prints the current directory. Do not use `cd /d`; the remaining text is treated as the path.

### `dir` and other synchronous commands

Any command other than `curl` (after `cd`) takes the synchronous path: DSI Studio waits without a timeout for it to finish. On Windows it runs through `cmd.exe /c`; on macOS/Linux it is started directly. Standard output is returned and standard error is written to the DSI Studio console. The implementation checks the external exit code and fails with `command exited with code <N>` on a non-zero exit.

### `curl`

`curl` is asynchronous (after the confirmation dialog is approved). The immediate reply contains a synthetic task ID such as:

```text
started curl1: curl -L -o "atlas.zip" "https://example.org/atlas.zip"
```

This confirms task registration, not successful transfer completion. While active, `list_window` includes a synthetic `curlN` entry with `status:"busy"` and the original command as its title.

The session log cursor must already be initialized to retrieve later curl output. The first-ever `log` command sets the cursor to the current end of the console and intentionally returns no earlier history. Use one of these sequences:

Launcher route:

```bash
bash ./dsi.sh log
bash ./dsi.sh run_shell "curl -L -o \"atlas.zip\" \"https://example.org/atlas.zip\""
```

The initial `log` may be empty; its purpose is to initialize the cursor. Poll `list_window` until the reported `curlN` entry disappears, then call `log` again.

ChatGPT (Web) route: set `include_log:true` on the curl-start request, or send a separate `log` request before curl. The immediate `response.log` may be empty, but it initializes the cursor. After `curlN` disappears, send a later higher-ID `log` request to retrieve the transfer output or error.

If the session had already called `log`, no extra initialization is needed.

There is currently no AI command to cancel a `curlN` task. On Windows, curl runs through `cmd.exe /c`; on macOS or Linux it is started directly. There is no completion timeout, so a stalled transfer can remain busy indefinitely. Relative output paths use DSI Studio's persistent current directory.

Do not place credentials, tokens, protected data, or untrusted command text in `run_shell`.

## Command arrays and routing

Both commands are handled by MainWindow before fallback to the selected data window.

- `run_cli` is normally synchronous.
- `dir` is synchronous.
- `curl` returns immediately.
- Do not place a dependent open or processing command after `curl` in the same array.
- Initialize `log` before asynchronous curl, then monitor the task in later requests with `list_window` and `log`.

Never send a DSI Studio `--action=...` line through `run_shell`. Never send an operating-system command through `run_cli`.