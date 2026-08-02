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

$lastMutation = [DateTime]::MinValue
function Invoke-Mutation([string]$Method,[string]$Uri,$Body)
{
    $elapsed = ([DateTime]::UtcNow - $script:lastMutation).TotalMilliseconds
    if($elapsed -lt 1000) { Start-Sleep -Milliseconds ([int](1000-$elapsed)) }
    $json = $Body | ConvertTo-Json -Compress -Depth 30
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $result = Invoke-RestMethod -Method $Method -Headers $headers `
      -ContentType 'application/json; charset=utf-8' -Uri $Uri -Body $bytes
    $script:lastMutation = [DateTime]::UtcNow
    return $result
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
      message = 'Update this issue body with the next JSON command. Send a higher id each time; use request close to end the runner.'
      dsi_session_result = $true
      issue = $issueNumber
      run = $runId
      updated_at = [DateTime]::UtcNow.ToString('o')
    }
    $created = Invoke-Mutation Post "$issueUri/comments" @{body=($ready | ConvertTo-Json -Depth 30)}
    $resultCommentId = [int64]$created.id
}

function Publish-Result($Result)
{
    $Result.dsi_session_result = $true
    $Result.issue = $issueNumber
    $Result.run = $runId
    $Result.updated_at = [DateTime]::UtcNow.ToString('o')
    $Result = Limit-Value $Result
    $text = $Result | ConvertTo-Json -Depth 30
    if($text.Length -gt 62000)
    {
        $fullSize = $text.Length
        $Result = [ordered]@{
          state = [string]$Result.state
          id = $Result.id
          last_id = $Result.last_id
          duration_ms = $Result.duration_ms
          truncated = $true
          full_size = $fullSize
          message = 'Result exceeded the GitHub issue-comment limit; large response fields were omitted.'
          dsi_session_result = $true
          issue = $issueNumber
          run = $runId
          updated_at = [DateTime]::UtcNow.ToString('o')
        }
        $text = $Result | ConvertTo-Json -Depth 30
    }
    Invoke-Mutation Patch "$api/repos/$repo/issues/comments/$resultCommentId" `
      @{body=$text} | Out-Null
}
if($null -ne $resultComment)
{
    Publish-Result ([ordered]@{
      state = 'ready'
      last_id = $lastId
      message = 'Session restarted. Send a higher id; use request close to end the runner.'
    })
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
function Get-ReplyOutput($Reply)
{
    $parts = @()
    if($null -ne $Reply.output) { $parts += [string]$Reply.output }
    foreach($item in @($Reply.result))
    {
        if($null -eq $item) { continue }
        if($null -ne $item.output) { $parts += [string]$item.output }
        if($null -ne $item.error) { $parts += [string]$item.error }
    }
    return $parts -join "`n"
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
function Require-DsiReply($Reply,[string]$Stage)
{
    if(Test-DsiReply $Reply) { return }
    throw "$Stage failed: $(Limit-Text (Get-ReplyOutput $Reply) 2000)"
}
function Get-Session($Command)
{
    $session = [string]$Command.session
    $guid = [Guid]::Empty
    if(-not [Guid]::TryParse($session,[ref]$guid)) { throw 'session must be a UUID.' }
    return $session
}
function Convert-ToPayload($Command)
{
    $session = Get-Session $Command
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
function Invoke-TrackWorkflow($Command)
{
    $session = Get-Session $Command
    $name = [string]$Command.name
    if([string]::IsNullOrWhiteSpace($name)) { throw 'TRACK requires name.' }

    $path = [string]$Command.path
    $window = [string]$Command.window
    if([string]::IsNullOrWhiteSpace($path) -eq [string]::IsNullOrWhiteSpace($window))
    {
        throw 'TRACK requires exactly one of path or window.'
    }

    $timeoutSeconds = 600
    if($null -ne $Command.timeout_seconds -and
       (-not [int]::TryParse([string]$Command.timeout_seconds,[ref]$timeoutSeconds) -or
        $timeoutSeconds -lt 1 -or $timeoutSeconds -gt 1800))
    {
        throw 'timeout_seconds must be between 1 and 1800.'
    }
    $pollMs = 250
    if($null -ne $Command.poll_ms -and
       (-not [int]::TryParse([string]$Command.poll_ms,[ref]$pollMs) -or
        $pollMs -lt 100 -or $pollMs -gt 5000))
    {
        throw 'poll_ms must be between 100 and 5000.'
    }

    $track = [ordered]@{}
    if(-not [string]::IsNullOrWhiteSpace($path))
    {
        $track.open = Invoke-DsiReply ([ordered]@{
          agent='Codex/ChatGPT-GitHub';session=$session;request='CMD';window='main'
          command=[ordered]@{cmd='open_fib';param=$path}
        })
        Require-DsiReply $track.open 'open_fib'
        $match = [regex]::Match((Get-ReplyOutput $track.open),'tracking[0-9A-Fa-f]+')
        if(-not $match.Success) { throw 'open_fib did not return a tracking window ID.' }
        $window = $match.Value
    }
    elseif($window -notmatch '^tracking[0-9A-Fa-f]+$')
    {
        throw "Invalid tracking window: $window"
    }
    $track.window = $window

    $settings = [string]$Command.set_params
    if(-not [string]::IsNullOrWhiteSpace($settings))
    {
        $track.set_params = Invoke-DsiReply ([ordered]@{
          agent='Codex/ChatGPT-GitHub';session=$session;request='CMD';window=$window
          command=[ordered]@{cmd='set_params';param=$settings}
        })
        Require-DsiReply $track.set_params 'set_params'
    }

    $regions = [string]$Command.regions
    $runParam = if([string]::IsNullOrWhiteSpace($regions)) {$name} else {@($name,$regions)}
    $track.start = Invoke-DsiReply ([ordered]@{
      agent='Codex/ChatGPT-GitHub';session=$session;request='CMD';window=$window
      command=[ordered]@{cmd='run_tracking';param=$runParam}
    })
    Require-DsiReply $track.start 'run_tracking'

    $statusPayload = [ordered]@{
      agent='Codex/ChatGPT-GitHub';session=$session;request='CMD';window=$window
      command=[ordered]@{cmd='list_tract';param='status'}
    }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $pollCount = 0
    do
    {
        $track.status = Invoke-DsiReply $statusPayload
        Require-DsiReply $track.status 'list_tract status'
        ++$pollCount
        if((Get-ReplyOutput $track.status) -match '(?m)done\t[0-9]+\s*$') { break }
        if($watch.Elapsed.TotalSeconds -ge $timeoutSeconds)
        {
            throw "Tracking did not finish within $timeoutSeconds seconds."
        }
        Start-Sleep -Milliseconds $pollMs
    }
    while($true)
    $watch.Stop()
    $track.poll_count = $pollCount
    $track.tracking_ms = $watch.ElapsedMilliseconds

    $track.final = Invoke-DsiReply ([ordered]@{
      agent='Codex/ChatGPT-GitHub';session=$session;request='CMD';window=$window
      command=[ordered]@{cmd='list_tract'}
    })
    Require-DsiReply $track.final 'list_tract'

    $voice = [string]$Command.voice
    if(-not [string]::IsNullOrWhiteSpace($voice))
    {
        $track.voice = Invoke-DsiReply ([ordered]@{
          agent='Codex/ChatGPT-GitHub';session=$session;request='CMD';window='main'
          command=[ordered]@{cmd='voice';param=$voice}
        })
        Require-DsiReply $track.voice 'voice'
    }
    if($Command.include_log -eq $true)
    {
        $track.log = Invoke-DsiReply ([ordered]@{
          agent='Codex/ChatGPT-GitHub';session=$session;request='LOG'
        })
    }
    return $track
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

try
{
    while([DateTime]::UtcNow -lt $deadline)
    {
        $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get,$issueUri)
        if($etag) { $request.Headers.TryAddWithoutValidation('If-None-Match',$etag) | Out-Null }
        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        try
        {
            if([int]$response.StatusCode -eq 304)
            {
                Start-Sleep -Milliseconds 250
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
            Start-Sleep -Milliseconds 250
            continue
        }

        $commandId = [int64]0
        if($null -eq $command.id -or
           -not [int64]::TryParse([string]$command.id,[ref]$commandId) -or
           $commandId -le 0)
        {
            Publish-Result ([ordered]@{state='error';last_id=$lastId;error='id must be a positive integer.'})
            Start-Sleep -Milliseconds 250
            continue
        }
        if($commandId -le $lastId)
        {
            Start-Sleep -Milliseconds 250
            continue
        }

        $kind = ([string]$command.request).ToLowerInvariant()
        if($kind -eq 'close')
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
            if($kind -eq 'track')
            {
                $workflowResult = Invoke-TrackWorkflow $command
                $result = [ordered]@{
                  state='done';id=$commandId;last_id=$commandId
                  duration_ms=$started.ElapsedMilliseconds
                  workflow=$workflowResult
                }
            }
            else
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
        Start-Sleep -Milliseconds 250
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
