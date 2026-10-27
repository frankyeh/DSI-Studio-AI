# DSI Studio AI Device Command Examples and Inventory

Use these with a `tracking<hex-address>` window. Select it once before sending
any command below:

```bash
bash ./dsi.sh set_window tracking<hex-address>
```

The selection persists for the session until changed by another `set_window` call.
Command names and text, path, or composite parameters are strings. Send standalone
numeric parameters as JSON numbers.

This file contains the complete device command inventory confirmed in the
current source. Device indices follow current table order; use `list_devices`
to discover them.

| Command | Common example | Important behavior |
|---|---|---|
| `new_device` | `["new_device","80 100 80"]` | Create a device at a supplied voxel position; omission places it near image center. The three coordinates remain one composite string. |
| `move_device` | `["move_device","82 101 79",0]` | Move one device to a supplied voxel coordinate. Omit the index to use the current row. |
| `push_device` | `["push_device",0]` | Move one device by -0.5 mm along its direction. Omit the index to use the current row. |
| `pull_device` | `["pull_device",0]` | Move one device by +0.5 mm along its direction. Omit the index to use the current row. |
| `copy_device` | `["copy_device",0]` | Copy one device and offset its x-position by one voxel. Omit the index to use the current row. |
| `set_acpc` | `["set_acpc"]` | Replace AC, PC, and Inter locators from fixed MNI coordinates mapped into subject space. |
| `delete_device` | `["delete_device","0&2&5"]` | Delete one or more devices. Use one index or an `&`-separated index list; omit the index to use the current row. |
| `delete_all_devices` | `["delete_all_devices"]` | Delete all devices. |
| `save_all_devices` | `["save_all_devices","C:/output/electrodes.dv.csv"]` | Save checked devices in table order. Without a path, open a save dialog. |
| `load_device` | `["load_device","C:/output/electrodes.dv.csv"]` | Append devices from a device file. Fails if the file yields no device. Without a path, open a file dialog. |
| `list_devices` | `["list_devices"]` | Return a tab-separated table in `output`: index, shown (1/0), name, type, color, length, x, y, z, phi, theta. `list_device` is an alias. |
| `list_device_types` | `["list_device_types"]` | Return the available device type names, one per line. |
| `set_device_type` | `["set_device_type","Locator",0]` | Set one device's type (exact name from `list_device_types`, case-insensitive). Applies the GUI rules for default name and length. Omit the index to use the current row. |
| `set_device_direction` | `["set_device_direction","30 45",0]` | Set one device's direction as `"phi theta"` in degrees or as a `"dx dy dz"` vector (normalized; zero fails). `set_device_dir` is an alias. Omit the index to use the current row. |
| `show_device_statistics` | `["show_device_statistics"]` | Compute device statistics. AI callers get the text directly in `output`; a local user instead sees it in a modal dialog. |
| `save_device_statistics` | `["save_device_statistics","C:/output/device_stat.txt"]` | Same statistics as `show_device_statistics`, but always written to the given path (no dialog, no direct-response text), for any caller. The path is required — a bare `save_device_statistics` with no path fails with a usage error. |

## Source-confirmed notes

- Device positions supplied to `new_device` and `move_device` are voxel coordinates in current FIB space.
- `push_device` and `pull_device` use a physical 0.5 mm movement converted using voxel size.
- `move_device`, `push_device`, `pull_device`, and `copy_device` use the current row when the index is omitted.
- `delete_device` accepts one index or an `&`-separated index list and uses the current row when omitted.
- Run `list_devices` to map names to indices before index-based commands; when names are ambiguous, ask the user rather than guessing.
- `phi`/`theta` follow the table columns: phi is the azimuth in the x–y plane and theta the angle from +z, both in degrees.
- `set_acpc` removes existing locator entries before creating replacements.
- `save_all_devices` writes only checked devices.
- `show_device_statistics` returns the report text directly to an AI caller (no dialog); a local user still sees a modal dialog. Use `save_device_statistics` instead when the result should be written to a file rather than returned.
- Confirm `delete_device`, `delete_all_devices`, and replacement of existing AC/PC/Inter locators before use.
