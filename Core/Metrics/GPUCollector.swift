import Foundation

/// Linux's V3D sysfs counters and standard DRM fdinfo engine counters.
/// Counts engine time, never infers utilization from GPU clock frequency.
enum GPUCollector {
    static let shellFunction = "gpu_sample() {\npython3 - \"$@\" <<'GPU_PY'\n" + python + "\nGPU_PY\n}\n"
    static let python = #"""
import glob, json, os, sys, time

def snapshot(sys_root='/sys', proc_root='/proc'):
    result = {'time': time.monotonic_ns(), 'engines': {}}
    # Resolve sysfs links so card and platform aliases do not double-count V3D.
    paths = set()
    for pattern in ('class/drm/card*/device/gpu_stats', 'bus/platform/drivers/v3d/*/gpu_stats',
                    'devices/platform/*.v3d/gpu_stats', 'devices/platform/*/*.v3d/gpu_stats',
                    'devices/platform/*/*/*.v3d/gpu_stats'):
        paths.update(os.path.realpath(p) for p in glob.glob(sys_root + '/' + pattern))
    for path in paths:
        try:
            with open(path) as f:
                for line in f:
                    parts = line.split()
                    if len(parts) != 4 or not all(v.isdigit() for v in parts[1:]):
                        continue
                    queue, stamp, jobs, runtime = parts
                    if queue not in ('bin', 'render', 'tfu', 'csd', 'cache_clean'):
                        continue
                    result['engines']['v3d|' + path + '|' + queue] = [int(stamp), int(runtime), 1]
        except (OSError, ValueError):
            pass
    # Standard DRM counters also cover integrated Intel and supported discrete GPUs.
    # fdinfo is restricted by process ownership; these are visible-client readings.
    clients = {}
    files = glob.glob(proc_root + '/[0-9]*/fdinfo/[0-9]*')
    if len(files) <= 8192:
        for path in files:
            try:
                with open(path) as f:
                    text = f.read(65536)
                if 'drm-driver:' not in text:
                    continue
                fields = dict(line.split(':', 1) for line in text.splitlines() if ':' in line)
                fields = {key.strip(): value.strip() for key, value in fields.items()}
                driver = fields.get('drm-driver', '')
                client = fields.get('drm-client-id', '')
                if not client.isdigit():
                    continue
                device = fields.get('drm-pdev', driver)
                for key, value in fields.items():
                    if not key.startswith('drm-engine-') or key.startswith('drm-engine-capacity-'):
                        continue
                    parts = value.split()
                    if len(parts) != 2 or not parts[0].isdigit() or parts[1] != 'ns':
                        continue
                    engine = key[len('drm-engine-'):]
                    capacity = fields.get('drm-engine-capacity-' + engine, '1')
                    if not capacity.isdigit() or int(capacity) < 1:
                        continue
                    identity = 'drm|' + device + '|' + driver + '|' + engine + '|' + client
                    # A shared file descriptor may appear in several processes.
                    counter = [result['time'], int(parts[0]), int(capacity)]
                    if identity not in clients or counter[1] > clients[identity][1]:
                        clients[identity] = counter
            except (OSError, ValueError):
                continue
    result['engines'].update(clients)
    return result

def utilization(before, after):
    totals = {}
    for identity, current in after.get('engines', {}).items():
        previous = before.get('engines', {}).get(identity)
        if previous is None:
            continue
        elapsed = current[0] - previous[0]
        busy = current[1] - previous[1]
        if elapsed <= 0 or busy < 0 or current[2] != previous[2]:
            continue
        key = identity.rsplit('|', 1)[0] if identity.startswith('drm|') else identity
        totals[key] = totals.get(key, 0) + 100.0 * busy / elapsed / current[2]
    return min(100.0, max(totals.values())) if totals else None

if __name__ == '__main__':
    try:
        mode, path = sys.argv[1:3]
        reading = snapshot()
        if mode == 'capture':
            with open(path, 'w') as f:
                json.dump(reading, f)
        else:
            with open(path) as f:
                value = utilization(json.load(f), reading)
            if value is not None:
                print('%.2f' % value)
    except (OSError, ValueError, KeyError, TypeError):
        pass
"""#
}
