pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// CPU, RAM, GPU, disk, network and temperature, sampled only while `active` (the dashboard sets it).
// /proc and /sys go through FileView. Disk usage needs df; NVIDIA load needs nvidia-smi, which runs only
// while the GPU is awake, since querying a sleeping GPU wakes it and costs battery.
Singleton {
    id: root

    property bool active: false
    readonly property real cpu: internal.cpu
    readonly property real memUsed: internal.memUsed
    readonly property real memTotal: internal.memTotal
    readonly property real mem: root.memTotal > 0 ? root.memUsed / root.memTotal : 0
    readonly property real diskUsed: internal.diskUsed
    readonly property real diskTotal: internal.diskTotal
    readonly property real disk: root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0
    // Bytes per second, summed over every interface except loopback.
    readonly property real netDown: internal.netDown
    readonly property real netUp: internal.netUp
    // °C; -1 when no CPU sensor was found.
    readonly property real temperature: internal.temperature
    // "none" (no NVIDIA GPU), "sleeping" (runtime-suspended, not queried) or "active".
    readonly property string gpuState: internal.gpuPath === "" ? "none" : internal.gpuAwake ? "active" : "sleeping"
    readonly property real gpu: internal.gpu
    // Disk usage changes slowly, so df runs on every Nth sample only.
    readonly property int diskEvery: 10
    // The last `historyLength` samples, oldest first, for the System tab's sparklines (0-1, and bytes/s).
    readonly property int historyLength: 60
    readonly property string csv: "--format=csv,noheader,nounits"
    readonly property list<real> cpuHistory: internal.cpuHistory
    readonly property list<real> memHistory: internal.memHistory
    readonly property list<real> downHistory: internal.downHistory
    readonly property list<real> upHistory: internal.upHistory
    // Mounted filesystems worth showing: [{ mount, used, size }], root first (home too when separate).
    readonly property var disks: internal.disks
    // [{ label, celsius }] from hwmon: the CPU, each NVMe drive, Wi‑Fi when it reports one; plus the GPU
    // while it's awake.
    readonly property var sensors: root.sensorList(internal.sensorReadings, internal.gpuTemperature)
    readonly property string kernel: kernelFile.text().trim()
    // Seconds since boot, read on every sample.
    readonly property real uptime: internal.uptime
    // "Hyprland · wayland"
    readonly property string session: `${Quickshell.env("XDG_CURRENT_DESKTOP")} · ${root.sessionType}`
    readonly property string sessionType: Quickshell.env("XDG_SESSION_TYPE") ?? ""

    function setActive(active: bool): void {
        root.active = active;
    }

    function sample(): void {
        cpuFile.reload();
        memFile.reload();
        netFile.reload();
        uptimeFile.reload();
        for (let i = 0; i < sensorFiles.count; i++)
            (sensorFiles.objectAt(i) as FileView)?.reload();
        if (internal.tempPath !== "")
            tempFile.reload();
        if (internal.gpuPath !== "")
            gpuPower.reload();
        if (internal.samples % root.diskEvery === 0)
            disk.exec(["df", "--block-size=1", "--output=target,used,size", "/", "/home"]);
        internal.samples++;
        root.record();
    }

    // Appends the latest readings to the histories, dropping the oldest past historyLength.
    function record(): void {
        const push = (list, value) => [...list, value].slice(-root.historyLength);
        internal.cpuHistory = push(internal.cpuHistory, internal.cpu);
        internal.memHistory = push(internal.memHistory, root.mem);
        internal.downHistory = push(internal.downHistory, internal.netDown);
        internal.upHistory = push(internal.upHistory, internal.netUp);
    }

    function sensorList(readings: var, gpu: real): var {
        const list = internal.sensorPaths.map(s => ({
                    label: s.label,
                    celsius: readings[s.path] ?? -1
                })).filter(s => s.celsius >= 0);
        if (gpu >= 0)
            list.splice(1, 0, {
                label: "GPU",
                celsius: gpu
            });
        return list;
    }

    // df rows: "<mount> <used> <size>"; the same filesystem twice (home on root) shows once.
    function parseDisks(text: string): void {
        const rows = text.trim().split("\n").slice(1).map(l => l.trim().split(/\s+/));
        const disks = rows.map(r => ({
                    mount: r[0],
                    used: Number(r[1]),
                    size: Number(r[2])
                }));
        internal.disks = disks.filter((d, i) => disks.findIndex(o => o.used === d.used && o.size === d.size) === i);
        const root_ = internal.disks.find(d => d.mount === "/");
        internal.diskUsed = root_?.used ?? 0;
        internal.diskTotal = root_?.size ?? 0;
    }

    function parseCpu(text: string): void {
        const fields = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const total = fields.reduce((a, b) => a + b, 0);
        const idle = fields[3] + fields[4];
        if (internal.cpuTotal > 0 && total > internal.cpuTotal)
            internal.cpu = 1 - (idle - internal.cpuIdle) / (total - internal.cpuTotal);
        internal.cpuTotal = total;
        internal.cpuIdle = idle;
    }

    function parseMem(text: string): void {
        const kib = key => Number((text.match(new RegExp(`^${key}:\\s+(\\d+)`, "m")) ?? [0, 0])[1]) * 1024;
        internal.memTotal = kib("MemTotal");
        internal.memUsed = internal.memTotal - kib("MemAvailable");
    }

    function parseNet(text: string): void {
        const rows = text.trim().split("\n").slice(2).map(l => l.trim().split(/[:\s]+/));
        const live = rows.filter(r => r[0] !== "lo");
        const rx = live.reduce((sum, r) => sum + Number(r[1]), 0);
        const tx = live.reduce((sum, r) => sum + Number(r[9]), 0);
        const now = Date.now();
        if (internal.netTime > 0) {
            const seconds = (now - internal.netTime) / 1000;
            internal.netDown = Math.max(0, (rx - internal.rx) / seconds);
            internal.netUp = Math.max(0, (tx - internal.tx) / seconds);
        }
        Object.assign(internal, {
            rx: rx,
            tx: tx,
            netTime: now
        });
    }

    // Prefers the CPU package sensor; acpitz is a last resort. The sensors list adds each NVMe drive and
    // the Wi‑Fi card when they have a hwmon.
    function parsePaths(text: string): void {
        const lines = text.trim().split("\n").map(l => l.split(" "));
        const hwmon = name => lines.find(l => l[0] === "hwmon" && l[2] === name)?.[1];
        const sensor = ["coretemp", "k10temp", "zenpower", "acpitz"].map(hwmon).find(path => path !== undefined);
        internal.tempPath = sensor ?? "";
        const nvme = lines.filter(l => l[0] === "hwmon" && l[2] === "nvme").map((l, i, all) => ({
                    label: all.length > 1 ? `NVMe ${i + 1}` : "NVMe",
                    path: l[1]
                }));
        const wifi = lines.filter(l => l[0] === "hwmon" && /^iwlwifi|^ath|^mt7/.test(l[2])).map(l => ({
                    label: "Wi‑Fi",
                    path: l[1]
                }));
        const cpu = sensor ? [
            {
                label: "CPU",
                path: sensor
            }
        ] : [];
        internal.sensorPaths = [...cpu, ...nvme, ...wifi];
        internal.gpuPath = lines.find(l => l[0] === "gpu")?.[1] ?? "";
    }

    function status(): string {
        const pct = v => `${Math.round(v * 100)}%`;
        const gpu = root.gpuState === "active" ? pct(root.gpu) : root.gpuState;
        const net = `↓${Math.round(root.netDown / 1024)} ↑${Math.round(root.netUp / 1024)} KiB/s`;
        const load = `cpu ${pct(root.cpu)}, ram ${pct(root.mem)}, gpu ${gpu}, disk ${pct(root.disk)}`;
        return `${root.active ? "sampling" : "idle"}: ${load}, ${net}, ${root.temperature}°C`;
    }

    onActiveChanged: {
        if (root.active && !internal.discovered)
            discovery.running = true;
    }

    QtObject {
        id: internal

        property bool discovered: false
        property string tempPath: ""
        property string gpuPath: ""
        property bool gpuAwake: false
        property int samples: 0
        property real cpu: 0
        property real cpuTotal: 0
        property real cpuIdle: 0
        property real memUsed: 0
        property real memTotal: 0
        property real diskUsed: 0
        property real diskTotal: 0
        property real rx: 0
        property real tx: 0
        property real netTime: 0
        property real netDown: 0
        property real netUp: 0
        property real temperature: -1
        property real gpu: 0
        property real gpuTemperature: -1
        property real uptime: 0
        property list<real> cpuHistory: []
        property list<real> memHistory: []
        property list<real> downHistory: []
        property list<real> upHistory: []
        property var disks: []
        // [{ label, path }] of hwmon directories, and path → °C from their temp1_input.
        property var sensorPaths: []
        property var sensorReadings: ({})
    }

    Timer {
        interval: Config.sysinfo.interval
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    Process {
        id: discovery

        command: ["sh", Quickshell.shellPath("scripts/sysinfo-paths.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parsePaths(text);
                internal.discovered = true;
            }
        }
    }

    FileView {
        id: cpuFile

        path: "/proc/stat"
        onLoaded: root.parseCpu(text())
    }

    FileView {
        id: memFile

        path: "/proc/meminfo"
        onLoaded: root.parseMem(text())
    }

    FileView {
        id: netFile

        path: "/proc/net/dev"
        onLoaded: root.parseNet(text())
    }

    FileView {
        id: tempFile

        // Millidegrees Celsius.
        path: internal.tempPath !== "" ? `${internal.tempPath}/temp1_input` : ""
        onLoaded: internal.temperature = Math.round(Number(text()) / 1000)
    }

    FileView {
        id: gpuPower

        path: internal.gpuPath !== "" ? `${internal.gpuPath}/power/runtime_status` : ""
        onLoaded: {
            internal.gpuAwake = text().trim() === "active";
            if (internal.gpuAwake)
                gpuQuery.exec(["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", root.csv]);
            else
                internal.gpuTemperature = -1;
        }
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: internal.uptime = Number(text().split(" ")[0])
    }

    FileView {
        id: kernelFile

        path: "/proc/sys/kernel/osrelease"
    }

    // One reader per sensor; sample() reloads them all.
    Instantiator {
        id: sensorFiles

        model: internal.sensorPaths

        FileView {
            id: sensorFile

            required property var modelData

            // Millidegrees Celsius.
            path: `${sensorFile.modelData.path}/temp1_input`
            onLoaded: internal.sensorReadings = Object.assign({}, internal.sensorReadings, {
                [sensorFile.modelData.path]: Math.round(Number(sensorFile.text()) / 1000)
            })
        }
    }

    Process {
        id: gpuQuery

        stdout: StdioCollector {
            onStreamFinished: {
                const [load, celsius] = text.trim().split(",").map(v => Number(v.trim()));
                internal.gpu = load / 100 || 0;
                internal.gpuTemperature = Number.isFinite(celsius) ? celsius : -1;
            }
        }
    }

    Process {
        id: disk

        stdout: StdioCollector {
            onStreamFinished: root.parseDisks(text)
        }
    }

    IpcHandler {
        function status(): string {
            return root.status();
        }

        function setActive(active: bool): void {
            root.setActive(active);
        }

        target: "sysinfo"
    }
}
