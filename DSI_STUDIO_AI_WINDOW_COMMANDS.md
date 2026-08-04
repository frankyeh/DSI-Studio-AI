# DSI Studio AI Shared Window Commands

`bring_to_front`, `minimize`, `maximize`, and `close` are shared AI dispatcher
commands. They are handled centrally by `MainWindow::dispatch_cmd()` before the
normal MainWindow-first and selected-window command routing. They are not separate
implementations in reconstruction, tracking, or image command handlers.

## Select the target window

Each AI session starts with `main` selected. `set_window` changes the persistent
target used by these shared commands and by later window-specific commands.

Use an exact current ID whenever possible:

```bash
bash ./dsi.sh set_window tracking7ff6ab123410
```

The ChatGPT (Web) issue equivalent is:

```json
{"cmd":"set_window","param":"tracking7ff6ab123410"}
```

Supported targets are:

- `main`;
- `recon<hex-address>`;
- `tracking<hex-address>`;
- `image<hex-address>`.

`set_window main`, or `set_window` without a parameter, returns to `main`.
`set_window` also accepts a bare non-main type plus a distinctive filename, but an
exact ID returned by `open_src`, `open_fib`, `open_image`, or `list_window` is safer.

## Shared controls

All four commands take no parameter. Do not add a dummy value.

| Command | Exact behavior |
|---|---|
| `bring_to_front` | Calls `showNormal()`, then raises and activates the selected window. This restores a minimized or maximized window to its normal state before bringing it forward. |
| `minimize` | Calls `showMinimized()` on the selected window. |
| `maximize` | Calls `showMaximized()` on the selected window. |
| `close` | Calls `close()` on the selected non-main window. AI is not allowed to close `main`; that request fails with `the main window cannot be closed by AI`. |

Launcher examples:

```bash
bash ./dsi.sh bring_to_front
bash ./dsi.sh minimize
bash ./dsi.sh maximize
bash ./dsi.sh close
```

ChatGPT (Web) issue examples:

```json
{"command":{"cmd":"bring_to_front"}}
{"command":{"cmd":"minimize"}}
{"command":{"cmd":"maximize"}}
{"command":{"cmd":"close"}}
```

Each issue request still needs its normal higher `id` and session UUID.

## Closing a window safely

`close` is destructive to the selected window and should normally be the final
command in a command array.

For a tracking window, an AI-issued close is non-spontaneous and bypasses the local
`Tractography not saved` prompt. Confirm before closing whenever unsaved tracts may
exist. Reconstruction and standalone image windows are also closed directly.

The dispatcher reports command success after issuing the close operation. Confirm
the result with `list_window` when the disappearance matters.

Closing a window does **not** reset the session's selected-window value. The session
still remembers the now-invalid ID. After closing, explicitly select another target:

```bash
bash ./dsi.sh set_window main
```

or:

```bash
bash ./dsi.sh set_window <another-current-window-ID>
```

Until that is done, a later window-specific command can fail with:

```text
target window not found, terminated by user? Use set_window to select a window first.
```

`list_window`, `set_window`, and other dispatcher-level discovery commands remain
available for recovery.

## Busy-window behavior

The dispatcher resolves and temporarily locks the selected target for these
commands. If another AI command currently has a supported window locked, the control
request can fail with:

```text
another CMD is running; check opened windows
```

Inspect `list_window` and retry only after the active command is finished. Do not
assume a timeout means the earlier operation stopped.

## Window close versus GitHub-channel close

These two operations use the word `close` but affect different things:

```json
{"command":{"cmd":"close"}}
```

closes the currently selected DSI Studio reconstruction, tracking, or image window.
It does not disconnect ChatGPT (Web).

```json
{"id":7,"request":"close"}
```

is the GitHub issue-channel remote-close envelope. It disconnects the issue channel
after publishing `state:"closed"`. It does not close a DSI Studio data window, the
main DSI Studio application, or the GitHub issue.

Never substitute one form for the other.

## Routing order

For each command in a request, the current dispatcher applies this order:

1. Shared window controls: `bring_to_front`, `minimize`, `maximize`, `close`.
2. Session commands: `set_title`, `log`, and `set_window`.
3. Window discovery: `list_window`.
4. All remaining commands are offered to `MainWindow` first.
5. Only a command unknown to `MainWindow` falls through to the persistently selected
   reconstruction, tracking, or image window.

Global MainWindow commands such as `voice`, `run_cli`, `run_shell`, and `open_fib`
remain available even while a non-main window is selected. `run_cli` and `run_shell`
do not act on the selected window: `run_cli` invokes its own internal CLI action
logic, while `run_shell` performs only its restricted `cd`, `dir`, or `curl`
operation. Read `DSI_STUDIO_AI_CLI_SHELL_COMMANDS.md` for their exact behavior.

The four shared window controls are different: they always act on the selected
target before ordinary MainWindow-first routing begins.
