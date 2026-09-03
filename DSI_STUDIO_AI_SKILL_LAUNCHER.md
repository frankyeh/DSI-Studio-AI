# DSI Studio AI Launcher

Use the Bash launcher whenever Bash is available:

```bash
bash ./dsi.sh <command> [values...] [-- <command> [values...] ...] [-Chat "message"]
```

Always include `bash` before `./dsi.sh`. Do not invoke `./dsi.sh` directly.

All launchers identify the current agent and session from these environment
variables:

```text
CLAUDE_CODE_SESSION_ID
CODEX_THREAD_ID
```

When `CLAUDE_CODE_SESSION_ID` is set, the launcher uses `Claude` as the agent name
and that value as the session ID. Otherwise, when `CODEX_THREAD_ID` is set, it uses
`Codex` as the agent name and that value as the session ID. Claude takes precedence
if both variables are set. The launchers no longer read `DSI_STUDIO_AGENT`. Do not
pass an agent name or session ID on the command line.

## Common syntax

Single commands remain unchanged:

```bash
bash ./dsi.sh set_title "Fiber tracking"
bash ./dsi.sh -Chat "Reading the DSI Studio instructions."
bash ./dsi.sh list_window
bash ./dsi.sh list_recent_fib
bash ./dsi.sh set_window tracking<hex-address>
bash ./dsi.sh set_slice 7
```

Use `--` to separate multiple DSI Studio commands in one request. Commands are sent
as one ordered batch and DSI Studio executes them sequentially, stopping the batch if
a command fails:

```bash
bash ./dsi.sh set_param show_slice 0 -- set_param show_tract 1 -- add_surface 0 25
```

`-Chat` is a request-level option, not a command. It may accompany either a single
command or a batch and applies once to the whole request:

```bash
bash ./dsi.sh voice "I will inspect the available tracts." -- list_auto_tract \
  -Chat "Starting a narrated tractography step."
```

Do not place an empty command before, after, or between `--` separators.

The Windows wrapper accepts the same command arguments:

```powershell
./dsi set_title "Fiber tracking"
./dsi -Chat "Reading the DSI Studio instructions."
./dsi list_window
./dsi list_recent_fib
./dsi set_window tracking<hex-address>
./dsi set_slice 7
./dsi set_param show_slice 0 -- set_param show_tract 1 -- add_surface 0 25
```

The PowerShell implementation may also be called directly from PowerShell:

```powershell
& ./dsi.ps1 set_title "Fiber tracking"
& ./dsi.ps1 list_window
& ./dsi.ps1 list_recent_fib
& ./dsi.ps1 set_param show_slice 0 -- set_param show_tract 1 -- add_surface 0 25
```

