# DSI Studio AI Shared Window Commands

`bring_to_front`, `minimize`, `maximize`, `move_window`, and `close` are shared AI dispatcher
commands, handled centrally by `MainWindow::dispatch_cmd()` before MainWindow-first and
selected-window routing, not by the reconstruction, tracking, image, or connectometry handlers.

## Select the target window

Each AI session starts with `main` selected. `set_window` changes the persistent target used by
shared and window-specific commands; a successful `open_src`, `open_fib`, `open_image`, or
`open_connectometry` replaces it with the new window, with no follow-up `set_window` needed.

```bash
bash ./dsi.sh set_window tracking7ff6ab123410
```

Web: `{"cmd":"set_window","param":"tracking7ff6ab123410"}`. Targets:

- `main`;
- `recon<hex-address>`, `tracking<hex-address>`, `image<hex-address>`;
- `connectometry<hex-address>` (the Correlational Tractography dialog; see
  `DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md`);
- `window<hex-address>`: any other visible window, such as the Fiber Data Hub, a result table, or a
  dialog. Only the shared controls and tutor commands act on it; other commands fail with
  `unknown command`.

`set_window main`, or `set_window` with no parameter, returns to `main`. Any other value must be an
exact ID currently listed by `list_window` or returned by an open command; there is no
bare-type-plus-filename form, and an unrecognized value (including a bare type such as `tracking`)
fails with `set_window: window "<value>" not found, terminated by user?`.

## Shared controls

`move_window` takes positions; the others take no parameter (do not add a dummy value). All act on
the selected window even while `list_window` reports it `busy`.

| Command | Exact behavior |
|---|---|
| `bring_to_front` | `showNormal()`, then raise and activate: restores a minimized or maximized window before bringing it forward. |
| `minimize` | `showMinimized()`. |
| `maximize` | `showMaximized()`. |
| `move_window <x> <y> [width] [height]` | Restores normal state, moves the top-left corner to screen position `x`,`y`, and optionally resizes, in the pixels `list_window` reports as `geometry`. |
| `close` | `close()` on the selected non-main window; for `main` it fails with `the main window cannot be closed by AI`. Closing a dialog cancels it, so do not close one the user is still answering. |

```bash
bash ./dsi.sh bring_to_front
bash ./dsi.sh minimize
bash ./dsi.sh maximize
bash ./dsi.sh close
```

Web: `{"command":{"cmd":"bring_to_front"}}`, likewise `minimize`, `maximize`, `close`; each request
still needs its normal higher `id` and session UUID.

### Closing a window safely

`close` is destructive and should normally be the last command in an array. Inspect `list_window`
first; a busy status does not block it. A tracking-window close by AI is non-spontaneous and
bypasses the local `Tractography not saved` prompt, so confirm whenever unsaved tracts may exist;
reconstruction, image, and connectometry windows also close directly. Success is reported once the
close is issued; confirm with `list_window` when the disappearance matters.

Closing does **not** reset the session's selected window, which still holds the now-invalid ID.
Afterwards run `set_window main` or `set_window <another-current-window-ID>`; until then
window-specific commands fail with
`target window not found, terminated by user? Use set_window to select a window first.`
`list_window`, `set_window`, and other dispatcher-level discovery commands remain available for
recovery.

## `list_window` response shape

`list_window` takes no parameter; `output` holds a JSON object:

```json
{
  "application":{"status":"busy"},
  "current_window":"tracking7ff6ab123410",
  "progress":[
    {"status":"convert DICOM to SRC or nifti files","now":3,"total":12,"at":"(3/12) 2 min"},
    {"status":"processing DICOM at C:/data/subj03","now":0,"total":0,"at":""}
  ],
  "windows":{
    "main":{"status":"idle","title":"","geometry":[0,0,1280,860]},
    "tracking7ff6ab123410":{"status":"busy","title":"subject.fz","geometry":[1280,0,1280,1000]},
    "window7ff6ab567800":{"status":"idle","title":"Fiber Data Hub","geometry":[200,120,900,700]}
  }
}
```

- `application.status`: `"idle"`, `"busy"`, or `"waiting"` (a modal dialog, such as `run_shell`'s
  confirmation prompt, is open somewhere).
- `current_window`: this session's persistent target (the value `set_window` reports), independent
  of other windows' status.
