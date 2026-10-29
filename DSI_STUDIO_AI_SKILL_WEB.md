# DSI Studio AI Web Session

Use this skill when the user asks you to connect to a DSI Studio Web session. Each session
has a two-word codename such as `neon-raven`. DSI Studio creates one Google Doc per Web chat,
in the user's `DSI Studio AI` Google Drive folder, named `DSI Studio <codename> on <computer>`
(after `set_title`: `<title> · DSI Studio <codename> on <computer>`), where `<computer>` is the
host name of the machine running DSI Studio. The document body is a single-slot mailbox
holding exactly one compact JSON message. DSI Studio reads it about every 500 ms; you
write a request, and DSI Studio replaces it with the result.

## Web agents

The Web transport does not depend on the agent. Any web-based AI agent that can read and
write a Google Doc can use it. It has been confirmed with ChatGPT, Claude, and Muse.

To confirm a new agent in GUI Web, run the full workflow: connect, `set_title`, a
`chat`-only request, `list_recent_fib`, open a recent `.fz`, AutoTrack left/right arcuate
fasciculus, and `list_tract` showing both bundles done. In headless Web, run `set_title`,
`run_shell`, `write_text_file`, `web_upload`, and `web_download` instead.

## Two modes

| Mode | Started by | Commands |
|---|---|---|
| GUI Web | **New Chat → Web** in DSI Studio | the full command center |
| Headless Web | `dsi_studio --action=ai` on a remote or cluster computer | `run_shell`, `write_text_file`, `patch_text_file`, `web_upload`, `web_download_prepare`, `web_download`, `set_work_dir`, `set_title`, `get_agent_settings`, `new_chat`, `send_chat`, and `get_chat` only |

A headless session's connection prompt includes "This session is headless" and its approval
mode; the GUI prompt does not. In a headless session, use only the headless commands above, and when a request needs
the DSI Studio window (opening a `.fz`, rendering, or dialogs), tell the user it is not available
in this session instead of trying it.

Headless Web starts a new chat by default (`--session=-1`); `--session=N` resumes the N-th listed
chat (0 = most recent), and `--session=<codename>` or `--session=<uuid>` resumes that chat. Each
concurrent `dsi_studio --action=ai` process needs its own chat (do not resume a chat already served
by another DSI Studio process). `--remove_session=N`, `--remove_session=<codename>`, or
`--remove_session=<uuid>` removes that chat (its Doc goes to the Drive trash) and exits.

Headless Web opens no window. `run_shell`, `write_text_file`, and `web_upload` wait for the
user's approval in that terminal unless `--approval` says otherwise:

| `--approval` | Read-only `run_shell`, `web_upload` | Other `run_shell` | `write_text_file`, `patch_text_file` |
|---|---|---|---|
| `manual` (default) | asks | asks | asks |
| `read_only` | runs | asks | asks |
| `auto` | runs | runs | runs |

GUI Web always asks in a dialog for all three.

A read-only command is one simple command (`pwd`, `ls`, `cat`, `head`, `tail`, `grep`, `wc`,
`stat`, `du`, `df`, `basename`, `dirname`, `readlink`, `realpath`, `find`, `rg`, `file`) with
no `;`, `&`, `|`, `<`, `>`, `$`, backquote, or brackets, and no writing option such as
`find -delete`/`-exec`. Anything else asks. Read-only means it cannot change files; its output
still comes back to you, so never read credentials or keys. Answering `a` at the terminal
switches the session to `auto`. Any other command, including `run_cli`, returns an error.

A headless session is a mission dispatcher, not a compute worker. Run a short DSI Studio
command line as its own process through `run_shell` (for example
`run_shell "dsi_studio --action=qc --source=sub-01.sz"`). `run_shell` waits at most 10 minutes,
so put long, repeated, or resource-intensive work in a script and dispatch it through the
cluster scheduler (for example `run_shell "sbatch job.sh"`), record the job ID, return to
waiting for commands, and check later with short commands such as `squeue`, `ls`, or `tail`.