When starting Windows PowerShell explicitly, use the call operator rather than
`-File`:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& './dsi.ps1' list_window"
```

## Launcher selection

| Agent | OS | Bash available | Recommended launcher | Requirements | Notes |
|---|---|---:|---|---|---|
| Codex | Windows | Yes | `bash ./dsi.sh ...` | Git Bash and Windows PowerShell | Shared recommended route; Python is not required |
| Claude | Windows | Yes | `bash ./dsi.sh ...` | Git Bash, Windows PowerShell, and Bash permission | Shared recommended route; Python is not required |
| Codex | Windows | No | `./dsi ...` | `dsi.cmd`, `dsi.ps1`, and Windows PowerShell | Native wrapper uses the PowerShell call-operator route |
| Claude | Windows | No | `& ./dsi.ps1 ...` | `dsi.ps1`, Windows PowerShell, and PowerShell permission | Native PowerShell route |
| Codex | macOS | Yes | `bash ./dsi.sh ...` | Bash and Python 3 | Uses the local Unix-domain socket |
| Claude | macOS | Yes | `bash ./dsi.sh ...` | Bash, Python 3, and Bash permission | Uses the local Unix-domain socket |
| Codex | Linux | Yes | `bash ./dsi.sh ...` | Bash and Python 3 | Uses the local Unix-domain socket |
| Claude | Linux | Yes | `bash ./dsi.sh ...` | Bash, Python 3, and Bash permission | Uses the local Unix-domain socket |

## File roles

| File | Platform | Role |
|---|---|---|
| `dsi.sh` | Windows, macOS, Linux | Recommended shared launcher |
| `dsi.cmd` | Windows | Native wrapper that forwards arguments through `DSI_ARG_*` environment variables and invokes `dsi.ps1` with PowerShell's call operator |
| `dsi.ps1` | Windows | Native PowerShell implementation and fallback; accepts normal PowerShell arguments or the safe `DSI_ARG_*` forwarding used by the wrappers |

On Windows, `dsi.sh` uses Git Bash only as the entry shell. It forwards the original
arguments through `DSI_ARGC` and `DSI_ARG_<n>`, resolves the packaged `dsi.ps1`, then
starts Windows PowerShell noninteractively with the call operator. The Windows Bash
branch contains no PowerShell heredoc and performs no Bash filesystem writes, so it
does not depend on a writable working directory or temporary directory. It
communicates with `\\.\pipe\dsi-studio` through `dsi.ps1` and does not require
Python.

`dsi.cmd` uses the same forwarding format and deliberately does not interpolate user
arguments into PowerShell source. This preserves spaces, parentheses, quoted or
composite values, `-Chat`, and batched `--` commands without relying on
`powershell.exe -File` argument binding.

`dsi.ps1` reads and writes the named-pipe protocol as UTF-8 and sets PowerShell's
console output encoding to UTF-8 so non-ASCII DSI Studio responses survive the
Windows wrapper path.

On macOS and Linux, `dsi.sh` uses Python 3 to build the request and communicate with
the local Unix-domain socket.

## Command batching

A single launcher invocation normally sends one command object. When `--` is present,
the launcher instead sends an ordered command array using the same request protocol
already supported by DSI Studio:

```text
bash ./dsi.sh command1 args... -- command2 args... -- command3 args...
```

This is useful when later commands do not require the returned output of earlier
commands. If a later action depends on discovering an ID, filename, tract name,
window ID, status, or other value from an earlier reply, send a separate launcher
request, inspect the result, and then continue.

For voice tutorials, batching may alternate narration and actions when the next action
is already known:

```bash
bash ./dsi.sh voice "I will hide the image slices." -- set_param show_slice 0 \
  -- voice "I will now show the tract and white matter surface." \
  -- set_param show_tract 1 -- add_surface 0 25