- `windows`: every AI-addressable window (`main`, `tracking...`, `recon...`, `image...`,
  `connectometry...`), every other visible window as `window...`, and any in-flight asynchronous
  `curlN` task, each with `status` (`idle`/`busy`/`waiting`) and `title`; windows also report
  `geometry` as `[x, y, width, height]` in screen pixels.
- A `connectometry...` window stays `busy` for the whole asynchronous `run` (permutation test). For
  percent complete, use that window's `progress` session command (`not_started`, or
  `<running|finished|stopped>\t<percent>`; `stopped` covers this session's `stop` and a local Stop
  click) rather than the coarse `list_window` status. An AI-initiated run suppresses the local
  completion popup; see `DSI_STUDIO_AI_SKILL_CORRELATIONAL_TRACTOGRAPHY.md`.
- `progress`: every active internal operation, outermost first, whatever window it belongs to:
  `status` (name), `now`/`total` (step counters), and `at` (`"(now/total) N min"` with a
  remaining-time estimate once available). An operation without intermediate steps stays at
  `now:0, total:0` until it finishes; granularity is whatever the operation reports. Empty when
  nothing runs.
- Poll `list_window` to watch a long command (`run_cli`, DICOM conversion, NIfTI-to-SRC batches,
  etc.) without waiting for its reply, as with `curlN` tasks.

## Tutor commands: show the user where to click

`list_ui`, `highlight_ui`, `clear_highlight`, `ask_user`, and `ask_user_modal` teach a local user.
They act on the selected window, never click, trigger, or change anything except the accent or the
question shown, and are not recorded in the command history. Use them when the user asks how to do
something in the GUI; use ordinary commands when the user asks you to do it.

