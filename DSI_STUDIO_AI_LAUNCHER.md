# DSI Studio AI Launcher

Use the Bash launcher whenever Bash is available:

```bash
bash ./dsi.sh <command> [values...]
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

```bash
bash ./dsi.sh set_title "Fiber tracking"
bash ./dsi.sh -Chat "Reading the DSI Studio instructions."
bash ./dsi.sh list_window
bash ./dsi.sh list_recent_fib
bash ./dsi.sh set_window tracking<hex-address>
bash ./dsi.sh set_slice 7
```

The Windows wrapper accepts the same arguments:

```powershell
./dsi set_title "Fiber tracking"
./dsi -Chat "Reading the DSI Studio instructions."
./dsi list_window
./dsi list_recent_fib
./dsi set_window tracking<hex-address>
./dsi set_slice 7
```

Claude may call the PowerShell implementation directly when Bash is unavailable:

```powershell
./dsi.ps1 set_title "Fiber tracking"
./dsi.ps1 list_window
./dsi.ps1 list_recent_fib
```

## Launcher selection

| Agent | OS | Bash available | Recommended launcher | Requirements | Notes |
|---|---|---:|---|---|---|
| Codex | Windows | Yes | `bash ./dsi.sh ...` | Git Bash and Windows PowerShell | Shared recommended route; Python is not required |
| Claude | Windows | Yes | `bash ./dsi.sh ...` | Git Bash, Windows PowerShell, and Bash permission | Shared recommended route; Python is not required |
| Codex | Windows | No | `./dsi ...` | `dsi.cmd`, `dsi.ps1`, and Windows PowerShell | Native Windows wrapper |
| Claude | Windows | No | `./dsi.ps1 ...` | `dsi.ps1`, Windows PowerShell, and PowerShell permission | Native PowerShell route |
| Codex | macOS | Yes | `bash ./dsi.sh ...` | Bash and Python 3 | Uses the local Unix-domain socket |
| Claude | macOS | Yes | `bash ./dsi.sh ...` | Bash, Python 3, and Bash permission | Uses the local Unix-domain socket |
| Codex | Linux | Yes | `bash ./dsi.sh ...` | Bash and Python 3 | Uses the local Unix-domain socket |
| Claude | Linux | Yes | `bash ./dsi.sh ...` | Bash, Python 3, and Bash permission | Uses the local Unix-domain socket |

## File roles

| File | Platform | Role |
|---|---|---|
| `dsi.sh` | Windows, macOS, Linux | Recommended shared launcher |
| `dsi.cmd` | Windows | Short native command that forwards to `dsi.ps1` |
| `dsi.ps1` | Windows | Native PowerShell implementation and fallback |

On Windows, `dsi.sh` uses Git Bash only as the entry shell. It then calls Windows
PowerShell noninteractively and communicates with `\\.\pipe\dsi-studio`. It does
not require Python or temporary files.

On macOS and Linux, `dsi.sh` uses Python 3 to build the request and communicate with
the local Unix-domain socket.

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
it does not need to be repeated before every command.

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

When Bash is unavailable, enable Claude's PowerShell tool and use:

```powershell
./dsi.ps1 ...
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

## Troubleshooting

### `bash` is not found

On Windows, install Git for Windows or add its `bin` directory to the agent process
`PATH`. Until then, Codex can use:

```powershell
./dsi ...
```

Claude can use:

```powershell
./dsi.ps1 ...
```

### The PowerShell tool is unavailable to Claude

Enable it with `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` before launching Claude Code. On
native Windows without Git Bash, Claude Code may enable the PowerShell tool
automatically, but explicitly enabling it makes the fallback deterministic.

### `dsi.sh requires Python 3 on macOS/Linux`

Install Python 3 or use a platform-specific native launcher. Python is not required
by the Windows branch.

### Bash reports permission errors for `/tmp` or the working directory

Use the current `dsi.sh`. Its Windows branch creates no temporary files and performs
no Bash filesystem writes. Confirm that the packaged file is the latest version.

### PowerShell displays interactive `>>` prompts

Use the current `dsi.sh`. Its Windows branch uses one noninteractive `-Command`
invocation rather than `-File -`.

### The Bash route still fails on Windows

Use the native fallback:

```powershell
./dsi list_window
```

This runs:

```text
dsi.cmd -> dsi.ps1 -> \\.\pipe\dsi-studio
```

For Claude's PowerShell tool, call the implementation directly:

```powershell
./dsi.ps1 list_window
```

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