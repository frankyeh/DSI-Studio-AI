# DSI Studio AI Web Session

Use this skill when the user asks you to connect to a DSI Studio Web session. Each session has a
two-word codename such as `neon-raven`. DSI Studio creates one Google Doc per Web chat in the user's
`DSI Studio AI` Google Drive folder, named `DSI Studio <codename> on <computer>` (after `set_title`:
`<title> · DSI Studio <codename> on <computer>`), `<computer>` being the host running DSI Studio. The
body is a single-slot mailbox holding exactly one compact JSON message, read about every 500 ms: you
write a request, and DSI Studio replaces it with the result.

## Web agents

The transport works with any web-based AI agent that can read and write a Google Doc; confirmed with
ChatGPT, Claude, and Muse. To confirm a new agent in GUI Web, run the full workflow: connect,
`set_title`, a `chat`-only request, `list_recent_fib`, open a recent `.fz`, AutoTrack the left and
right arcuate fasciculus, and `list_tract` showing both bundles done. In headless Web, run
`set_title`, `run_shell`, `write_text_file`, `web_upload`, and `web_download` instead.

## Two modes

| Mode | Started by | Commands |
|---|---|---|
| GUI Web | **New Chat → Web** in DSI Studio | The full command center |
| Headless Web | `dsi_studio --action=ai` on a remote or cluster computer | Only `run_shell`, `write_text_file`, `patch_text_file`, `web_upload`, `web_download_prepare`, `web_download`, `set_work_dir`, `set_title`, `get_agent_settings`, `new_chat`, `send_chat`, and `get_chat`; anything else, including `run_cli`, returns an error |

A headless connection prompt includes "This session is headless" and its approval mode; the GUI
prompt does not. When a headless request needs the DSI Studio window (opening a `.fz`, rendering,
dialogs), tell the user it is not available instead of trying it.

Headless Web opens no window. It starts a new chat by default (`--session=-1`); `--session=N` resumes
the N-th listed chat (0 = most recent), and `--session=<codename>` or `--session=<uuid>` resumes that
chat. Each concurrent `dsi_studio --action=ai` process needs its own chat (never resume a chat served
by another process). `--remove_session=N`, `--remove_session=<codename>`, or
`--remove_session=<uuid>` removes that chat (its Doc goes to the Drive trash) and exits.

Approval: GUI Web always asks in a dialog. Headless Web asks in its terminal per `--approval`, and
answering `a` there switches the session to `auto`:

| `--approval` | Read-only `run_shell`, `web_upload` | Other `run_shell` | `write_text_file`, `patch_text_file` |
|---|---|---|---|
| `manual` (default) | asks | asks | asks |
| `read_only` | runs | asks | asks |
| `auto` | runs | runs | runs |

A read-only command is one simple command (`pwd`, `ls`, `cat`, `head`, `tail`, `grep`, `wc`, `stat`,
`du`, `df`, `basename`, `dirname`, `readlink`, `realpath`, `find`, `rg`, `file`) with no `;`, `&`, `|`,
`<`, `>`, `$`, backquote, or brackets, and no writing option such as `find -delete`/`-exec`; anything
else asks. It cannot change files, but its output still reaches you, so never read credentials or
keys.

A headless session is a mission dispatcher, not a compute worker. Run a short DSI Studio command line
as its own process through `run_shell` (e.g. `run_shell "dsi_studio --action=qc --source=sub-01.sz"`).
`run_shell` waits at most 10 minutes, so put long, repeated, or resource-intensive work in a script,
dispatch it through the cluster scheduler (e.g. `run_shell "sbatch job.sh"`), record the job ID,
return to waiting for commands, and check later with short commands such as `squeue`, `ls`, or
`tail`.

## Read the manuals first

This file covers only the Web transport. Before sending commands, read `AGENTS.md` in the public
repository `frankyeh/DSI-Studio-AI`, then only the command examples and skills it points to for the
task. The manuals show launcher form; over Web, send the same command in `command`, and ignore
launcher-only topics (`dsi.sh` setup, session environment variables, and `new_chat`):

```text
bash ./dsi.sh open_fib "C:/data/subject.fz"   ->  {"cmd":"open_fib","param":"C:/data/subject.fz"}
bash ./dsi.sh -Chat "Opening the file."       ->  "chat":"Opening the file."
```

## Start

1. The user starts a session in either mode and pastes its connection prompt (this skill and the
   codename, e.g. "connect to DSI Studio neon-raven"), or says "connect to DSI neon-raven" or (e.g. in
   voice mode) "connect to the latest DSI session". GUI Web posts the prompt in the chat history;
   headless Web prints it and serves until Ctrl+C. On its first run, headless Web first prints a
   Google URL and code to enter on any computer or phone. Its terminal then shows only the chat
   history (your `chat` text, commands, errors, and approval prompts); `--debug` adds DSI Studio's log
   and command output. A resumed document (`--session`) may still hold an old message: read it, keep
   the same `session`, and use an `id` greater than any in it.
