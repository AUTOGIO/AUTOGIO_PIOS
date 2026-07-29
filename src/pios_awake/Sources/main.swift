import AppKit
import Foundation

final class AwakeController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var caffeinateProcess: Process?
    private let pidFileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent("com.pios.awake", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("pios_awake.pid")
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageOnly
            button.toolTip = "PIOS Awake"
        }

        let menu = NSMenu()
        toggleItem = NSMenuItem(
            title: "Awake: Off",
            action: #selector(toggleAwake),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu

        adoptExistingCaffeinateIfNeeded()
        refreshUI()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Quit menu stops caffeinate via quitApp. Unexpected termination leaves
        // caffeinate running if Awake was On (PID file remains for adopt-on-relaunch).
    }

    @objc private func toggleAwake() {
        if isAwake {
            stopCaffeinate()
        } else {
            startCaffeinate()
        }
        refreshUI()
    }

    @objc private func quitApp() {
        if isAwake {
            stopCaffeinate()
        }
        NSApp.terminate(nil)
    }

    private var isAwake: Bool {
        if let process = caffeinateProcess, process.isRunning {
            return true
        }
        if let pid = readPid(), isProcessAlive(pid) {
            return true
        }
        return false
    }

    private func startCaffeinate() {
        stopCaffeinate()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-dims"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            caffeinateProcess = process
            writePid(process.processIdentifier)
        } catch {
            NSLog("PIOS Awake: failed to start caffeinate: \(error)")
            caffeinateProcess = nil
            clearPidFile()
        }
    }

    private func stopCaffeinate() {
        if let process = caffeinateProcess, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        caffeinateProcess = nil

        if let pid = readPid(), isProcessAlive(pid) {
            kill(pid, SIGTERM)
            // Brief wait; force if needed
            usleep(200_000)
            if isProcessAlive(pid) {
                kill(pid, SIGKILL)
            }
        }
        clearPidFile()
    }

    private func adoptExistingCaffeinateIfNeeded() {
        guard let pid = readPid() else { return }
        if isProcessAlive(pid) {
            // Track externally; we don't own the Process object
            caffeinateProcess = nil
        } else {
            clearPidFile()
        }
    }

    private func refreshUI() {
        let on = isAwake
        toggleItem.title = on ? "Awake: On" : "Awake: Off"
        toggleItem.state = on ? .on : .off

        let symbol = on ? "cup.and.saucer.fill" : "moon.zzz"
        if let button = statusItem.button {
            if let image = NSImage(
                systemSymbolName: symbol,
                accessibilityDescription: on ? "Awake On" : "Awake Off"
            ) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = on ? "☕️" : "☾"
            }
        }
    }

    private func writePid(_ pid: Int32) {
        try? String(pid).write(to: pidFileURL, atomically: true, encoding: .utf8)
    }

    private func readPid() -> Int32? {
        guard let text = try? String(contentsOf: pidFileURL, encoding: .utf8) else { return nil }
        return Int32(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func clearPidFile() {
        try? FileManager.default.removeItem(at: pidFileURL)
    }

    private func isProcessAlive(_ pid: Int32) -> Bool {
        pid > 0 && kill(pid, 0) == 0
    }
}

let app = NSApplication.shared
let delegate = AwakeController()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
