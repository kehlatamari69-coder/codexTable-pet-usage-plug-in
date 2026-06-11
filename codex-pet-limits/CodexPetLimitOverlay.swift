import AppKit
import Foundation

struct RateWindow {
    let usedPercent: Int
    let resetsAt: Int?

    var remainingPercent: Int {
        max(0, min(100, 100 - usedPercent))
    }
}

struct LimitSnapshot {
    let fiveHour: RateWindow?
    let weekly: RateWindow?
    let reached: Bool
}

struct PetAnchor {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

struct PetState {
    let isOpen: Bool
    let anchor: PetAnchor?
}

final class OverlayView: NSView {
    var snapshot: LimitSnapshot?
    private let spriteImage: NSImage? = {
        let path = NSHomeDirectory() + "/.codex/pets/sproutpal/spritesheet.webp"
        return NSImage(contentsOfFile: path)
    }()

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds
        let radius: CGFloat = 22

        NSColor(calibratedWhite: 0.02, alpha: 0.62).setFill()
        Path.roundedRect(bounds, radius: radius).fill()

        guard let snapshot else {
            drawMoodSprite(row: 0, column: 4)
            drawText("读取中", x: 52, y: 7, size: 11, weight: .semibold, color: .white)
            return
        }

        let overall = snapshot.fiveHour?.remainingPercent ?? 0
        let weekly = snapshot.weekly?.remainingPercent
        let showWeeklyCountdown = weekly == 0
        let status = statusText(
            overall: overall,
            reached: snapshot.reached,
            fiveHourResetsAt: snapshot.fiveHour?.resetsAt,
            weeklyRemaining: weekly,
            weeklyResetsAt: snapshot.weekly?.resetsAt
        )
        let color = statusColor(overall: overall, reached: snapshot.reached, weeklyRemaining: weekly)
        let mood = moodFrame(overall: overall, reached: snapshot.reached, weeklyRemaining: weekly)

        drawMoodSprite(row: mood.row, column: mood.column)
        let statusSize: CGFloat = (snapshot.reached || overall <= 0 || showWeeklyCountdown) ? 10 : 11
        drawText(status, x: 52, y: 5, size: statusSize, weight: .bold, color: color)
        drawText("\(overall)%", x: bounds.width - 38, y: 5, size: 11, weight: .bold, color: .white)
        drawMiniBar(percent: overall, color: color)
    }

    private func drawMiniBar(percent: Int, color: NSColor) {
        let barX: CGFloat = 52
        let barY: CGFloat = 27
        let barWidth: CGFloat = bounds.width - 62
        let barHeight: CGFloat = 4
        let background = Path.roundedRect(CGRect(x: barX, y: barY, width: barWidth, height: barHeight), radius: 4.5)
        NSColor.white.withAlphaComponent(0.18).setFill()
        background.fill()

        let fillWidth = max(2, barWidth * CGFloat(percent) / 100)
        let fill = Path.roundedRect(CGRect(x: barX, y: barY, width: fillWidth, height: barHeight), radius: 4.5)
        color.setFill()
        fill.fill()
    }

    private func drawMoodSprite(row: Int, column: Int) {
        guard let spriteImage else {
            return
        }

        let columns: CGFloat = 8
        let rows: CGFloat = 9
        let frameWidth = spriteImage.size.width / columns
        let frameHeight = spriteImage.size.height / rows
        let source = CGRect(
            x: CGFloat(column) * frameWidth,
            y: CGFloat(row) * frameHeight,
            width: frameWidth,
            height: frameHeight
        )
        let maxHeight: CGFloat = 38
        let targetWidth = maxHeight * (frameWidth / frameHeight)
        let target = CGRect(x: 9, y: 3, width: targetWidth, height: maxHeight)
        spriteImage.draw(in: target, from: source, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
    }

    private func drawText(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: CGRect(x: x, y: y, width: bounds.width - x - 10, height: 20), withAttributes: attributes)
    }

