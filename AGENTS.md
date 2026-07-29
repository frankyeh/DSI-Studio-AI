# DSI Studio

Read `DSI_STUDIO_AI_SETUP.md` first. DSI Studio starts Codex in this DSI Studio AI directory, where `dsi_agent.ps1` is located, and adds the user-selected project directory separately for project access. Windows may block PowerShell scripts, so apply a process-scoped bypass in each wrapper invocation; this does not change user or system policy. Then learn by doing these three requests in order:

```powershell
$session = $env:CODEX_THREAD_ID
Set-ExecutionPolicy -Scope Process Bypass -Force; ./dsi_agent.ps1 -Agent Codex -Session $session -Target TITLE "<concise title derived from the user's task>"
Set-ExecutionPolicy -Scope Process Bypass -Force; ./dsi_agent.ps1 -Agent Codex -Session $session -Target CHAT "<brief improvised message that you are reading the manual before continuing>"
Set-ExecutionPolicy -Scope Process Bypass -Force; ./dsi_agent.ps1 -Agent Codex -Session $session -Target main list_recent_fib
```

Derive `TITLE` from the user's task and improvise the first `CHAT`; never copy either placeholder literally. After all three complete, read `DSI_STUDIO_AI_MANUAL.md` and only the relevant examples from this directory, then continue the task using the added project directory for user files. Prefix every wrapper request with `Set-ExecutionPolicy -Scope Process Bypass -Force;`, use one invocation per request, and never search for the session, access or reuse the pipe directly, inspect the wrapper, or launch another shell. `main` is fixed; call `LIST` only for a tracking/image window ID. Update `TITLE` when the task changes substantially, verify completion, and ask before destructive actions.