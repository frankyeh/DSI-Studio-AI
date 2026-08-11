#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
MINGW*|MSYS*|CYGWIN*)
    export DSI_ARGC=$#
    i=0
    for value in "$@"; do
        printf -v name 'DSI_ARG_%d' "$i"
        printf -v "$name" '%s' "$value"
        export "$name"
        i=$((i+1))
    done
    ps=$(cat <<'PS1'
$ErrorActionPreference = 'Stop'
$argv = @(for($i = 0; $i -lt [int]$env:DSI_ARGC; $i++)
{
    [Environment]::GetEnvironmentVariable("DSI_ARG_$i")
})
[string[]]$Value = @()
$Chat = $null
for($i = 0; $i -lt $argv.Count; $i++)
{
    if($argv[$i] -ieq '-Chat')
    {
        $i++
        if($i -ge $argv.Count) { throw '-Chat requires a message.' }
        $Chat = $argv[$i]
    }
    else
    {
        $Value += $argv[$i]
    }
}
if(!$Value.Count -and !$Chat) { throw 'Usage: bash ./dsi.sh [command] [values...] [-- command values...] [-Chat "message"]' }

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
PS1
)
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ps"
    exit $?
;;
esac

if command -v python3 >/dev/null 2>&1; then
    py=(python3)
elif command -v python >/dev/null 2>&1; then
    py=(python)
else
    echo "dsi.sh requires Python 3 on macOS/Linux." >&2
    exit 1
fi

exec "${py[@]}" - "$@" <<'PY'
import json
import math
import os
import re
import socket
import sys
import tempfile


def fail(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


session = os.environ.get("CLAUDE_CODE_SESSION_ID", "").strip()
if session:
    agent = "Claude"
else:
    session = os.environ.get("CODEX_THREAD_ID", "").strip()
    if not session:
        fail("Missing CLAUDE_CODE_SESSION_ID or CODEX_THREAD_ID.")
    agent = "Codex"

args = sys.argv[1:]
values = []
chat = None
i = 0
while i < len(args):
    if args[i].lower() == "-chat":
        if i + 1 == len(args):
            fail("-Chat requires a message.")
        chat = args[i + 1]
        i += 2
    else:
        values.append(args[i])
        i += 1

if not values and chat is None:
    fail('Usage: bash ./dsi.sh [command] [values...] [-- command values...] [-Chat "message"]')

integer = re.compile(r"^[+-]?\d+$")
number = re.compile(r"^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$")


def convert(text):
    if integer.fullmatch(text):
        value = int(text)
        if -(1 << 63) <= value < (1 << 63):
            return value
    if number.fullmatch(text):
        value = float(text)
        if math.isfinite(value):
            return value
    return text


request = {"agent": agent, "session": session}
if values:
    segments = []
    current = []
    for value in values:
        if value == "--":
            if not current:
                fail("Empty command in batch.")
            segments.append(current)
            current = []
        else:
            current.append(value)
    if not current:
        fail("Batch cannot end with --.")
    segments.append(current)

    commands = []
    for segment in segments:
        command = {"cmd": segment[0]}
        params = [convert(value) for value in segment[1:]]
        if len(params) == 1:
            command["param"] = params[0]
        elif params:
            command["param"] = params
        commands.append(command)
    request["command"] = commands[0] if len(commands) == 1 else commands
if chat is not None:
    request["chat"] = chat

payload = json.dumps(request, separators=(",", ":"), ensure_ascii=False).encode()
paths = []
override = os.environ.get("DSI_STUDIO_SOCKET")
if override:
    paths.append(override)
for base in (
    os.environ.get("TMPDIR"), os.environ.get("TMP"),
    os.environ.get("TEMP"), tempfile.gettempdir(), "/tmp",
):
    if base:
        path = os.path.join(base, "dsi-studio")
        if path not in paths:
            paths.append(path)

errors = []
for endpoint in paths + ["\0dsi-studio"]:
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        client.settimeout(5)
        client.connect(endpoint)
        client.sendall(payload)
        client.shutdown(socket.SHUT_WR)
        chunks = []
        while True:
            chunk = client.recv(4096)
            if not chunk:
                reply = b"".join(chunks)
                sys.stdout.buffer.write(reply)
                if reply and not reply.endswith(b"\n"):
                    sys.stdout.buffer.write(b"\n")
                raise SystemExit
            chunks.append(chunk)
    except OSError as error:
        errors.append(f"{endpoint!r}: {error}")
    finally:
        client.close()
fail("Cannot connect to DSI Studio local socket:\n" + "\n".join(errors))
PY