"""云图查看：读取 AESimFM .h5 文件，画位移/应力/SDV 云图
Usage:
  python scripts/plot_h5.py test/inputs/srx_minimal.h5              # 最后一步
  python scripts/plot_h5.py test/inputs/srx_minimal.h5  --step 1   # 指定步
  python scripts/plot_h5.py test/inputs/srx_minimal.h5  --all      # 所有步对比
"""
import matplotlib
matplotlib.use('Agg')
import h5py, sys, os, argparse
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.tri as tri

# C3D8 / C3D20R hex face triangulation for 2D projection
HEX_FACES = [
    [0,1,2,3], [4,5,6,7],  # bottom, top
    [0,1,5,4], [1,2,6,5],  # front, right
    [2,3,7,6], [3,0,4,7],  # back, left
]

def hex_to_tris(elem_nodes):
    """Decompose a hex element into 2D triangles (projection to XY)."""
    tris = []
    nn = len(elem_nodes)
    if nn == 4:  # quad (CAX)
        tris.append([elem_nodes[0], elem_nodes[2], elem_nodes[1]])
        tris.append([elem_nodes[0], elem_nodes[3], elem_nodes[2]])
    elif nn >= 8:  # hex
        for face in HEX_FACES:
            if max(face) < nn:
                a, b, c, d = [elem_nodes[f] for f in face]
                tris.append([a, c, b])
                tris.append([a, d, c])
    else:
        for j in range(1, nn - 1):
            tris.append([elem_nodes[0], elem_nodes[j], elem_nodes[j + 1]])
    return tris

def load_mesh(h5):
    coords = h5['/mesh/nodes/coordinates'][:]
    conn_raw = h5['/mesh/elements/connectivity'][:]
    conn = []
    for e in range(conn_raw.shape[0]):
        nodes = [int(n) - 1 for n in conn_raw[e] if n > 0]
        if nodes:
            conn.append(nodes)
    return coords, conn

def build_triangulation(coords, conn):
    x, y = coords[:, 0], coords[:, 1]
    all_tris = []
    for elem_nodes in conn:
        all_tris.extend(hex_to_tris(elem_nodes))
    return tri.Triangulation(x, y, np.array(all_tris))

def von_mises(stress_6):
    """von Mises from [SXX,SYY,SZZ,SXY,SXZ,SYZ] (Abaqus order in HDF5)."""
    s11, s22, s33, s12, s13, s23 = stress_6[:6]
    return np.sqrt(0.5 * ((s11-s22)**2 + (s22-s33)**2 + (s33-s11)**2 +
                          6*(s12**2 + s13**2 + s23**2)))

def plot_contour(ax, triang, values, title, cmap='jet'):
    tcf = ax.tricontourf(triang, values, levels=20, cmap=cmap)
    ax.tricontour(triang, values, levels=10, colors='k', linewidths=0.3)
    plt.colorbar(tcf, ax=ax)
    ax.set_aspect('equal')
    ax.set_title(title, fontsize=9)

