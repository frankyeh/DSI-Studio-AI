# DSI Studio AI Web Session

Use this skill when DSI Studio gives you a Web session document (a Google Doc titled
`DSI Studio <session-uuid>`). DSI Studio creates one document per Web chat, in the
user's `DSI Studio AI` Google Drive folder. The document body is a single-slot mailbox
holding exactly one compact JSON message. DSI Studio reads it about every 500 ms; you
write a request, and DSI Studio replaces it with the result.

Common DSI Studio operating rules are in `AGENTS.md`; this file covers only the Web
transport.

## Provider status

| Web agent | Status |
|---|---|
| ChatGPT | supported |
| Claude | to test |
| Muse | to test |
| Grok | to test |

A provider is advertised in DSI Studio only after it passes the full workflow:
connect, `set_title`, `chat`, `list_recent_fib`, open a recent `.fz`, AutoTrack
left/right arcuate fasciculus, and `list_tract` showing both bundles done.

## Start

1. The user picks **New Chat → Web · ChatGPT** in DSI Studio, which copies a
   connection prompt with the session document link.
2. Read the document. DSI Studio has written the first message:

```json
{"dsi_bridge":true,"session":"<uuid>","from":"dsi","state":"ready"}
```

3. Use that `session` value unchanged in every request. Never invent a session UUID,
   and never create another session document yourself.

You need write access to the document through the Google Docs API (your Google Drive
or Docs tools). If you can't write to it, tell the user, and don't send commands
any other way.

## Message lifecycle

```text
ready -> request -> processing -> done | error -> next request -> ...
```

## Sending a request

Replace the **entire** document body with one line of compact JSON, written through the
Google Docs API. Typing it in the editor can turn quotes into smart quotes.

```json
{"dsi_bridge":true,"session":"<uuid>","id":1,"from":"agent","state":"request","command":{"cmd":"list_window"}}
```

- `id` starts at 1 and increases by one for each request.
- `command` is one `{"cmd":...,"param":...}` object or an ordered array of them. An
  array runs in order and stops at the first error.
- `chat` (optional) is user-facing text recorded in the DSI Studio chat, like `-Chat`.
- `reasoning` (optional) is a brief reasoning summary recorded in the chat history.
- A request needs at least one of `command`, `chat`, or `reasoning`.

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

Read the document body until it holds a message with `"from":"dsi"` and the same `id`:

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
- Don't rename or move the document, add comments, or keep old messages. The body
  holds only the latest message.
- If the user stops the chat in DSI Studio, requests wait unanswered until they press
  Resume.
- If DSI Studio restarts while the body still says `processing`, the outcome is
  unknown, and DSI Studio does not run that request again. Check the state with a
  harmless command such as `list_window` before repeating any work.
