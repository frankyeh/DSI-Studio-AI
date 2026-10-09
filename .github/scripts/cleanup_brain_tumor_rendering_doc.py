from pathlib import Path
import sys
p=Path(sys.argv[1])
text=p.read_text(encoding='utf-8')
repl={
'missing surfaces, corrupted 3D views':'missing White_Matter brain envelopes, corrupted 3D views',
'direct DSI 3D tumor + brain-surface view':'direct DSI 3D tumor + cleaned `White_Matter` brain-envelope view',
'cropping unused outer margin when no anatomy, surface, tract, or orientation context is removed.':'cropping unused outer margin when no anatomy, brain-envelope, tract, or orientation context is removed.'
}
for old,new in repl.items():
    if old not in text:
        raise SystemExit(f'missing expected text: {old}')
    text=text.replace(old,new)
p.write_text(text,encoding='utf-8')
