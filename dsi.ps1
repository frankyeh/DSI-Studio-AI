param(
    [Parameter(Position=0,ValueFromRemainingArguments)]
    [string[]]$Value,

    [string]$Chat
)

$ErrorActionPreference = 'Stop'
$Session = $env:CLAUDE_CODE_SESSION_ID
if($Session)
{
    $Agent = 'Claude'
}
else
{
    $Session = $env:CODEX_THREAD_ID
    if(!$Session) { throw 'Missing CLAUDE_CODE_SESSION_ID or CODEX_THREAD_ID.' }
    $Agent = 'Codex'
}

function Convert-DsiValue([string]$Text)
{
    $integer = 0L
    if([long]::TryParse($Text,[ref]$integer)) { return $integer }
    $number = 0.0
    if([double]::TryParse($Text,
        [Globalization.NumberStyles]::Float,
        [Globalization.CultureInfo]::InvariantCulture,
        [ref]$number)) { return $number }
    return $Text
}

if(!$Value.Count -and !$Chat) { throw 'Missing command name.' }

$request = [ordered]@{agent=$Agent;session=$Session}
if($Value.Count)
{
    $Segments = @()
    [string[]]$Current = @()
    foreach($item in $Value)
    {
        if($item -eq '--')
        {
            if(!$Current.Count) { throw 'Empty command in batch.' }
            $Segments += ,@($Current)
            [string[]]$Current = @()
        }
        else
        {
            $Current += $item
        }
    }
    if(!$Current.Count) { throw 'Batch cannot end with --.' }
    $Segments += ,@($Current)

    $Commands = @()
    foreach($segment in $Segments)
    {
        $cmd = [ordered]@{cmd=$segment[0]}
        $param = @($segment | Select-Object -Skip 1 | ForEach-Object {Convert-DsiValue $_})
        if($param.Count -eq 1) { $cmd.param = $param[0] }
        elseif($param.Count -gt 1) { $cmd.param = $param }
        $Commands += ,$cmd
    }
    $request.command = if($Commands.Count -eq 1) { $Commands[0] } else { $Commands }
}
if($Chat) { $request.chat = $Chat }

$pipe = $writer = $reader = $null
try
{
    $pipe = [IO.Pipes.NamedPipeClientStream]::new('.','dsi-studio')
    $pipe.Connect(5000)
    $utf8 = [Text.UTF8Encoding]::new($false)
    $writer = [IO.StreamWriter]::new($pipe,$utf8,1024,$true)
    $reader = [IO.StreamReader]::new($pipe,$utf8,$false,1024,$true)
    $writer.Write(($request | ConvertTo-Json -Compress -Depth 8))
    $writer.Flush()
    $reader.ReadToEnd()
}
finally
{
    foreach($stream in @($reader,$writer,$pipe))
    {
        if($stream) { try {$stream.Dispose()} catch [IO.IOException] {} }
    }
}
