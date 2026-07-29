# DSI Studio

This file is for Codex. `CLAUDE.md` contains the same instructions with only the launcher changed for Claude, so do not read it.

Learn DSI Studio by performing these requests in order.

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

## 4. Work with a FIB/FZ tracking window

If this step does not apply to the user's task, study the commands and continue to the next step without running them.

### 4.1 Open a user-supplied file

```powershell
./dsi main open_fib "C:/data/subject.fz"
./dsi LIST
```

Replace the example path with the exact user-supplied path.

### 4.2 Open a recent file when no path is supplied

```powershell
./dsi main list_recent_fib
./dsi main open_fib "<exact relevant path returned by list_recent_fib>"
./dsi LIST
```

Do not invent a path. Copy the new `tracking<hex-address>` key returned by `LIST`.

### 4.3 Switch the displayed slice

```powershell
./dsi tracking<hex-address> list_slice
./dsi tracking<hex-address> set_slice <slice-index>
./dsi tracking<hex-address> list_slice
```

Use an index returned by `list_slice`. A Hub-provided slice may initially report `available` because its source is HTTP. `set_slice` downloads and registers it; repeat `list_slice` until the selected row reports `ready` before using it.

### 4.4 Segment a brain with SynthSeg

Select a suitable anatomical slice with Step 4.3, then discover the available models:

```powershell
./dsi tracking<hex-address> list_unet
./dsi tracking<hex-address> segment_brain human_synthseg <slice-index>
./dsi tracking<hex-address> list_region
```

Run `human_synthseg` only when its `list_unet` row reports `available=1`. The final command confirms the regions created by SynthSeg.

### 4.5 Add the bilateral thalamus from BrainSeg

```powershell
./dsi tracking<hex-address> list_atlas
./dsi tracking<hex-address> add_region_from_atlas "0 1 3&4"
./dsi tracking<hex-address> list_region
```

First confirm that `list_atlas` reports `template=0`, `atlas=1`, and `name=BrainSeg`. In the current BrainSeg label table, `3&4` are the zero-based label indices for `Thalamus_Left` and `Thalamus_Right`.

## 5. Run whole-brain fiber tracking with `CMD`

If this step does not apply to the user's task, study the commands and continue to the next step without running them.

Use the tracking-window key returned by `LIST`.

### 5.1 Inspect tracking parameters

```powershell
./dsi tracking<hex-address> list_param tracking
```

### 5.2 Start tracking

```powershell
./dsi tracking<hex-address> run_tracking "Whole Brain"
```

### 5.3 Wait for completion

```powershell
./dsi tracking<hex-address> list_tract status
```

Repeat until it reports `status=done`.

### 5.4 Inspect the resulting bundle

```powershell
./dsi tracking<hex-address> list_tract
```

## 6. Query Fiber Data Hub with `CMD`

If this step does not apply to the user's task, study the commands and continue to the next step without running them.

### 6.1 List repositories

```powershell
./dsi main hub_repo
```

### 6.2 List tags

```powershell
./dsi main hub_tags "<exact repository returned by hub_repo>"
```

### 6.3 List matching files

```powershell
./dsi main hub_files "<exact repository>" "<exact tag returned by hub_tags>" ".fz" 0 20
```

In `hub_files`, `.fz` filters filenames, `0` starts with the first matching file, and `20` returns at most 20 matching files. The first reply column is the file-row index used by commands such as `hub_open`.

### 6.4 Open a Hub file

```powershell
./dsi main hub_open "<exact repository>" "<exact tag>" <file-row-index>
./dsi LIST
```

Use the row index returned by `hub_files`. After the tracking window opens, use Step 4.3 to load any HTTP-backed slice needed for the task.

Do not copy placeholders literally.

## Continue with the task

The same folder contains `DSI_STUDIO_AI_MANUAL.md` for relay rules, `DSI_STUDIO_AI_SKILL_*.md` for task workflows, and `DSI_STUDIO_AI_COMMAND_EXAMPLES_*.md` for command syntax and inventories. Read only the files relevant to the user's task, then continue using `./dsi`.