# DSI Studio

These instructions are shared by Codex and Claude.

Use the recommended launcher for every request:

```bash
bash ./dsi.sh <command> [values...]
```

Always include `bash` before `./dsi.sh`. If this launcher does not work, read
`DSI_STUDIO_AI_LAUNCHER.md` for platform requirements, troubleshooting, and the
documented Windows fallback.

Learn DSI Studio by performing the following three requests in order. Complete and
inspect all three replies before reading further in this file or opening any other
DSI Studio AI document.

## 1. Set the task title

```bash
bash ./dsi.sh set_title "<concise title derived from the user's task>"
```

## 2. Send a progress message

```bash
bash ./dsi.sh -Chat "<brief improvised message that you are reading the DSI Studio manual before continuing>"
```

## 3. Learn a main-window command

```bash
bash ./dsi.sh list_recent_fib
```

After receiving and inspecting the replies to Steps 1-3, continue below.

## 4. Work with an SRC/SZ reconstruction window

If this step does not apply to the user's task, study the commands and continue to
the next step without running them.

### 4.1 Open a user-supplied source file

```bash
bash ./dsi.sh open_src "C:/data/subject.sz"
```

Replace the example path with the exact user-supplied path. Copy the exact
`recon<hex-address>` ID from `recon window created, id: recon...` in the successful
command `output`. Do not call `list_window` merely to rediscover this window.

### 4.2 Open a recent source file when no path is supplied

```bash
bash ./dsi.sh list_recent_src
bash ./dsi.sh open_src "<exact relevant path returned by list_recent_src>"
```

Do not invent a path. Copy the exact reconstruction-window ID returned by
`open_src`.

### 4.3 Inspect reconstruction parameters

Select the returned `recon<hex-address>` once; the selection persists for later
commands in this section:

```bash
bash ./dsi.sh set_window recon<hex-address>
bash ./dsi.sh list_param
```

Before changing source data or running reconstruction, read
`DSI_STUDIO_AI_COMMAND_EXAMPLES_RECONSTRUCTION.md`. Reconstruction corrections,
mask operations, resampling, and b-table changes can materially alter the result;
do not run them merely to learn the interface.

## 5. Work with a FIB/FZ tracking window

If this step does not apply to the user's task, study the commands and continue to
the next step without running them.

### 5.1 Open a user-supplied file

```bash
bash ./dsi.sh open_fib "C:/data/subject.fz"
```

Replace the example path with the exact user-supplied path. Copy the exact
`tracking<hex-address>` ID from `tracking window created, id: tracking...` in the
successful command `output`. Do not call `list_window` merely to rediscover this window.

### 5.2 Open a recent file when no path is supplied

Use an exact relevant path returned by Step 3:

```bash
bash ./dsi.sh open_fib "<exact relevant path returned by list_recent_fib>"
```

Do not invent a path. Copy the exact new tracking-window ID from the successful
`open_fib` command `output`.

Select it once; the selection persists for every later command in this file until
changed again:

```bash
bash ./dsi.sh set_window tracking<hex-address>
```

### 5.3 Switch the displayed slice

```bash
bash ./dsi.sh list_slice
bash ./dsi.sh set_slice <slice-index>
bash ./dsi.sh list_slice
```

Use an index returned by `list_slice`. A Hub-provided slice may initially report
`available` because its source is HTTP. `set_slice` downloads and registers it;
repeat `list_slice` until the selected row reports `ready` before using it.

### 5.4 Segment a brain with SynthSeg

Select a suitable anatomical slice with Step 5.3, then discover the available
models:

```bash
bash ./dsi.sh list_unet
bash ./dsi.sh segment_brain human_synthseg <slice-index>
bash ./dsi.sh list_region
```

Run `human_synthseg` only when its `list_unet` row reports `available=1`. The final
command confirms the regions created by SynthSeg.

### 5.5 Add the bilateral thalamus from BrainSeg

```bash
bash ./dsi.sh list_atlas
bash ./dsi.sh add_region_from_atlas "0 1 3&4"
bash ./dsi.sh list_region
```

First confirm that `list_atlas` reports `template=0`, `atlas=1`, and
`name=BrainSeg`. In the current BrainSeg label table, `3&4` are the zero-based label
indices for `Thalamus_Left` and `Thalamus_Right`.

## 6. Run whole-brain fiber tracking

If this step does not apply to the user's task, study the commands and continue to
the next step without running them.

The tracking window selected in Step 5.2 remains selected. Call `list_window` only
to confirm its ID or discover a different already-open reconstruction, tracking, or
image window.

### 6.1 Inspect tracking parameters

```bash
bash ./dsi.sh list_param tracking
```

### 6.2 Start tracking

```bash
bash ./dsi.sh run_tracking "Whole Brain"
```

### 6.3 Wait for completion

```bash
bash ./dsi.sh list_tract status
```

Repeat until it reports `status=done`.

### 6.4 Inspect the resulting bundle

```bash
bash ./dsi.sh list_tract
```

## 7. Query Fiber Data Hub

If this step does not apply to the user's task, study the commands and continue to
the next step without running them.

### 7.1 List repositories

```bash
bash ./dsi.sh hub_repo
```

### 7.2 List tags

```bash
bash ./dsi.sh hub_tags "<exact repository returned by hub_repo>"
```

### 7.3 List matching files

```bash
bash ./dsi.sh hub_files "<exact repository>" "<exact tag returned by hub_tags>" ".fz" 0 20
```

In `hub_files`, `.fz` filters filenames, `0` starts with the first matching file,
and `20` returns at most 20 matching files. The first reply column is the file-row
index used by commands such as `hub_open`.

### 7.4 Open a Hub file

```bash
bash ./dsi.sh hub_open "<exact repository>" "<exact tag>" <file-row-index>
```

Use the row index returned by `hub_files`. If the reply contains
`tracking window created, id: tracking...`, use that exact ID. A network-backed open
may finish after the immediate reply; when no ID is returned, call `list_window` to
discover the newly opened window. After the tracking window opens, use Step 5.3 to
load any HTTP-backed slice needed for the task.

Do not copy placeholders literally.

## Continue with the task

When the user demonstrates a workflow, changes settings manually, or retries a failed
action, run `bash ./dsi.sh log` and inspect the returned action history instead
of relying on memory.

The same folder contains `DSI_STUDIO_AI_MANUAL.md` for relay rules,
`DSI_STUDIO_AI_SKILL_*.md` for task workflows, and
`DSI_STUDIO_AI_COMMAND_EXAMPLES_*.md` for command syntax and inventories. Read only
the files relevant to the user's task, then continue using `bash ./dsi.sh`.
