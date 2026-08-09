# DSI Studio AI Shared Window Commands

`bring_to_front`, `minimize`, `maximize`, and `close` are shared AI dispatcher
commands. They are handled centrally by `MainWindow::dispatch_cmd()` before the
normal MainWindow-first and selected-window command routing. They are not separate
implementations in reconstruction, tracking, image, or connectometry command handlers.

## Select the target window

Each AI session starts with `main` selected. `set_window` changes the persistent
target used by shared and later window-specific commands. Successful `open_src`,
`open_fib`, `open_image`, and `open_connectometry` also replace it with the newly
created window.

`set_window` requires an exact current ID (or `main`) — there is no bare-type-plus-filename
form. Get the exact ID from `list_window`, or from a successful `open_src`/`open_fib`/
`open_image`/`open_connectometry` (which also becomes the new target automatically,
without needing a follow-up `set_window` call):

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
- `image<hex-address>`;
- `connectometry<hex-address>` (the Correlational Tractography dialog; see
  `DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md`).

`set_window main`, or `set_window` without a parameter, returns to `main`. Any other
value must be an exact ID currently listed by `list_window`; an unrecognized value
(including a bare type name like `tracking` with no hex address) fails with
`set_window: window "<value>" not found, terminated by user?`.

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
exist. Reconstruction, standalone image, and connectometry windows are also closed
directly.

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

## `list_window` response shape

`list_window` takes no parameter and returns its result in `output` as a JSON object:

```json
{
  "application":{"status":"busy"},
  "current_window":"tracking7ff6ab123410",
  "progress":[
    {"status":"convert DICOM to SRC or nifti files","now":3,"total":12,"at":"(3/12) 2 min"},
    {"status":"processing DICOM at C:/data/subj03","now":0,"total":0,"at":""}
  ],
  "windows":{
    "main":{"status":"idle","title":""},
    "tracking7ff6ab123410":{"status":"busy","title":"subject.fz"}
  }
}
```

- `application.status` is `"idle"`, `"busy"`, or `"waiting"` (a modal dialog, such as
  `run_shell`'s confirmation prompt, is open somewhere in the application).
- `current_window` is the session's own persistent target (the same value `set_window`
  reports), independent of any other window's status.
- `windows` lists every AI-addressable window (`main`, `tracking...`, `recon...`,
  `image...`, `connectometry...`) plus any in-flight asynchronous `curlN` task,
  each with its own `status` (`idle`/`busy`/`waiting`) and `title`. A
  `connectometry...` window stays `busy` for the full duration of an
  asynchronous `run` (permutation test), not just for the instant the command
  was dispatched. For percent-complete during a long run, use that window's
  own `progress` session command (`not_started`, or
  `<running|finished|stopped>\t<percent>` -- `stopped` covers both this
  session's own `stop` command and a local user's own Stop click) rather
  than `list_window`, which only ever reports coarse `idle`/`busy`/
  `waiting`. See
  `DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md` for details, including
  that an AI-initiated run suppresses the local completion popup.
- `progress` reflects every currently active internal operation, outermost first,
  regardless of which window (if any) it belongs to. Each entry's `status` is the
  operation's name, `now`/`total` are its step counters, and `at` is a pre-formatted
  `"(now/total) N min"` string with a remaining-time estimate once one is available.
  An operation that never reports intermediate steps stays at `now:0, total:0` until
  it finishes — `progress` reflects whatever granularity the running operation itself
  reports, not a guarantee of step-level detail for every command. `progress` is an
  empty array when nothing is running.
- Poll `list_window` to watch a long-running command (`run_cli`, DICOM conversion,
  NIfTI-to-SRC batches, etc.) without waiting for its final reply, the same way an
  active `curlN` task is already tracked in `windows`.

## Window close versus GitHub-channel close

These two operations use the word `close` but affect different things:

```json
{"command":{"cmd":"close"}}
```

closes the currently selected DSI Studio reconstruction, tracking, image, or
connectometry window. It does not disconnect ChatGPT (Web).

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
   reconstruction, tracking, image, or connectometry window.

Global MainWindow commands such as `voice`, `run_cli`, `run_shell`, and `open_fib`
remain available even while a non-main window is selected. `run_cli` and `run_shell`
do not act on the selected window: `run_cli` invokes its own internal CLI action
logic, while `run_shell` runs any shell command after local-user confirmation
(`cd` alone needs no confirmation). Read `DSI_STUDIO_AI_CLI_SHELL_COMMANDS.md` for
their exact behavior.

The four shared window controls are different: they always act on the selected
target before ordinary MainWindow-first routing begins.
