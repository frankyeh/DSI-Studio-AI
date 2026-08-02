# DSI Studio Direct GitHub Issue Channel

Current DSI Studio can connect directly to a GitHub issue and use it as a remote
command/result mailbox. This route does not use a self-hosted GitHub Actions runner,
a workflow dispatch, a request file, or repository commits.

The issue body carries the next request. One issue comment marked
`"dsi_session_result":true` carries the latest result.

## Requirements

Before connecting:

- DSI Studio must be open and its GitHub login must have completed.
- The issue URL must have the exact form
  `https://github.com/<owner>/<repository>/issues/<number>`.
- The issue must be open and must not be a pull request.
- The issue creator must be the repository owner named in the URL.
- The issue title must start exactly with `DSI Studio session`.
- DSI Studio's GitHub token must be able to read the issue and create or edit issue
  comments.

The repository may be public or private if the token has access. The privacy rules
below still apply because command results can expose local information to everyone
who can read the issue.

## Connect DSI Studio

1. Open the DSI Studio AI Agent window.
2. Click **Connect Issue**.
3. Paste the full GitHub issue URL.
4. Wait for the AI Agent status to report that it connected.

DSI Studio validates the issue and searches its comments for a JSON object containing:

```json
{"dsi_session_result":true}
```

If no such comment exists, DSI Studio creates one with an initial `idle` result.
After connection, DSI Studio polls the issue body about twice per second and uses an
ETag to avoid reprocessing an unchanged body.

## Issue request format

The issue body must contain one JSON object. Each actionable body needs a numeric
`id` greater than the last ID processed during the current connection.

Normal DSI Studio requests require a UUID `session` and use the same fields as the
named-pipe relay:

- `TITLE`
- `CHAT`
- `LIST`
- `LOG`
- `CMD`

DSI Studio supplies the issue channel's agent identity internally. Do not add or rely
on an `agent` field in the issue body.

### List windows

```json
{
  "id": 1,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "LIST"
}
```

### Run one command

```json
{
  "id": 2,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "main",
  "command": {
    "cmd": "run_shell",
    "param": "dir \"C:\\data\\*.fz\" /s /b"
  }
}
```

### Run an ordered command array

```json
{
  "id": 3,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": [
    {
      "cmd": "voice",
      "param": "I will now run tumor segmentation."
    },
    {
      "cmd": "segment_brain",
      "param": ["human_tumor_T1w", 8]
    },
    {
      "cmd": "list_region"
    }
  ]
}
```

Commands execute in array order. The reply contains one command result per item.
A `voice` item in a batch can be routed to the main window while the remaining
commands use the declared target window.

### Include the incremental work log

```json
{
  "id": 4,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": {"cmd":"list_tract","param":"status"},
  "include_log": true
}
```

When `include_log` is true, DSI Studio runs the requested operation and then performs
a separate `LOG` request for the same session. The result places that second reply in
`response.log`. Use this only when the new console/action history is needed because
large output increases GitHub transfer and parsing cost.

## Read the result comment

DSI Studio edits the same result comment after each processed request. A typical
result is:

```json
{
  "state": "done",
  "id": 3,
  "last_id": 3,
  "duration_ms": 120,
  "response": {
    "status": "success",
    "result": [
      {"cmd":"voice","status":"success"},
      {"cmd":"segment_brain","status":"success"},
      {"cmd":"list_region","status":"success"}
    ]
  },
  "dsi_session_result": true,
  "issue": 12,
  "updated_at": "2026-08-02T18:00:00Z"
}
```

Always match the result using `last_id`. Do not infer completion from the comment
edit time.

The outer issue-channel `state` is `idle` before the first processed request and
`done` after a request is forwarded. A forwarded DSI request can still fail, so always
inspect the nested `response.status`, `response.error`, and per-command results.

If the serialized result exceeds about 60 KiB, DSI Studio replaces `response` with a
truncation error instead of posting an oversized comment.

A successful reply for an asynchronous operation means the start command was
accepted; it does not prove the operation completed. Use the documented status
command in a later higher-ID request.

## Disconnect

The local user can click **Disconnect Issue** in the AI Agent window.

A remote controller can disconnect by replacing the issue body with a higher ID and:

```json
{"id":5,"request":"close"}
```

The `close` request disconnects the issue channel immediately. It does not close the
GitHub issue and does not publish a new final result comment. Do not wait for a
`closed` result state. Close the GitHub issue separately after confirming with the
local user that remote control has ended.

Closing the GitHub issue alone is not the documented disconnect mechanism. Use the
button or the explicit higher-ID `close` request.

## Reconnection behavior

Connecting starts a new local polling state with `last_id` reset to zero. Therefore,
reconnecting to an issue whose body still contains an old actionable request may run
that request again. Before reconnecting, replace the body with the next intended
higher-ID request or a harmless request whose effect is understood.

## Demo mode

When the user requests demo mode, follow the complete `Demo mode` rules in
`DSI_STUDIO_AI_MANUAL.md`.

Put a concise `voice` item before each major user-visible action, preferably in the
same ordered command array. Narrate the scientific or operational action rather than
the issue channel, polling, IDs, command arrays, or other orchestration details.

Do not claim success until the nested DSI response and any required later status
request verify it. Avoid overlapping speech.

## Operational rules

- Use one meaningful request per issue-body update.
- Increase `id` for every request during one connection.
- Keep one UUID `session` for related DSI work so `LOG` remains incremental.
- Use exact returned window IDs and verified file paths, indices, model IDs, and
  parameter IDs.
- Send asynchronous start commands only once, then inspect status with a later ID.
- Treat the result comment as a latest-result mailbox, not an append-only history.
- Do not reconnect while an old mutating request remains in the issue body unless
  repeating it is intentional.
- Use `run_shell` for restricted shell access.

## Privacy and security

Issue bodies and result comments can expose local paths, filenames, window titles,
command parameters, DSI Studio output, screenshots paths, and incremental logs. Do
not send credentials, protected information, patient-identifying information, or
other sensitive content through this channel.

The issue-author and title checks restrict which issue can be connected, but they do
not make issue content confidential. Use a private repository when appropriate,
limit the token's permissions, disconnect after use, and close the issue when the
session record is no longer needed.
