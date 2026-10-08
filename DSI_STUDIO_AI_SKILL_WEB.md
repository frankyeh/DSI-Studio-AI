# DSI Studio AI Web Session

Use this skill when DSI Studio gives you a Web session UUID. Each Web chat has its own
folder, `DSI Studio AI/<session-uuid>/`, in the user's Google Drive. You and DSI Studio
exchange numbered, write-once JSON files in that folder:

```text
DSI Studio AI/<session-uuid>/
  agent000001.json   your request 1
  dsi000001.json     DSI Studio's reply to request 1
  agent000002.json
  dsi000002.json
  ...
```

DSI Studio looks for the next `agentNNNNNN.json` about every 500 ms, runs it once, and
creates the matching `dsiNNNNNN.json`.

## Web agents

The Web transport does not depend on the agent. Any web-based AI agent that can create and
read files in Google Drive can use it. Agents confirmed on the earlier Google Doc mailbox
(ChatGPT, Claude, Muse) need to be confirmed again on this file protocol.

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
   with the session UUID, and pastes it into a web-based AI agent.
2. Find the folder `DSI Studio AI/<session-uuid>` in Google Drive, and check that you
   can create and read files in it (see the next section).
3. Find the next number: check `agent000001.json`, `agent000002.json`, ... by exact
   name until one does not exist. That is your next request number. A new session
   starts at `agent000001.json`. If the last existing `agentNNNNNN.json` has no
   `dsiNNNNNN.json` yet, wait for that reply first.

## If you cannot create files

You need a Google Drive connector (also called an app, integration, or tool) that can
create files and read them. A read-only connector is not enough.

If the connector is missing or read-only:

1. Tell the user that DSI Studio's Web chat needs Google Drive access that can create files.
2. Walk them through enabling it in your own product: open the connector or app settings,
   add Google Drive, sign in with the **same Google account** used in DSI Studio's
   Settings, and allow file creation. Give the exact steps for your product if you know them.
3. Ask them to come back to this chat (or start a new one and paste the connection prompt
   again) once it is connected.

If your product has no connector that can create Drive files, say so plainly and
suggest another web-based agent. Do not ask the user to create files by hand, and do
not send commands any other way.

## Sending a request

Create **one new** file `agentNNNNNN.json` (six digits, zero-padded) in the session
folder, containing one JSON request:

```json
{"command":{"cmd":"list_window"}}
```

Create it with its content in one step (a plain JSON file, not a Google Doc). Never
overwrite or edit a file after creating it.

- `command` is one `{"cmd":...,"param":...}` object or an ordered array of them. An
  array runs in order and stops at the first error.
- `chat` (optional) is user-facing text recorded in the DSI Studio chat, like `-Chat`.
- `reasoning` (optional) is a brief reasoning summary recorded in the chat history.
- A request needs at least one of `command`, `chat`, or `reasoning`.

A batch puts the array directly in `command`. Do not wrap it in `cmd`
(`{"command":{"cmd":[...]}}` fails with `invalid cmd text`):

```json
{"command":[{"cmd":"set_window","param":"tracking7ff6ab123410"},{"cmd":"list_tract","param":"status"}]}
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
{"command":{"cmd":"set_title","param":"Arcuate fasciculus mapping"}}
```

## Reading the result

Read `dsiNNNNNN.json` with the same number, by exact name, until it exists:

```json
{"status":"success","result":[...]}
```

It is the same reply `dsi.sh` would print. A long command produces no reply file until
it finishes.

## Rules

- Send one request at a time: create `agent(N+1)` only after `dsiN` exists.
- Look files up by exact name. Do not list the folder during normal operation.
- Only you create `agent` files and only DSI Studio creates `dsi` files. Never modify,
  rename, move, or delete either.
- Never invent a session UUID or create another session folder.
- DSI Studio stops polling after 3 minutes without a request, and when the user presses
  Stop. If no `dsiNNNNNN.json` appears for a request, ask the user to press **Resume**
  on the chat in DSI Studio. Resume continues the same numbering and copies the
  connection prompt again, so the user can also paste it into a new agent chat.
- If DSI Studio stopped while running a request, it does not run it again: the reply
  file holds `outcome unknown`. Check the state with a harmless command such as
  `list_window` before repeating any work.
