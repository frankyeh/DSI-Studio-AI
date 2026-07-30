# DSI Studio AI Launcher

Use the Bash launcher whenever Bash is available:

```bash
bash ./dsi.sh <TITLE|CHAT|LIST|LOG|window-id> [command/values...]
```

Always include `bash` before `./dsi.sh`. Do not invoke `./dsi.sh` directly.

All launchers read the agent and session from these environment variables supplied by DSI Studio:

```text
DSI_STUDIO_AGENT
CODEX_THREAD_ID
```

Do not pass the agent name or session ID on the command line.

## Common syntax

```bash
bash ./dsi.sh TITLE "Fiber tracking"
bash ./dsi.sh CHAT "Reading the DSI Studio instructions."
bash ./dsi.sh LIST
bash ./dsi.sh main list_recent_fib
bash ./dsi.sh tracking<hex-address> set_slice 7
```

The Windows fallback accepts the same arguments:

```powershell
./dsi TITLE "Fiber tracking"
./dsi CHAT "Reading the DSI Studio instructions."
./dsi LIST
./dsi main list_recent_fib
./dsi tracking<hex-address> set_slice 7
```

## Launcher selection

| Agent | OS | Bash available | Recommended launcher | Requirements | Notes |
|---|---|---:|---|---|---|
| Codex | Windows | Yes | `bash ./dsi.sh ...` | Git Bash and Windows PowerShell | Shared recommended route; Python is not required |
| Claude | Windows | Yes | `bash ./dsi.sh ...` | Git Bash, Windows PowerShell, and Bash permission | Shared recommended route; Python is not required |
| Codex | Windows | No | `./dsi ...` | `dsi.cmd`, `dsi.ps1`, and Windows PowerShell | Native Windows fallback |
| Claude | Windows | No | `./dsi ...` | `dsi.cmd`, `dsi.ps1`, Windows PowerShell, and permission to run it | Native Windows fallback |
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

On Windows, `dsi.sh` uses Git Bash only as the entry shell. It then calls Windows PowerShell noninteractively and communicates with `\\.\pipe\dsi-studio`. It does not require Python or temporary files.

On macOS and Linux, `dsi.sh` uses Python 3 to build the request and communicate with the local Unix-domain socket.

## Agent configuration

### Claude

Allow the exact recommended command prefix:

```cpp
"--allowedTools","Bash(bash ./dsi.sh:*)",
```

Claude must therefore call:

```bash
bash ./dsi.sh ...
```

A bare `./dsi.sh ...` command does not match that permission rule.

### Codex

Codex does not use Claude's `--allowedTools` option. On Windows, make Git Bash available on `PATH` when using the recommended Bash route. A common location is:

```text
C:\Program Files\Git\bin
```

When Bash is unavailable or blocked, use the native fallback:

```powershell
./dsi ...
```

## Troubleshooting

### `bash` is not found

On Windows, install Git for Windows or add its `bin` directory to the agent process `PATH`. Until then, use:

```powershell
./dsi ...
```

### `dsi.sh requires Python 3 on macOS/Linux`

Install Python 3 or use a platform-specific native launcher. Python is not required by the Windows branch.

### Bash reports permission errors for `/tmp` or the working directory

Use the current `dsi.sh`. Its Windows branch creates no temporary files and performs no Bash filesystem writes. Confirm that the packaged file is the latest version.

### PowerShell displays interactive `>>` prompts

Use the current `dsi.sh`. Its Windows branch uses one noninteractive `-Command` invocation rather than `-File -`.

### The Bash route still fails on Windows

Use the native fallback:

```powershell
./dsi LIST
```

This runs:

```text
dsi.cmd -> dsi.ps1 -> \\.\pipe\dsi-studio
```

### Missing agent or session

DSI Studio must place both values in the child process environment:

```text
DSI_STUDIO_AGENT
CODEX_THREAD_ID
```

The launchers intentionally do not accept these values as command-line arguments.