2. Find the session document:
   - **Link given** (e.g. pasted from Google Docs): use it.
   - **Codename given:** search the `DSI Studio AI` folder for a Doc whose name contains
     `DSI Studio <codename>`.
   - **"The latest":** list that folder's Docs, newest modified first, and take the first named
     `... DSI Studio <codename> on <computer>`. If two or more changed in the last few minutes, tell
     the user their codenames and titles and ask which one.

   After connecting by codename or "latest", tell the user the codename and title (e.g. "Connected to
   neon-raven, Test OpenNeuro scripts").
3. Check that you can read and write the document (next section).
4. Read the first message DSI Studio wrote; its `code` confirms the document:

```json
{"dsi_bridge":true,"session":"<uuid>","code":"neon-raven","from":"dsi","state":"ready"}
```

5. Use that `session` value (the UUID, not the codename) unchanged in every request. Never invent a
   session UUID or create another session document.

## If you cannot write to the document

You need a Google Drive or Google Docs connector (app, integration, or tool) that can read **and
edit** a Google Doc; a browser link or read-only connector is not enough. If it is missing or
read-only: tell the user that DSI Studio's Web chat needs Google Docs edit access; walk them through
adding Google Drive or Google Docs in your product's connector or app settings (exact steps if you
know them), signing in with the **same Google account** as in DSI Studio's Settings and allowing edit
access; then ask them to return to this chat (or start a new one and paste the connection prompt)
and retry. Known: **Claude** writes with the **Google Docs** connector (`update_doc`); its Google Drive
connector can only read. If your product has no connector that can edit a Google Doc, say so plainly
and suggest another web-based agent. Never ask the user to copy messages into the document by hand
or send commands any other way.

## Message lifecycle

```text
ready -> request -> processing -> done | error -> next request -> ...
```

While a request is `processing`, DSI Studio may add `step`:

- `"step":"waiting_approval"` with `"approval":"<what will run>"`: nothing has run; the user must
  approve on the DSI Studio computer (a dialog in GUI Web, the terminal in headless Web). Tell the
  user, keep reading, and do not resend.
- `"step":"running"`: approved and running; a long wait is normal. A synchronous `run_shell` adds
  `"pid"`, its process ID.

A result error starting with `user declined` means nothing ran; any other `run_shell` error (exit
code, timeout) means the command ran.

## Sending a request

Replace the **entire** body with one line of compact JSON through the Google Docs API (typing in the
editor can create smart quotes), as plain text, never Markdown (`dsi\_bridge` or a stray `}` makes it
invalid):

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"agent","state":"request","command":{"cmd":"list_window"}}
```

Read the document (`documents.get`), take `E`, the `endIndex` of the last element in `body.content`,
and send one `documents.batchUpdate`:

```json
{"requests":[
  {"deleteContentRange":{"range":{"startIndex":1,"endIndex":<endIndex - 1>}}},
  {"insertText":{"location":{"index":1},"text":"<compact JSON request>"}}],
 "writeControl":{"requiredRevisionId":"<revisionId from the read>"}}
```

Deleting up to `E-1` keeps the final newline every Doc needs; a smaller range leaves the end of the
previous message behind, which DSI Studio reports as invalid JSON. When the body is empty (`E` is 2),
send only `insertText`. If the revision changed, read again before retrying.

- `id` starts at 1 and increases by one per request.
- `command` is one `{"cmd":...,"param":...}` object or an ordered array, run in order and stopped at
  the first error. Put a batch directly in `command`, never in `cmd`
  (`{"command":{"cmd":[...]}}` fails with `invalid cmd text`).
- `param` is omitted, one value, or an array for several values; strings are never split on spaces.
- `chat` (optional): user-facing text recorded in the DSI Studio chat, like `-Chat`. `reasoning`
  (optional): a brief reasoning summary recorded in the chat history. A request needs at least one of
  `command`, `chat`, or `reasoning`.

```json
{"dsi_bridge":true,"session":"<uuid>","id":5,"from":"agent","state":"request","command":[{"cmd":"set_window","param":"tracking7ff6ab123410"},{"cmd":"list_tract","param":"status"}]}
{"cmd":"segment_brain","param":["human_tumor","15"]}
```

Name the chat with `set_title` in the first request:

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"agent","state":"request","command":{"cmd":"set_title","param":"Arcuate fasciculus mapping"}}
```

