# DSI Studio ChatGPT (Web) GitHub Issue Channel

DSI Studio can use one private GitHub issue as a command/result mailbox for
ChatGPT Web. ChatGPT writes the next request into the issue body. DSI Studio
writes the latest result into one issue comment marked
`"dsi_session_result":true`.

```text
ChatGPT Web -> private GitHub issue -> DSI Studio
ChatGPT Web <- result comment       <- DSI Studio
```

This route does not use GitHub Actions, workflow dispatch, repository request
files, result files, or commits.

Use a private repository because requests and results may contain local paths,
filenames, window titles, command parameters, processing output, and incremental
logs. Do not place credentials, protected health information, patient identifiers,
or unpublished confidential data in the issue.

## Repository requirements

Use a private repository owned by a personal GitHub account. The issue creator
must be the same personal account shown as the repository owner in the issue URL.

For example, an issue in:

```text
https://github.com/frankyeh/DSI-Studio-Connect/issues/7
```

must be created by `frankyeh`.

An organization-owned repository is not supported by the current validation
because an issue is created by a user account, not by the organization itself.

The repository may be empty. It needs only:

- private visibility;
- Issues enabled;
- access for the ChatGPT GitHub integration;
- access for the fine-grained token configured in DSI Studio.

No Contents, Actions, Workflows, Pull requests, or Administration permission is
needed for this channel.

## Agent repository selection

When the user has not named an exact repository, the ChatGPT agent should:

1. List private repositories visible through the connected GitHub integration.
2. Keep personal-account repositories whose owner matches the authenticated user.
3. Show the exact `owner/repository` names and let the user select one.
4. Prefer a dedicated repository such as `owner/DSI-Studio-Connect`.
5. Confirm that the integration can create, read, and update issues there.

Do not silently select a public or organization-owned repository. General code
access does not prove that issue actions are available. Creating and then reading
the session issue is the practical ChatGPT-side access test.

If the user already names an exact repository, verify that repository instead of
listing alternatives.

## One-time DSI Studio token setup

DSI Studio uses a GitHub token separate from the GitHub integration used by
ChatGPT.

Create a fine-grained personal access token:

1. In GitHub, open **Settings**.
2. Open **Developer settings**.
3. Open **Personal access tokens** -> **Fine-grained tokens**.
4. Select **Generate new token**.
5. Give it a narrow name such as `DSI Studio issue channel`.
6. Set a reasonable expiration date.
7. Under **Repository access**, choose **Only select repositories**.
8. Select the private issue-channel repository.
9. Under **Repository permissions**, set **Issues** to **Read and write**.
10. Leave unrelated permissions without access.
11. Generate the token and copy it immediately.

The token owner need not technically be the repository owner, but the token must
have access to the selected private repository. Using the same account for the
repository owner, issue creator, and token owner is the simplest arrangement.

Never paste the token into ChatGPT, an issue, a repository file, a prompt, a
screenshot, or a command result.

Configure it in DSI Studio:

1. Open the **AI Agent** window.
2. Open **AI Settings**.
3. Paste the token into **GitHub token (issue channel)**.
4. Click **Save**.

If no token is configured, **ChatGPT (Web)** is disabled in the New Chat dialog
and DSI Studio displays a setup hint.

The token is stored in local `QSettings`. Revoke or rotate it if the computer or
settings storage may have been exposed.

## What DSI Studio verifies

Starting a ChatGPT (Web) connection performs real GitHub API operations. DSI Studio:

1. Calls `GET /user` to identify the token owner.
2. Reads the selected issue.
3. Reads up to 100 issue comments.
4. Reuses a result comment authored by the token owner and marked
   `"dsi_session_result":true`, choosing the one with the highest `last_id` if
   more than one exists.
5. Creates an initial result comment with
   `POST /issues/<number>/comments` if none exists.
6. Updates that comment with `PATCH /issues/comments/<comment-id>` after each
   processed request.

The connection fails if the token cannot read the issue or comments or cannot
create the initial result comment. Later permanent authorization failures stop the
channel. Therefore the repository must be included in the token scope and
**Issues: Read and write** must be enabled.

DSI Studio also validates that:

