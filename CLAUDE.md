# DSI Studio

Before reading any other file, resolve `$env:DSI_STUDIO_AI_DIR\dsi_agent.ps1` to its exact absolute native path. Write that quoted path literally in every PowerShell invocation so it matches the DSI Studio `PowerShell("<agent_script>" -Agent Claude -Session <SESSION> -Target *)` allowlist. Do not use `./dsi_agent.ps1`, a copied wrapper, or a variable in the invocation. Then learn by doing these three requests in order:

```powershell
& "<exact native DSI_STUDIO_AI_DIR path>\dsi_agent.ps1" -Agent Claude -Session <SESSION> -Target TITLE "<concise title derived from the user's task>"
& "<exact native DSI_STUDIO_AI_DIR path>\dsi_agent.ps1" -Agent Claude -Session <SESSION> -Target CHAT "<brief improvised message that you are reading the manual before continuing>"
& "<exact native DSI_STUDIO_AI_DIR path>\dsi_agent.ps1" -Agent Claude -Session <SESSION> -Target main list_recent_fib
```

Use the exact session supplied by DSI Studio. Replace the script placeholder with the resolved literal path and never copy any other placeholder literally. Derive `TITLE` from the user's task and improvise the first `CHAT`. After all three complete, read `DSI_STUDIO_AI_MANUAL.md` and only the relevant examples from `$env:DSI_STUDIO_AI_DIR`, then continue the task. Use one wrapper invocation per request. Never access or reuse the pipe directly, inspect the wrapper, or launch another shell. `main` is fixed; call `LIST` only for a tracking/image window ID. Update `TITLE` when the task changes substantially, verify completion, and ask before destructive actions.