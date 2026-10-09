from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
text = p.read_text(encoding='utf-8')

step1 = '''### Brain surface for tumor location visualization

For tumor-report 3D rendering, use the **`White_Matter` region produced by the
`human_tumor` segmentation as the brain envelope / spatial anchor**.

Do **not** use `add_surface`, a separate DSI surface object, or a separately generated
isosurface for the tumor report. Set `show_surface=0`; the checked `White_Matter` region
itself provides the translucent brain envelope.

The U-Net `White_Matter` output can contain disconnected fragments. Before final 3D
rendering, **defragment `White_Matter`** and visually verify that it forms a coherent brain
envelope. This cleanup is for `White_Matter` visualization only; do not defragment the tumor
compartments unless the user explicitly requests a segmentation edit.

Resolve the current row by name, then run:

```bash
bash ./dsi.sh region_action_defragment <white-matter-index>
bash ./dsi.sh list_region
```

Keep DSI Studio's **original RGB** for the segmentation regions and change **alpha only**.
`list_region` reports color as `#AARRGGBB`; preserve `RRGGBB` and replace `AA`:

```text
White_Matter       alpha 10  = 0x0A
Necrosis           alpha 200 = 0xC8
Peritumoral Edema  alpha 80  = 0x50
Enhancing Tumor    alpha 100 = 0x64
```

Use `set_region_color` with the resulting unsigned ARGB value. Do not copy RGB values from
another subject. The verified sub-003 example produced:

```text
Necrosis           #c85b484e
Peritumoral Edema  #508397ab
Enhancing Tumor    #64bc6e71
White_Matter       #0ae7e7ee
```

After setting alpha, **move `White_Matter` to the bottom of the Region table so it renders
last**. Re-resolve indices as rows move:

```bash
bash ./dsi.sh list_region
bash ./dsi.sh move_down_region <current-white-matter-index>
# repeat until White_Matter is the final row
bash ./dsi.sh list_region
```

For final tumor 3D scenes, normally show only `Necrosis`, `Peritumoral Edema`,
`Enhancing Tumor`, and `White_Matter`. Hide the other tissue labels unless specifically
needed. The cleaned `White_Matter` region is a visualization anchor and is not part of
Tumor Core.

'''
text, n = re.subn(r'### Brain surface for tumor location visualization\n.*?(?=### Required checkpoint after Step 1)', step1, text, flags=re.S)
assert n == 1, n

sec112 = '''### 11.2 3D figures: direct DSI Studio exports with the segmentation-derived White_Matter brain envelope

Final 3D figures must be **fresh direct DSI Studio saves**. Do not invert a black screenshot,
replace its background, hue-filter an all-tract image, or synthesize missing anatomy.

The canonical brain envelope is the **defragmented `White_Matter` region from
`human_tumor` segmentation**. Do not use `add_surface`, a separate `surface` object, or a
separate isosurface.

#### Canonical tumor + brain-envelope rendering preset

1. Resolve current region rows by name with `list_region`.
2. Defragment `White_Matter`:

```bash
bash ./dsi.sh region_action_defragment <white-matter-index>
bash ./dsi.sh list_region
```

3. Preserve DSI-assigned RGB and change alpha only:

```text
Necrosis           alpha = 200
Peritumoral Edema  alpha = 80
Enhancing Tumor    alpha = 100
White_Matter       alpha = 10
```

4. Move `White_Matter` to the **last Region-table row**, rechecking indices as it moves.
5. Show only the three tumor compartments plus `White_Matter` unless extra tissue anatomy
   is specifically required.
6. Disable separate surface and slice objects:

```bash
bash ./dsi.sh set_param show_surface 0
bash ./dsi.sh set_param show_slice 0
```

7. Use a white 3D background:

```bash
bash ./dsi.sh set_param bkg_color 16777215
```

The cleaned `White_Matter` region should appear as a very translucent brain envelope around
the more opaque tumor compartments.

#### Tract coloring in tumor + tract figures

Do **not** use directional tract coloring in final report figures. Use assigned colors and
cluster-color the tract bundles:

```bash
bash ./dsi.sh set_param tract_color_style 1
bash ./dsi.sh color_all_cluster
```

`tract_color_style=1` is **Assigned** color. Use `show_only_tracts` for one-tract report
figures; preserve the bundle's assigned cluster color. Keep distinct assigned cluster colors
in the all-tract overview.

For every final 3D scene, set an explicit view, call `get_camera`, save with `save_screen`,
and inspect the saved PNG. If the image is missing the `White_Matter` envelope, a tumor
compartment, or the requested tract, return to DSI Studio and regenerate it.

'''
text, n = re.subn(r'### 11\.2 3D figures:.*?(?=### 11\.3 2D slice figures)', sec112, text, flags=re.S)
assert n == 1, n