- the URL uses HTTPS with host `github.com`;
- the URL has the exact issue form, not a pull-request URL;
- the issue is open;
- the issue creator is the personal repository owner named in the URL;
- the issue title starts exactly with `DSI Studio session`.

Each GitHub request has a 15-second transfer timeout. Transient network failures
are retried. Rate limits use GitHub's retry/reset information. Permanent HTTP
failures such as authorization loss stop the channel.

## Give ChatGPT access to the private repository

ChatGPT must use a connected GitHub integration that supports issue creation,
issue reading, issue-body updates, issue-comment reading, and issue closing.

1. In ChatGPT, open **Settings** -> **Apps**.
2. Open the GitHub app configuration.
3. Grant access to the private issue-channel repository.
4. If the repository was created later, add it to the app's selected repositories.
5. Start a new ChatGPT conversation if the repository is not visible in the current
   one.

The credentials have separate roles:

- ChatGPT uses its GitHub integration to select the repository, create the session
  issue, replace its body, read the result comment, and close the issue.
- DSI Studio uses its locally stored token to read the issue and create or update
  the result comment.

The agent must never request, receive, repeat, display, or test the DSI Studio token.

## Start a new session

### Agent procedure

The ChatGPT agent should:

1. Resolve and verify the exact private personal repository.
2. Create one new issue in that repository.
3. Give it a concise descriptive title beginning exactly with:

   ```text
   DSI Studio session
   ```

   For example:

   ```text
   DSI Studio session corticospinal tract mapping
   ```

   When the first valid request creates the DSI Studio chat, DSI Studio
   automatically uses the complete issue title as the chat title.

4. Use a non-actionable initial body such as:

   ```json
   {"state":"waiting for DSI Studio connection"}
   ```

5. Read the new issue to confirm access and give its URL to the user.
6. Tell the user to connect DSI Studio using the procedure below.
7. After connection, read the issue comments and find the token-owned comment whose
   JSON contains:

   ```json
   {"dsi_session_result":true}
   ```

8. Do not send a request until that result comment exists.
9. Generate one canonical UUID without braces and keep it for the entire task.
   Do not reuse that session UUID for another issue or unrelated task.
10. Replace the issue body with one request JSON object at a time.
11. Use a positive integer `id` greater than the result comment's `last_id`.
12. After every update, read the same result comment and wait until `last_id`
    equals the submitted ID.
13. Inspect the nested reply before deciding the next command.
14. For asynchronous work, send the start command once and use later higher-ID
    status requests instead of repeating it.
15. At the end, send a higher-ID remote-close request, verify `state:"closed"` when
    available, and then close the GitHub issue.

Commands belong only in the issue body. Do not use issue comments to send commands.
Do not create request/result files, workflow dispatches, commits, or GitHub Actions.

### DSI Studio user procedure

There is no separate **Connect Issue** or **Reconnect Issue** button.

To start the channel:

1. Open DSI Studio's **AI Agent** window.
2. Click **New Chat**.
3. In **Agent**, select **ChatGPT (Web)**.
4. Paste the complete issue URL into **Issue URL**.
5. Click **Start**.

The URL must have this exact form:

```text
https://github.com/<owner>/<repository>/issues/<number>
```

After a successful connection:

- the agent label shows `ChatGPT(Web)`;
- the status reports `Connected to <issue URL>`;
- the main action button shows **Stop**;
- DSI Studio creates or reuses the result comment and begins polling the issue body.

Connecting does not yet create a DSI Studio chat entry. The chat is created when
DSI Studio receives the first valid request containing a new `session` UUID.

Common connection failures include:

- no token is configured;
- the repository is outside the token's selected repository scope;
- **Issues: Read and write** is missing;
- the issue is closed;
- the URL points to a pull request;
- the issue creator is not the repository owner;
- the issue title does not start with `DSI Studio session`.

## Stop and resume

While connected, the main action button shows **Stop**. Clicking **Stop** disconnects
the GitHub channel. It does not close DSI Studio, remove the chat, or close the issue.

After stopping the active web session, the button shows **Resume**. Clicking it:

1. Opens **Resume Chat** locked to **ChatGPT (Web)**.
2. Prefills the most recently used issue URL.
3. Allows the URL to be reviewed or changed.
4. Reconnects after the user clicks **Resume**.

