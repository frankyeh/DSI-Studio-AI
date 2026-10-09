from pathlib import Path

p = Path("DSI_STUDIO_AI_SKILL_BRAIN_TUMOR.md")
s = p.read_text(encoding="utf-8")
marker = "### 7.5 Orientation labels\n"

block = r'''
#### Canonical 2D tract-tumor slice rendering

The final tract-specific structural slice is generated in DSI Studio first and annotated in
Python afterward. The tract is **not converted to a region**. In the ROI/slice view,
`roi_track=1` draws the currently shown tract where its streamlines intersect or run within
the displayed slice. Depending on tract orientation, this may look like discrete colored
dots/short segments (through-plane crossing) or a short colored line (in-plane course).

For final 2D tumor/tract figures use this presentation state explicitly rather than relying
on GUI defaults:

```bash
# Select the structural background and the plane that best shows tumor/tract geometry.
dsi set_slice_by_name "<exact T1w-gd or FLAIR slice name>"
dsi set_roi_view <0=sagittal|1=coronal|2=axial>

# Resolve rows by name immediately before use.
dsi list_region
dsi list_tract

# Center through Tumor Core (or another justified lesion-center region).
dsi move_slice_to_region <Tumor-Core-index>

# Tumor is shown as REGION EDGES, not as an opaque filled mask.
dsi set_param roi_draw_edge 1
dsi set_param roi_edge_width 2

# Show tract intersections/segments on the slice and suppress diffusion-direction glyphs.
dsi set_param roi_track 1
dsi set_param roi_track_count 500000
dsi set_param roi_fiber 0

# Remove working-view clutter from the final report figure.
dsi set_param roi_position 0
dsi set_param roi_ruler 0

# Show only the true tumor compartments in 2D; do not show White_Matter or the Tumor Core copy.
dsi show_only_regions "<Necrosis-index>&<Peritumoral-Edema-index>&<Enhancing-Tumor-index>"

# Show one tract only on a tract-specific page. Keep its Assigned/cluster color.
dsi set_param tract_color_style 1
dsi show_only_tracts "<tract-index>"

# Save the full-resolution structural/tumor/tract slice.
dsi save_roi_screen "<tract>_<modality>_<plane>.png"
```

`roi_draw_edge=1` is **mandatory for final 2D tumor figures**. It keeps the structural MRI
visible while outlining Necrosis, Peritumoral Edema, and Enhancing Tumor. Do not show the
segmentation-derived `White_Matter` envelope in 2D; that envelope is for the 3D figures.

`roi_track=1` and `roi_fiber=0` are different controls: the first shows the selected tract
on the structural slice, while the second hides local diffusion fiber-direction glyphs.
Do not turn `roi_fiber` on merely to make the tract visible.

After saving, open the image and verify that (1) the tumor edges are visible, (2) the tract
is visible at the lesion level, and (3) the chosen plane demonstrates the relationship. If
the tract appears only as a few dots because it crosses the plane orthogonally, choose a
more informative plane through the same lesion center when that better demonstrates its
course.

#### Python tract callout: leader line + tract name

The leader line and tract-name box used in the accepted report are **post-processing
annotations**, not DSI Studio tract rendering. They are allowed because they do not alter
the anatomical pixels. The annotation endpoint must be placed on the visible tract after
opening and inspecting the saved slice; do not guess its location from anatomy alone.

Use a helper like this after `save_roi_screen`:

```python
from PIL import Image, ImageDraw, ImageFont
import math


def _font(size):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf", size)
    except Exception:
        return ImageFont.load_default()


def annotate_tract_slice(src, dst, tract_name, tract_xy, label_xy,
                         left="R", right="L", top="A", bottom="P",
                         note="Radiological convention"):
    """Add orientation and a leader-line tract label without altering source anatomy.

    tract_xy: (x,y) pixel location on the visible tract in the ORIGINAL DSI image.
    label_xy: (x,y) desired label-box center in the ORIGINAL DSI image coordinate frame.
    """
    im = Image.open(src).convert("RGB")
    size = max(im.size)//16
    margin = size*3//2
    out = Image.new("RGB", (im.width+2*margin, im.height+2*margin), "black")
    out.paste(im, (margin, margin))
    d = ImageDraw.Draw(out)
    W,H = out.size

    f_orient = _font(size)
    for txt,xy in ((top,(W/2,margin/2)),
                   (bottom,(W/2,H-margin/2)),
                   (left,(margin/2,H/2)),
                   (right,(W-margin/2,H/2))):
        d.text(xy, txt, fill="white", font=f_orient, anchor="mm")
    if note:
        d.text((margin//4,H-margin//4), note, fill="white",
               font=_font(max(12,size//2)), anchor="ld")

    tx,ty = tract_xy[0]+margin, tract_xy[1]+margin
    lx,ly = label_xy[0]+margin, label_xy[1]+margin
    f_label = _font(max(16,size*3//4))
    bbox = d.textbbox((lx,ly), tract_name, font=f_label, anchor="mm")
    pad_x,pad_y = 10,6
    box = (bbox[0]-pad_x,bbox[1]-pad_y,bbox[2]+pad_x,bbox[3]+pad_y)

    candidates=[((box[0],ly),(tx-box[0])**2+(ty-ly)**2),
                ((box[2],ly),(tx-box[2])**2+(ty-ly)**2),
                ((lx,box[1]),(tx-lx)**2+(ty-box[1])**2),
                ((lx,box[3]),(tx-lx)**2+(ty-box[3])**2)]
    (sx,sy),_ = min(candidates,key=lambda x:x[1])
    width=max(2,size//20)
    d.line([(sx,sy),(tx,ty)], fill="white", width=width)

    vx,vy=tx-sx,ty-sy
    length=max(1.0,math.hypot(vx,vy)); ux,uy=vx/length,vy/length
    px,py=-uy,ux
    arrow=max(8,size//5)
    wing=max(5,size//9)
    d.polygon([(tx,ty),
               (tx-arrow*ux+wing*px,ty-arrow*uy+wing*py),
               (tx-arrow*ux-wing*px,ty-arrow*uy-wing*py)], fill="white")

    d.rounded_rectangle(box, radius=max(4,size//8), fill="black",
                        outline="white", width=max(2,size//24))
    d.text((lx,ly), tract_name, fill="white", font=f_label, anchor="mm")
    out.save(dst)
```

For an axial radiological image use `left="R", right="L", top="A", bottom="P"`. The
`tract_xy` point must be selected from the actual DSI-exported tract dots/segments. Put the
label box in empty space and keep the leader line from obscuring the tumor or tract.

'''

if "#### Canonical 2D tract-tumor slice rendering" not in s:
    if marker not in s:
        raise SystemExit("orientation marker not found")
    s = s.replace(marker, block + marker, 1)

old = '''dsi set_params "roi_draw_edge=1&roi_edge_width=2"\ndsi set_param roi_fiber 0\ndsi list_region'''
new = '''dsi set_params "roi_draw_edge=1&roi_edge_width=2"\ndsi set_param roi_track 1\ndsi set_param roi_track_count 500000\ndsi set_param roi_fiber 0\ndsi set_param roi_position 0\ndsi set_param roi_ruler 0\ndsi list_region'''
if old in s:
    s = s.replace(old, new, 1)

anchor = "[ ] each tract page has a structural slice showing tumor/tract relative position\n"
add = '''[ ] every final 2D tumor slice has `roi_draw_edge=1` so tumor compartments are shown as edges\n[ ] tract-specific 2D slices have `roi_track=1` and `roi_fiber=0`\n[ ] each tract-specific 2D slice has a leader line and tract-name label placed on the visible tract\n'''
if add.strip() not in s and anchor in s:
    s = s.replace(anchor, anchor + add, 1)

p.write_text(s.rstrip() + "\n", encoding="utf-8")
