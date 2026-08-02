# DSI Studio GitHub Issue Session

This workflow lets a remote ChatGPT session control an already-open DSI Studio on
the `HOME-FRANK` self-hosted Windows runner without starting a new runner job for
every command.

## Files

- `.github/workflows/chatgpt-dsi-issue-session.yml` runs the persistent session.
- `.github/chatgpt-dsi-session-request.json` starts one session by identifying the
  issue to monitor.

The existing `.github/workflows/chatgpt-dsi-studio.yml` remains available for
one-command runs.

## Session sequence

1. Create a new open issue in `frankyeh/DSI-Studio-AI`. The repository owner must
   be the issue author.
2. Put the first DSI Studio request in the issue body.
3. Start the runner by changing `.github/chatgpt-dsi-session-request.json` to the
   issue number and committing it.
4. The runner creates one result comment containing
   `"dsi_session_result": true` and then monitors the issue body.
5. For each next action, replace the issue body with one JSON request whose `id`
   is greater than the preceding request ID.
6. Read the fixed result comment. Continue only after its `last_id` equals the
   submitted request ID.
7. End the session by replacing the issue body with a higher ID and
   `"request":"close"`. The runner writes `"state":"closed"` and exits.

Only one DSI Studio runner job is active at a time. A session expires after about
350 minutes if it is not closed first.

## Start request

Example `.github/chatgpt-dsi-session-request.json`:

```json
{"issue":12,"debug":false,"run":1}
```

- `issue` is the GitHub issue number.
- `debug` should normally be `false`. Use `true` only to diagnose a failed
  workflow, then inspect that exact run log.
- `run` is a caller-controlled value used only to make each start-file commit
  different. Increment it for each new start.

The start-file commit launches the runner once. Subsequent DSI commands use only
issue updates and do not create commits or workflow runs.

## Issue request format

Every issue body must contain exactly one JSON object.

### List windows

```json
{
  "id": 1,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "LIST"
}
```

### Run a command

```json
{
  "id": 2,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "main",
  "command": {
    "cmd": "list_recent_fib"
  }
}
```

### Run a command and retrieve the incremental DSI work log

```json
{
  "id": 3,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": {
    "cmd": "list_tract",
    "param": "status"
  },
  "include_log": true
}
```

The supported request types are `TITLE`, `CHAT`, `LIST`, `LOG`, and `CMD`. Their
fields and DSI Studio behavior are the same as documented in
`DSI_STUDIO_AI_MANUAL.md`.

The `session` field must be a UUID and should remain unchanged throughout one issue
session. Command parameters may be strings, numbers, arrays, or composite strings,
matching the ordinary DSI Studio relay format.

## Close request

```json
{"id":4,"request":"close"}
```

`close` does not need a session UUID. Its ID must still be greater than the prior
request ID.

Closing the GitHub issue also makes the runner stop after its next poll, but an
explicit `close` command is preferred because it writes a deterministic final
result.

## Result comment

The runner creates or reuses one issue comment marked:

```json
{"dsi_session_result":true}
```

A successful response resembles:

```json
{
  "state": "done",
  "id": 2,
  "last_id": 2,
  "duration_ms": 4,
  "response": {
    "status": "success"
  },
  "dsi_session_result": true,
  "issue": 12,
  "run": 30733005490,
  "updated_at": "2026-08-02T04:48:54.7105984Z"
}
```

Result states:

| State | Meaning |
|---|---|
| `ready` | Runner is connected to the issue and waiting for a higher request ID. |
| `done` | DSI Studio accepted the request and did not return an immediate error. |
| `error` | Validation, pipe communication, JSON parsing, or DSI Studio failed. The runner remains active for a corrected higher ID. |
| `closed` | The issue was closed or a `close` request ended the runner. |
| `expired` | The persistent session reached its time limit. |

Always match the result by `last_id`; do not infer completion from comment time or
workflow status alone. The comment is replaced for every result instead of adding a
new comment for each command.

## Validation and recovery

- IDs must be positive integers and strictly increase.
- Reusing an old ID is ignored.
- An invalid command produces `state:error` but does not stop the runner.
- The issue must be open, must not be a pull request, and must have been opened by
  the repository owner.
- Window IDs must be `main`, `recon<hex-address>`, `tracking<hex-address>`, or
  `image<hex-address>`.
- The runner restores `last_id` from the fixed result comment if a session is
  restarted on the same issue.
- DSI Studio must already be open on the same desktop as the self-hosted runner.

## Privacy and security

`DSI-Studio-AI` is a public repository. Issue bodies and comments are public and may
reveal local paths, filenames, window titles, command parameters, DSI Studio output,
or work logs. Do not send protected, confidential, credential, patient-identifying,
or otherwise sensitive information through this channel.

The workflow accepts only issues opened by the repository owner and validates the
DSI request structure before connecting to the local named pipe. This limits who can
start a usable mailbox but does not make the public issue confidential.

Use a new issue for each independent control session, send `close` when finished,
and close the issue after reviewing the final result.
