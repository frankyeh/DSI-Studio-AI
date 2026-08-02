# DSI Studio GitHub Issue Session

This workflow lets a remote ChatGPT session control an already-open DSI Studio on
the `HOME-FRANK` self-hosted Windows runner without starting a new runner job for
every command.

## Files

- `.github/workflows/chatgpt-dsi-issue-session.yml` starts the persistent session.
- `.github/scripts/dsi_issue_session.ps1` validates requests, communicates with DSI
  Studio, and publishes results.
- `.github/chatgpt-dsi-session-request.json` starts one session by identifying the
  issue to monitor.

The existing `.github/workflows/chatgpt-dsi-studio.yml` remains available for
one-command runs.

## Session sequence

1. Create a new open issue in `frankyeh/DSI-Studio-AI`. The repository owner must
   be the issue author.
2. Put the first request in the issue body.
3. Change `.github/chatgpt-dsi-session-request.json` to the issue number and commit
   it once.
4. The runner creates one result comment containing
   `"dsi_session_result": true` and monitors the issue body.
5. For each next action, replace the issue body with one JSON request whose `id`
   is greater than the preceding request ID.
6. Continue only after the fixed result comment reports the submitted `last_id` and
   a terminal state such as `done` or `error`.
7. End the session with a higher ID and `"request":"close"`. The runner writes
   `"state":"closed"` and exits.

Only one DSI Studio runner job is active at a time. A session expires after about
350 minutes if it is not closed first.

## Start request

Example `.github/chatgpt-dsi-session-request.json`:

```json
{"issue":12,"debug":false,"run":1}
```

- `issue` is the GitHub issue number.
- `debug` should normally be `false`. Use `true` only to diagnose a failed run.
- `run` only makes the start-file commit different. Increment it for each start.

The start-file commit launches the runner once. Subsequent commands use only issue
updates and do not create commits or workflow runs.

## Fast tracking request

Use `TRACK` when the goal is to open or reuse a FIB, start fiber tracking, wait for
actual completion, return the final tract table, and optionally speak a completion
message. This replaces several remote issue updates with one request.

### Open a FIB and track

```json
{
  "id": 1,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "TRACK",
  "path": "C:/data/subject.gqi.fz",
  "name": "Whole Brain",
  "timeout_seconds": 600,
  "poll_ms": 250,
  "voice": "Fiber tracking finished"
}
```

The runner performs these steps locally:

1. `open_fib` on `main`.
2. Extract the returned `tracking<hex-address>` ID.
3. Optionally apply `set_params`.
4. Start `run_tracking`.
5. Poll `list_tract status` until the output reports `done`.
6. Call `list_tract` and return the final bundle counts.
7. Optionally call `voice` and `LOG`.

### Reuse an existing tracking window

```json
{
  "id": 2,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "TRACK",
  "window": "tracking7ff6ab123410",
  "name": "CST",
  "set_params": "max_tract_count=50000&tip_iteration=0",
  "regions": "0:3&1:0",
  "include_log": true
}
```

`TRACK` fields:

| Field | Requirement and behavior |
|---|---|
| `id` | Positive integer greater than the preceding request ID. |
| `session` | UUID reused throughout the issue session. |
| `request` | Must be `TRACK`. |
| `path` | FIB/FZ path to open. Supply exactly one of `path` or `window`. |
| `window` | Existing `tracking<hex-address>` ID. Supply exactly one of `path` or `window`. |
| `name` | Required nonempty new tract-bundle name. |
| `set_params` | Optional `name=value[&name=value...]` tracking settings. |
| `regions` | Optional explicit ROI settings such as `0:3&1:0`. Validate region indices first. |
| `timeout_seconds` | Optional completion timeout, 1–1800 seconds; default 600. |
| `poll_ms` | Optional local DSI status interval, 100–5000 ms; default 250. |
| `voice` | Optional text spoken after successful completion. |
| `include_log` | Optional `true` to append the incremental DSI work log. |

A successful result contains `workflow.window`, `workflow.start`,
`workflow.status`, `workflow.poll_count`, `workflow.tracking_ms`, and
`workflow.final`. The request is `done` only after `list_tract status` reports
`done`; a successful `run_tracking` launch alone is not treated as completion.

Validated on August 2, 2026 with
`C:/Users/YEHFC/AppData/Local/Temp/hcp-ya/100307.gqi.fz`: one issue request opened
the FIB, derived the tracking window, completed whole-brain tracking after two local
status polls, returned 154,823 tracts, and spoke completion. The complete runner-side
workflow took 4.603 seconds.

## Standard issue request format

Every issue body must contain exactly one JSON object.

### List windows

```json
{
  "id": 3,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "LIST"
}
```

### Run one command

```json
{
  "id": 4,
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
  "id": 5,
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

Standard DSI request types are `TITLE`, `CHAT`, `LIST`, `LOG`, and `CMD`. Their
fields and DSI Studio behavior are documented in `DSI_STUDIO_AI_MANUAL.md`.
`TRACK` is a workflow-level convenience request that composes those ordinary DSI
commands without changing the DSI Studio relay protocol.

Command parameters may be strings, numbers, arrays, or composite strings, matching
the ordinary DSI Studio relay format.

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

A standard successful response resembles:

```json
{
  "state": "done",
  "id": 4,
  "last_id": 4,
  "duration_ms": 52,
  "response": {
    "status": "success"
  },
  "dsi_session_result": true,
  "issue": 12,
  "run": 30733485245,
  "updated_at": "2026-08-02T05:05:37.2595168Z"
}
```

Result states:

| State | Meaning |
|---|---|
| `ready` | Runner is connected and waiting for a higher request ID. |
| `done` | The standard command completed, or a `TRACK` request reached definitive tracking completion. |
| `error` | Validation, named-pipe communication, JSON parsing, or DSI Studio failed. The runner remains active for a corrected higher ID. |
| `closed` | The issue was closed or a `close` request ended the runner. |
| `expired` | The persistent session reached its time limit. |

Always match the result by `last_id`; do not infer completion from comment time or
workflow status alone. The fixed comment is replaced for every result instead of
adding one comment per command.

## Speed and reliability behavior

- The runner polls issue changes every 250 ms using authenticated ETags.
- The first `ready` comment is created once; a redundant startup update was removed.
- Each DSI command still uses a new named-pipe connection. Keeping one pipe open
  across requests is unsupported.
- `TRACK` performs asynchronous status polling locally, avoiding repeated remote
  issue-update and comment-read cycles.
- DSI errors at any composed `TRACK` stage stop the workflow request and return
  `state:error` with the failed stage.
- Result strings are capped before publication. If the complete JSON would exceed
  the GitHub issue-comment limit, large response fields are omitted and the result
  reports `truncated:true` instead of failing the session.
- GitHub mutations remain separated by at least one second to reduce secondary
  rate-limit risk.

## Validation and recovery

- IDs must be positive integers and strictly increase.
- Reusing an old ID is ignored.
- An invalid request produces `state:error` but does not stop the runner.
- The issue must be open, must not be a pull request, and must have been opened by
  the repository owner.
- Standard window IDs must be `main`, `recon<hex-address>`,
  `tracking<hex-address>`, or `image<hex-address>`.
- The runner restores `last_id` from the fixed result comment if restarted on the
  same issue.
- DSI Studio must already be open on the same desktop as the self-hosted runner.
- After an ambiguous timeout or runner interruption, inspect `LIST`, `LOG`, or the
  relevant DSI status before retrying a command that may already have started.

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
