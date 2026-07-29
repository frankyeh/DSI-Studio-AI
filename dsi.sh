#!/usr/bin/env bash
set -euo pipefail

if command -v python3 >/dev/null 2>&1; then
    py=(python3)
elif command -v python >/dev/null 2>&1; then
    py=(python)
elif command -v py >/dev/null 2>&1; then
    py=(py -3)
else
    echo "dsi.sh requires Python 3." >&2
    exit 1
fi

exec "${py[@]}" - "$@" <<'PY'
import ctypes
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


def windows_pipe():
    from ctypes import wintypes

    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    pipe_name = r"\\.\pipe\dsi-studio"
    kernel32.WaitNamedPipeW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD]
    kernel32.WaitNamedPipeW.restype = wintypes.BOOL
    kernel32.CreateFileW.argtypes = [
        wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD, wintypes.LPVOID,
        wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE,
    ]
    kernel32.CreateFileW.restype = wintypes.HANDLE
    kernel32.WriteFile.argtypes = [
        wintypes.HANDLE, wintypes.LPCVOID, wintypes.DWORD,
        ctypes.POINTER(wintypes.DWORD), wintypes.LPVOID,
    ]
    kernel32.WriteFile.restype = wintypes.BOOL
    kernel32.ReadFile.argtypes = [
        wintypes.HANDLE, wintypes.LPVOID, wintypes.DWORD,
        ctypes.POINTER(wintypes.DWORD), wintypes.LPVOID,
    ]
    kernel32.ReadFile.restype = wintypes.BOOL
    kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
    kernel32.CloseHandle.restype = wintypes.BOOL

    if not kernel32.WaitNamedPipeW(pipe_name, 5000):
        fail(f"Cannot connect to {pipe_name}: Windows error {ctypes.get_last_error()}.")
    handle = kernel32.CreateFileW(pipe_name, 0xC0000000, 0, None, 3, 0, None)
    if handle == wintypes.HANDLE(-1).value:
        fail(f"Cannot open {pipe_name}: Windows error {ctypes.get_last_error()}.")
    try:
        written = wintypes.DWORD()
        data = ctypes.create_string_buffer(payload)
        if not kernel32.WriteFile(handle, data, len(payload), ctypes.byref(written), None):
            fail(f"Cannot write to {pipe_name}: Windows error {ctypes.get_last_error()}.")
        chunks = []
        while True:
            buffer = ctypes.create_string_buffer(4096)
            read = wintypes.DWORD()
            okay = kernel32.ReadFile(handle, buffer, len(buffer), ctypes.byref(read), None)
            if read.value:
                chunks.append(buffer.raw[:read.value])
            if okay:
                continue
            error = ctypes.get_last_error()
            if error == 234:
                continue
            if error in {109, 232}:
                break
            fail(f"Cannot read from {pipe_name}: Windows error {error}.")
        return b"".join(chunks)
    finally:
        kernel32.CloseHandle(handle)


def unix_socket():
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
    endpoints = paths + ["\0dsi-studio"]
    errors = []
    for endpoint in endpoints:
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
                    return b"".join(chunks)
                chunks.append(chunk)
        except OSError as error:
            errors.append(f"{endpoint!r}: {error}")
        finally:
            client.close()
    fail("Cannot connect to DSI Studio local socket:\n" + "\n".join(errors))


reply = windows_pipe() if os.name == "nt" else unix_socket()
sys.stdout.buffer.write(reply)
if reply and not reply.endswith(b"\n"):
    sys.stdout.buffer.write(b"\n")
PY
