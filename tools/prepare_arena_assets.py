"""Extract only the CC0 modules used by the authored arenas. Archives stay in build/.

Downloads: Quaternius' public itch.io Standard download and Kenney's own OGA post.
No paid Source assets. Preserve original files and licenses, record SHA256 provenance.
"""
import hashlib
import json
import struct
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
SCI = '''WallAstra_Straight WallAstra_Straight_Window WallWindow_Straight
Column_Round Column_MetalSupport Door_Frame_A Platform_Metal Platform_DarkPlates
Prop_Computer Prop_AccessPoint Prop_Crate3 Prop_Crate4 Prop_Barrel_Large
Prop_Vent_Big Prop_Light_Wide Prop_Rail_4 Prop_Cable_1'''.split()
PIRATE = '''barrel boat-row-large chest crate crate-bottles flag-high-pennant
mast-ropes palm-detailed-bend palm-detailed-straight rocks-a rocks-b
ship-large ship-medium ship-small structure-platform-dock structure-fence
tower-complete-large cannon-mobile'''.split()


def extract(archive, folder, names, ext, source):
    target = ROOT / 'assets/third_party' / folder
    target.mkdir(parents=True, exist_ok=True)
    manifest = {}
    with ZipFile(ROOT / 'build/asset_downloads' / archive) as z:
        entries = z.namelist()
        selected = set()
        for name in names:
            path = next(n for n in entries if n.endswith('/' + name + ext))
            selected.add(path)
            if ext in ('.gltf', '.glb'):
                raw = z.read(path)
                doc = json.loads(raw if ext == '.gltf' else raw[20:20 + struct.unpack_from('<I', raw, 12)[0]])
                for kind in ('images', 'buffers'):
                    for item in doc.get(kind, []):
                        uri = item.get('uri', '')
                        if uri and not uri.startswith('data:'):
                            relative = str(Path(path).parent / uri).replace('\\', '/')
                            selected.add(relative if relative in entries else next(n for n in entries if n.endswith('/' + uri)))
        selected.update(n for n in entries if Path(n).name in ('License.txt', 'License_Standard.txt'))
        for n in sorted(selected):
            content = z.read(n)
            out = target / ('Textures/' + Path(n).name if folder == 'kenney_pirate' and '/Textures/' in n else Path(n).name)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_bytes(content)
            manifest[out.relative_to(target).as_posix()] = hashlib.sha256(content).hexdigest()
    (target / 'source.json').write_text(json.dumps({'source': source, 'license': 'CC0-1.0', 'files_sha256': manifest}, indent=2) + '\n')
    print(folder, len(manifest), 'files')


if __name__ == '__main__':
    extract('scifi_standard.zip', 'quaternius_scifi', SCI, '.gltf', 'https://quaternius.itch.io/modular-sci-fi-megakit')
    extract('kenney_pirate.zip', 'kenney_pirate', PIRATE, '.glb', 'https://opengameart.org/content/pirate-kit')
