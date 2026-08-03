# DSI Studio Web Agent GitHub Issue Channel

DSI Studio can use one private GitHub issue as a command/result mailbox for
ChatGPT Web. The issue body carries the next request. One issue comment marked
`"dsi_session_result":true` carries the latest result.

```text
ChatGPT Web -> private GitHub issue -> DSI Studio
ChatGPT Web <- result comment       <- DSI Studio
```

This route does not use GitHub Actions, workflow dispatch, repository request files,
result files, or commits.

Use a private repository because requests and results may contain local paths,
filenames, window titles, command parameters, processing output, and incremental
logs. Do not place credentials, protected health information, patient identifiers,
or unpublished confidential data in the issue.

## Repository requirements

The supported repository is a private repository owned by a personal GitHub account.
The issue creator must be the same personal account shown as the repository owner in
the issue URL.

For example, an issue in:

```text
https://github.com/frankyeh/DSI-Studio-Connect/issues/7
```

must be created by `frankyeh`.

An organization-owned repository is not supported by the current validation because
the issue is created by a user account, not by the organization itself.

The repository may be empty. It needs only:

- private visibility;
- Issues enabled;
- access for the ChatGPT GitHub integration;
- access for the fine-grained token configured in DSI Studio.

No Contents, Actions, Workflows, Pull requests, or Administration permission is
needed for the issue channel.

## Agent repository selection

When the user has not already named an exact repository, the ChatGPT agent should:

1. List the private repositories visible through the connected GitHub integration.
2. Keep only personal-account repositories whose owner matches the authenticated
   GitHub user.
3. Show the exact `owner/repository` names and ask the user to select one.
4. Prefer a dedicated empty repository such as `owner/DSI-Studio-Connect`.
5. Confirm that the GitHub integration can create, read, and update issues in the
   selected repository.

Do not silently choose a public repository or an organization-owned repository.

Repository visibility or general code access alone does not prove that issue actions
are available. Creating the session issue and then reading and updating it are the
practical ChatGPT-side permission checks.

If the user already names an exact repository, verify it instead of listing choices.

## One-time DSI Studio token setup

DSI Studio uses a GitHub token that is separate from the GitHub integration used by
ChatGPT.

Create a fine-grained personal access token:

1. In GitHub, open **Settings**.
2. Open **Developer settings**.
3. Open **Personal access tokens** -> **Fine-grained tokens**.
4. Select **Generate new token**.
5. Give it a narrow name, such as `DSI Studio issue channel`.
6. Set a reasonable expiration date.
7. Under **Repository access**, choose **Only select repositories**.
8. Select the private issue-channel repository.
9. Under **Repository permissions**, set **Issues** to **Read and write**.
10. Leave unrelated repository permissions without access.
11. Generate the token and copy it immediately.

The token owner does not technically need to be the repository owner, but the token
must have access to the selected private repository. Using the same personal account
for the repository owner, issue creator, and token owner is the simplest setup.

Never paste the token into ChatGPT, an issue, a repository file, a prompt, a
screenshot, or a command result.

Configure the token in DSI Studio:

1. Open DSI Studio.
2. Open the **AI Agent** window.
3. Open **AI Settings**.
4. Paste the token into **GitHub token (issue channel)**.
5. Click **Save**.

If no token is configured, the **Web agent** option in the New Chat dialog is disabled
and DSI Studio displays a setup hint.

The token is saved in DSI Studio's local `QSettings` storage. Protect the local
operating-system account and revoke or rotate the token if the computer or settings
storage may have been exposed.

## What DSI Studio verifies

Starting a Web agent session performs actual GitHub API checks. DSI Studio:

1. Calls `GET /user` to identify the token owner.
2. Reads the selected issue.
3. Reads the issue comments.
4. Creates the result comment with `POST /issues/<number>/comments` when no matching
   result comment exists.
5. Updates that same comment with `PATCH /issues/comments/<comment-id>` as requests
   complete.

The connection fails if the token cannot read the issue or comments. It also fails if
it cannot create the initial result comment. Later authorization failures stop the
channel.

Therefore the selected repository must be included in the token's repository access
and **Issues: Read and write** must be enabled. Read-only Issues permission is not
enough.