Selecting an existing ChatGPT web chat and clicking the `ChatGPT(Web)` agent label
opens the same reconnect dialog. There is no separate reconnect command or button.

When resuming the same issue:

- keep the existing result comment;
- keep the same session UUID to continue the same DSI Studio chat;
- use an ID greater than the existing `last_id`;
- never resend an already acknowledged request.

Using a different session UUID creates a different DSI Studio chat when the next
request arrives.

## Issue request format

The issue body must contain one JSON object. A normal actionable request uses:

- `id`: a positive integer greater than the current `last_id`;
- `session`: one canonical UUID without braces;
- `command`: one command object or an ordered array of command objects;
- `chat`: optional user-facing text;
- `reasoning`: optional brief reasoning summary recorded in chat history;
- `include_log`: optional Boolean requesting a separate incremental `log` reply.

A request may contain `command`, `chat`, `reasoning`, or a useful combination. A
`chat`-only or `reasoning`-only request is valid. A request with none of these fails
with `missing command field`.

DSI Studio injects the web-agent identity internally as
`Codex/ChatGPT-GitHub`. Do not add or rely on an `agent` field.

There is no normal request-type keyword and no per-request `window` or `title`
field. The sole exception is the remote `{"request":"close"}` envelope described
later.

### Automatic chat creation and title

The first valid request with a new session UUID:

1. creates the DSI Studio web chat;
2. executes the submitted chat/command content;
3. internally runs `set_title` with the complete GitHub issue title.

That internal title operation is not included in the published command result. Do
not use `set_title` as the first request because the automatic issue-title operation
runs afterward and overwrites it. Use a descriptive issue title, or send `set_title`
in a later request after the chat exists.

### Command and parameter encoding

A command object has this form:

```json
{"cmd":"command-name","param":"optional value"}
```

`param` may be:

- omitted for a parameterless command;
- one string, number, or Boolean;
- an array when the command needs multiple separate values.

Commands in an array execute in order and stop after the first error. The reply
contains one result for every attempted command, including `set_window`.

### Command routing and persistent window selection

Each session starts with `main` selected. The current dispatcher applies this order
to every command in a request:

1. `bring_to_front`, `minimize`, `maximize`, and window `close` are handled centrally
   and act directly on the selected supported window.
2. `set_title`, `log`, and `set_window` are handled as session commands.
3. `list_window` is handled as dispatcher-level discovery.
4. Every remaining command is offered to `MainWindow` first.
5. If `MainWindow` reports the command as unknown, DSI Studio forwards it to the
   session's persistently selected reconstruction, tracking, or image window.

This means main/global commands such as `voice`, `run_cli`, `run_shell`, and
main-window open/list commands remain available while a non-main window is selected.
`run_cli` and `run_shell` use their own behavior rather than the selected data window.
The four shared window controls are different: they always act on the selected target
instead of being offered to `MainWindow` first.

Use `set_window main`, or `set_window` with no parameter, to return the persistent
target to `main`.

Prefer an exact ID returned by `list_window` or an open command:

```json
{"cmd":"set_window","param":"tracking7ff6ab123410"}
```

The current interface also accepts a bare window type plus a distinctive filename:

```json
{"cmd":"set_window","param":["tracking","subject.fz"]}
```

Supported bare types are `tracking`, `recon`, and `image`. Exact IDs are safer when
more than one similar window is open.

### Shared window controls

The four shared controls take no parameter:

```json
{"cmd":"bring_to_front"}
{"cmd":"minimize"}
{"cmd":"maximize"}
{"cmd":"close"}
```

Their behavior is:

- `bring_to_front` calls `showNormal()`, raises, and activates the selected window;
  a maximized window is restored to normal before being brought forward;
- `minimize` calls `showMinimized()`;
- `maximize` calls `showMaximized()`;
- `close` closes the selected reconstruction, tracking, or image window;
- `close` fails when `main` is selected because AI cannot close the main window.

An AI-issued tracking-window close bypasses the local `Tractography not saved`
prompt. Confirm before closing when unsaved tracts may exist. Put window `close` last
in an ordered command array.

After a window closes, the session still remembers its now-invalid ID. Verify the
window disappeared with `list_window`, then send `set_window main` or select another
current ID before issuing a later window-specific command. Otherwise the later
command can fail because the target window no longer exists.

