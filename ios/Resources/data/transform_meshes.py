"""
Space/SF Theme Mesh Transformer
- Cube meshes (46 lines) → asteroid-shaped irregular rocks
- Large sphere mesh → planet with bumpy surface
"""

import os
import shutil
import math
import random

MESH_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "meshes")


def backup(path):
    bak = path + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)


def parse_obj(path):
    vertices, texcoords, normals, faces, header = [], [], [], [], []
    with open(path, "r") as f:
        for line in f:
            s = line.strip()
            if s.startswith("v "):
                parts = s.split()
                vertices.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif s.startswith("vt "):
                parts = s.split()
                texcoords.append([float(parts[1]), float(parts[2])])
            elif s.startswith("vn "):
                parts = s.split()
                normals.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif s.startswith("f "):
                faces.append(s)
            elif not s.startswith("v") and not s.startswith("f"):
                header.append(s)
    return header, vertices, texcoords, normals, faces


def write_obj(path, header, vertices, texcoords, normals, faces):
    with open(path, "w") as f:
        for h in header:
            f.write(h + "\n")
        for v in vertices:
            f.write(f"v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f}\n")
        for vt in texcoords:
            f.write(f"vt {vt[0]:.4f} {vt[1]:.4f}\n")
        for vn in normals:
            f.write(f"vn {vn[0]:.4f} {vn[1]:.4f} {vn[2]:.4f}\n")
        for face in faces:
            f.write(face + "\n")


def noise3d(x, y, z, seed=0):
    """Simple deterministic pseudo-random noise based on position."""
    h = hash((round(x * 1000), round(y * 1000), round(z * 1000), seed))
    return ((h % 10000) / 10000.0) * 2.0 - 1.0


def smooth_noise(x, y, z, seed=0, octaves=3, persistence=0.5):
    """Multi-octave noise for smoother displacement."""
    total = 0.0
    amplitude = 1.0
    frequency = 1.0
    max_val = 0.0
    for i in range(octaves):
        total += noise3d(x * frequency, y * frequency, z * frequency, seed + i) * amplitude
        max_val += amplitude
        amplitude *= persistence
        frequency *= 2.0
    return total / max_val


def make_asteroid_from_cube(vertices, seed=0):
    """Deform cube vertices into an irregular asteroid shape."""
    rng = random.Random(seed)

    # First compute center
    cx = sum(v[0] for v in vertices) / len(vertices)
    cy = sum(v[1] for v in vertices) / len(vertices)
    cz = sum(v[2] for v in vertices) / len(vertices)

    new_verts = []
    for v in vertices:
        # Direction from center
        dx, dy, dz = v[0] - cx, v[1] - cy, v[2] - cz
        dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        if dist < 0.0001:
            new_verts.append(v[:])
            continue

        # Normalize direction
        nx, ny, nz = dx/dist, dy/dist, dz/dist

        # Displacement: smooth noise along the direction vector
        disp = smooth_noise(nx, ny, nz, seed=seed, octaves=3, persistence=0.6)

        # Scale displacement: 15-35% of distance
        scale = 0.22 + disp * 0.18

        new_dist = dist * (1.0 + scale)
        new_verts.append([
            cx + nx * new_dist,
            cy + ny * new_dist,
            cz + nz * new_dist
        ])

    return new_verts


def recompute_face_normals(vertices, faces):
    """Recompute per-vertex normals from face geometry for the simple cube case."""
    # For cube (8 verts, 6 quad faces), recompute normals
    # Parse face indices
    face_verts = []
    for face in faces:
        parts = face.split()[1:]
        verts_in_face = []
        for p in parts:
            vi = int(p.split("/")[0]) - 1  # 0-indexed
            verts_in_face.append(vi)
        face_verts.append(verts_in_face)

    # Compute per-face normals
    face_normals = []
    for fv in face_verts:
        v0 = vertices[fv[0]]
        v1 = vertices[fv[1]]
        v2 = vertices[fv[2]]
        # Edge vectors
        e1 = [v1[i] - v0[i] for i in range(3)]
        e2 = [v2[i] - v0[i] for i in range(3)]
        # Cross product
        n = [
            e1[1]*e2[2] - e1[2]*e2[1],
            e1[2]*e2[0] - e1[0]*e2[2],
            e1[0]*e2[1] - e1[1]*e2[0]
        ]
        length = math.sqrt(sum(x*x for x in n))
        if length > 0:
            n = [x/length for x in n]
        face_normals.append(n)

    return face_normals


