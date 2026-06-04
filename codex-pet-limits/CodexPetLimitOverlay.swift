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
    let primary: RateWindow?
    let secondary: RateWindow?
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

        let fiveHour = snapshot.primary?.remainingPercent ?? 0
        let week = snapshot.secondary?.remainingPercent ?? 0
        let overall = min(fiveHour, week)
        let status = statusText(overall: overall, reached: snapshot.reached)
        let color = statusColor(overall: overall, reached: snapshot.reached)
        let mood = moodFrame(overall: overall, reached: snapshot.reached)

        drawMoodSprite(row: mood.row, column: mood.column)
        drawText(status, x: 52, y: 5, size: 11, weight: .bold, color: color)
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

    private func statusText(overall: Int, reached: Bool) -> String {
        if reached || overall <= 0 { return "休息" }
        if overall < 10 { return "低电" }
        if overall < 30 { return "省用" }
        if overall < 60 { return "稳定" }
        return "满电"
    }

    private func moodFrame(overall: Int, reached: Bool) -> (row: Int, column: Int) {
        if reached || overall <= 0 { return (5, 0) }
        if overall < 10 { return (5, 1) }
        if overall < 30 { return (8, 2) }
        if overall < 60 { return (6, 0) }
        return (4, 2)
    }

    private func statusColor(overall: Int, reached: Bool) -> NSColor {
        if reached || overall <= 0 { return NSColor.systemRed }
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
    private var positionTimer: Timer?
    private var limitsTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panel.contentView = overlay
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        refreshPosition()

        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.refreshPosition()
        }
        limitsTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshLimits()
        }
    }

    private func refreshPosition() {
        let petState = readPetState()
        guard isCodexDesktopRunning(), petState.isOpen, let anchor = petState.anchor else {
            panel.orderOut(nil)
            return
        }

        movePanel(to: anchor)
        if !panel.isVisible {
            panel.orderFrontRegardless()
            refreshLimits()
        }
    }

    private func refreshLimits() {
        DispatchQueue.global(qos: .utility).async {
            let limits = readRateLimits()
            DispatchQueue.main.async {
                self.overlay.snapshot = limits
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

func isCodexDesktopRunning() -> Bool {
    NSWorkspace.shared.runningApplications.contains { app in
        app.bundleURL?.path == "/Applications/Codex.app"
            && app.activationPolicy == .regular
    }
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

func readRateLimits() -> LimitSnapshot? {
    let codex = "/Applications/Codex.app/Contents/Resources/codex"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: codex)
    process.arguments = ["app-server", "--stdio"]

    let input = Pipe()
    let output = Pipe()
    process.standardInput = input
    process.standardOutput = output
    process.standardError = Pipe()

    do {
        try process.run()
    } catch {
        return nil
    }

    let initialize = #"{"id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-pet-limits","title":"Codex Pet Limits","version":"0.1.0"},"capabilities":{"experimentalApi":true,"requestAttestation":false,"optOutNotificationMethods":[]}}}"# + "\n"
    let request = #"{"id":2,"method":"account/rateLimits/read","params":null}"# + "\n"
    input.fileHandleForWriting.write(Data(initialize.utf8))
    Thread.sleep(forTimeInterval: 0.2)
    input.fileHandleForWriting.write(Data(request.utf8))
    Thread.sleep(forTimeInterval: 6.0)
    input.fileHandleForWriting.closeFile()

    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.terminate()

    guard let text = String(data: data, encoding: .utf8) else { return nil }
    for line in text.split(separator: "\n").map(String.init) {
        guard
            line.contains(#""id":2"#),
            let data = line.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = root["result"] as? [String: Any],
            let rateLimits = result["rateLimits"] as? [String: Any]
        else {
            continue
        }
        return parseSnapshot(rateLimits)
    }
    return nil
}

func parseSnapshot(_ rateLimits: [String: Any]) -> LimitSnapshot {
    let primary = parseWindow(rateLimits["primary"])
    let secondary = parseWindow(rateLimits["secondary"])
    let reached = rateLimits["rateLimitReachedType"] is String
    return LimitSnapshot(primary: primary, secondary: secondary, reached: reached)
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