sec117 = '''### 11.7 Figure-generation order and state discipline

1. Finish segmentation, tracking, T2R, and morphology measurements first.
2. Resolve region indices by name with `list_region`.
3. Defragment `White_Matter` and verify a coherent brain envelope.
4. Preserve DSI RGB and set alpha only: Necrosis 200, Edema 80, Enhancing Tumor 100,
   White_Matter 10.
5. Move `White_Matter` to the final Region-table row so it renders last.
6. Show the three tumor compartments plus `White_Matter`; hide unnecessary tissue labels.
7. Set `show_surface=0` and `show_slice=0`. Do not call `add_surface`; no separate isosurface
   is required.
8. Set `bkg_color=16777215` for white-background 3D rendering.
9. For tract figures, set `tract_color_style=1` and run `color_all_cluster`; do not use
   directional tract color in the final report.
10. Generate all required tumor-only, all-tract, and single-tract 3D figures while this
    preset remains active.
11. For each view, call `get_camera`, save with `save_screen`, and visually inspect the PNG.
12. Keep 2D structural/slice figures on black background.
13. Assemble the PDF only from accepted direct DSI exports.

'''
text, n = re.subn(r'### 11\.7 Figure-generation order and state discipline\n.*?(?=### 11\.8 Final report QC checklist)', sec117, text, flags=re.S)
assert n == 1, n

repl = {
    '[ ] tumor/brain isosurfaces are visibly present in each required 3D scene': '[ ] defragmented White_Matter region is visibly present as the brain envelope in each required 3D scene',
    '[ ] no figure is visibly corrupted, missing its surface, or generated by post-hoc hue masking': '[ ] no figure is visibly corrupted, missing its White_Matter brain envelope, or generated by post-hoc hue masking',
    '- tumor only + brain surface: at least axial and coronal': '- tumor only + cleaned White_Matter brain envelope: at least axial and coronal',
    '- all selected tracts + tumor + brain surface: at least one overview, preferably two views': '- all selected tracts + tumor + cleaned White_Matter brain envelope: at least one overview, preferably two views',
    '- each affected/clinically important tract + tumor + brain surface: two useful orthogonal views': '- each affected/clinically important tract + tumor + cleaned White_Matter brain envelope: two useful orthogonal views',
    'whether the brain surface/tumor/tract are visibly present': 'whether the White_Matter brain envelope/tumor/tract are visibly present',
    '- synthesize a missing tumor or brain surface;': '- synthesize a missing tumor or White_Matter brain envelope;',
    'Fresh direct white-background axial + coronal tumor/brain-surface 3D': 'Fresh direct white-background axial + coronal tumor + cleaned White_Matter brain-envelope 3D',
    'Fresh direct white-background all-tract + tumor + brain-surface 3D': 'Fresh direct white-background all-tract + tumor + cleaned White_Matter brain-envelope 3D',
}
for old, new in repl.items():
    assert old in text, old
    text = text.replace(old, new)

anchor = '[ ] all 3D figures use white background\n'
extra = ('[ ] White_Matter comes from human_tumor segmentation, not add_surface or a separate isosurface\n'
         '[ ] White_Matter was defragmented/cleaned before final 3D rendering\n'
         '[ ] White_Matter alpha is 10 and White_Matter is the final Region-table row\n'
         '[ ] Necrosis / Peritumoral Edema / Enhancing Tumor alpha values are 200 / 80 / 100\n'
         '[ ] tumor-region RGB values are the original DSI-assigned RGB values\n'
         '[ ] final tract figures use Assigned cluster colors, not directional colors\n')
assert anchor in text
text = text.replace(anchor, anchor + extra, 1)

old = ('On the same page include direct DSI Studio **tumor + brain-surface 3D views**, preferably\n'
       'axial and coronal, on a white background. The brain surface is required because it provides\n'
       'the spatial anchor for tumor location.')
new = ('On the same page include direct DSI Studio **tumor + cleaned `White_Matter` brain-envelope\n'
       '3D views**, preferably axial and coronal, on a white background. The segmentation-derived\n'
       '`White_Matter` region is the required spatial anchor; do not substitute `add_surface` or a\n'
       'separate isosurface.')
assert old in text
text = text.replace(old, new, 1)

old = 'The tract-tumor section starts with an **all selected tracts + tumor + brain surface** 3D\noverview.'
new = 'The tract-tumor section starts with an **all selected tracts + tumor + cleaned `White_Matter`\nbrain envelope** 3D overview.'
assert old in text
text = text.replace(old, new, 1)

old = '1. **Direct DSI 3D figure with one tract only**, plus tumor compartments and brain surface.'
new = '1. **Direct DSI 3D figure with one tract only**, plus tumor compartments and the cleaned `White_Matter` brain envelope.'
assert old in text
text = text.replace(old, new, 1)

p.write_text(text, encoding='utf-8')
