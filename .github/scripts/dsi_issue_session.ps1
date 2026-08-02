$ErrorActionPreference = 'Stop'
if($env:RUNNER_NAME -ne 'HOME-FRANK')
{
    throw "This workflow requires runner HOME-FRANK; current runner is $env:RUNNER_NAME."
}
if($env:RUNNER_OS -ne 'Windows') { throw 'This workflow requires Windows.' }

$repo = $env:GITHUB_REPOSITORY
$api = $env:GITHUB_API_URL
$owner = $env:GITHUB_REPOSITORY_OWNER
$runId = [int64]$env:GITHUB_RUN_ID
$headers = @{
    Authorization = "Bearer $env:GH_TOKEN"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

if($env:GITHUB_EVENT_NAME -eq 'workflow_dispatch')
{
    $issueNumberText = $env:INPUT_ISSUE
    $debugText = $env:INPUT_DEBUG
}
else
{
    $file = Invoke-RestMethod -Method Get -Headers $headers `
      -Uri "$api/repos/$repo/contents/.github/chatgpt-dsi-session-request.json?ref=$env:GITHUB_SHA"
    $requestText = [Text.Encoding]::UTF8.GetString(
      [Convert]::FromBase64String(($file.content -replace '\s','')))
    try { $start = $requestText | ConvertFrom-Json }
    catch { throw "Invalid session request JSON: $($_.Exception.Message)" }
    $issueNumberText = [string]$start.issue
    $debugText = if($null -eq $start.debug) { 'false' } else { [string]$start.debug }
}

$issueNumber = 0
if(-not [int]::TryParse($issueNumberText,[ref]$issueNumber) -or $issueNumber -le 0)
{
    throw 'issue must be a positive integer.'
}
$debug = $false
if($debugText -notmatch '^(?i:true|false)$') { throw 'debug must be boolean.' }
$debug = [bool]::Parse($debugText)

trap
{
    $line = $_.InvocationInfo.ScriptLineNumber
    $command = $_.InvocationInfo.Line.Trim()
    Write-Host "::error title=DSI issue session failed::line=$line command=$command error=$($_.Exception.Message)"
    exit 1
}
if($debug) { Set-PSDebug -Trace 1 }

$issueUri = "$api/repos/$repo/issues/$issueNumber"
$issue = Invoke-RestMethod -Method Get -Headers $headers -Uri $issueUri
if($null -ne $issue.pull_request) { throw 'Pull requests cannot be used as DSI Studio sessions.' }
if([string]$issue.user.login -ne $owner)
{
    throw "Issue #$issueNumber must be opened by repository owner $owner."
}
if([string]$issue.state -ne 'open') { throw "Issue #$issueNumber is not open." }

function Invoke-Mutation([string]$Method,[string]$Uri,$Body)
{
    $json = $Body | ConvertTo-Json -Compress -Depth 30
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    return Invoke-RestMethod -Method $Method -Headers $headers `
      -ContentType 'application/json; charset=utf-8' -Uri $Uri -Body $bytes
}
function Limit-Text([string]$Text,[int]$Limit)
{
    if($null -eq $Text -or $Text.Length -le $Limit) { return $Text }
    return "[truncated; original $($Text.Length) chars]`n" +
      $Text.Substring($Text.Length-$Limit)
}
function Limit-Value($Value,[string]$Name = '',[int]$Depth = 0)
{
    if($null -eq $Value -or $Depth -gt 20) { return $Value }
    if($Value -is [string])
    {
        $limit = if($Name -eq 'output') {12000} elseif($Name -eq 'error') {4000} else {20000}
        return Limit-Text $Value $limit
    }
    if($Value -is [System.Collections.IDictionary])
    {
        foreach($key in @($Value.Keys))
        {
            $Value[$key] = Limit-Value $Value[$key] ([string]$key) ($Depth+1)
        }
        return $Value
    }
    if($Value -is [System.Collections.IList])
    {
        for($index = 0;$index -lt $Value.Count;++$index)
        {
            $Value[$index] = Limit-Value $Value[$index] $Name ($Depth+1)
        }
        return $Value
    }
    if($Value -is [pscustomobject])
    {
        foreach($property in @($Value.PSObject.Properties))
        {
            $property.Value = Limit-Value $property.Value $property.Name ($Depth+1)
        }
    }
    return $Value
}

$resultComment = $null
$comments = @(Invoke-RestMethod -Method Get -Headers $headers -Uri "$issueUri/comments?per_page=100")
foreach($comment in $comments)
{
    try { $candidate = $comment.body | ConvertFrom-Json }
    catch { continue }
    if($candidate.dsi_session_result -eq $true) { $resultComment = $comment }
}

$lastId = [int64]0
if($null -ne $resultComment)
{
    try
    {
        $previous = $resultComment.body | ConvertFrom-Json
        if($null -ne $previous.last_id) { $lastId = [int64]$previous.last_id }
    }
    catch { $lastId = 0 }
    $resultCommentId = [int64]$resultComment.id
}
else
{
    $ready = [ordered]@{
      state = 'ready'
      last_id = $lastId
      dsi_session_result = $true
      issue = $issueNumber
      run = $runId
      updated_at = [DateTime]::UtcNow.ToString('o')
    }
    $created = Invoke-Mutation Post "$issueUri/comments" @{body=($ready | ConvertTo-Json -Compress -Depth 30)}
    $resultCommentId = [int64]$created.id
}

function Publish-Result($Result)
{
    $Result.dsi_session_result = $true
    $Result.issue = $issueNumber
    $Result.run = $runId
    $Result.updated_at = [DateTime]::UtcNow.ToString('o')
    $Result = Limit-Value $Result
    $text = $Result | ConvertTo-Json -Compress -Depth 30
    if($text.Length -gt 62000)
    {
        $Result = [ordered]@{
          state = [string]$Result.state
          id = $Result.id
          last_id = $Result.last_id
          duration_ms = $Result.duration_ms
          truncated = $true
          full_size = $text.Length
          error = 'Result exceeded the GitHub issue-comment limit; large response fields were omitted.'
          dsi_session_result = $true
          issue = $issueNumber
          run = $runId
          updated_at = [DateTime]::UtcNow.ToString('o')
        }
        $text = $Result | ConvertTo-Json -Compress -Depth 30
    }
    Invoke-Mutation Patch "$api/repos/$repo/issues/comments/$resultCommentId" `
      @{body=$text} | Out-Null
}

function Invoke-Dsi($Request)
{
    $pipe = $writer = $reader = $null
    try
    {
        $pipe = [IO.Pipes.NamedPipeClientStream]::new('.','dsi-studio')
        $pipe.Connect(5000)
        $utf8 = [Text.UTF8Encoding]::new($false)
        $writer = [IO.StreamWriter]::new($pipe,$utf8,1024,$true)
        $reader = [IO.StreamReader]::new($pipe,$utf8,$false,1024,$true)
        $json = $Request | ConvertTo-Json -Compress -Depth 30
        if($debug) { Write-Host "dsi_request=$json" }
        $writer.Write($json)
        $writer.Flush()
        return $reader.ReadToEnd()
    }
    finally
    {
        foreach($stream in @($reader,$writer,$pipe))
        {
            if($stream) { try {$stream.Dispose()} catch [IO.IOException] {} }
        }
    }
}
function Invoke-DsiReply($Request)
{
    $text = Invoke-Dsi $Request
    if([string]::IsNullOrWhiteSpace($text)) { throw 'DSI Studio returned no data.' }
    try { return $text | ConvertFrom-Json }
    catch { throw "DSI Studio returned invalid JSON: $($_.Exception.Message)" }
}
function Test-DsiReply($Reply)
{
    if(([string]$Reply.status).ToLowerInvariant() -in @('error','failed','failure')) { return $false }
    foreach($item in @($Reply.result))
    {
        if($null -ne $item -and
           ([string]$item.status).ToLowerInvariant() -in @('error','failed','failure'))
        {
            return $false
        }
    }
    return $true
}
function Convert-ToPayload($Command)
{
    $session = [string]$Command.session
    $guid = [Guid]::Empty
    if(-not [Guid]::TryParse($session,[ref]$guid)) { throw 'session must be a UUID.' }
    $kind = ([string]$Command.request).ToUpperInvariant()
    if($kind -notin @('TITLE','CHAT','LIST','LOG','CMD')) { throw "Invalid request: $kind" }
    $payload = [ordered]@{agent='Codex/ChatGPT-GitHub';session=$session;request=$kind}
    switch($kind)
    {
        'TITLE'
        {
            $title = [string]$Command.title
            if([string]::IsNullOrWhiteSpace($title)) { throw 'TITLE requires title.' }
            $payload.title = $title
        }
        'CHAT'
        {
            $chat = [string]$Command.chat
            if([string]::IsNullOrWhiteSpace($chat)) { throw 'CHAT requires chat.' }
            $payload.chat = $chat
        }
        'CMD'
        {
            $window = [string]$Command.window
            if($window -notmatch '^(main|recon[0-9A-Fa-f]+|tracking[0-9A-Fa-f]+|image[0-9A-Fa-f]+)$')
            {
                throw "Invalid window: $window"
            }
            $cmd = [string]$Command.command.cmd
            if($cmd -notmatch '^[A-Za-z0-9_]+$') { throw "Invalid command: $cmd" }
            $payload.window = $window
            $payload.command = [ordered]@{cmd=$cmd}
            if($null -ne $Command.command.param) { $payload.command.param = $Command.command.param }
            if($null -ne $Command.chat)
            {
                $chat = [string]$Command.chat
                if([string]::IsNullOrWhiteSpace($chat)) { throw 'chat must be non-empty when provided.' }
                $payload.chat = $chat
            }
        }
    }
    return $payload
}

Add-Type -AssemblyName System.Net.Http
$client = [Net.Http.HttpClient]::new()
$client.DefaultRequestHeaders.Authorization = `
  [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$env:GH_TOKEN)
$client.DefaultRequestHeaders.Accept.ParseAdd('application/vnd.github+json')
$client.DefaultRequestHeaders.UserAgent.ParseAdd('chatgpt-dsi-issue-session')
$client.DefaultRequestHeaders.Add('X-GitHub-Api-Version','2022-11-28')
$etag = $null
$deadline = [DateTime]::UtcNow.AddMinutes(350)
$hotUntil = [DateTime]::UtcNow.AddSeconds(30)
$pendingIssue = $issue

try
{
    while([DateTime]::UtcNow -lt $deadline)
    {
        if($null -ne $pendingIssue)
        {
            $currentIssue = $pendingIssue
            $pendingIssue = $null
        }
        else
        {
            $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get,$issueUri)
            if($etag) { $request.Headers.TryAddWithoutValidation('If-None-Match',$etag) | Out-Null }
            $response = $client.SendAsync($request).GetAwaiter().GetResult()
            try
            {
                if([int]$response.StatusCode -eq 304)
                {
                    Start-Sleep -Milliseconds $(if([DateTime]::UtcNow -lt $hotUntil) {100} else {500})
                    continue
                }
                if(-not $response.IsSuccessStatusCode)
                {
                    $detail = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                    throw "Issue poll failed: $([int]$response.StatusCode) $detail"
                }
                $etag = if($null -ne $response.Headers.ETag) {$response.Headers.ETag.ToString()} else {$null}
                $currentIssue = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
            }
            finally
            {
                $response.Dispose()
                $request.Dispose()
            }
        }

        if([string]$currentIssue.state -ne 'open')
        {
            Publish-Result ([ordered]@{state='closed';last_id=$lastId;message='Issue was closed.'})
            break
        }

        try { $command = [string]$currentIssue.body | ConvertFrom-Json }
        catch
        {
            Publish-Result ([ordered]@{
              state='error';last_id=$lastId
              error="Issue body must be one JSON command: $($_.Exception.Message)"
            })
            $hotUntil = [DateTime]::UtcNow.AddSeconds(30)
            continue
        }

        $commandId = [int64]0
        if($null -eq $command.id -or
           -not [int64]::TryParse([string]$command.id,[ref]$commandId) -or
           $commandId -le 0)
        {
            Publish-Result ([ordered]@{state='error';last_id=$lastId;error='id must be a positive integer.'})
            $hotUntil = [DateTime]::UtcNow.AddSeconds(30)
            continue
        }
        if($commandId -le $lastId) { continue }

        if(([string]$command.request).ToLowerInvariant() -eq 'close')
        {
            $lastId = $commandId
            Publish-Result ([ordered]@{
              state='closed';id=$commandId;last_id=$lastId
              message='DSI Studio issue session closed.'
            })
            "closed=true" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
            break
        }

        $started = [Diagnostics.Stopwatch]::StartNew()
        try
        {
            $payload = Convert-ToPayload $command
            $reply = Invoke-DsiReply $payload
            $result = [ordered]@{
              state=if(Test-DsiReply $reply) {'done'} else {'error'}
              id=$commandId
              last_id=$commandId
              duration_ms=$started.ElapsedMilliseconds
              response=$reply
            }
            if($command.include_log -eq $true -and $payload.request -ne 'LOG')
            {
                $result.log = Invoke-DsiReply ([ordered]@{
                  agent='Codex/ChatGPT-GitHub';session=$payload.session;request='LOG'
                })
            }
        }
        catch
        {
            $result = [ordered]@{
              state='error';id=$commandId;last_id=$commandId
              duration_ms=$started.ElapsedMilliseconds
              error=$_.Exception.Message
            }
        }
        finally { $started.Stop() }

        $lastId = $commandId
        Publish-Result $result
        $hotUntil = [DateTime]::UtcNow.AddSeconds(30)
    }

    if([DateTime]::UtcNow -ge $deadline)
    {
        Publish-Result ([ordered]@{
          state='expired';last_id=$lastId
          error='Session reached the 350-minute limit.'
        })
        throw 'Session reached the 350-minute limit.'
    }
}
finally
{
    $client.Dispose()
    if($debug) { Set-PSDebug -Off }
}
