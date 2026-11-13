"""Bake CC0 rigid weapon joints into lightweight articulated GLBs, preserving source files.

Run with Python + numpy. No Blender or runtime mesh conversion required.
"""
from pathlib import Path
import json
import struct
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'assets/third_party/pichuliru_guns'
DTYPES = {5121: 'u1', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
SIZES = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def convert(source):
    raw = source.read_bytes()
    json_len = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + json_len])
    binary = raw[28 + json_len:]

    def read(idx):
        a = doc['accessors'][idx]
        v = doc['bufferViews'][a['bufferView']]
        dtype = np.dtype(DTYPES[a['componentType']])
        width = SIZES[a['type']]
        return np.ndarray((a['count'], width), dtype=dtype, buffer=binary,
                          offset=v.get('byteOffset', 0) + a.get('byteOffset', 0),
                          strides=(v.get('byteStride', width * dtype.itemsize), dtype.itemsize)).copy()

    joints = [doc['nodes'][i]['name'] for i in doc['skins'][0]['joints']]
    groups = {}
    for primitive in doc['meshes'][0]['primitives']:
        attrs = {k: read(v) for k, v in primitive['attributes'].items()}
        indices = read(primitive['indices']).reshape(-1, 3)
        for tri in indices:
            bones = attrs['JOINTS_0'][tri]
            weights = attrs['WEIGHTS_0'][tri]
            names = [joints[int(b[np.argmax(w)])] for b, w in zip(bones, weights)]
            bone = max(set(names), key=names.count)
            part = bone if bone in ('Magazine', 'Bolt', 'Slide') else 'Body'
            key = (part, primitive['material'])
            groups.setdefault(key, []).extend(tri.tolist())

    out = {'asset': {'version': '2.0', 'generator': 'Sakura Blitz rigid-joint preparation'},
           'scene': 0, 'scenes': [{'nodes': []}], 'nodes': [], 'meshes': [],
           'materials': doc['materials'], 'accessors': [], 'bufferViews': [], 'buffers': []}
    blob = bytearray()

    def accessor(data, typ, component=5126):
        while len(blob) % 4:
            blob.append(0)
        start = len(blob)
        data = np.asarray(data, dtype=DTYPES[component])
        blob.extend(data.tobytes())
        view = len(out['bufferViews'])
        out['bufferViews'].append({'buffer': 0, 'byteOffset': start, 'byteLength': data.nbytes})
        index = len(out['accessors'])
        a = {'bufferView': view, 'componentType': component, 'count': len(data), 'type': typ}
        if typ == 'VEC3':
            a.update(min=data.min(axis=0).tolist(), max=data.max(axis=0).tolist())
        out['accessors'].append(a)
        return index

    # Accumulate individual source primitives: indices are local to each material surface.
    for (part, material), ids in groups.items():
        prim = next(p for p in doc['meshes'][0]['primitives'] if p['material'] == material)
        vertices = read(prim['attributes']['POSITION'])[ids]
        normals = read(prim['attributes']['NORMAL'])[ids]
        # Vertex positions remain in common weapon space. Node pivot is zero; existing
        # reload translation and bolt animation can move these independently.
        uv = np.stack((-vertices[:, 2] * 2.7, vertices[:, 1] * 2.7), axis=1)
        attributes = {'POSITION': accessor(vertices, 'VEC3'), 'NORMAL': accessor(normals, 'VEC3'),
                      'TEXCOORD_0': accessor(uv, 'VEC2')}
        mesh_index = len(out['meshes'])
        out['meshes'].append({'primitives': [{'attributes': attributes, 'material': material}]})
        node_index = len(out['nodes'])
        out['nodes'].append({'name': part + '__' + doc['materials'][material]['name'], 'mesh': mesh_index})
        out['scenes'][0]['nodes'].append(node_index)
    while len(blob) % 4:
        blob.append(0)
    out['buffers'] = [{'byteLength': len(blob)}]
    data = json.dumps(out, separators=(',', ':')).encode()
    data += b' ' * (-len(data) % 4)
    total = 12 + 8 + len(data) + 8 + len(blob)
    result = struct.pack('<III', 0x46546C67, 2, total)
    result += struct.pack('<II', len(data), 0x4E4F534A) + data
    result += struct.pack('<II', len(blob), 0x004E4942) + blob
    target = ROOT / 'prepared' / source.name
    target.parent.mkdir(exist_ok=True)
    target.write_bytes(result)
    print(source.name, len(groups), 'surfaces', len(result), 'bytes')


if __name__ == '__main__':
    for source in ROOT.glob('*.glb'):
        convert(source)