    private func statusText(
        overall: Int,
        reached: Bool,
        fiveHourResetsAt: Int?,
        weeklyRemaining: Int?,
        weeklyResetsAt: Int?
    ) -> String {
        if weeklyRemaining == 0 {
            if let countdown = resetCountdownText(resetsAt: weeklyResetsAt) {
                return "周\(countdown)"
            }
            return "周刷新"
        }
        if reached || overall <= 0 {
            if let countdown = resetCountdownText(resetsAt: fiveHourResetsAt) {
                return countdown
            }
            return "休息"
        }
        if overall < 10 { return "低电" }
        if overall < 30 { return "省用" }
        if overall < 60 { return "稳定" }
        return "满电"
    }

    private func resetCountdownText(resetsAt: Int?) -> String? {
        guard let resetsAt else {
            return nil
        }

        let seconds = max(0, resetsAt - Int(Date().timeIntervalSince1970))
        if seconds <= 0 {
            return "刷新中"
        }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(max(1, minutes))m"
    }

    private func moodFrame(overall: Int, reached: Bool, weeklyRemaining: Int?) -> (row: Int, column: Int) {
        if weeklyRemaining == 0 || reached || overall <= 0 { return (5, 0) }
        if overall < 10 { return (5, 1) }
        if overall < 30 { return (8, 2) }
        if overall < 60 { return (6, 0) }
        return (4, 2)
    }

    private func statusColor(overall: Int, reached: Bool, weeklyRemaining: Int?) -> NSColor {
        if weeklyRemaining == 0 || reached || overall <= 0 { return NSColor.systemRed }
        if overall < 10 { return NSColor.systemOrange }
        if overall < 30 { return NSColor.systemYellow }
        if overall < 60 { return NSColor.systemTeal }
        return NSColor.systemGreen
    }
}

enum Path {
    static func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    }
}

final class LimitOverlayApp: NSObject, NSApplicationDelegate {
    private let panel = NSPanel(
        contentRect: CGRect(x: 80, y: 720, width: 150, height: 44),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    private let overlay = OverlayView(frame: CGRect(x: 0, y: 0, width: 150, height: 44))
    private let rateLimitClient = RateLimitClient()
    private var positionTimer: Timer?
    private var limitsTimer: Timer?
    private var codexWaitTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panel.contentView = overlay
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let notifications = NSWorkspace.shared.notificationCenter
        notifications.addObserver(
            self,
            selector: #selector(workspaceApplicationChanged(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        notifications.addObserver(
            self,
            selector: #selector(workspaceApplicationChanged(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        updateCodexLifecycle()
    }

    @objc private func workspaceApplicationChanged(_ notification: Notification) {
        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            isCodexApplication(app)
        else {
            return
        }
        updateCodexLifecycle()
    }

    private func updateCodexLifecycle() {
        if isCodexDesktopRunning() {
            stopCodexWaitTimer()
            startActiveTimers()
            refreshPosition()
        } else {
            stopActiveTimers()
            startCodexWaitTimer()
            hideAndClear()
        }
    }

    private func startActiveTimers() {
        if positionTimer == nil {
            positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.refreshPosition()
            }
        }
        if limitsTimer == nil {
            limitsTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.overlay.needsDisplay = true
                self?.refreshLimits(force: self?.overlay.snapshot == nil)
            }
        }
    }

    private func stopActiveTimers() {
        positionTimer?.invalidate()
        positionTimer = nil
        limitsTimer?.invalidate()
        limitsTimer = nil
    }

    private func startCodexWaitTimer() {
        guard codexWaitTimer == nil else { return }
        codexWaitTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateCodexLifecycle()
        }
    }

    private func stopCodexWaitTimer() {
        codexWaitTimer?.invalidate()
        codexWaitTimer = nil
    }

    private func hideAndClear() {
        overlay.snapshot = nil
        overlay.needsDisplay = true
        panel.orderOut(nil)
        rateLimitClient.stop()
    }

    private func refreshPosition() {
        guard isCodexDesktopRunning() else {
            updateCodexLifecycle()
            return
        }

        let petState = readPetState()
        guard petState.isOpen, let anchor = petState.anchor else {
            hideAndClear()
            return
        }

        movePanel(to: anchor)
        if !panel.isVisible {
            panel.orderFrontRegardless()
            refreshLimits(force: overlay.snapshot == nil)
        }
    }

    private func refreshLimits(force: Bool) {
        rateLimitClient.refreshIfNeeded(force: force) { [weak self] limits in
            DispatchQueue.main.async {
                guard let self else { return }
                if let limits {
                    self.overlay.snapshot = limits
                }
                self.overlay.needsDisplay = true
            }
        }
    }

    private func movePanel(to anchor: PetAnchor) {
        guard let screen = NSScreen.main else { return }
        let screenHeight = screen.frame.height
        let width: CGFloat = 150
        let height: CGFloat = 44
        let x = max(8, anchor.x + anchor.width / 2 - width / 2)
        let yFromTop = min(screenHeight - height - 8, anchor.y + anchor.height + 9)
        let cocoaY = max(8, screenHeight - yFromTop - height)
        panel.setFrame(CGRect(x: x, y: cocoaY, width: width, height: height), display: true)
    }
}