If another AI command currently has a supported window locked, a shared control may
fail with `another CMD is running; check opened windows`. Inspect `list_window` and
retry only after the active command finishes.

Read `DSI_STUDIO_AI_WINDOW_COMMANDS.md` for the complete shared-window rules.

### Window close versus issue-channel close

These are different protocol operations:

```json
{
  "id": 7,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "command": {"cmd":"close"}
}
```

closes the selected DSI Studio data window. It does not disconnect the issue channel.

```json
{"id":8,"request":"close"}
```

disconnects the GitHub issue channel after publishing `state:"closed"`. It does not
close a DSI Studio data window, DSI Studio itself, or the GitHub issue.

Never substitute one form for the other.

### Internal CLI and restricted shell commands

`run_cli` executes one DSI Studio command-line action inside the running DSI Studio
process. Put the complete command line in one string:

```json
{
  "id": 9,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "command": {
    "cmd": "run_cli",
    "param": "--action=vis --source=C:/data/subject.fz --cmd=list_tract"
  }
}
```

Missing `--action` defaults to `vis`. The action uses its own CLI/global state and
does not target the session's `set_window` selection. Wildcard looping and the
action's own required options apply. `run_cli` normally remains active until the
internal action returns.

`run_shell` accepts only one `cd`, `dir`, or `curl` string. For asynchronous curl,
initialize the log cursor on the start request:

```json
{
  "id": 10,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "command": {
    "cmd": "run_shell",
    "param": "curl -L -o \"subject.fz\" \"https://example.org/subject.fz\""
  },
  "include_log": true
}
```

`cd` changes DSI Studio's process-wide current directory. `dir` is synchronous.
`curl` is asynchronous: its immediate result reports a synthetic `curlN` task ID,
not transfer completion. The immediate `response.log` may be empty; on the first log
read, DSI Studio initializes the cursor at the current end of the console. Poll
`list_window` until that `curlN` entry disappears, then send a later higher-ID `log`
request to retrieve transfer output or errors. A separate `log` request before curl
is equivalent to using `include_log:true` on the start request.

Do not put a command that depends on the downloaded file after `curl` in the same
command array. Never send a DSI Studio `--action=...` line through `run_shell`, and
never send an operating-system command through `run_cli`. Read
`DSI_STUDIO_AI_CLI_SHELL_COMMANDS.md` before using either command.

### First request: list windows

```json
{
  "id": 1,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "command": {"cmd": "list_window"}
}
```

`list_window` returns one command result whose `output` is compact JSON containing:

- `application.status`;
- each supported window ID;
- each window's `status`: `idle`, `busy`, or `waiting`;
- each window's current title.

`waiting` means a modal local dialog needs user input. Active asynchronous shell
transfers also appear as synthetic `curlN` entries with `status:"busy"`.

### Send user-facing progress

```json
{
  "id": 2,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "chat": "I am checking the open windows before selecting the tractography window."
}
```

### Select a window and run an ordered command array

```json
{
  "id": 3,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "command": [
    {"cmd": "set_window", "param": "tracking7ff6ab123410"},
    {"cmd": "voice", "param": "I will now map the selected tract."},
    {"cmd": "run_auto_track", "param": "<exact identifier returned by list_auto_tract>"}
  ]
}
```

Here `voice` is still handled by `MainWindow`; `run_auto_track`, if unknown to
`MainWindow`, is forwarded to the selected tracking window.

### Include the incremental work log

```json
{
  "id": 4,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "command": {"cmd": "list_tract", "param": "status"},
  "include_log": true
}
```

When `include_log` is true, DSI Studio runs a separate `log` command after the main
operation and places that complete command reply in `response.log`. The first log
read starts at the session's current console position instead of returning the full
historic console. Later reads return only new non-debug output, subject to size caps.

### Rename the chat after creation

```json
{
  "id": 5,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "command": {"cmd": "set_title", "param": "Corticospinal tract mapping"}
}
```

Send this only after at least one earlier request has created the chat.

## Read the result comment

