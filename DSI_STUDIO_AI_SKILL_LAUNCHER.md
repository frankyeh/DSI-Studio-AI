# DSI Studio AI Launcher

Use the Bash launcher whenever Bash is available, always with `bash` before `./dsi.sh` (never
`./dsi.sh` directly):

```bash
bash ./dsi.sh <command> [values...] [-- <command> [values...] ...] [-Chat "message"]
```

DSI Studio supplies `DSI_STUDIO_AGENT` and, in `DSI_STUDIO_SOCKET`, its own pipe to the agents it
launches, so the launcher always reaches that instance. The launcher uses `DSI_STUDIO_SESSION` when
set ("Parallel pipelines"); otherwise it reads only that agent's native session variable, supplied
to the agent's tool subprocesses:

```text
Codex       -> CODEX_THREAD_ID                 (supplied by Codex)
Claude      -> CLAUDE_CODE_SESSION_ID          (Claude Code, to its Bash and PowerShell tools)
Muse        -> MUSE_SESSION_ID                 (DSI Studio, the same UUID as its MSP session)
Antigravity -> ANTIGRAVITY_CONVERSATION_ID     (Antigravity)
Grok        -> GROK_SESSION_ID                 (Grok)
```

The launcher never infers the agent from whichever variables are present and never accepts an agent
name or session value on the command line.

## Syntax

```bash
bash ./dsi.sh set_title "Fiber tracking"
bash ./dsi.sh -Chat "Opening the subject's FIB file."
bash ./dsi.sh list_window
bash ./dsi.sh set_window tracking<hex-address>
bash ./dsi.sh set_slice 7
bash ./dsi.sh set_param show_slice 0 -- set_param show_tract 1 -- add_surface 0 25
bash ./dsi.sh voice "I will inspect the available tracts." -- list_auto_tract \
  -Chat "Starting a narrated tractography step."
```

- `--` separates commands into one ordered array (the same request protocol DSI Studio already
  supports), executed sequentially and stopped at the first failure. Batch only commands that do not
  need earlier replies; when a later command depends on a returned ID, filename, tract name, window
  ID, status, or other value, send separate requests and inspect each reply. Never put an empty
  command before, after, or between `--` separators.
- `-Chat` is a request-level option, not a command: one message for the whole single command or
  batch.
- Voice tutorials may alternate narration and known actions in a batch; each `voice` stays a separate
  command:

```bash
bash ./dsi.sh voice "I will hide the image slices." -- set_param show_slice 0 \
  -- voice "I will now show the tract and white matter surface." \
  -- set_param show_tract 1 -- add_surface 0 25
```

### Large text through stdin (`--stdin`)

Put the literal `--stdin` where a long string parameter (such as a script) goes; the launcher
replaces it with the whole stdin text (UTF-8) as one string:

```bash
bash ./dsi.sh write_text_file build_report.py --stdin <<'PY'
import json
print("quotes, $, %, !, &, |, <, >, backticks and indentation need no escaping")
PY
```

Quote the heredoc delimiter (`<<'PY'`) so Bash does not expand `$` or backticks. `--stdin` works for
any command and string parameter, also inside a `--` batch, at most once per request, and is always a
string, never a number. Without it the launcher never reads stdin; the request DSI Studio receives is
the same either way.

### Windows native forms

```powershell
./dsi list_window
./dsi set_param show_slice 0 -- set_param show_tract 1 -- add_surface 0 25
& ./dsi.ps1 list_window
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& './dsi.ps1' list_window"
```

`./dsi` (`dsi.cmd`) and `& ./dsi.ps1` accept the same arguments as `dsi.sh`. When starting Windows
PowerShell explicitly, use the call operator as above, never `-File`.

### Command-inventory notation

`DSI_STUDIO_AI_COMMAND_EXAMPLES_*.md` writes commands as compact arrays such as `["set_slice",7]`,
describing name and argument order, not executable requests. Select the window once with
`set_window` (it persists until changed), then run `bash ./dsi.sh set_slice 7`.

## External agent sessions

An agent started outside DSI Studio has no DSI Studio chat, so commands return `session not found`.
Only when the user explicitly asks to connect this session, set `DSI_STUDIO_AGENT` to the agent name
(DSI Studio sets it only for agents it launches) and run, alone without other commands, values, or
`-Chat`:

```bash
bash ./dsi.sh new_chat
```

It registers the agent's own session UUID as a new chat, or fails with `session already exists`.
Never run it automatically after `session not found`: a chat the user removed must stay removed.
With several DSI Studio instances open, also set `DSI_STUDIO_SOCKET` to the intended instance's pipe;
otherwise the launcher reaches the first instance started. `new_chat` with an agent name
(`new_chat claude`) instead creates a separate DSI-managed chat
(`DSI_STUDIO_AI_COMMAND_EXAMPLES_GENERAL.md`).

## Parallel pipelines (`DSI_STUDIO_SESSION`)

