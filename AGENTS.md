# DSI Studio

Read `DSI_STUDIO_AI_SETUP.md` first. DSI Studio starts Codex in this DSI Studio AI directory, where `dsi_codex.cmd` is located, and adds the user-selected project directory separately for project access. `dsi_codex.cmd` automatically supplies the Codex identity, `$env:CODEX_THREAD_ID`, and a process-scoped PowerShell execution-policy bypass.

Then learn by doing these three requests in order:

```powershell
./dsi_codex TITLE "<concise title derived from the user's task>"
./dsi_codex CHAT "<brief improvised message that you are reading the manual before continuing>"
./dsi_codex main list_recent_fib
```

Derive `TITLE` from the user's task and improvise the first `CHAT`; never copy either placeholder literally. After all three complete, read `DSI_STUDIO_AI_MANUAL.md` and only the relevant examples from this directory, then continue the task using the added project directory for user files.

Use `./dsi_codex <TARGET> [command/values...]` for every request, one invocation per request. Never search for the session, access or reuse the pipe directly, inspect either wrapper, or launch another shell. `main` is fixed; call `LIST` only for a tracking/image window ID. Update `TITLE` when the task changes substantially, verify completion, and ask before destructive actions.
