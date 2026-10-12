"""Exercise the actual embedded Linux sampler with an isolated sysfs/procfs fixture."""
import json
import pathlib
import tempfile

source = pathlib.Path('Core/Metrics/GPUCollector.swift').read_text().split('static let python = #"""', 1)[1].rsplit('"""#', 1)[0]
module = {'__name__': 'gpu_test'}
exec(source, module)
with tempfile.TemporaryDirectory() as root:
    root = pathlib.Path(root)
    sysfs = root / 'sys'
    procfs = root / 'proc'
    stats = sysfs / 'devices/platform/axi/1002000000.v3d/gpu_stats'
    stats.parent.mkdir(parents=True)
    stats.write_text('queue timestamp jobs runtime\nrender 1000000000 4 100000000\nbin 1000000000 3 50000000\n')
    before = module['snapshot'](str(sysfs), str(procfs))
    stats.write_text('queue timestamp jobs runtime\nrender 2000000000 6 600000000\nbin 2000000000 4 250000000\n')
    after = module['snapshot'](str(sysfs), str(procfs))
    assert module['utilization'](before, after) == 50
    assert module['utilization'](after, after) is None
    assert module['utilization'](after, before) is None
    stats.unlink()
    paths = [procfs / f'{pid}/fdinfo/4' for pid in (10, 11)]
    for path in paths:
        path.parent.mkdir(parents=True)
        path.write_text('drm-driver: i915\ndrm-pdev: 0000:00:02.0\ndrm-client-id: 42\ndrm-engine-render: 100000000 ns\ndrm-engine-capacity-render: 2\n')
    before = module['snapshot'](str(sysfs), str(procfs))
    assert len(before['engines']) == 1, 'shared descriptors count once'
    for path in paths:
        path.write_text(path.read_text().replace('100000000 ns', '500000000 ns'))
    after = module['snapshot'](str(sysfs), str(procfs))
    for value in before['engines'].values(): value[0] = 1000000000
    for value in after['engines'].values(): value[0] = 2000000000
    assert module['utilization'](before, after) == 20, 'capacity-normalized integrated GPU reading'
    assert module['utilization']({'engines': {}}, after) is None
    for value in after['engines'].values(): value[1] = 99999999999
    assert module['utilization'](before, after) == 100
    assert module['utilization']({'engines': {}}, {'engines': {}}) is None
print('GPU checks passed: V3D runtime deltas, integrated DRM counters, duplicate FDs, capacities, counter resets, missing sensors and bounds.')

# Separate integrated/external devices stay separate; clients on one engine add up.
before = {'engines': {
    'drm|integrated|i915|render|1': [1000, 0, 1],
    'drm|external|amdgpu|render|1': [1000, 0, 1],
    'drm|external|amdgpu|render|2': [1000, 0, 1]}}
after = {'engines': {
    'drm|integrated|i915|render|1': [2000, 300, 1],
    'drm|external|amdgpu|render|1': [2000, 400, 1],
    'drm|external|amdgpu|render|2': [2000, 200, 1]}}
assert module['utilization'](before, after) == 60
assert module['utilization'](before, {'engines': {k: [2000, 0, 1] for k in before['engines']}}) == 0
print('Multiple GPU checks passed: separate devices, combined clients, idle counters.')

# Execute the production shell gates with GPU collection disabled.
import subprocess
ssh_source = pathlib.Path('Core/Connections/SSHService.swift').read_text()
capture = next(line.strip() for line in ssh_source.splitlines() if 'then gpu_sample capture' in line)
start = ssh_source.index('    if [ "$collect_gpu" = 1 ]; then\n    gpu_readings=')
end = ssh_source.index('\n    if [ -n "$temp_dir" ]; then', start)
gpu_commands = ssh_source[start:end]
script = 'collect_gpu=0\ngpu_sample() { echo UNEXPECTED_GPU; }\n' + capture + '\n' + gpu_commands
result = subprocess.run(['sh', '-c', script], capture_output=True, text=True, check=True)
assert result.stdout == '' and result.stderr == '', 'disabled GPU collection executes no GPU sampling or output'
print('GPU opt-out shell checks passed.')