DSI Studio also validates that:

- the URL uses HTTPS and the host is `github.com`;
- the URL has the exact issue form, not a pull-request URL;
- the issue is open;
- the issue creator is the personal repository owner named in the URL;
- the issue title starts exactly with `DSI Studio session`.

## Give ChatGPT access to the private repository

ChatGPT must use a connected GitHub integration that supports issue creation, issue
reading, issue-body updates, and issue-comment reading.

1. In ChatGPT, open **Settings** -> **Apps**.
2. Open the GitHub app configuration.
3. Grant access to the selected private issue-channel repository.
4. If the repository was created after the app was installed, add it to the app's
   selected repositories.
5. Start a new ChatGPT conversation if the repository is not visible in the current
   conversation.

The two credentials have different roles:

- ChatGPT uses its GitHub integration to list repositories, create the session issue,
  replace the issue body, read the result comment, and close the issue.
- DSI Studio uses the fine-grained token stored in AI Settings to read the issue and
  create or update the result comment.

The agent must never request, receive, repeat, display, or test the DSI Studio token.

## Start a new session

### Agent procedure

The ChatGPT agent should:

1. Resolve the exact private personal repository using the repository-selection rules
   above.
2. Confirm that the ChatGPT GitHub integration can access the repository.
3. Create one new issue in that repository.
4. Use a title beginning exactly with:

   ```text
   DSI Studio session
   ```

   A descriptive suffix is allowed, for example:

   ```text
   DSI Studio session corticospinal tract mapping
   ```

5. Use a non-actionable initial body, for example:

   ```json
   {"state":"waiting for DSI Studio connection"}
   ```

6. Read the newly created issue to confirm access and give its URL to the user.
7. Tell the user to start a Web agent session in DSI Studio using the steps below.
8. After the user reports that DSI Studio connected, read the issue comments and find
   the comment whose JSON contains:

   ```json
   {"dsi_session_result":true}
   ```

9. Do not send a request until that result comment exists.
10. Generate one UUID session value and keep it for the entire task.
11. Replace the issue body with one request JSON object at a time.
12. Increase the positive numeric `id` for every request.
13. Read the fixed result comment after each issue-body update and wait until
    `last_id` equals the submitted ID.
14. Inspect the nested response before deciding the next command.
15. For asynchronous work, send the start command only once and use later higher-ID
    status requests.
16. At the end, send a higher-ID `close` request, verify the result when available,
    and close the GitHub issue after DSI Studio has stopped the channel.

Commands belong only in the issue body. Do not use issue comments to send commands.
Do not create repository request files, result files, workflow dispatches, or commits.

### DSI Studio user procedure

There is no separate **Connect Issue** or **Reconnect Issue** button in the current
interface.

To start the channel:

1. Open DSI Studio's **AI Agent** window.
2. Click **New Chat**.
3. Select **Web agent (ChatGPT via GitHub issue)**.
4. Paste the full issue URL into **Issue URL**.
5. Click **Start**.

The URL must have this exact form:

```text
https://github.com/<owner>/<repository>/issues/<number>
```

After a successful start:

- the agent label shows `ChatGPT(Web)`;
- the status reports that DSI Studio connected to the issue URL;
- the main send button shows **Stop**;
- DSI Studio creates or reuses its result comment and begins reading the issue body.

If the start fails, inspect the displayed error. Common causes are:

- the token is missing;
- the selected private repository is not included in the token;
- **Issues: Read and write** is not enabled;
- the issue is closed;
- the URL points to a pull request;
- the issue creator is not the repository owner;
- the issue title does not start with `DSI Studio session`.

## Stop and resume the Web agent

While the channel is active, the main send button shows **Stop**. Clicking **Stop**
stops the GitHub issue channel. It does not close DSI Studio or the GitHub issue.

After a stopped Web agent session, the button shows **Resume**. Clicking **Resume**:

1. Opens the chat dialog locked to **Web agent** mode.
2. Prefills the most recently used issue URL.
3. Allows the issue URL to be reviewed or changed.
4. Restarts the channel after the user clicks **Resume** in the dialog.

There is no separate reconnect command or reconnect button.