DSI Studio edits the same result comment after every processed request. A typical
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
      {
        "cmd": "set_window",
        "status": "success",
        "output": "current window: tracking7ff6ab123410"
      },
      {"cmd": "voice", "status": "success"},
      {"cmd": "run_auto_track", "status": "success"}
    ]
  },
  "dsi_session_result": true,
  "issue": 7,
  "updated_at": "2026-08-04T01:00:00Z"
}
```

Always match completion using `last_id`. Do not infer completion from issue activity,
comment edit time, or elapsed time.

The outer `state` may be:

- `idle`: the result comment exists but no request has been processed;
- `done`: the complete reply contains no reported command error;
- `error`: validation or at least one attempted operation failed;
- `closed`: a remote close request was published before disconnection.

Always inspect:

- `response.status`;
- every `response.result[].status` and `error`;
- `response.log` when requested;
- `response.error` when present, including a truncation error.

A chat/reasoning-only success has `response.status:"success"` and an empty
`response.result` array.

If the serialized result exceeds about 60 KiB, DSI Studio replaces `response` with
a truncation error instead of posting the oversized response.

A successful reply for an asynchronous command means the operation was accepted. It
does not prove background processing finished. For asynchronous `curl`, initialize
the log cursor on or before the start request, wait for the synthetic `curlN` entry
to disappear from `list_window`, then inspect a later `log` reply.

## Remote close

Replace the issue body with a higher request ID and:

```json
{"id":6,"request":"close"}
```

A remote-close request does not require `session`. DSI Studio attempts to publish
`state:"closed"` and then disconnects the issue channel. It does not close the
GitHub issue, a DSI Studio data window, or DSI Studio itself. After acknowledgement,
ChatGPT may close the issue.

Closing the GitHub issue directly also stops DSI Studio when the next poll observes
the closed state, but the explicit close request is preferred because it provides a
protocol acknowledgement.

## Troubleshooting

### No result comment appears

Confirm that the user selected **New Chat** -> **ChatGPT (Web)**, pasted the correct
issue URL, and clicked **Start**.

Then verify that the DSI Studio token:

- has not expired or been revoked;
- includes the selected repository;
- has **Issues: Read and write**;
- belongs to a user who can access that private repository.

### The connection succeeds but no chat appears

Connection only creates or reuses the result comment. Post the first higher-ID
request with a valid canonical UUID in `session`. The chat appears when DSI Studio
processes that request.

### A first `set_title` request did not persist

The first request is followed by DSI Studio's automatic issue-title assignment. Use
a descriptive issue title or send `set_title` in a later request.

### A command ran in an unexpected window

First determine whether it is a shared dispatcher command. `bring_to_front`,
`minimize`, `maximize`, and window `close` always act on the persistently selected
window. Other ordinary commands are offered to `MainWindow` first and only fall
through to the selected non-main window when unknown to `MainWindow`.

`run_cli` is a global MainWindow command, but its selected CLI action uses its own
state. For example, `vis` uses the most recently created tracking window rather than
the AI session's `set_window` target.

Use `list_window`, select an exact current ID, and inspect every per-command result.
After closing a window, select `main` or another valid ID before the next
window-specific command.

### A curl request returned success but the file is missing

The initial `run_shell curl` result confirms only asynchronous task registration.
The log cursor must be initialized before relevant output is written. Set
`include_log:true` on the curl-start request or send a separate `log` request first.
Then poll `list_window` until the reported `curlN` entry disappears and request `log`
again. That later log may report that curl could not start, did not finish, or wrote
an error to standard error. There is no automatic transfer timeout or cancellation
command.

### ChatGPT cannot list or create the issue

Add the private repository to the ChatGPT GitHub app configuration. Code-search
visibility alone is not enough; the integration must support issue actions.

### Authorization fails after the channel started

The token may have expired, lost repository access, or lost Issues write permission.
Correct the token in **AI Settings**, then use **Resume**.

### The same command might run twice

Read the existing result comment and use an ID greater than `last_id`. Do not delete
or manually replace the result comment when resuming the same issue.

## Demo mode

Use demo mode only when the user asks for a demonstration, presentation, guided
walkthrough, or spoken narration. Follow the complete demo-mode rules in
`DSI_STUDIO_AI_MANUAL.md`.

Before every major visible action, speak one concise sentence explaining what will
happen next and why it is useful. Do not narrate routine discovery commands or
internal issue-channel mechanics. Base progress narration on verified DSI Studio
state and do not announce completion until the relevant response confirms it.
