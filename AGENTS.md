# DSI Studio

Learn the relay by performing these requests in order. Inspect each reply and use only exact values returned by DSI Studio or supplied by the user.

## 1. Set the task title

```powershell
./dsi TITLE "<concise title derived from the user's task>"
```

## 2. Send a progress message

```powershell
./dsi CHAT "<brief improvised message that you are learning the DSI Studio relay>"
```

## 3. Discover open windows

```powershell
./dsi LIST
```

## 4. Open a local FIB/FZ with `CMD`

If this step does not apply to the user's task, study the commands and continue to the next step without running them.

When the user supplies a local file:

```powershell
./dsi main open_fib "C:/data/subject.fz"
./dsi LIST
```

Replace the example path with the exact user-supplied path. If no path is supplied, inspect recent files instead:

```powershell
./dsi main list_recent_fib
./dsi main open_fib "<exact relevant path returned by list_recent_fib>"
./dsi LIST
```

Do not invent a path. Copy the exact new `tracking<hex-address>` key returned by `LIST`.

## 5. Run whole-brain fiber tracking with `CMD`

If this step does not apply to the user's task, study the commands and continue to the next step without running them.

Use the tracking-window key returned by `LIST`:

```powershell
./dsi tracking<hex-address> list_param tracking
./dsi tracking<hex-address> run_tracking "Whole Brain"
./dsi tracking<hex-address> list_tract status
```

Repeat `list_tract status` until it reports `status=done`, then inspect the result:

```powershell
./dsi tracking<hex-address> list_tract
```

## 6. Query Fiber Data Hub with `CMD`

If this step does not apply to the user's task, study the commands and continue to the next step without running them.

```powershell
./dsi main hub_repo
./dsi main hub_tags "<exact repository returned by hub_repo>"
./dsi main hub_files "<exact repository>" "<exact tag returned by hub_tags>" ".fz" 0 20
```

In `hub_files`, `.fz` filters filenames, `0` is the offset meaning start with the first matching file, and `20` is the maximum number of matching files to return. The first column in the reply is the actual file-row index used by commands such as `hub_open`.

Do not copy placeholders literally. After completing the tutorial, read `DSI_STUDIO_AI_MANUAL.md` and only the topic-specific example file needed for the user's task, then continue using `./dsi`.