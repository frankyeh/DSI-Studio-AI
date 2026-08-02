# DSI Studio GitHub Issue Session

This workflow lets a remote ChatGPT session interact with an already-open DSI
Studio on the `HOME-FRANK` self-hosted Windows runner without starting a new runner
job for every command.

## Files

- `.github/workflows/chatgpt-dsi-issue-session.yml` starts the persistent session.
- `.github/scripts/dsi_issue_session.ps1` validates commands, talks to DSI Studio,
  and publishes results.
- `.github/chatgpt-dsi-session-request.json` starts one session by identifying the
  issue to monitor.

The existing `.github/workflows/chatgpt-dsi-studio.yml` remains available for a
single independent command.

## Interactive sequence

1. Create a new open issue in `frankyeh/DSI-Studio-AI`. The repository owner must
   be the issue author.
2. Put the first DSI Studio request in the issue body.
3. Change `.github/chatgpt-dsi-session-request.json` to the issue number and commit
   it once.
4. The runner creates one fixed result comment containing
   `"dsi_session_result":true` and monitors the issue body.
5. Replace the issue body with one next command whose `id` is greater than the
   preceding ID.
6. Read the fixed result comment. Continue only when `last_id` equals the submitted
   ID and `state` is `done` or `error`.
7. Use the result to decide the next interactive command.
8. End with a higher ID and `"request":"close"`. The runner writes
   `"state":"closed"` and exits.

Only one DSI Studio runner job is active at a time. A session expires after about
350 minutes if it is not closed first.

## Start request

Example `.github/chatgpt-dsi-session-request.json`:

```json
{"issue":12,"debug":false,"run":1}
```

- `issue` is the GitHub issue number.
- `debug` should normally be `false`. Use `true` only to diagnose one failed run.
- `run` only makes the start-file commit different. Increment it for each new
  session start.

The start-file commit launches the runner once. All later commands use only issue
updates and do not create commits or workflow runs.

## Issue request format

Every issue body contains exactly one JSON object. Supported request types are
`TITLE`, `CHAT`, `LIST`, `LOG`, and `CMD`, matching the ordinary DSI Studio relay.

### Set the task title

```json
{
  "id": 1,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "TITLE",
  "title": "Interactive fiber tracking"
}
```

### List windows

```json
{
  "id": 2,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "LIST"
}
```

### Run one command

```json
{
  "id": 3,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "main",
  "command": {
    "cmd": "list_recent_fib"
  }
}
```

### Run one command with a parameter

```json
{
  "id": 4,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": {
    "cmd": "list_tract",
    "param": "status"
  }
}
```

### Include the incremental DSI work log

```json
{
  "id": 5,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": {
    "cmd": "list_tract"
  },
  "include_log": true
}
```

Use `include_log` only when the new console/action history is needed. Large logs
increase GitHub transfer and ChatGPT parsing time.

The `session` field must be a UUID and should remain unchanged throughout one issue
session. Command parameters may be strings, numbers, arrays, or composite strings,
matching the ordinary DSI Studio relay format documented in
`DSI_STUDIO_AI_MANUAL.md`.

## Interactive operating rules

- Send exactly one meaningful DSI request per issue update.
- Match each result using `last_id`; never infer completion from comment time.
- Use the returned window ID directly after `open_src`, `open_fib`, or `open_image`.
- Do not call `LIST` merely to rediscover a window ID that was just returned.
- For asynchronous work such as fiber tracking, first send `run_tracking`, then use
  later interactive requests to inspect `list_tract status` and decide what to do.
- A successful start response means the operation started; it does not prove an
  asynchronous task is finished.
- Keep the session open while ChatGPT and the user continue interacting. Send
  `close` only after the task is complete.

## Close request

```json
{"id":6,"request":"close"}
```

`close` does not need a session UUID. Its ID must still be greater than the prior
request ID.

Closing the GitHub issue also stops the runner after its next poll, but explicit
`close` is preferred because it writes a deterministic final result.

## Result comment

The runner creates or reuses one issue comment marked:

```json
{"dsi_session_result":true}
```

A successful response resembles:

```json
{"state":"done","id":3,"last_id":3,"duration_ms":52,
 "response":{"status":"success"},"dsi_session_result":true,
 "issue":12,"run":30733485245,
 "updated_at":"2026-08-02T05:05:37.2595168Z"}
```

Result states:

| State | Meaning |
|---|---|
| `ready` | Runner is connected and waiting for a higher request ID. |
| `done` | DSI Studio completed the immediate request without an error. |
| `error` | Validation, pipe communication, JSON parsing, or DSI Studio failed. The runner remains active for a corrected higher ID. |
| `closed` | The issue was closed or a `close` request ended the runner. |
| `expired` | The persistent session reached its time limit. |

The fixed comment is replaced for every result rather than adding one comment per
command.

## Interactive latency optimizations

- The first issue body is processed immediately after startup instead of waiting for
  another issue poll.
- The runner polls every 100 ms for 30 seconds after each result, when the next
  interactive command is most likely. It backs off to 500 ms while idle.
- Polling uses authenticated ETags and one persistent `HttpClient` connection.
- There is no artificial one-second delay before publishing each result.
- Results are compact JSON rather than pretty-printed JSON.
- Each DSI request still uses a fresh named-pipe connection because the current DSI
  Studio relay closes the connection after one response.
- Result strings are capped before publication. If the complete JSON exceeds the
  GitHub issue-comment limit, large fields are omitted and the result reports
  `truncated:true` rather than terminating the session.

The main remaining delay is the public GitHub round trip: ChatGPT updates the issue,
the runner detects it, the runner updates the fixed comment, and ChatGPT reads that
comment. Keeping one runner active removes repeated runner startup, checkout, and
workflow-log packaging.

## Validation and recovery

- IDs must be positive integers and strictly increase.
- Reusing an old ID is ignored.
- An invalid request produces `state:error` but does not stop the runner.
- The issue must be open, must not be a pull request, and must have been opened by
  the repository owner.
- Window IDs must be `main`, `recon<hex-address>`, `tracking<hex-address>`, or
  `image<hex-address>`.
- The runner restores `last_id` from the fixed result comment if restarted on the
  same issue.
- DSI Studio must already be open on the same desktop as the self-hosted runner.
- After an ambiguous timeout or interruption, inspect `LIST`, `LOG`, or the relevant
  DSI status before retrying an operation that may already have started.

## Privacy and security

`DSI-Studio-AI` is a public repository. Issue bodies and comments are public and may
reveal local paths, filenames, window titles, command parameters, DSI Studio output,
or work logs. Do not send protected, confidential, credential, patient-identifying,
or otherwise sensitive information through this channel.

The workflow accepts only issues opened by the repository owner and validates the
request structure before connecting to the local named pipe. This limits who can
start a usable mailbox but does not make the public issue confidential.

Use a new issue for each independent control session, send `close` when finished,
and close the issue after reviewing the final result.
