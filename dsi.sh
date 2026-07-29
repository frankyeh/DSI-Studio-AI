#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
MINGW*|MSYS*|CYGWIN*)
    ps1=$(mktemp "${TMPDIR:-/tmp}/dsi.XXXXXX.ps1")
    trap 'rm -f "$ps1"' EXIT
    cat >"$ps1" <<'PS1'
param(
    [Parameter(Mandatory,Position=0)]
    [string]$Target,

    [Parameter(Position=1,ValueFromRemainingArguments)]
    [string[]]$Value,

    [string]$Chat
)

$ErrorActionPreference = 'Stop'
$Agent = $env:DSI_STUDIO_AGENT
$Session = $env:CODEX_THREAD_ID
if(!$Agent) { throw 'Missing DSI_STUDIO_AGENT.' }
if(!$Session) { throw 'Missing CODEX_THREAD_ID.' }

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
switch($Target.ToUpperInvariant())
{
    'LIST'  {$request.request = 'LIST'}
    'LOG'   {$request.request = 'LOG'}
    'CHAT'  {$request.request = 'CHAT';  $request.chat = $Value -join ' '}
    'TITLE' {$request.request = 'TITLE'; $request.title = $Value -join ' '}
    default
    {
        if(!$Value.Count) { throw 'Missing command name.' }
        $request.request = 'CMD'
        $request.window = $Target
        $request.command = [ordered]@{cmd=$Value[0]}
        $param = @($Value | Select-Object -Skip 1 | ForEach-Object {Convert-DsiValue $_})
        if($param.Count -eq 1) { $request.command.param = $param[0] }
        elseif($param.Count -gt 1) { $request.command.param = $param }
    }
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
    powershell.exe -NoProfile -ExecutionPolicy Bypass \
        -File "$(cygpath -w "$ps1")" "$@"
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


agent = os.environ.get("DSI_STUDIO_AGENT", "").strip()
session = os.environ.get("CODEX_THREAD_ID", "").strip()
if not agent:
    fail("Missing DSI_STUDIO_AGENT.")
if not session:
    fail("Missing CODEX_THREAD_ID.")

args = sys.argv[1:]
if not args:
    fail("Usage: ./dsi.sh <TITLE|LIST|LOG|CHAT|window-id> [command/values...]")

target, *args = args
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
kind = target.upper()
if kind in {"LIST", "LOG"}:
    request["request"] = kind
elif kind == "CHAT":
    request.update(request="CHAT", chat=" ".join(values))
elif kind == "TITLE":
    request.update(request="TITLE", title=" ".join(values))
else:
    if not values:
        fail("Missing command name.")
    command = {"cmd": values[0]}
    params = [convert(value) for value in values[1:]]
    if len(params) == 1:
        command["param"] = params[0]
    elif params:
        command["param"] = params
    request.update(request="CMD", window=target, command=command)
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