When resuming the same issue, keep the existing result comment. DSI Studio reads its
`last_id`, and a request whose ID was already acknowledged is not executed again.
The next agent request must use an ID greater than the existing `last_id`.

## Issue request format

The issue body must contain one JSON object. Each actionable request needs a positive
numeric `id` greater than the `last_id` in the result comment.

Normal requests require one UUID `session` and use the same request fields as the
local launcher:

- `TITLE`
- `CHAT`
- `LIST`
- `LOG`
- `CMD`

DSI Studio supplies the Web agent identity internally. Do not add or rely on an
`agent` field in the issue body.

The `title` field is valid only when `request` is `TITLE`. Never add `title` to a
`CHAT`, `LIST`, `LOG`, `CMD`, or `close` request.

### Set the task title

```json
{
  "id": 1,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "TITLE",
  "title": "Corticospinal tract mapping"
}
```

### Send user-facing progress

```json
{
  "id": 2,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CHAT",
  "chat": "I am checking the recent FIB files before opening one."
}
```

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

### Run an ordered command array

```json
{
  "id": 5,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": [
    {
      "cmd": "voice",
      "param": "I will now map the selected tract."
    },
    {
      "cmd": "run_auto_track",
      "param": "<exact identifier returned by list_auto_tract>"
    }
  ]
}
```

Commands execute in order and stop at the first failure. The reply contains one
result per attempted command.

### Include the incremental work log

```json
{
  "id": 6,
  "session": "7dd34326-b99a-4ba5-9de6-2d48188022f3",
  "request": "CMD",
  "window": "tracking7ff6ab123410",
  "command": {"cmd":"list_tract","param":"status"},
  "include_log": true
}
```

When `include_log` is true, DSI Studio performs a separate `LOG` request after the
main operation and places that reply in `response.log`. Use it only when incremental
console or action history is needed.

## Read the result comment

DSI Studio edits the same result comment after every processed request. A typical
result is:

```json
{
  "state": "done",
  "id": 5,
  "last_id": 5,
  "duration_ms": 120,
  "response": {
    "status": "success",
    "result": [
      {"cmd":"voice","status":"success"},
      {"cmd":"run_auto_track","status":"success"}
    ]
  },
  "dsi_session_result": true,
  "issue": 7,
  "updated_at": "2026-08-03T16:00:00Z"
}
```

Always match completion using `last_id`. Do not infer completion from issue activity,
comment edit time, or elapsed time.

The outer `state` may be:

- `idle`: the result comment exists but no request has been processed;
- `done`: the request completed successfully;
- `error`: request validation or a DSI Studio operation failed;
- `closed`: the remote close request was acknowledged before the channel stopped.

Always inspect `response.status`, `response.error`, and every per-command result.

If the serialized result exceeds about 60 KiB, DSI Studio replaces the response with
a truncation error instead of posting an oversized comment.

A successful reply for an asynchronous operation means the start command was
accepted. It does not prove that processing finished. Use the documented status
command in a later higher-ID request.

## Remote close

A remote agent should replace the issue body with a higher request ID and:

```json
{"id":7,"request":"close"}
```

DSI Studio attempts to publish `state:"closed"` and then stops the issue channel. The
request does not close the GitHub issue or DSI Studio itself. After the local channel
has stopped, the ChatGPT agent may close the GitHub issue.

Closing the GitHub issue directly also causes DSI Studio to stop when it next observes
the closed state, but the explicit close request is preferred because it provides a
protocol acknowledgement.

## Troubleshooting

### No result comment appears

Confirm that the user selected **New Chat** -> **Web agent**, pasted the correct issue
URL, and clicked **Start**.

Then verify the DSI Studio token:

- the token has not expired or been revoked;
- the selected repository is included in its repository access;
- **Issues** is set to **Read and write**;
- the token owner can access the private repository.

The absence of a result comment usually means DSI Studio could not complete its read
or write API checks.

### ChatGPT cannot list or create the issue

Open the ChatGPT GitHub app configuration and add the private repository. Repository
code-search visibility is not enough; the integration must support issue actions.

### Authorization fails after the channel started

The token may have expired, lost repository access, or lost Issues write permission.
DSI Studio stops the channel on permanent authorization failures. Correct the token
in **AI Settings**, then use **Resume**.

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