## Read the manuals first

This file covers only the Web transport. Before sending commands, read `AGENTS.md` in the
public repository `frankyeh/DSI-Studio-AI` for the common operating rules. Then read only
the command examples and workflow skills it points to for the current task.

Those manuals show commands in launcher form. Over Web, send the same command in the
`command` field:

```text
bash ./dsi.sh open_fib "C:/data/subject.fz"   ->  {"cmd":"open_fib","param":"C:/data/subject.fz"}
bash ./dsi.sh -Chat "Opening the file."       ->  "chat":"Opening the file."
```

Ignore launcher-only topics such as `dsi.sh` setup, session environment variables, and
`new_chat`.

## Start

1. The user starts a Web session in either mode. The user then pastes its connection prompt
   (this skill and the codename, e.g. "connect to DSI Studio neon-raven"), or just says "connect to DSI neon-raven" or,
   for example in voice mode, "connect to the latest DSI session". GUI Web posts the prompt in the chat history for the user to copy;
   headless Web prints it and serves until Ctrl+C. On its first run, headless Web first
   prints a Google URL and code, which the user enters on any computer or phone. By default it
   starts a new chat, or resumes an existing chat when given `--session` (same session document).
   A resumed document may still hold an old message: read it first, keep the same `session`, and give
   your next request an `id` greater than any `id` in it. Its terminal
   then shows only the chat history (your `chat` text, each command, errors, and approval
   prompts); `--debug` also shows DSI Studio's log and command output.
2. Find the session document:
   - **Link given** (e.g. pasted from Google Docs): use it.
   - **Codename given:** search the `DSI Studio AI` folder for a Doc whose name contains
     `DSI Studio <codename>`.
   - **"The latest":** list the Docs in that folder, newest modified first, and take the
     first one named `... DSI Studio <codename> on <computer>`. If two or more changed in the last few
     minutes, tell the user their codenames and titles and ask which one.
   After connecting by codename or "latest", tell the user the codename and title you
   connected to (e.g. "Connected to neon-raven, Test OpenNeuro scripts").
3. Check that you can read and write the session document (see the next section).
4. Read the document. DSI Studio has written the first message, which also holds the
   codename (`code`) so you can confirm the document:

```json
{"dsi_bridge":true,"session":"<uuid>","code":"neon-raven","from":"dsi","state":"ready"}
```

5. Use that `session` value (the UUID, not the codename) unchanged in every request. Never invent a session UUID,
   and never create another session document yourself.

## If you cannot write to the document

You need a Google Drive or Google Docs connector (also called an app, integration, or
tool) that can read **and edit** a Google Doc. Opening the link in a browser, or a
read-only connector, is not enough.

If the connector is missing or read-only:

1. Tell the user that DSI Studio's Web chat needs Google Docs edit access.
2. Walk them through enabling it in your own product: open the connector or app settings,
   add Google Drive or Google Docs, sign in with the **same Google account** used in DSI
   Studio's Settings, and allow edit access. Give the exact steps for your product if
   you know them.
3. Ask them to come back to this chat (or start a new one and paste the connection prompt
   again) once it is connected, then retry reading the document.

Known connectors:

- **Claude:** use the **Google Docs** connector (`update_doc`) to write. The Google Drive
  connector can only read the document.

If your product has no connector that can edit a Google Doc, say so plainly and suggest
another web-based agent. Do not ask the user to copy messages into the document by hand,
and do not send commands any other way.

## Message lifecycle

```text
ready -> request -> processing -> done | error -> next request -> ...
```

While a request is `processing`, DSI Studio may add `step` to that message:

- `"step":"waiting_approval"` with `"approval":"<what will run>"`: nothing has run yet; the
  user must approve it on the DSI Studio computer (a dialog in GUI Web, the terminal in headless
  Web). Tell the user, keep reading, and do not resend.
- `"step":"running"`: approved and running; a long wait is normal. A synchronous `run_shell`
  adds `"pid"`, its process ID.

