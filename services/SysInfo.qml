pragma Singleton

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

    function setActive(active: bool): void {
        root.active = active;
    }

    function sample(): void {
        cpuFile.reload();
        memFile.reload();
        netFile.reload();
        if (internal.tempPath !== "")
            tempFile.reload();
        if (internal.gpuPath !== "")
            gpuPower.reload();
        if (internal.samples % root.diskEvery === 0)
            disk.exec(["df", "--block-size=1", "--output=used,size", "/"]);
        internal.samples++;
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

    // Prefers the CPU package sensor; acpitz is a last resort.
    function parsePaths(text: string): void {
        const lines = text.trim().split("\n").map(l => l.split(" "));
        const hwmon = name => lines.find(l => l[0] === "hwmon" && l[2] === name)?.[1];
        const sensor = ["coretemp", "k10temp", "zenpower", "acpitz"].map(hwmon).find(path => path !== undefined);
        internal.tempPath = sensor ?? "";
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
                gpuQuery.exec(["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]);
        }
    }

    Process {
        id: gpuQuery

        stdout: StdioCollector {
            onStreamFinished: internal.gpu = Number(text.trim()) / 100 || 0
        }
    }

    Process {
        id: disk

        stdout: StdioCollector {
            onStreamFinished: {
                const [used, size] = text.trim().split("\n")[1]?.trim().split(/\s+/).map(Number) ?? [0, 0];
                internal.diskUsed = used;
                internal.diskTotal = size;
            }
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