Each session has its own selected window and working directory, so pipelines running at the same
time (for example deterministic and probabilistic tracking) need different sessions, even on the
same instance and pipe; never share one. Give each a stable UUID of its own in `DSI_STUDIO_SESSION`
and register it once with `new_chat` before its first command:

```bash
export DSI_STUDIO_SESSION=$(python3 -c 'import os,sys,uuid;print(uuid.uuid5(uuid.NAMESPACE_URL,os.environ["CLAUDE_CODE_SESSION_ID"]+"/"+sys.argv[1]))' deterministic)
bash ./dsi.sh new_chat
bash ./dsi.sh open_fib "C:/data/sub-01.fz"
```

Use the agent's own session variable in place of `CLAUDE_CODE_SESSION_ID`; any stable, distinct UUID
works (on Windows, `New-Guid` once and reuse it).

## Launcher selection

| OS | Bash available | Launcher | Requirements |
|---|---|---|---|
| Windows | Yes | `bash ./dsi.sh ...` | Git Bash and Windows PowerShell (no Python); Claude also needs Bash permission |
| Windows | No | Codex: `./dsi ...`; Claude, Muse, Grok: `& ./dsi.ps1 ...` | `dsi.cmd` (Codex), `dsi.ps1`, and Windows PowerShell; Claude also needs PowerShell permission |
| macOS, Linux | Yes | `bash ./dsi.sh ...` | Bash and Python 3 (local Unix-domain socket); Claude also needs Bash permission |

Antigravity runs from the selected project directory, so it uses the absolute AI directory from its
startup prompt: `bash <AI-dir>/dsi.sh ...`, or on Windows without Bash `& <AI-dir>/dsi.ps1 ...`.

## File roles

| File | Platform | Role |
|---|---|---|
| `dsi.sh` | Windows, macOS, Linux | Recommended shared launcher |
| `dsi.cmd` | Windows | Native wrapper: forwards arguments through `DSI_ARG_*` environment variables and invokes `dsi.ps1` with PowerShell's call operator; stdin passes through for `--stdin` |
| `dsi.ps1` | Windows | Native PowerShell implementation and fallback; takes normal PowerShell arguments or the safe `DSI_ARG_*` forwarding |

- **Windows `dsi.sh`:** Git Bash is only the entry shell. It forwards the arguments through `DSI_ARGC`
  and `DSI_ARG_<n>`, resolves the packaged `dsi.ps1`, and starts Windows PowerShell noninteractively
  with the call operator. It has no PowerShell heredoc and no Bash filesystem writes, so it needs no
  writable working or temporary directory, and it reaches DSI Studio's named pipe through `dsi.ps1`
  without Python.
- **`dsi.cmd`** uses the same forwarding and never interpolates user arguments into PowerShell
  source, preserving spaces, parentheses, quoted or composite values, `-Chat`, and `--` batches
  without `powershell.exe -File` argument binding.
- **`dsi.ps1`** reads and writes the named-pipe protocol as UTF-8 and sets the console output encoding
  to UTF-8, so non-ASCII responses survive. It reads the caller's stdin directly; large text never
  travels through `DSI_ARG_*`.
- **macOS/Linux `dsi.sh`** uses Python 3 to build the request and talk to the Unix-domain socket; the
  embedded Python code comes on file descriptor 3, keeping stdin free for `--stdin`.

## Agent configuration

- **Claude:** allow both prefixes:

  ```cpp
  "--allowedTools","Bash(bash ./dsi.sh:*),PowerShell(./dsi.ps1:*),WebFetch,WebSearch,Read,Glob,Grep",
  ```

  A bare `./dsi.sh ...` does not match the Bash rule; the PowerShell rule targets `dsi.ps1`, not the
  `dsi.cmd` wrapper. Without Bash, enable the PowerShell tool with
  `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` before launching Claude Code (native Windows without Git Bash
  may enable it automatically; setting it makes the fallback deterministic).
- **Codex:** does not use `--allowedTools`. On Windows, put Git Bash on `PATH` (commonly
  `C:\Program Files\Git\bin`); otherwise use `./dsi ...`.
- **Muse:** started with `MUSE_SESSION_ID` equal to the MSP `session/start.sessionId`.
- **Antigravity:** exports its real conversation UUID as `ANTIGRAVITY_CONVERSATION_ID` to tool
  subprocesses; DSI Studio does not synthesize or override it.
- **Grok:** DSI Studio launches `grok agent --always-approve stdio` (Grok Build ACP) in this AI
  directory and passes the chat UUID as `session/new._meta.sessionId`; Grok exports it as
  `GROK_SESSION_ID` (Grok Build 1.0.4 or later). Sign in with `grok login`; usage is billed to that
  xAI account. Grok runs with always-approve, like Muse. Grok stores sessions by working directory, so
  a chat started from one DSI Studio install folder may not reopen from another; DSI Studio then
  reports the load failure instead of starting a new conversation.

### Local models through Ollama (Claude and Codex)