A result error that starts with `user declined` means nothing ran. Any other `run_shell` error
(exit code, timeout) means the command ran.

## Sending a request

Replace the **entire** document body with one line of compact JSON, written through the
Google Docs API. Typing it in the editor can turn quotes into smart quotes.
Write the JSON as plain text, never Markdown: `dsi\_bridge` or a stray `}` makes it invalid.

With `documents.batchUpdate`, read `E`, the `endIndex` of the last element in `body.content`,
then send `deleteContentRange` for `startIndex` 1 to `endIndex` `E-1` (keeps only the final
newline; skip it when `E` is 2) followed by `insertText` at index 1. A smaller range leaves the
end of the previous message behind, which DSI Studio reports as invalid JSON.

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"agent","state":"request","command":{"cmd":"list_window"}}
```

To replace the body, read the document first (`documents.get`), then send one
`documents.batchUpdate`:

```json
{"requests":[
  {"deleteContentRange":{"range":{"startIndex":1,"endIndex":<endIndex - 1>}}},
  {"insertText":{"location":{"index":1},"text":"<compact JSON request>"}}],
 "writeControl":{"requiredRevisionId":"<revisionId from the read>"}}
```

`endIndex` is that of the last element in `body.content`. Deleting only up to
`endIndex - 1` keeps the final newline every Doc must have. If the body is already
empty (`endIndex` is 2), send only `insertText`. If the update fails because the
revision changed, read the document again before retrying.

- `id` starts at 1 and increases by one for each request.
- `command` is one `{"cmd":...,"param":...}` object or an ordered array of them. An
  array runs in order and stops at the first error.
- `chat` (optional) is user-facing text recorded in the DSI Studio chat, like `-Chat`.
- `reasoning` (optional) is a brief reasoning summary recorded in the chat history.
- A request needs at least one of `command`, `chat`, or `reasoning`.

A batch puts the array directly in `command`. Do not wrap it in `cmd`
(`{"command":{"cmd":[...]}}` fails with `invalid cmd text`):

```json
{"dsi_bridge":true,"session":"<uuid>","id":5,"from":"agent","state":"request","command":[{"cmd":"set_window","param":"tracking7ff6ab123410"},{"cmd":"list_tract","param":"status"}]}
```

`param` is omitted, a single value, or an array for several values. DSI Studio does
not split a string on spaces:

```json
{"cmd":"segment_brain","param":["human_tumor","15"]}
```

Command routing, persistent `set_window` selection, shared window controls, `run_cli` (GUI only),
and `run_shell` work as described in `AGENTS.md` and the command examples. You have no
file system or Python of your own on the user's computer: to produce a file there (for
example a PPTX report), write the script with `write_text_file` and run it with
`run_shell "python <script>"` (`DSI_STUDIO_AI_COMMAND_EXAMPLES_CLI_SHELL.md`), then fetch
the result with `web_upload`. To read
console output (for example after an asynchronous `curl`), send `{"cmd":"log"}` as a
command. The first `log` sets the cursor, and later calls return only new output.

Name the chat with `set_title` in the first request:

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"agent","state":"request","command":{"cmd":"set_title","param":"Arcuate fasciculus mapping"}}
```

## Reading the result

