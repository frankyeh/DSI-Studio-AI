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

The Web agent equivalent is:

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

Web agent examples:

```json
{"command":{"cmd":"bring_to_front"}}
{"command":{"cmd":"minimize"}}
{"command":{"cmd":"maximize"}}
{"command":{"cmd":"close"}}
```

Each Web request still needs its normal higher `id` and session UUID.

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

Shared `bring_to_front`, `minimize`, `maximize`, and `close` act on the selected
window even while `list_window` reports it as `busy` with background work.

Use `list_window` to inspect state before a destructive `close`; a busy status does
not imply that the shared control will be rejected.

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

## Tutor commands: show the user where to click

`list_ui`, `highlight_ui`, and `clear_highlight` teach a local user. They act on the
selected window but never click, trigger, or change anything except the visible
accent, and they are not recorded in the command history. Use them when the user
asks how to do something in the GUI; use ordinary commands when the user asks you to
do it.

| Command | Exact behavior |
|---|---|
| `list_ui [filter]` | Lists visible controls of the selected window as `{"total":N,"controls":[{"id","kind","label"}]}`, at most 50 entries; `total` counts all matches. `filter` is a case-insensitive substring of `id` or `label`. |
| `highlight_ui <id> [caption] [gesture]` | Draws an orange ring around the one visible control named `id`, with an optional caption (120 characters at most). `gesture` animates a demonstration once, about 2 s, and stops when the user presses the mouse: `drag`, `shift` (Shift + drag), `freehand`, or `rect`. Replaces any earlier highlight. |
| `clear_highlight` | Removes the highlight. Returns `cleared` or `nothing to clear`. |

`kind` in `list_ui` is:

- `button` or `disabled button`: a visible button, by objectName;
- `view`: the 3D view `GLWidget` or the 2D slice view `graphicsView`, the targets for
  gestures;
- `option`: an entry of the tracking window's Options tree, by option id, with its
  tree path as `label` (for example `Tract Rendering > Tube Diameter (voxel)`);
- `menu`: a menu action, by objectName, with its menu path as `label`.

`highlight_ui` results:

- a button or view: `highlighted: <id>`;
- an option: the tree expands to it, its editor is ringed, and the output is
  `option: <tree path>`;
- a menu action: nothing is drawn; the output is `menu: <menu path>`, for example
  `menu: Tracts > Save Tracts As...`. Tell the user that path.

Failures: `control not found or not visible`, `ambiguous control`,
`control is disabled`, and `a dialog is open; ask the user to close it first` (all
three tutor commands except `clear_highlight` refuse while a modal dialog is open).

Teach one step at a time: highlight, say what to do, and wait for the user before
the next step. For example, to teach tract selection in a tracking window:

```json
{"command":{"cmd":"highlight_ui","param":"actionSelect_Tracts"}}
{"command":{"cmd":"highlight_ui","param":["GLWidget","Drag across the tracts","drag"]}}
```

Send the second request only after the user has chosen Select Tracts (Ctrl+S). The
launcher form is `bash ./dsi.sh highlight_ui GLWidget "Drag across the tracts" drag`. Each
gesture follows the GUI's own behavior:

- tract editing (`GLWidget`): choose Select, Delete, Cut, or Paint Tracts first, then
  `drag` a line across the tracts; `shift` adds bend points while dragging. Undo
  (Ctrl+Z) reverts the last edit of every checked bundle.
- region drawing (`graphicsView`): `tool0` rectangle (`rect`), `tool1` freehand
  (`freehand`), `tool2` sphere and `tool3` cube (`drag` out from the center), `tool4`
  polygon (click each corner, double-click to close). Right-click or Shift erases.
  Undo Edit (Ctrl+Shift+Z) reverts the last region edit.

The main window's **Tutorial...** button runs the same walkthroughs locally without
an agent.

## Routing order

For each command in a request, the current dispatcher applies this order:

1. Shared window controls: `bring_to_front`, `minimize`, `maximize`, `close`.
2. Session commands: `set_title`, `log`, and `set_window`.
3. Window discovery and tutoring: `list_window`, `list_ui`, `highlight_ui`, and
   `clear_highlight`.
4. Read-only system commands: `get_agent_settings` and `get_chat` (also in headless mode).
5. All remaining commands are offered to `MainWindow` first.
6. Only a command unknown to `MainWindow` falls through to the persistently selected
   reconstruction, tracking, image, or connectometry window.

Global MainWindow commands such as `voice`, `run_cli`, `run_shell`, and `open_fib`
remain available even while a non-main window is selected. `run_cli` and `run_shell`
do not act on the selected window: `run_cli` invokes its own internal CLI action
logic, while `run_shell` runs any shell command after local-user confirmation
. Read `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md` for
their exact behavior.

The four shared window controls are different: they always act on the selected
target before ordinary MainWindow-first routing begins.