Claude and Codex can use a model served by Ollama on the same computer or another machine on a
trusted LAN. DSI Studio, the agent CLI, and `dsi.sh` stay on the client, which needs no Ollama binary.

Server (Ollama machine):

- Bind to the LAN, e.g. `OLLAMA_HOST=0.0.0.0:11434`, and restart. Allow TCP 11434 only from the DSI
  Studio workstation or subnet: Ollama has no authentication, so never expose it to the Internet.
- Use a tool-capable coding model (e.g. `qwen3-coder` or `gpt-oss` class) with a 64K context, e.g.
  `OLLAMA_CONTEXT_LENGTH=65536`; a short context truncates the system prompt and breaks tool use.
- Optional: `OLLAMA_KEEP_ALIVE=30m` avoids reloading the model per chat.
- Codex needs an Ollama release serving `/v1/responses`; a 404 for that path means update Ollama.

Client: AI Settings → Ollama connection → Host/IP and Port → Check connection.

| Check connection message | Meaning |
|---|---|
| `Connected · N models` | Ollama reached and models listed |
| `Connected · no models installed` | Ollama reached; pull a model on the server |
| `Reachable, but not an Ollama server` | Another service answers on that port |
| `No response within 10 s ...` | Server asleep, wrong address, or port blocked |
| `Unavailable: <error>` | Connection refused, DNS failure, or another network error |

Models then appear for both agents as `<model> (Ollama@<host>)` in New Chat, sharing one Host/IP and
Port. Claude connects to `http://<host>:<port>` (Anthropic-compatible API); Codex to
`http://<host>:<port>/v1` (Responses API) through a DSI Studio-supplied `-c` provider override,
leaving `~/.codex/config.toml` unchanged. Each chat keeps its creation server; changing Host/IP only
affects the list for new chats. DSI Studio adds the host to `NO_PROXY` for the agent process, so a
system proxy does not intercept LAN traffic. Check connection proves connectivity and model
discovery, not that the model handles the agent's system and tool protocol; some fail there (e.g.
`qwen3.8:27b` under Claude returns HTTP 500 "System message must be at the beginning"), so choose
another model when such an error appears.

## Windows launcher smoke test

`.github/scripts/test_launcher_windows.ps1` and the `Launcher smoke` workflow guard the Windows
launcher contract against a local named-pipe server. They check launcher files under a path with
spaces and parentheses; a read-only working directory and read-only `TEMP`/`TMP`/`TMPDIR`; the Git
Bash `dsi.sh` route without a PowerShell heredoc; the `dsi.cmd` route without `powershell.exe -File`;
the PowerShell call-operator fallback; quoted/composite parameters, numeric conversion, `-Chat`, and
`--` batches; and UTF-8 text with non-ASCII characters. A regression guard for the constrained-language
problem requires `dsi.cmd` to keep `-Command` with the call operator and never return to `-File`. The
test does not claim an unsigned script can bypass an enterprise WDAC/AppLocker policy: under a real
system-enforced `ConstrainedLanguage` policy, PowerShell restricts arbitrary .NET type construction
and method calls, and if it blocks `NamedPipeClientStream`, the launcher cannot bypass it; the script
must be allowed/trusted by the policy or run in an approved environment.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `bash` is not found (Windows) | Install Git for Windows or add its `bin` to the agent's `PATH`. Meanwhile Codex uses `./dsi ...`; Claude and Muse use `& ./dsi.ps1 ...`. |
| Claude has no PowerShell tool | Set `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` before launching Claude Code. |
| `dsi.sh requires Python 3 on macOS/Linux` | Install Python 3 or use a platform-specific native launcher; the Windows branch needs no Python. |
| Bash permission errors for `/tmp` or the working directory | Older `dsi.sh` embedded PowerShell in a Bash heredoc, which Git Bash may write to a temporary file, failing in a read-only sandbox. Use the current `dsi.sh`. |
| `powershell.exe -File dsi.ps1` language-mode or argument-binding error | Never use `-File`; use `./dsi list_window` or the `-Command "& './dsi.ps1' ..."` form. If a system WDAC/AppLocker policy still rejects operations inside `dsi.ps1`, that is a real policy restriction the launcher cannot override. |
| PowerShell shows interactive `>>` prompts | Use the current `dsi.sh` or `dsi.cmd`: one noninteractive `-Command` call, no `-File -` or inline heredoc. |
| The Bash route still fails on Windows | Use `./dsi list_window` (`dsi.cmd -> PowerShell -Command -> dsi.ps1 -> \\.\pipe\dsi-studio`), or for Claude's PowerShell tool `& ./dsi.ps1 list_window`. |
| Garbled Unicode on Windows | Use the current `dsi.ps1`, `dsi.cmd`, or `dsi.sh` (UTF-8 decoding and console output). If the outer terminal still shows mojibake, check that the host captures UTF-8 instead of re-decoding with an OEM code page. |
| Missing session environment | The process needs `DSI_STUDIO_AGENT` and the agent's native session variable (table at the top); session values are never accepted as arguments. |
