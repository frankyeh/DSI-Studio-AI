# DSI Studio Direct GitHub Issue Channel for ChatGPT Web

DSI Studio can connect directly to a GitHub issue and use it as a remote
command/result mailbox for ChatGPT Web. This route does not use a self-hosted
GitHub Actions runner, workflow dispatch, request file, result file, or repository
commit.

The issue body carries the next request. One issue comment marked
`"dsi_session_result":true` carries the latest result.

```text
ChatGPT Web -> private GitHub issue -> DSI Studio
ChatGPT Web <- result comment       <- DSI Studio
```

Use a private repository. Requests and results may contain local paths, filenames,
window titles, command parameters, processing output, or incremental logs.

## One-time user setup

The simplest supported configuration uses one personal GitHub account for all three
roles:

1. owner of the private issue-channel repository;
2. creator of each session issue through ChatGPT;
3. owner of the fine-grained personal access token used by DSI Studio.

This matters because current DSI Studio validates that the issue creator is the
personal account named as the repository owner in the issue URL. An
organization-owned repository is not supported by this validation because an issue
is created by a user account, not by the organization itself.

### 1. Create a private GitHub repository

1. Sign in to GitHub with the personal account that will control DSI Studio.
2. Select **New repository**.
3. Set **Owner** to that personal account.
4. Choose a repository name, for example `DSI-Studio-AI-Channel`.
5. Set visibility to **Private**.
6. Create the repository. A README is optional; the channel does not use repository
   files or commits.
7. In the repository settings, make sure **Issues** is enabled.

Do not place DSI Studio source code, data files, screenshots, credentials, or patient
information in this repository. Only session issues are needed.

### 2. Create a fine-grained GitHub personal access token

GitHub permits unauthenticated reads of some public issue data, but creating or
editing issue comments always requires authentication. The DSI Studio channel must
therefore have a token even when the repository is public.

Create a fine-grained personal access token:

1. In GitHub, open **Settings**.
2. Open **Developer settings**.
3. Open **Personal access tokens** -> **Fine-grained tokens**.
4. Select **Generate new token**.
5. Give it a narrow name, such as `DSI Studio issue channel`.
6. Choose a reasonable expiration date.
7. Set **Resource owner** to the same personal account that owns the private
   repository.
8. Under **Repository access**, choose **Only select repositories**.
9. Select only the private issue-channel repository.
10. Under **Repository permissions**, set **Issues** to **Read and write**.
11. Leave unrelated permissions such as Contents, Actions, Workflows, Pull requests,
    and Administration without access.
12. Generate the token and copy it immediately.

The token cannot grant access that its owner does not already have. If the repository
is later transferred, renamed, deleted, or removed from the token's selected
repositories, create or revise the token accordingly.

Never paste this token into ChatGPT, an issue body, an issue comment, a prompt, a
repository file, or a screenshot.

### 3. Configure the token in DSI Studio

1. Open DSI Studio.
2. Open the **AI Agent** window.
3. Click **Settings**.
4. Paste the fine-grained token into **GitHub token (issue channel)**.
5. Click **Save**.

The field is masked in the dialog. Current DSI Studio saves this value in its local
`QSettings` storage so it remains available after restart. The token is independent
of the normal DSI Studio login token. Protect the operating-system account and rotate
or revoke the token if that computer or settings storage may have been exposed.

### 4. Give ChatGPT access to the private repository

ChatGPT must use a connected GitHub tool or plugin that supports creating, reading,
and updating issues. Read-only repository search is insufficient for this workflow.

1. In ChatGPT, open **Settings** -> **Apps** or the current plugin/app directory.
2. Connect or install the GitHub integration used for issue actions.
3. On GitHub, grant it access only to the private issue-channel repository when the
   integration permits selected-repository access.
4. If the repository was created after GitHub was connected to ChatGPT, open the
   GitHub app configuration again and add the new repository.
5. Start a new ChatGPT conversation if the newly granted repository is not visible
   in the current conversation.

A newly created or newly authorized private repository may take several minutes to
appear. The user may need to reopen the GitHub app configuration and confirm that the
repository is selected.

The ChatGPT GitHub credential and the DSI Studio fine-grained token are separate:

- ChatGPT uses its connected GitHub integration to create and update the issue body
  and read the result comment.
- DSI Studio uses the fine-grained token configured in AI Settings to read the issue
  and create or update its result comment.
- The agent must never request, receive, repeat, test, or display the DSI Studio
  token.

## Start a session

### User request to the agent

The user should identify the private issue-channel repository and ask the agent to
control DSI Studio through a GitHub issue. Example:

```text
Use my private <owner>/<repository> repository to start a DSI Studio issue session.
Create the issue, give me its URL, and then use the direct issue channel after I
connect DSI Studio.
```

### Agent procedure

The ChatGPT agent should follow these steps:

1. Confirm that it can create and update issues in the exact private repository.
2. Create one new issue in that repository.
3. Use a title beginning exactly with:

   ```text
   DSI Studio session
   ```

   A descriptive suffix is allowed, for example:

   ```text
   DSI Studio session tumor segmentation demo
   ```

4. Use a non-actionable initial body, for example:

   ```json
   {"state":"waiting for DSI Studio connection"}
   ```

5. Give the issue URL to the user.
6. Ask the user to open DSI Studio's **AI Agent** window, click **Connect Issue**,
   paste the URL, and report when the status shows that it connected.
7. After connection, find the issue comment whose JSON body contains:

   ```json
   {"dsi_session_result":true}
   ```

   DSI Studio creates this comment with an initial `idle` state when none exists.
