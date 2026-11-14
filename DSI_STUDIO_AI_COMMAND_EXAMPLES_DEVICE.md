# DSI Studio AI Device Command Examples and Inventory

Complete device inventory confirmed in the current source. Use these in a `tracking<hex-address>`
window, selected once with `bash ./dsi.sh set_window tracking<hex-address>` (it persists until
changed). Names and text, path, or composite parameters are strings; send standalone numbers as JSON
numbers. Indices follow current table order: run `list_devices` to map names to indices first, and
ask the user rather than guess when names are ambiguous. Commands with an optional index use the
current row when it is omitted. Positions are voxel coordinates in current FIB space.

| Command | Example | Behavior |
|---|---|---|
| `new_device` | `["new_device","80 100 80"]` | Create a device at a voxel position (one composite string); omitted: near image center. |
| `move_device` | `["move_device","82 101 79",0]` | Move one device to a voxel coordinate. |
| `push_device`, `pull_device` | `["push_device",0]`, `["pull_device",0]` | Move one device by -0.5 mm or +0.5 mm along its direction (physical distance converted with the voxel size). |
| `copy_device` | `["copy_device",0]` | Copy one device, offsetting x by one voxel. |
| `set_acpc` | `["set_acpc"]` | Remove existing locators and create AC, PC, and Inter locators from fixed MNI coordinates mapped into subject space. |
| `delete_device` | `["delete_device","0&2&5"]` | Delete one device or an `&`-separated index list. |
| `delete_all_devices` | `["delete_all_devices"]` | Delete all devices. |
| `save_all_devices` | `["save_all_devices","C:/output/electrodes.dv.csv"]` | Save only checked devices, in table order (no path: save dialog). |
| `load_device` | `["load_device","C:/output/electrodes.dv.csv"]` | Append devices from a file; fails if it yields none (no path: file dialog). |
| `list_devices` | `["list_devices"]` | Tab-separated table in `output`: index, shown (1/0), name, type, color, length, x, y, z, phi, theta; alias `list_device`. `phi` is the azimuth in the x–y plane and `theta` the angle from +z, in degrees. |
| `list_device_types` | `["list_device_types"]` | Available device type names, one per line. |
| `set_device_type` | `["set_device_type","Locator",0]` | Set a device's type (exact name from `list_device_types`, case-insensitive), applying the GUI rules for default name and length. |
| `set_device_direction` | `["set_device_direction","30 45",0]` | Set direction as `"phi theta"` in degrees or a `"dx dy dz"` vector (normalized; zero fails); alias `set_device_dir`. |
| `show_device_statistics` | `["show_device_statistics"]` | Device statistics: text in `output` for AI callers, a modal dialog for a local user. |
| `save_device_statistics` | `["save_device_statistics","C:/output/device_stat.txt"]` | The same statistics written to the required path for any caller (no dialog, no response text); without a path it fails with a usage error. |

Confirm `delete_device`, `delete_all_devices`, and replacement of existing AC/PC/Inter locators
before use.
