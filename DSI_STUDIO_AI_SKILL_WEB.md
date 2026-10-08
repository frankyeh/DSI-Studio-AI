# DSI Studio AI Web Session

Use this skill when DSI Studio gives you a Web session file: a plain JSON file named
`DSI Studio <session-uuid>.json`. DSI Studio creates one file per Web chat, in the
user's `DSI Studio AI` Google Drive folder. The file is a single-slot mailbox holding
exactly one compact JSON message. DSI Studio reads it about every 500 ms; you write a
request, and DSI Studio replaces it with the result.

## Web agents

The Web transport does not depend on the agent. Any web-based AI agent that can read and
write a Google Drive file can use it. It has been confirmed with ChatGPT, Claude, and Muse.

To confirm a new agent, run the full workflow: connect, `set_title`, a `chat`-only request,
`list_recent_fib`, open a recent `.fz`, AutoTrack left/right arcuate fasciculus, and
`list_tract` showing both bundles done.

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

1. The user picks **New Chat → Web** in DSI Studio, which copies a connection prompt
   with the session file's name and Drive file ID, and pastes it into a web-based AI agent.
2. Check that you can read and write the session file (see the next section).
3. Read the file. DSI Studio has written the first message:

```json
{"dsi_bridge":true,"session":"<uuid>","from":"dsi","state":"ready"}
```

4. Use that `session` value unchanged in every request. Never invent a session UUID,
   and never create another session file yourself.

## If you cannot write to the file

You need a Google Drive connector (also called an app, integration, or tool) that can
read **and overwrite** a file's content. Opening the link in a browser, or a read-only
connector, is not enough.

If the connector is missing or read-only:

1. Tell the user that DSI Studio's Web chat needs Google Drive edit access.
2. Walk them through enabling it in your own product: open the connector or app settings,
   add Google Drive, sign in with the **same Google account** used in DSI Studio's
   Settings, and allow edit access. Give the exact steps for your product if you know them.
3. Ask them to come back to this chat (or start a new one and paste the connection prompt
   again) once it is connected, then retry reading the file.

If your product has no connector that can overwrite a Drive file, say so plainly and
suggest another web-based agent. Do not ask the user to copy messages into the file by
hand, and do not send commands any other way.

## Message lifecycle

```text
ready -> request -> processing -> done | error -> next request -> ...
```

## Sending a request

Overwrite the **entire** file content with one compact JSON message. Keep the file a
plain JSON file: do not convert it to a Google Doc, rename it, or move it.

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"agent","state":"request","command":{"cmd":"list_window"}}
```

With the Drive API this is a media upload that replaces the content:
`PATCH https://www.googleapis.com/upload/drive/v3/files/<file-id>?uploadType=media`
with the JSON as the body. Read it back with
`GET https://www.googleapis.com/drive/v3/files/<file-id>?alt=media`.

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

Command routing, persistent `set_window` selection, shared window controls, `run_cli`,
and `run_shell` work as described in `AGENTS.md` and the command examples. To read
console output (for example after an asynchronous `curl`), send `{"cmd":"log"}` as a
command. The first `log` sets the cursor, and later calls return only new output.

Name the chat with `set_title` in the first request:

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"agent","state":"request","command":{"cmd":"set_title","param":"Arcuate fasciculus mapping"}}
```

## Reading the result

Read the file until it holds a message with `"from":"dsi"` and the same `id`:

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"dsi","state":"processing"}
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"dsi","state":"done","response":{...}}
```

`state` is `done` or `error`. `response` is the same reply `dsi.sh` would print. A long
command stays `processing` until it finishes.

## Rules

- Send one request at a time: write the next request only after `done` or `error` for
  the current `id`.
- Never overwrite a `processing` message.
- Don't rename, move, or convert the file, or keep old messages. It holds only the
  latest message.
- DSI Studio stops polling after 3 minutes without a request, and when the user presses
  Stop. A request sent after that waits unanswered. If no `processing` appears within a
  few seconds, ask the user to press **Resume** on the chat in DSI Studio. Resume copies
  the connection prompt again, so the user can also paste it into a new agent chat.
- If DSI Studio stopped while running a request, it does not run that request again.
  When the chat is resumed, it replaces the stale `processing` with `state:"error"` and
  `outcome unknown` for that `id`. Check the state with a harmless command such as
  `list_window` before repeating any work.