def get_inc_data(inc_grp, coords, conn, h5):
    """Extract plottable fields from an increment group."""
    triang = build_triangulation(coords, conn)
    results = []

    # Nodal: displacement magnitude
    if 'node' in inc_grp and 'U' in inc_grp['node']:
        u = inc_grp['node/U'][:]
        mag = np.sqrt(u[:,0]**2 + u[:,1]**2 + u[:,2]**2)
        results.append(('U mag', mag, 'jet'))

    # Nodal: temperature
    if 'node' in inc_grp and 'TEMP' in inc_grp['node']:
        results.append(('TEMP', inc_grp['node/TEMP'][:], 'hot'))

    # IP: von Mises stress
    if 'integration_point' in inc_grp and 'S' in inc_grp['integration_point']:
        s_all = inc_grp['integration_point/S'][0, :]
        ne = len(conn)
        nip = s_all.shape[0] // (6 * ne) if ne > 0 else s_all.shape[0] // 6
        # Average IP stress to nodes
        nodal_vm = np.zeros(coords.shape[0])
        node_cnt = np.zeros(coords.shape[0])
        for e, elem_nodes in enumerate(conn):
            for ip in range(nip):
                idx = (e * nip + ip) * 6
                vm = von_mises(s_all[idx:idx+6])
                # Distribute to all element nodes (crude averaging)
                for n in elem_nodes:
                    nodal_vm[n] += vm
                    node_cnt[n] += 1
        mask = node_cnt > 0
        nodal_vm[mask] /= node_cnt[mask]
        results.append(('von Mises (Pa)', nodal_vm, 'coolwarm'))

    # IP: selected SDVs
    if 'integration_point' in inc_grp and 'SDV' in inc_grp['integration_point']:
        sdv_all = inc_grp['integration_point/SDV'][0, :]
        ne = len(conn)
        nstate = sdv_all.shape[0] // ne if ne > 0 else 0
        try:
            sdv_names = [n.decode().strip('\x00').strip() for n in h5['/state/sdv/names'][:]]
        except:
            sdv_names = []
        # Pick interesting SDVs: non-constant, non-zero
        for i in range(min(nstate, 50)):
            vals = sdv_all[i::nstate] if nstate > 0 else np.array([])
            if len(vals) == 0: continue
            nodal_sdv = np.zeros(coords.shape[0])
            cnt_sdv = np.zeros(coords.shape[0])
            for e, elem_nodes in enumerate(conn):
                for n in elem_nodes:
                    nodal_sdv[n] += vals[e]
                    cnt_sdv[n] += 1
            cnt_sdv[cnt_sdv == 0] = 1
            nodal_sdv /= cnt_sdv
            spread = nodal_sdv.max() - nodal_sdv.min()
            if spread > 1e-20:
                name = sdv_names[i] if i < len(sdv_names) else f"SDV{i+1}"
                results.append((name, nodal_sdv, 'plasma'))
    return triang, results

def main():
    parser = argparse.ArgumentParser(description='AESimFM H5 cloud plot')
    parser.add_argument('h5path', help='Path to .h5 file')
    parser.add_argument('--step', type=int, default=0, help='Step to plot (0=last)')
    parser.add_argument('--all', action='store_true', help='Plot all steps')
    args = parser.parse_args()

    if not os.path.exists(args.h5path):
        print(f"File not found: {args.h5path}")
        sys.exit(1)

    h5 = h5py.File(args.h5path, 'r')
    coords, conn = load_mesh(h5)
    print(f"Mesh: {coords.shape[0]} nodes, {len(conn)} elements")

    steps = sorted(h5.get('/steps', {}).keys())

    if args.all:
        step_list = steps
    elif args.step > 0:
        key = f'step_{args.step:04d}'
        step_list = [key] if key in steps else [steps[-1]]
    else:
        step_list = [steps[-1]]

    for step_name in step_list:
        incs = sorted(h5[f'/steps/{step_name}'].keys())
        if not incs: continue
        last_inc = incs[-1]
        inc_grp = h5[f'/steps/{step_name}/{last_inc}']
        triang, results = get_inc_data(inc_grp, coords, conn, h5)

        n = len(results)
        if n == 0:
            print(f"No data for {step_name}/{last_inc}")
            continue

        ncols = min(3, n)
        nrows = (n + ncols - 1) // ncols
        fig, axes = plt.subplots(nrows, ncols, figsize=(4.5*ncols, 3.5*nrows))
        if n == 1:
            axes = [axes]
        else:
            axes = axes.flatten()

        for idx, (title, values, cmap) in enumerate(results):
            plot_contour(axes[idx], triang, values, title, cmap)

        for i in range(n, len(axes)):
            axes[i].set_visible(False)

        basename = os.path.splitext(os.path.basename(args.h5path))[0]
        fig.suptitle(f'{basename} — {step_name}/{last_inc}', fontsize=11)
        plt.tight_layout()
        out = args.h5path.replace('.h5', f'_{step_name}_cloud.png')
        plt.savefig(out, dpi=150, bbox_inches='tight')
        plt.close(fig)
        print(f"  {step_name}/{last_inc}: {n} fields -> {out}")

    h5.close()

if __name__ == '__main__':
    main()