Routing, persistent `set_window`, shared window controls, `run_cli` (GUI only), and `run_shell` work
as in `AGENTS.md`. You have no file system or Python on the user's computer: to produce a file there
(e.g. a PPTX report), write the script with `write_text_file`, run it with
`run_shell "python <script>"` (`DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md`), and fetch the result
with `web_upload`. Read console output (e.g. after an asynchronous `curl`) with `{"cmd":"log"}`; the
first `log` sets the cursor, later calls return only new output.

## Reading the result

Read the body until it holds a message with `"from":"dsi"` and the same `id`:

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"dsi","state":"processing"}
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"dsi","state":"done","response":{...}}
```

`state` ends as `done` or `error`; `response` is the reply `dsi.sh` would print. A long command stays
`processing` until it finishes. A request DSI Studio cannot accept (invalid JSON, wrong session, or a
reused `id`) gets `state:"error"` with the reason; nothing ran, so fix and resend.

## Getting files from DSI Studio

`web_upload <local file>` copies one file from the user's computer to a private (never public) file
`<session>_<file name>` in their `DSI Studio AI` Drive folder. A relative path resolves against the
chat's working directory. It needs approval like a read-only `run_shell` (GUI Web always asks); a
decline fails with `user declined to upload this file`. Save first, then upload:

```json
"command":[{"cmd":"save_lr_screen","param":"result.png"},{"cmd":"web_upload","param":"result.png"}]
{"cmd":"web_upload","status":"success","attachment":{"name":"result.png","drive_id":"1abc...","mime_type":"image/png","size":823417,"url":"https://drive.google.com/file/d/1abc.../view"}}
```

The second line is the `web_upload` entry in `response.result[]`. Open the file with your Drive tools
by `drive_id` (the `url` is the same file but needs the user's sign-in); never ask the user to
download and re-upload it. PNG, JPEG, TXT, CSV/TSV, JSON, and PDF are directly usable; DSI Studio
formats (`.fz`, `.tt.gz`, `.nii.gz`, `.sz`) transfer, but reading them depends on your tools. Upload
only what the task needs: the file leaves the user's computer.

## Sending files to DSI Studio

DSI Studio can read only Drive files it created, so to give it a file you made (a script, CSV/JSON,
ROI or mask, image, NIfTI), fill a slot it creates; a file you create yourself, even in the same
folder, cannot be downloaded. For a text file (script, CSV, JSON), `write_text_file <name> <content>`
is simpler and needs no Drive file.

1. `web_download_prepare <file name>` returns the slot's `drive_id`:

```json
{"cmd":"web_download_prepare","status":"success","attachment":{"name":"mask.nii.gz","drive_id":"1abc...","url":"https://drive.google.com/file/d/1abc.../view"}}
```

2. With your Drive tools, **replace the content of that existing file** (`drive_id`); never create a
   new Drive file or convert it to a Google Doc or Sheet. If your tools cannot replace an existing
   file's content, sending files is not available for your product.
3. `web_download <drive_id>` downloads it and returns its local path; a slot never filled is rejected
   with `the upload slot is still empty`:

```json
{"cmd":"web_download","status":"success","attachment":{"name":"mask.nii.gz","path":"/.../ai_projects/web_files/<session>/mask.nii.gz","mime_type":"application/octet-stream","size":1234567,"drive_id":"1abc..."}}
```

4. Use `attachment.path` in later commands, such as `run_shell` (or `run_cli` in GUI Web).

The file is saved in this session's folder and never opened or run automatically. A same-named
existing file is not replaced; prepare another name. The slot moves to the Drive trash after a
successful download.

## Rules

- One request at a time: write the next only after `done` or `error` for the current `id`, and never
  overwrite a `processing` message.
- Do not move the document, add comments, or keep old messages; the body holds only the latest
  message. Rename it only to wake DSI Studio.
- After 3 minutes without a request, DSI Studio goes idle and sees body edits only after a delay of
  up to several minutes. If no `processing` appears within 15 seconds of a request, rename the
  document to a new title that still contains `DSI Studio <codename>` (e.g. add or bump a counter at
  the start), without rewriting the request; DSI Studio notices within about 10 seconds, reads the
  request, and leaves idle mode. If still no `processing` within 30 seconds, ask the user to press
  **Resume** on the chat in DSI Studio, which also posts the connection prompt again for a new agent
  chat. DSI Studio stops polling only when the user presses Stop or closes it; later requests wait
  unanswered.
- If DSI Studio stopped while running a request, it never reruns it: on Resume it replaces the stale
  `processing` with `state:"error"` and `outcome unknown` for that `id`, naming the pid of a shell
  command, which may still run (check with e.g. `run_shell "ps -p <pid>"`). Check state with a
  harmless command such as `list_window` before repeating any work.
