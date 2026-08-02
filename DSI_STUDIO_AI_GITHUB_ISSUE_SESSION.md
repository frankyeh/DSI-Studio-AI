# DSI Studio GitHub Issue Session

This workflow lets a remote ChatGPT session control an already-open DSI Studio on
the `HOME-FRANK` self-hosted Windows runner.

## No repository commits during control

Normal DSI Studio control uses only:

- opening one GitHub issue to start the session;
- replacing that issue's body with each request; and
- one fixed bot comment for the latest result.

The production workflow has `contents: read` permission. It does not write request
files, result files, or commits to the repository. Do not use a pushed JSON request
file to start or operate a DSI Studio session.

## Start a session

Create a new issue in `frankyeh/DSI-Studio-AI`:

1. The issue must be opened by `frankyeh`.
2. Its title must start with `DSI Studio session`.
3. Its body must contain the first complete JSON request.

Example:

```json
{"id":1,"session":"7dd34326-b99a-4ba5-9de6-2d48188022f3","request":"LIST"}
```

Opening the issue starts `.github/workflows/chatgpt-dsi-issue-session.yml`. The
workflow runs on `HOME-FRANK`, connects to `\\.\pipe\dsi-studio`, and creates one
fixed result comment containing `"dsi_session_result":true`.

Continue only when the result comment reports the submitted ID in `last_id` and
`state` is `done` or `error`.

Only one DSI Studio runner job is active at a time. A session expires after about
350 minutes if it is not closed first.

## Issue request format

Every issue body contains exactly one JSON object. Supported request types are
`TITLE`, `CHAT`, `LIST`, `LOG`, and `CMD`, matching the ordinary DSI Studio relay.
The `session` field must be a UUID and remain unchanged throughout one issue session.

Increase `id` for every issue-body update. Never reuse or decrease it.

### Send one command

```json
{
  "id": 2,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "main",
  "command": {
    "cmd": "hub_repo"
  }
}
```

### Send an ordered command array

DSI Studio accepts an ordered array in `command`. The issue action validates every
item and forwards the complete array in one `CMD` request.

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

Commands execute in array order. The response contains one result entry per item.
Use one array when narration and the following action must be sent together.

In DSI Studio builds containing commit
`ec6576812b0e6d24a6092e85e1f9ec1ff7e58ce4`, a `voice` item inside a batch targeted
at a tracking, reconstruction, or image window is routed internally to the main
window. The remaining items continue on the requested target window. Rebuild and
restart DSI Studio after that source change before relying on this cross-window
voice routing.

All non-`voice` commands in one batch target the declared `window`.

### Include the incremental DSI work log

```json
{
  "id": 4,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": {"cmd":"list_tract"},
  "include_log": true
}
```

Use `include_log` only when new console/action history is needed. Large logs increase
GitHub transfer and parsing time.

Command parameters may be strings, numbers, arrays, or composite strings, matching
`DSI_STUDIO_AI_MANUAL.md`.

## Read the result

The runner edits the same bot comment after every request. Match the response using
`last_id`, never timestamps.

A successful batch resembles:

```json
{
  "state": "done",
  "id": 3,
  "last_id": 3,
  "response": {
    "status": "success",
    "result": [
      {"cmd":"voice","status":"success"},
      {"cmd":"segment_brain","status":"success"},
      {"cmd":"list_region","status":"success"}
    ]
  },
  "dsi_session_result": true
}
```

Result states:

| State | Meaning |
|---|---|
| `ready` | Runner is connected and waiting for a higher request ID. |
| `done` | DSI Studio completed the immediate request without an error. |
| `error` | Validation, pipe communication, JSON parsing, or DSI Studio failed. The runner remains active for a corrected higher ID. |
| `closed` | The issue was closed or a `close` request ended the runner. |
| `expired` | The persistent session reached its time limit. |

A successful `voice` result confirms that DSI Studio started the PowerShell/SAPI
process. It does not prove that audible speech completed.

A successful start response for a long-running operation does not prove that the
operation finished. Use a later status command rather than automatically retrying.

## Close the session

Replace the issue body with a higher ID:

```json
{"id":5,"request":"close"}
```

Wait for:

```json
{"state":"closed","last_id":5}
```

Then close the GitHub issue. Closing the issue directly also stops the runner after
its next poll, but explicit `close` provides a deterministic final result.

## Operational rules

- Send one meaningful DSI request per issue-body update.
- Put related DSI operations in one `command` array when ordering matters.
- Match every response using `last_id`.
- Use exact returned window IDs; do not construct or guess them.
- For asynchronous work, send the start command once and inspect its status in a
  later request.
- An invalid request produces `state:error` without terminating the session.
- The issue must remain open, must not be a pull request, and must be owned by the
  repository owner.
- DSI Studio must already be open on the same desktop as the self-hosted runner.

## Privacy and security

`DSI-Studio-AI` is public. Issue bodies and comments may expose local paths,
filenames, window titles, parameters, DSI output, or logs. Do not send credentials,
protected information, patient-identifying information, or other sensitive content
through this channel.

Use a new issue for each independent control session, send `close` when finished,
and close the issue after reviewing the final result.