Read the document body until it holds a message with `"from":"dsi"` and the same `id`:

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"dsi","state":"processing"}
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"dsi","state":"done","response":{...}}
```

`state` is `done` or `error`. `response` is the same reply `dsi.sh` would print. A long
command stays `processing` until it finishes. A request DSI Studio cannot accept (invalid JSON, wrong
session, or a reused `id`) gets `state:"error"` with the reason; nothing was run, so fix
it and resend.

## Getting files from DSI Studio

`web_upload <local file>` copies one file from the user's computer to a private file in
their `DSI Studio AI` Google Drive folder, named `<session>_<file name>`. It is never made public.
A relative path is resolved against the chat's working directory. Uploading a local file needs
the user's approval like a read-only `run_shell` (see the `--approval` table; GUI Web always asks),
and a declined upload fails with `user declined to upload this file`. Save first, then upload:

```json
"command":[{"cmd":"save_lr_screen","param":"result.png"},{"cmd":"web_upload","param":"result.png"}]
```

The `web_upload` entry in `response.result[]` carries the file:

```json
{"cmd":"web_upload","status":"success","attachment":{"name":"result.png","drive_id":"1abc...","mime_type":"image/png","size":823417,"url":"https://drive.google.com/file/d/1abc.../view"}}
```

Open it with your Google Drive tools by `drive_id` (the `url` is the same file and needs the
user's sign-in). Don't ask the user to download and re-upload it. PNG, JPEG, TXT, CSV/TSV, JSON
and PDF are directly usable; DSI Studio formats (`.fz`, `.tt.gz`, `.nii.gz`, `.sz`) transfer, but
reading them depends on your tools. Upload only what the task needs: the file leaves the user's
computer.

## Sending files to DSI Studio

To give DSI Studio a file you made (a script, CSV/JSON, ROI or mask, image, NIfTI), fill a
Drive slot that DSI Studio creates. DSI Studio can read only Drive files it created, so a new
file you create yourself, even in the same folder, cannot be downloaded. For a text file
(script, CSV, JSON), `write_text_file <name> <content>` is simpler and needs no Drive file.

1. Send `web_download_prepare <file name>`. Its `attachment` holds the slot's `drive_id`:

```json
{"cmd":"web_download_prepare","status":"success","attachment":{"name":"mask.nii.gz","drive_id":"1abc...","url":"https://drive.google.com/file/d/1abc.../view"}}
```

2. With your Google Drive tools, **replace the content of that existing file** (`drive_id`) with
   your file. Do not create a new Drive file and do not convert it to a Google Doc or Sheet.
3. Send `web_download <drive_id>`. DSI Studio downloads the file and returns its local path. A slot
   whose content was never replaced is rejected with `the upload slot is still empty`:

```json
{"cmd":"web_download","status":"success","attachment":{"name":"mask.nii.gz","path":"/.../ai_projects/web_files/<session>/mask.nii.gz","mime_type":"application/octet-stream","size":1234567,"drive_id":"1abc..."}}
```

4. Use `attachment.path` in later commands, such as `run_shell` (or `run_cli` in GUI Web).

The file is saved in a folder for this session and is never opened or run automatically. An
existing file with the same name is not replaced: prepare another name instead. The Drive slot
is moved to the trash after a successful download. If your Drive tools cannot replace the content
of an existing file, sending files to DSI Studio is not available for your product.

## Rules

- Send one request at a time: write the next request only after `done` or `error` for
  the current `id`.
- Never overwrite a `processing` message.
- Don't move the document, add comments, or keep old messages. The body holds only the
  latest message. Rename it only to wake DSI Studio (below).
- After 3 minutes without a request, DSI Studio goes idle and sees a body edit only after
  a delay of up to several minutes. If no `processing` appears within 15 seconds of a
  request, rename the document to a new title that still contains `DSI Studio <codename>`
  (e.g. add or bump a counter at the start); DSI Studio
  notices the rename within about 10 seconds, reads the request, and leaves idle mode.
  Do not rewrite the request. It stops polling after 1 hour without a request, and when
  the user presses Stop. A request sent after that waits unanswered. If no `processing`
  appears within 30 seconds after the rename, ask the user to press **Resume** on the chat
  in DSI Studio. Resume posts the connection prompt again, so the user can also paste it
  into a new agent chat.
- If DSI Studio stopped while running a request, it does not run that request again.
  When the chat is resumed, it replaces the stale `processing` with `state:"error"` and
  `outcome unknown` for that `id`. If it was running a shell command, the error names its
  pid, which may still be running (for example `run_shell "ps -p <pid>"`). Check the state
  with a harmless command such as `list_window` before repeating any work.