final class RateLimitClient {
    private let queue = DispatchQueue(label: "com.yy.codex-pet-limits.rate-limits")
    private let minRefreshInterval: TimeInterval = 300
    private let codexPath = "/Applications/Codex.app/Contents/Resources/codex"

    private var process: Process?
    private var input: FileHandle?
    private var output: FileHandle?
    private var errorOutput: FileHandle?
    private var outputBuffer = Data()
    private var lastRequestAt = Date.distantPast
    private var nextRequestID = 2
    private var pendingCompletions: [(LimitSnapshot?) -> Void] = []

    func refreshIfNeeded(force: Bool, completion: @escaping (LimitSnapshot?) -> Void) {
        queue.async {
            let now = Date()
            if !force, now.timeIntervalSince(self.lastRequestAt) < self.minRefreshInterval {
                completion(nil)
                return
            }

            self.pendingCompletions.append(completion)

            guard self.startIfNeeded() else {
                self.finishPending(with: nil)
                return
            }

            if now.timeIntervalSince(self.lastRequestAt) >= self.minRefreshInterval || force {
                self.sendRateLimitRequest()
                self.lastRequestAt = now
            }
        }
    }

    func stop() {
        queue.async {
            self.output?.readabilityHandler = nil
            self.errorOutput?.readabilityHandler = nil
            self.input?.closeFile()
            self.process?.terminate()
            self.input = nil
            self.output = nil
            self.errorOutput = nil
            self.process = nil
            self.outputBuffer.removeAll(keepingCapacity: false)
            self.lastRequestAt = Date.distantPast
            self.finishPending(with: nil)
        }
    }