| Command | Exact behavior |
|---|---|
| `list_ui [filter]` | Lists visible controls of the selected window only (including its floating docks, not other windows it opened) as `{"total":N,"controls":[{"id","kind","label","run"}]}`, at most 50 entries; `total` counts all matches. `run` is the command the control sends (for example `open_dwi_dicom`, or `enable_slice=0` with its parameter). `filter` is a case-insensitive substring of `id`, `label`, or `run`. |
| `highlight_ui <id> [caption] [gesture]` | Draws an orange ring around the one visible control named `id` of a kind `list_ui` reports, with an optional caption (120 characters at most). `gesture` animates a demonstration once, about 2 s, stopping when the user presses the mouse: strokes `drag`, `shift` (Shift + drag), `freehand`, `rect`; clicks `click`, `double`, `right` (the cursor glides to the control's center and clicks); 3D-view moves `rotate`, `roll`, `zoom`, `pan`, `wheel` (table below); another gesture or a fifth value fails with the usage text. Success replaces the earlier highlight; failure leaves it. |
| `clear_highlight` | Removes the highlight: `cleared` or `nothing to clear`. |
| `ask_user <question> [option]...` | A modeless dialog at the top-right corner of the screen, on top of all windows and without taking focus, so the user keeps working in DSI Studio. For questions and step instructions with buttons such as `Done` and `Cancel`. Up to four options are buttons, more are a drop-down list (first preselected), none means a typed answer. The question can be any text; the answer, returned exactly as given, is the `output`. One choice per question. Closing the dialog fails with `the user closed the question without answering`. The request returns only after the answer. |
| `ask_user_modal <question> [option]...` | The same, but blocks DSI Studio until the user answers, for decisions needed before anything else. |

`kind` in `list_ui`:

- `button` or `disabled button`: by objectName; an unnamed toolbar button is listed as
  `run:<command>`.
- `setting` or `disabled setting`: a drop-down list or slider that sends a command (its value is
  never reported).
- `pages`: the page list `nav_rail` of the main window (Tractography, Correlational, Image,
  Settings) or the reconstruction window (Mask, Preprocessing, Methods).
- `view`: the 3D view `GLWidget` or 2D slice view `graphicsView`, the targets for gestures.
- `panel`: a whole dock by objectName, with its title as `label`; in the tracking window
  `regionDockWidget` (region list), `ROIdockWidget` (2D ROI window), `renderingWidgetHolder`
  (Options), `TractWidgetHolder` (tract list), and `DeviceDockWidget` (devices). For tours.
- `option`: a tracking-window Options tree entry as `option:<option id>`, with its tree path as
  `label` (e.g. `option:tube_diameter`, `Tract Rendering > Tube Diameter (voxel)`); the prefix keeps
  it distinct from a same-named toolbar button such as the `roi_*` buttons. Listed in alphabetical
  order of ids.
- `menu` or `disabled menu`: a visible menu-bar item by objectName, with its menu path as `label`; a
  menu itself goes by the menu's objectName (e.g. `menuTracts`, label `Tracts`), and highlighting it
  opens it. Context-menu-only items are not listed. A
  generated item without a name, such as each U-Net model under Slices > Segment, is listed as
  `run:<command>=<param>` (e.g. `run:segment_brain=<model>`), `<param>` being what it sends.

A label that looks like a file name or path (a button showing a loaded file, for example) is
returned empty.

`highlight_ui` outputs:

- a button, setting, or view: `highlighted: <id>`;
- `run:<command>`: the one visible control, or else menu action, sending that command; when several
  send it with different parameters (`ambiguous control`), use `run:<command>=<param>` from `list_ui`;
- `option:<id>`: the tree expands to it and its editor is ringed: `option: <tree path>`;
- an enabled, visible menu action: the earlier highlight is removed and the menus open down to the
  item and highlight it (as hovering does; nothing is triggered): `menu: <menu path>`, e.g.
  `menu: Tracts > Save Tracts As...`. Also tell the user the path: open menus close when the user
  clicks elsewhere, and a native macOS menu bar may not open.

Failures: `control not found or not visible`, `ambiguous control`, `control is disabled`, and
`a dialog is open; ask the user to close it first` (every tutor command except `clear_highlight`
refuses while a modal dialog is open).

### Tutor protocol

The tutor commands rely on these rules instead of extra checks:

- **Fresh ids only.** After a window opens or closes, call `list_window`, `set_window`, then
  `list_ui` before highlighting. Never reuse an id or window ID learned before the change; a
  reopened window can contain a same-named control.
- **One tutor per DSI Studio instance.** The highlight is shared: any session's `highlight_ui` or
  `clear_highlight` replaces or removes it. Only the tutoring session sends these commands or asks
  the user.
- **Read results as text.** `list_ui` serializes a JSON object in `output`; `highlight_ui` and
  `clear_highlight` return the plain text above; `ask_user` and `ask_user_modal` return the answer as
  given. Failures come back in `error`.
- **Options without changing the tree.** `highlight_ui option:<id>` expands the tree and selects the
  row; when the user only needs the location, report the `label` path from `list_ui <filter>`.
- **Narrow long lists.** When `total` exceeds 50, retry with a more specific `filter` rather than
  guessing ids.

### Teaching from a skill

DSI Studio has no built-in tutorial; the agent is the tutor and the skills are the lessons. When the
user asks "teach me how to ..." (for example, brain tumor analysis):

1. For a new user, start from the matching lesson in `DSI_STUDIO_AI_SKILL_LESSONS.md` (import,
   reconstruction, tracking, regions, AutoTrack, connectome, differential, correlational, brain
   tumor). For depth, read the matching `DSI_STUDIO_AI_SKILL_*.md`, or the DSI Studio documentation
   at https://dsi-studio.labsolver.org/ when no skill covers it; its steps are commands with reasons.
2. Unless the user explicitly asked for a voice tutorial, offer one with `ask_user` (e.g.
   "Yes, with voice" or "No, text only") before using `voice` (`AGENTS.md` 9.2). Start with the plan
   (by `voice` if accepted, otherwise in the chat), and use `ask_user` for choices the skill leaves to
   the user (which data to open, whether to include a step).
3. For each command in the skill, select its window and call
   `highlight_ui run:<command> "<short caption>"`, and explain by `voice` (if accepted) or chat what
   to click, what to set, and why.
   - `menu: <path>`: tell the user the menu path.
   - A step that opens a file or folder dialog: first `set_work_dir <data folder>`, so main-window
     dialogs open there, and name the file to pick.
   - `control not found or not visible`: open the page or window holding it (`highlight_ui nav_rail`
     for pages), or check `list_ui <command>`. If no control sends the command, explain the step and
     offer to run it.
4. Show the instruction with `ask_user "<what to do now>" Done Cancel` (add `Help` or other options
   when useful); it stays on top while the user works, and a menu opened by `highlight_ui` stays
   open. After `Done`, read `log`: a `user operation` line (written by the main, reconstruction, and
   tracking windows) with the same `cmd` shows the user started the step, and the lines after it the
   result. Then verify the outcome with state queries (`list_window`, the window's list commands) or
   a screenshot, as the skill does: the log does not prove success, repeated changes of one
   tracking-window setting (a slider drag) merge into one line that may appear only after the user's
   next operation, and some results (such as T2R tables) appear in dialogs the user must close. On
   `Cancel`, stop the lesson or ask what to do next.
5. Call `clear_highlight` when the lesson ends.

The `run` link between a control and its command comes from DSI Studio itself, so a moved or renamed
button is still found; do not copy control ids into notes or manuals. Some controls cannot be
highlighted, such as reconstruction fields and tract and region table cells; describe them by label
and position.

Example: teaching tract selection (send the second request only after the user chose Select Tracts,
Ctrl+S):

```json
{"command":{"cmd":"highlight_ui","param":"actionSelect_Tracts"}}
{"command":{"cmd":"highlight_ui","param":["GLWidget","Drag across the tracts","drag"]}}
```

Launcher form: `bash ./dsi.sh highlight_ui GLWidget "Drag across the tracts" drag`. Mouse steps have
no command; show them with a gesture that follows the GUI's behavior:

| View | Mode | Gesture | Tell the user |
|---|---|---|---|
| `GLWidget` | Select, Delete, Cut, or Paint Tracts | `drag` | Press the left button, drag a line across the tracts, and release. Paint Tracts then asks for a color. |
| `GLWidget` | same | `shift` | Hold Shift while dragging to add bend points (a curved line). |
| `graphicsView` | freehand region tool (`tool1`) | `freehand` | Hold the left button and draw around the area. Right-click, or hold Shift, to erase. |
| `graphicsView` | rectangle tool (`tool0`) | `rect` | Drag from one corner to the opposite corner. |
| `graphicsView` | sphere (`tool2`) or cube (`tool3`) tool | `drag` | Press at the center and drag outward to set the size. |
| `graphicsView` | polygon tool (`tool4`) | `click`, then `double` | Click each corner, then double-click to close the shape. |
| `graphicsView` | any | `wheel` | Scroll to zoom the slice (hold Ctrl when the view shows a scroll bar). |
| `GLWidget` | normal | `rotate` | Drag with the left button to rotate; hold Shift to tilt only (up/down drag, no turning), Ctrl for 16× finer moves (all drags). |
| `GLWidget` | normal | `roll` | Start the left drag in a corner (outside the inscribed circle) to roll the view in-plane. |
| `GLWidget` | normal | `zoom` or `wheel` | Drag up with the right button, or scroll, to zoom in. |
| `GLWidget` | normal | `pan` | Drag with the middle button, or both buttons, to move the scene. |
| `GLWidget` | normal | `double` | Double-click a region, tract, or device to select its row. |
| any button, drop-down, or tool | | `click` (`right` for a context menu) | Move to the control and click it. |

Undo is Ctrl+Z for tract edits (the last edit of every checked bundle) and Undo Edit (Ctrl+Shift+Z)
for the last region edit.

## Routing order

For each command, the dispatcher applies this order:

1. Shared window controls: `bring_to_front`, `minimize`, `maximize`, `move_window`, `close` (always
   on the selected target).
2. Session commands: `set_title`, `log`, and `set_window`.
3. Window discovery and tutoring: `list_window`, `list_ui`, `highlight_ui`, `clear_highlight`,
   `ask_user`, and `ask_user_modal`.
4. Read-only system commands: `get_agent_settings` and `get_chat` (also in headless mode).
5. All remaining commands are offered to `MainWindow` first.
6. Only a command unknown to `MainWindow` falls through to the selected reconstruction, tracking,
   image, or connectometry window.

Global MainWindow commands such as `voice`, `run_cli`, `run_shell`, and `open_fib` work while a
non-main window is selected. `run_cli` and `run_shell` never act on the selected window: `run_cli`
runs its own internal CLI action logic, and `run_shell` runs any shell command after local-user
confirmation (see `DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md`).
