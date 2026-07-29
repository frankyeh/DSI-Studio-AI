# DSI Studio

Read `DSI_STUDIO_AI_SETUP.md` first. DSI Studio starts Claude in this DSI Studio AI directory, where `dsi.cmd` is located, and adds the user-selected project directory separately for project access. DSI Studio supplies `DSI_STUDIO_AGENT` and `CODEX_THREAD_ID`; `dsi.cmd` supplies them to the relay and applies a process-scoped PowerShell execution-policy bypass.

Then learn by doing these three requests in order:

```powershell
./dsi TITLE "<concise title derived from the user's task>"
./dsi CHAT "<brief improvised message that you are reading the manual before continuing>"
./dsi main list_recent_fib
```

Derive `TITLE` from the user's task and improvise the first `CHAT`; never copy either placeholder literally. After all three complete, read `DSI_STUDIO_AI_MANUAL.md` and only the relevant examples from this directory, then continue the task using the added project directory for user files.

Use `./dsi <TARGET> [command/values...]` for every request, one invocation per request. Never search for the agent or session, access or reuse the pipe directly, inspect either wrapper, or launch another shell. `main` is fixed; call `LIST` only for a tracking/image window ID. Update `TITLE` when the task changes substantially, verify completion, and ask before destructive actions.