def deform_sphere_mesh(vertices, seed=42, strength=0.06):
    """Add subtle bumps to sphere mesh for planet surface."""
    rng = random.Random(seed)
    new_verts = []
    for v in vertices:
        dist = math.sqrt(v[0]**2 + v[1]**2 + v[2]**2)
        if dist < 0.0001:
            new_verts.append(v[:])
            continue
        nx, ny, nz = v[0]/dist, v[1]/dist, v[2]/dist
        # Medium-frequency noise for planet terrain
        disp = smooth_noise(nx*2, ny*2, nz*2, seed=seed, octaves=4, persistence=0.55)
        new_dist = dist * (1.0 + disp * strength)
        new_verts.append([nx * new_dist, ny * new_dist, nz * new_dist])
    return new_verts


def transform_cube_meshes():
    """Transform all 46-line cube OBJ files into asteroid shapes."""
    count = 0
    for fname in sorted(os.listdir(MESH_DIR)):
        if not fname.endswith(".obj"):
            continue
        path = os.path.join(MESH_DIR, fname)

        # Quick check: count lines
        with open(path, "r") as f:
            lines = f.readlines()

        # Cube meshes have 8 vertices and 6 quad faces (46 lines total)
        if len(lines) != 46:
            continue

        backup(path)
        header, vertices, texcoords, normals, faces = parse_obj(path)

        if len(vertices) != 8:
            continue  # not a standard cube

        # Generate unique seed from filename
        seed = hash(fname) % 9999

        # Deform into asteroid
        new_verts = make_asteroid_from_cube(vertices, seed=seed)

        # Recompute normals from new geometry
        face_normals = recompute_face_normals(new_verts, faces)

        # Replace normals
        new_normals = face_normals  # one per face, but we need per-vertex
        # Use face normals directly (6 normals for 6 faces)
        if len(face_normals) == len(normals):
            normals = face_normals

        write_obj(path, header, new_verts, texcoords, normals, faces)
        count += 1
        print(f"  Asteroid: {fname}")

    return count


def transform_sphere_meshes():
    """Add planet-like bumps to sphere meshes."""
    count = 0
    sphere_sizes = [1482, 15655]  # line counts for sphere meshes

    for fname in sorted(os.listdir(MESH_DIR)):
        if not fname.endswith(".obj"):
            continue
        path = os.path.join(MESH_DIR, fname)

        with open(path, "r") as f:
            lines = f.readlines()

        if len(lines) not in sphere_sizes:
            continue

        # Check if it's actually a sphere (look for mtllib sphere.mtl)
        content = "".join(lines[:5])
        if "sphere" not in content.lower():
            continue

        backup(path)
        header, vertices, texcoords, normals, faces = parse_obj(path)

        seed = hash(fname) % 9999
        # Subtle deformation for planet look
        new_verts = deform_sphere_mesh(vertices, seed=seed, strength=0.05)

        write_obj(path, header, new_verts, texcoords, normals, faces)
        count += 1
        print(f"  Planet: {fname}")

    return count


if __name__ == "__main__":
    print("=== Space/SF Theme Mesh Transformation ===")

    print("\n[1/2] Cube → Asteroid meshes:")
    n_cubes = transform_cube_meshes()
    print(f"  {n_cubes} cube meshes transformed")

    print("\n[2/2] Sphere → Planet meshes:")
    n_spheres = transform_sphere_meshes()
    print(f"  {n_spheres} sphere meshes transformed")

    print("\nDone! Backups saved as *.bak files.")
