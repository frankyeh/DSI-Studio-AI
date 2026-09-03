$ErrorActionPreference = 'Stop'

$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Bash = (Get-Command bash.exe -ErrorAction SilentlyContinue).Source
if(!$Bash)
{
    $Bash = 'C:\Program Files\Git\bin\bash.exe'
    if(!(Test-Path $Bash)) { throw 'Git Bash was not found.' }
}

$Root = Join-Path $env:RUNNER_TEMP 'DSI launcher (read only)'
$Ai = Join-Path $Root 'ai folder (test)'
$Temp = Join-Path $Root 'temp'
Remove-Item $Root -Recurse -Force -ErrorAction SilentlyContinue
New-Item $Ai,$Temp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Repo 'dsi.sh'),(Join-Path $Repo 'dsi.cmd'),(Join-Path $Repo 'dsi.ps1') $Ai

$Session = '11111111-1111-4111-8111-111111111111'

function Assert-True($Condition,[string]$Message)
{
    if(!$Condition) { throw $Message }
}

function Invoke-Launcher([string]$Executable,[string[]]$Arguments)
{
    $Response = '{"status":"success","text":"Unicode 測試 ✓"}'
    $PipeJob = Start-Job -ArgumentList $Response -ScriptBlock {
        param($Response)
        $Utf8 = [Text.UTF8Encoding]::new($false)
        $Pipe = [IO.Pipes.NamedPipeServerStream]::new(
            'dsi-studio',[IO.Pipes.PipeDirection]::InOut,1,
            [IO.Pipes.PipeTransmissionMode]::Byte,[IO.Pipes.PipeOptions]::None)
        try
        {
            $Pipe.WaitForConnection()
            $Buffer = New-Object byte[] 65536
            $Read = $Pipe.Read($Buffer,0,$Buffer.Length)
            $Request = $Utf8.GetString($Buffer,0,$Read)
            $Bytes = $Utf8.GetBytes($Response)
            $Pipe.Write($Bytes,0,$Bytes.Length)
            $Pipe.Flush()
            $Request
        }
        finally
        {
            $Pipe.Dispose()
        }
    }

    $LauncherJob = Start-Job -ArgumentList $Executable,$Arguments,$Ai,$Temp,$Session -ScriptBlock {
        param($Executable,$Arguments,$Ai,$Temp,$Session)
        $env:CODEX_THREAD_ID = $Session
        Remove-Item Env:CLAUDE_CODE_SESSION_ID -ErrorAction SilentlyContinue
        $env:TEMP = $Temp
        $env:TMP = $Temp
        $env:TMPDIR = $Temp
        Set-Location $Ai
        $Output = (& $Executable @Arguments 2>&1 | Out-String).Trim()
        [pscustomobject]@{Output=$Output;ExitCode=$LASTEXITCODE}
    }

    if(!(Wait-Job $LauncherJob -Timeout 20))
    {
        Stop-Job $LauncherJob,$PipeJob -ErrorAction SilentlyContinue
        Remove-Job $LauncherJob,$PipeJob -Force -ErrorAction SilentlyContinue
        throw "Launcher timed out: $Executable $($Arguments -join ' ')"
    }
    $Launch = Receive-Job $LauncherJob -Wait -AutoRemoveJob

    if(!(Wait-Job $PipeJob -Timeout 5))
    {
        Stop-Job $PipeJob -ErrorAction SilentlyContinue
        Remove-Job $PipeJob -Force -ErrorAction SilentlyContinue
        throw "Launcher did not connect to the named pipe: $Executable $($Arguments -join ' ')`n$($Launch.Output)"
    }
    $Request = (Receive-Job $PipeJob -Wait -AutoRemoveJob | Select-Object -Last 1)
    Assert-True ($Launch.ExitCode -eq 0) "Launcher exited with $($Launch.ExitCode): $($Launch.Output)"
    Assert-True ($Launch.Output -like '*Unicode 測試 ✓*') "UTF-8 response was corrupted: $($Launch.Output)"
    [pscustomobject]@{Request=($Request | ConvertFrom-Json);Output=$Launch.Output}
}

$OriginalAcl = Get-Acl $Root
try
{
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $Acl = Get-Acl $Root
    $Rule = [Security.AccessControl.FileSystemAccessRule]::new(
        $Identity,'Write,Modify','ContainerInherit,ObjectInherit','None','Deny')
    $Acl.AddAccessRule($Rule) | Out-Null
    Set-Acl $Root $Acl

    $BashResult = Invoke-Launcher $Bash @(
        './dsi.sh','set_param','show_slice','0','--','voice','中文 (test)',
        '-Chat','Agent ✓')
    Assert-True ($BashResult.Request.agent -eq 'Codex') 'Bash launcher lost the agent identity.'
    Assert-True ($BashResult.Request.session -eq $Session) 'Bash launcher lost the session ID.'
    Assert-True ($BashResult.Request.command.Count -eq 2) 'Bash launcher did not preserve the batch.'
    Assert-True ($BashResult.Request.command[0].cmd -eq 'set_param') 'First batched command changed.'
    Assert-True ($BashResult.Request.command[0].param[0] -eq 'show_slice') 'Composite parameter changed.'
    Assert-True ($BashResult.Request.command[0].param[1] -eq 0) 'Numeric conversion changed.'
    Assert-True ($BashResult.Request.command[1].param -eq '中文 (test)') 'Quoted Unicode parameter changed.'
    Assert-True ($BashResult.Request.chat -eq 'Agent ✓') '-Chat forwarding changed.'

    $CmdResult = Invoke-Launcher (Join-Path $Ai 'dsi.cmd') @(
        'set_title','Folder (A) with spaces','--','list_window','-Chat','Native ✓')
    Assert-True ($CmdResult.Request.command.Count -eq 2) 'dsi.cmd did not preserve the batch.'
    Assert-True ($CmdResult.Request.command[0].param -eq 'Folder (A) with spaces') 'dsi.cmd changed a quoted parameter.'
    Assert-True ($CmdResult.Request.chat -eq 'Native ✓') 'dsi.cmd changed -Chat.'

    $PowerShellResult = Invoke-Launcher 'powershell.exe' @(
        '-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-Command',
        "& './dsi.ps1' list_window")
    Assert-True ($PowerShellResult.Request.command.cmd -eq 'list_window') 'Call-operator fallback failed.'

    $CmdText = Get-Content (Join-Path $Ai 'dsi.cmd') -Raw
    Assert-True ($CmdText -notmatch '(?i)\s-File\s') 'dsi.cmd regressed to powershell -File.'
    Assert-True ($CmdText -match '(?i)-Command\s+"& \$env:DSI_PS1"') 'dsi.cmd no longer uses the tested call-operator path.'

    $ShText = Get-Content (Join-Path $Ai 'dsi.sh') -Raw
    $WindowsBranch = $ShText.Substring(0,$ShText.IndexOf("esac")+4)
    Assert-True ($WindowsBranch -notmatch '<<.*PS1') 'Windows dsi.sh regressed to a PowerShell heredoc.'

    Write-Host 'Windows launcher smoke tests passed.'
}
finally
{
    Set-Acl $Root $OriginalAcl -ErrorAction SilentlyContinue
    Remove-Item $Root -Recurse -Force -ErrorAction SilentlyContinue
}