```

Each `voice` remains a separate DSI Studio command within the batch. `-Chat`, when
present, remains one request-level message for the whole batch.

## Command-inventory notation

`DSI_STUDIO_AI_COMMAND_EXAMPLES_*.md` uses compact arrays such as:

```text
["set_slice",7]
```

These arrays describe command names and argument order; they are not executable
requests. Select the window once with `set_window`, then execute the same command
through the launcher:

```bash
bash ./dsi.sh set_window tracking<hex-address>
bash ./dsi.sh set_slice 7
```

The selection persists for the session until changed by another `set_window` call;
it does not need to be repeated before every command. Commands that can be determined
in advance may instead be grouped with `--` as described above.

## Agent configuration

### Claude

Allow both supported command prefixes:

```cpp
"--allowedTools","Bash(bash ./dsi.sh:*),PowerShell(./dsi.ps1:*),WebFetch,WebSearch,Read,Glob,Grep",
```

Use the Bash route when Bash is available:

```bash
bash ./dsi.sh ...
```

When Bash is unavailable, enable Claude's PowerShell tool and invoke the script with
PowerShell's call operator:

```powershell
& ./dsi.ps1 ...
```

A bare `./dsi.sh ...` command does not match the Bash permission rule. The
PowerShell rule intentionally targets `dsi.ps1` directly rather than the `dsi.cmd`
wrapper.

### Codex

Codex does not use Claude's `--allowedTools` option. On Windows, make Git Bash
available on `PATH` when using the recommended Bash route. A common location is:

```text
C:\Program Files\Git\bin
```

When Bash is unavailable or blocked, use the native wrapper:

```powershell
./dsi ...
```

## Windows launcher smoke test

`.github/scripts/test_launcher_windows.ps1` and the `Launcher smoke` workflow guard
the Windows launcher contract. The test uses a local named-pipe server and checks:

- launcher files located under a path containing spaces and parentheses;
- a read-only launcher working directory and read-only `TEMP`/`TMP`/`TMPDIR`;
- the Git Bash `dsi.sh` route without a Windows PowerShell heredoc;
- the native `dsi.cmd` route without `powershell.exe -File`;
- the tested PowerShell call-operator fallback;
- quoted/composite parameters, numeric conversion, `-Chat`, and batched `--` commands;
- UTF-8 request and response text, including non-ASCII characters.

The test also contains a regression guard for the reported constrained-language
launcher problem: `dsi.cmd` must continue using `-Command` plus the call operator and
must not return to `-File`. It does not claim that an unsigned script can bypass an
enterprise WDAC/AppLocker policy. Under a real system-enforced `ConstrainedLanguage`
policy, PowerShell restricts arbitrary .NET type construction and method calls; if
the policy blocks `NamedPipeClientStream`, DSI Studio cannot bypass that security
policy from the launcher. The script must instead be allowed/trusted by the system
policy or run through an approved environment.

## Troubleshooting

### `bash` is not found

On Windows, install Git for Windows or add its `bin` directory to the agent process
`PATH`. Until then, Codex can use:

```powershell
./dsi ...
```

Claude can use:

```powershell
& ./dsi.ps1 ...
```

### The PowerShell tool is unavailable to Claude

Enable it with `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` before launching Claude Code. On
native Windows without Git Bash, Claude Code may enable the PowerShell tool
automatically, but explicitly enabling it makes the fallback deterministic.

### `dsi.sh requires Python 3 on macOS/Linux`

Install Python 3 or use a platform-specific native launcher. Python is not required
by the Windows branch.

### Bash reports permission errors for `/tmp` or the working directory

Older packaged versions of `dsi.sh` embedded the Windows PowerShell implementation
inside a Bash heredoc. Git Bash may materialize a heredoc through a temporary file,
which can fail in a read-only sandbox.

Use the current `dsi.sh`. Its Windows branch forwards arguments through environment
variables and invokes the packaged `dsi.ps1`; it contains no PowerShell heredoc and
performs no Bash filesystem writes.

### `powershell.exe -File dsi.ps1` reports a language-mode or argument-binding error

Do not use the `-File` route. The packaged `dsi.cmd` already uses the tested
call-operator form with environment-variable argument forwarding:

```powershell
./dsi list_window
```

If invoking Windows PowerShell yourself, use:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& './dsi.ps1' list_window"
```

If a system-enforced WDAC/AppLocker policy still rejects operations inside
`dsi.ps1`, that is a real PowerShell policy restriction rather than a launcher
quoting problem; the launcher cannot override it.

### PowerShell displays interactive `>>` prompts

Use the current `dsi.sh` or `dsi.cmd`. Both invoke one noninteractive `-Command`
call-operator request and do not use `-File -` or inline heredoc PowerShell.

### The Bash route still fails on Windows

Use the native fallback:

```powershell
./dsi list_window
```

This runs:

```text
dsi.cmd -> PowerShell -Command -> dsi.ps1 -> \\.\pipe\dsi-studio
```

For Claude's PowerShell tool, call the implementation directly:

```powershell
& ./dsi.ps1 list_window
```

### Unicode output is garbled on Windows

Use the current `dsi.ps1`, `dsi.cmd`, or Windows branch of `dsi.sh`. The PowerShell
implementation explicitly decodes the named-pipe response as UTF-8 and sets console
output to UTF-8. If an outer terminal still displays mojibake, verify that the host
captures UTF-8 rather than re-decoding the child process output with an OEM code page.

### Missing session environment

The process environment must contain at least one of:

```text
CLAUDE_CODE_SESSION_ID
CODEX_THREAD_ID
```

Claude Code normally supplies `CLAUDE_CODE_SESSION_ID` to its Bash and PowerShell
tool subprocesses. Codex supplies `CODEX_THREAD_ID`. The launchers derive the agent
name from the variable found and intentionally do not accept either value as a
command-line argument.