    private func startIfNeeded() -> Bool {
        if let process, process.isRunning, input != nil {
            return true
        }

        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: codexPath)
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            return false
        }

        input = inputPipe.fileHandleForWriting
        output = outputPipe.fileHandleForReading
        errorOutput = errorPipe.fileHandleForReading
        self.process = process

        output?.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.queue.async {
                self?.handleOutput(data)
            }
        }
        errorOutput?.readabilityHandler = { handle in
            _ = handle.availableData
        }
        process.terminationHandler = { [weak self] _ in
            self?.queue.async {
                self?.input = nil
                self?.output = nil
                self?.errorOutput = nil
                self?.process = nil
                self?.lastRequestAt = Date.distantPast
                self?.finishPending(with: nil)
            }
        }

        let initialize = #"{"id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-pet-limits","title":"Codex Pet Limits","version":"0.1.0"},"capabilities":{"experimentalApi":true,"requestAttestation":false,"optOutNotificationMethods":[]}}}"# + "\n"
        writeLine(initialize)
        return true
    }

    private func sendRateLimitRequest() {
        let requestID = nextRequestID
        nextRequestID += 1
        let request = #"{"id":\#(requestID),"method":"account/rateLimits/read","params":null}"# + "\n"
        writeLine(request)
    }

    private func writeLine(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        input?.write(data)
    }

    private func handleOutput(_ data: Data) {
        outputBuffer.append(data)

        while let newline = outputBuffer.firstIndex(of: 10) {
            let lineData = outputBuffer[..<newline]
            outputBuffer.removeSubrange(...newline)

            guard
                let root = try? JSONSerialization.jsonObject(with: Data(lineData)) as? [String: Any],
                let result = root["result"] as? [String: Any],
                let rateLimits = result["rateLimits"] as? [String: Any]
            else {
                continue
            }

            let snapshot = parseSnapshot(rateLimits)
            finishPending(with: snapshot)
        }
    }

    private func finishPending(with snapshot: LimitSnapshot?) {
        guard !pendingCompletions.isEmpty else { return }
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0(snapshot) }
    }
}

func isCodexDesktopRunning() -> Bool {
    NSWorkspace.shared.runningApplications.contains(where: isCodexApplication)
}

func isCodexApplication(_ app: NSRunningApplication) -> Bool {
    app.bundleIdentifier == "com.openai.codex"
        || app.localizedName == "Codex"
        || app.bundleURL?.lastPathComponent == "Codex.app"
}

func readPetState() -> PetState {
    let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/.codex-global-state.json")
    guard
        let data = try? Data(contentsOf: url),
        let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let state = root["electron-persisted-atom-state"] as? [String: Any]
    else {
        return PetState(isOpen: false, anchor: nil)
    }

    let isOpen =
        (root["electron-avatar-overlay-open"] as? Bool) ??
        (state["electron-avatar-overlay-open"] as? Bool) ??
        false

    guard isOpen else {
        return PetState(isOpen: false, anchor: nil)
    }

    let bounds =
        (root["electron-avatar-overlay-bounds"] as? [String: Any]) ??
        (state["electron-avatar-overlay-bounds"] as? [String: Any])

    guard
        let bounds,
        let mascot = bounds["mascot"] as? [String: Any],
        let left = mascot["left"] as? Double,
        let top = mascot["top"] as? Double,
        let width = mascot["width"] as? Double,
        let height = mascot["height"] as? Double,
        let overlayX = bounds["x"] as? Double,
        let overlayY = bounds["y"] as? Double
    else {
        return PetState(isOpen: true, anchor: nil)
    }

    let anchor = PetAnchor(
        x: CGFloat(overlayX + left),
        y: CGFloat(overlayY + top),
        width: CGFloat(width),
        height: CGFloat(height)
    )
    return PetState(isOpen: true, anchor: anchor)
}

func parseSnapshot(_ rateLimits: [String: Any]) -> LimitSnapshot {
    let fiveHour = parseWindow(rateLimits["primary"])
    let weekly = parseWindow(rateLimits["secondary"])
    let reached = rateLimits["rateLimitReachedType"] is String
    return LimitSnapshot(fiveHour: fiveHour, weekly: weekly, reached: reached)
}

func parseWindow(_ value: Any?) -> RateWindow? {
    guard let dict = value as? [String: Any] else { return nil }
    let used = dict["usedPercent"] as? Int ?? Int(dict["usedPercent"] as? Double ?? 0)
    let resetsAt = dict["resetsAt"] as? Int
    return RateWindow(usedPercent: used, resetsAt: resetsAt)
}

let app = NSApplication.shared
let delegate = LimitOverlayApp()
app.delegate = delegate
app.run()
