# DSI Studio

Learn the relay by performing these requests in order. Inspect each reply and use only exact values returned by DSI Studio.

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

## 4. Open a recent FIB/FZ with `CMD`

```powershell
./dsi main list_recent_fib
./dsi main open_fib "<exact relevant path returned by list_recent_fib>"
./dsi LIST
```

If no relevant recent FIB/FZ is returned, do not invent a path; continue to the next step.

## 5. Query Fiber Data Hub with `CMD`

```powershell
./dsi main hub_repo
./dsi main hub_tags "<exact repository returned by hub_repo>"
./dsi main hub_files "<exact repository>" "<exact tag returned by hub_tags>" ".fz" 0 20
```

Do not copy placeholders literally. After completing the tutorial, read `DSI_STUDIO_AI_MANUAL.md` and only the topic-specific example file needed for the user's task, then continue using `./dsi`.