8. Generate one UUID session value and keep it for the related work.
9. Replace the issue body with one request JSON object at a time.
10. Increase numeric `id` for every request.
11. Read the fixed result comment after each update and wait until `last_id` equals
    the submitted request ID.
12. Inspect the nested DSI response before deciding the next command.
13. For an asynchronous operation, send its start command only once, then use a later
    higher-ID request to inspect status.
14. At the end, send a higher-ID `close` request, verify the final result when
    available, and close the GitHub issue after the local channel has disconnected.

Do not use issue comments to send commands. Commands belong only in the issue body.
Do not create repository request files, result files, workflow dispatches, or commits.

## Connect DSI Studio

After the agent creates the issue:

1. Open the DSI Studio **AI Agent** window.
2. Click **Connect Issue**.
3. Paste the full issue URL, using the exact form:

   ```text
   https://github.com/<owner>/<repository>/issues/<number>
   ```

4. Wait for the AI Agent status to report that it connected.

DSI Studio validates that:

- the URL uses HTTPS and points to `github.com`;
- the path is an issue URL, not a pull request;
- the issue is open;
- the issue creator is the personal repository owner named in the URL;
- the issue title starts exactly with `DSI Studio session`;
- the configured fine-grained token can read the issue and create or edit issue
  comments.

After connection, DSI Studio polls the issue body about twice per second and uses an
ETag to avoid reprocessing an unchanged body.

## Issue request format

The issue body must contain one JSON object. Each actionable request needs a positive
numeric `id` greater than the `last_id` in the result comment.

Normal DSI Studio requests require a UUID `session` and use the same fields as the
named-pipe interface:

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

Commands execute in array order and stop at the first failure. The reply contains one
result per attempted item. A `voice` item can be routed to the main window while the
remaining commands use the declared target window.

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
`response.log`. Use it only when the new console or action history is needed because
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

Always match completion using `last_id`. Do not infer completion from issue activity,
comment edit time, or elapsed wall-clock time.

The outer `state` may be:

- `idle`: connected result comment exists but no request has been processed;
- `done`: the request was processed successfully;
- `error`: request validation or a DSI operation failed;
- `closed`: the remote close request was acknowledged before disconnecting.

Always inspect `response.status`, `response.error`, and every per-command result.

If the serialized result exceeds about 60 KiB, DSI Studio replaces `response` with a
truncation error instead of posting an oversized comment.

A successful reply for an asynchronous operation means the start command was
accepted; it does not prove completion. Use the documented status command in a later
higher-ID request.

## Disconnect

The local user can click **Disconnect Issue** in the AI Agent window.

A remote agent should replace the issue body with a higher ID and:

```json
{"id":5,"request":"close"}
```

DSI Studio attempts to publish `state:"closed"` and then disconnects the local issue
channel. The close request does not close the GitHub issue or DSI Studio itself.
After the channel is disconnected, the ChatGPT agent may close the GitHub issue.

If the final acknowledgement cannot be published because of a network or token
failure, the local user may still disconnect with the button. The agent must not keep
sending commands after the user reports that the local channel is disconnected.

Closing the GitHub issue directly also causes DSI Studio to stop polling when it next
observes the closed state, but the explicit close request is preferred because it
provides a protocol-level acknowledgement.

## Reconnection behavior

DSI Studio reads `last_id` from its existing result comment when reconnecting. A body
whose ID has already been acknowledged is not executed again.

Before reconnecting:

- keep the existing DSI result comment;
- do not delete or manually replace it;
- verify that it was created by the same personal account that owns the repository;
- submit the next request with an ID greater than its `last_id`.

If the result comment is deleted, belongs to another account, or cannot be edited by
the configured token, DSI Studio may create another result comment or reject the
connection.

## Demo mode

When the user requests demo mode, follow the complete `Demo mode` rules in
`DSI_STUDIO_AI_MANUAL.md`.

Put a concise `voice` item before each major user-visible action, preferably in the
same ordered command array. Narrate the scientific or operational action rather than
the issue channel, polling, IDs, command arrays, or other orchestration details.

Do not mention internal pacing principles in narration. Do not say phrases such as
`without waiting silently`, `no silence`, `polling`, `cooldown`, `sending another
voice command`, or `checking the issue`.

Do not claim success until the nested DSI response and any required later status
request verify it. Avoid continuous or overlapping speech.

## Agent operational rules

- Use one meaningful request per issue-body update.
- Increase `id` for every request and never reuse an ID.
- Keep one UUID `session` for related DSI work so `LOG` remains incremental.
- Use exact returned window IDs and verified file paths, indices, model IDs, and
  parameter IDs.
- Send asynchronous start commands only once, then inspect status with a later ID.
- Treat the result comment as a latest-result mailbox, not an append-only history.
- Do not edit or create the DSI result comment; DSI Studio owns that comment.
- Do not put commands in issue comments.
- Do not place the fine-grained PAT in any GitHub or ChatGPT content.
- Use `run_shell` only for its restricted supported commands.
- Disconnect and close the issue when work is complete.

## Privacy and security

A private repository limits visibility but does not make arbitrary content safe to
transmit. Everyone with repository access can read the issue body and result comment.

Issue content can expose:

- local paths and filenames;
- window titles and current datasets;
- command parameters;
- DSI Studio output and error messages;
- screenshot output paths;
- incremental logs.

Do not send credentials, API tokens, protected health information,
patient-identifying information, unpublished confidential data, or other sensitive
content through this channel.

Use the narrowest possible fine-grained token:

- one personal resource owner;
- only the issue-channel repository;
- Issues read and write;
- no Contents, Actions, Workflows, or administration permissions;
- a limited expiration date.

Revoke and replace the token after suspected exposure. Remove ChatGPT's repository
access when the channel is no longer needed.
