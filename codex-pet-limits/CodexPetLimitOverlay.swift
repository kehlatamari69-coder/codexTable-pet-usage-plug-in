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
    private let spriteRows: CGFloat = {
        let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/pets/sproutpal/pet.json")
        guard
            let data = try? Data(contentsOf: url),
            let manifest = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let version = integer(manifest["spriteVersionNumber"])
        else {
            return 9
        }
        return version >= 2 ? 11 : 9
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

        let overall = snapshot.fiveHour?.remainingPercent
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
        let statusSize: CGFloat = (snapshot.reached || overall == nil || overall == 0 || showWeeklyCountdown) ? 10 : 11
        drawText(status, x: 52, y: 5, size: statusSize, weight: .bold, color: color)
        let percentageText = overall.map { "\($0)%" } ?? "--%"
        drawText(percentageText, x: bounds.width - 38, y: 5, size: 11, weight: .bold, color: .white)
        drawMiniBar(percent: overall, color: color)
    }

    private func drawMiniBar(percent: Int?, color: NSColor) {
        let barX: CGFloat = 52
        let barY: CGFloat = 27
        let barWidth: CGFloat = bounds.width - 62
        let barHeight: CGFloat = 4
        let background = Path.roundedRect(CGRect(x: barX, y: barY, width: barWidth, height: barHeight), radius: 4.5)
        NSColor.white.withAlphaComponent(0.18).setFill()
        background.fill()

        guard let percent, percent > 0 else { return }
        let fillWidth = barWidth * CGFloat(percent) / 100
        let fill = Path.roundedRect(CGRect(x: barX, y: barY, width: fillWidth, height: barHeight), radius: 4.5)
        color.setFill()
        fill.fill()
    }

    private func drawMoodSprite(row: Int, column: Int) {
        guard let spriteImage else {
            return
        }

        let columns: CGFloat = 8
        let rows = spriteRows
        let frameWidth = spriteImage.size.width / columns
        let frameHeight = spriteImage.size.height / rows
        let sourceY = spriteImage.size.height - CGFloat(row + 1) * frameHeight
        let source = CGRect(
            x: CGFloat(column) * frameWidth,
            y: sourceY,
            width: frameWidth,
            height: frameHeight
        )
        let maxHeight: CGFloat = 38
        let targetWidth = maxHeight * (frameWidth / frameHeight)
        let target = CGRect(x: 9, y: 3, width: targetWidth, height: maxHeight)
        NSGraphicsContext.saveGraphicsState()
        spriteImage.draw(in: target, from: source, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()
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
        overall: Int?,
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
        guard let overall else {
            return "等待用量"
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
        if hours >= 24 {
            return "\(hours / 24)d\(hours % 24)h"
        }
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(max(1, minutes))m"
    }

    private func moodFrame(overall: Int?, reached: Bool, weeklyRemaining: Int?) -> (row: Int, column: Int) {
        if weeklyRemaining == 0 || reached { return (5, 0) }
        guard let overall else { return (0, 4) }
        if overall <= 0 { return (5, 0) }
        if overall < 10 { return (5, 1) }
        if overall < 30 { return (8, 2) }
        if overall < 60 { return (6, 0) }
        return (4, 2)
    }

    private func statusColor(overall: Int?, reached: Bool, weeklyRemaining: Int?) -> NSColor {
        if weeklyRemaining == 0 || reached { return NSColor.systemRed }
        guard let overall else { return NSColor.secondaryLabelColor }
        if overall <= 0 { return NSColor.systemRed }
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
    private var lastPanelFrame: CGRect?
    private var stateGeneration = 0

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
            positionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                self?.refreshPosition()
            }
        }
        if limitsTimer == nil {
            limitsTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                guard let self else { return }
                guard isCodexDesktopRunning() else {
                    self.updateCodexLifecycle()
                    return
                }
                guard self.panel.isVisible else { return }
                self.overlay.needsDisplay = true
                self.refreshLimits(force: false)
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
        stateGeneration &+= 1
        overlay.snapshot = nil
        overlay.needsDisplay = true
        panel.orderOut(nil)
        lastPanelFrame = nil
        rateLimitClient.stop()
    }

    private func refreshPosition() {
        let petState = readPetState()
        guard petState.isOpen, let anchor = petState.anchor else {
            hideAndClear()
            return
        }

        movePanel(to: anchor)
        if !panel.isVisible {
            panel.orderFrontRegardless()
            refreshLimits(force: true)
        }
    }

    private func refreshLimits(force: Bool) {
        let generation = stateGeneration
        rateLimitClient.refreshIfNeeded(force: force) { [weak self] limits in
            DispatchQueue.main.async {
                guard let self,
                      generation == self.stateGeneration,
                      self.panel.isVisible else { return }
                if let limits {
                    self.overlay.snapshot = limits
                    self.overlay.needsDisplay = true
                }
            }
        }
    }

    private func movePanel(to anchor: PetAnchor) {
        let screens = NSScreen.screens
        guard let primary = screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main else { return }
        let primaryTop = primary.frame.maxY
        let petCenter = CGPoint(
            x: anchor.x + anchor.width / 2,
            y: primaryTop - anchor.y - anchor.height / 2
        )
        let targetScreen = screens.first(where: { $0.frame.contains(petCenter) }) ?? primary
        let frame = panelFrame(for: anchor, screen: targetScreen.frame, primaryTop: primaryTop)
        guard frame != lastPanelFrame else { return }
        lastPanelFrame = frame
        panel.setFrame(frame, display: true)
    }
}

func panelFrame(for anchor: PetAnchor, screen: CGRect, primaryTop: CGFloat) -> CGRect {
    let width: CGFloat = 150
    let height: CGFloat = 44
    let desiredX = anchor.x + anchor.width / 2 - width / 2
    let desiredY = primaryTop - (anchor.y + anchor.height + 9) - height
    let x = min(max(screen.minX + 8, desiredX), screen.maxX - width - 8)
    let y = min(max(screen.minY + 8, desiredY), screen.maxY - height - 8)
    return CGRect(x: x, y: y, width: width, height: height)
}

final class RateLimitClient {
    private let queue = DispatchQueue(label: "com.yy.codex-pet-limits.rate-limits")
    private let minRefreshInterval: TimeInterval = 55

    private var lastRequestAt = Date.distantPast
    private var isRefreshing = false

    func refreshIfNeeded(force: Bool, completion: @escaping (LimitSnapshot?) -> Void) {
        queue.async {
            let now = Date()
            if !force, now.timeIntervalSince(self.lastRequestAt) < self.minRefreshInterval {
                completion(nil)
                return
            }
            guard !self.isRefreshing else {
                return
            }
            self.isRefreshing = true
            self.lastRequestAt = now
            let snapshot = readLatestLocalRateLimits(now: now)
            self.isRefreshing = false
            completion(snapshot)
        }
    }

    func stop() {
        queue.async {
            self.lastRequestAt = Date.distantPast
            self.isRefreshing = false
        }
    }
}

struct LocalRateLimitCandidate {
    let timestamp: Date
    let snapshot: LimitSnapshot
}

struct RecentSessionFile {
    let url: URL
    let modifiedAt: Date
}

func readLatestLocalRateLimits(now: Date) -> LimitSnapshot? {
    var latest: LocalRateLimitCandidate?
    for file in recentSessionFiles(now: now) {
        if let latest, file.modifiedAt < latest.timestamp {
            break
        }
        guard let candidate = latestRateLimitCandidate(in: file.url, now: now) else {
            continue
        }
        if latest == nil || candidate.timestamp > latest!.timestamp {
            latest = candidate
        }
    }
    return latest?.snapshot
}

func recentSessionFiles(now: Date) -> [RecentSessionFile] {
    let fileManager = FileManager.default
    let root = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex/sessions")
    let calendar = Calendar.current
    var files: [(url: URL, modifiedAt: Date)] = []

    for dayOffset in 0..<8 {
        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else {
            continue
        }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            continue
        }
        let directory = root
            .appendingPathComponent(String(format: "%04d", year))
            .appendingPathComponent(String(format: "%02d", month))
            .appendingPathComponent(String(format: "%02d", day))
        guard let entries = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            continue
        }
        for url in entries where url.pathExtension == "jsonl" {
            let modifiedAt = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? .distantPast
            files.append((url, modifiedAt))
        }
    }

    return files.sorted { lhs, rhs in
        if lhs.modifiedAt == rhs.modifiedAt {
            return lhs.url.lastPathComponent > rhs.url.lastPathComponent
        }
        return lhs.modifiedAt > rhs.modifiedAt
    }.map { RecentSessionFile(url: $0.url, modifiedAt: $0.modifiedAt) }
}

func latestRateLimitCandidate(in url: URL, now: Date) -> LocalRateLimitCandidate? {
    guard let data = readTail(of: url, maxBytes: 512_000) else {
        return nil
    }
    let text = String(decoding: data, as: UTF8.self)

    for line in text.split(separator: "\n", omittingEmptySubsequences: true).reversed() {
        guard line.contains("\"type\":\"token_count\""), line.contains("\"rate_limits\"") else {
            continue
        }
        guard
            let data = String(line).data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let payload = root["payload"] as? [String: Any],
            let rateLimits = payload["rate_limits"] as? [String: Any],
            let snapshot = parseLocalSnapshot(rateLimits, now: now)
        else {
            continue
        }
        let timestamp = parseISO8601(root["timestamp"] as? String) ?? .distantPast
        return LocalRateLimitCandidate(timestamp: timestamp, snapshot: snapshot)
    }
    return nil
}

func readTail(of url: URL, maxBytes: UInt64) -> Data? {
    guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
    defer { try? handle.close() }
    guard let size = try? handle.seekToEnd() else { return nil }
    let offset = size > maxBytes ? size - maxBytes : 0
    do {
        try handle.seek(toOffset: offset)
        return try handle.readToEnd()
    } catch {
        return nil
    }
}

private let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let iso8601WithoutFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

func parseISO8601(_ value: String?) -> Date? {
    guard let value else { return nil }
    return iso8601WithFractionalSeconds.date(from: value)
        ?? iso8601WithoutFractionalSeconds.date(from: value)
}

func parseLocalSnapshot(_ rateLimits: [String: Any], now: Date) -> LimitSnapshot? {
    let primary = rateLimits["primary"] as? [String: Any]
    let secondary = rateLimits["secondary"] as? [String: Any]
    let windows = [primary, secondary].compactMap { $0 }

    var fiveHourData = windows.first { integer($0["window_minutes"]) == 300 }
    var weeklyData = windows.first { integer($0["window_minutes"]) == 10_080 }

    // Legacy records omitted window_minutes but consistently used primary/secondary.
    if fiveHourData == nil, weeklyData == nil, windows.allSatisfy({ integer($0["window_minutes"]) == nil }) {
        fiveHourData = primary
        weeklyData = secondary
    }
    let fiveHour = parseLocalWindow(fiveHourData, now: now)
    let weekly = parseLocalWindow(weeklyData, now: now)
    guard fiveHour != nil || weekly != nil else { return nil }

    let exhausted = fiveHour?.remainingPercent == 0 || weekly?.remainingPercent == 0
    let reached = rateLimits["rate_limit_reached_type"] is String && exhausted
    return LimitSnapshot(fiveHour: fiveHour, weekly: weekly, reached: reached)
}

func parseLocalWindow(_ value: [String: Any]?, now: Date) -> RateWindow? {
    guard let value, let used = number(value["used_percent"]) else { return nil }
    let resetsAt = integer(value["resets_at"])
    if let resetsAt, resetsAt <= Int(now.timeIntervalSince1970) {
        return RateWindow(usedPercent: 0, resetsAt: nil)
    }
    return RateWindow(usedPercent: Int(used.rounded()).clamped(to: 0...100), resetsAt: resetsAt)
}

func number(_ value: Any?) -> Double? {
    if let value = value as? NSNumber { return value.doubleValue }
    if let value = value as? String { return Double(value) }
    return nil
}

func integer(_ value: Any?) -> Int? {
    if let value = value as? NSNumber { return value.intValue }
    if let value = value as? String { return Int(value) }
    return nil
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
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

    guard let bounds,
          let overlayX = number(bounds["x"]),
          let overlayY = number(bounds["y"]) else {
        return PetState(isOpen: true, anchor: nil)
    }

    if let mascot = bounds["mascot"] as? [String: Any],
       let left = number(mascot["left"]),
       let top = number(mascot["top"]),
       let width = number(mascot["width"]),
       let height = number(mascot["height"]) {
        let anchor = PetAnchor(
            x: CGFloat(overlayX + left),
            y: CGFloat(overlayY + top),
            width: CGFloat(width),
            height: CGFloat(height)
        )
        return PetState(isOpen: true, anchor: anchor)
    }

    // Current Codex stores the mascot's logical origin without the 53-point
    // transparent effect padding used by its 198x206 composition window.
    let anchor = inferredPetAnchor(overlayX: overlayX, overlayY: overlayY)
    return PetState(isOpen: true, anchor: anchor)
}

func inferredPetAnchor(overlayX: Double, overlayY: Double) -> PetAnchor {
    PetAnchor(x: CGFloat(overlayX - 53), y: CGFloat(overlayY - 53), width: 198, height: 206)
}

func runSelfTests() -> Bool {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let futureReset = 1_700_100_000

    guard parseISO8601("2026-07-18T05:22:53.732Z") != nil,
          parseISO8601("2026-07-18T05:22:53Z") != nil else {
        print("FAIL: ISO-8601 timestamp variants regressed")
        return false
    }

    let inferredAnchor = inferredPetAnchor(overlayX: 172, overlayY: 741)
    guard inferredAnchor.x == 119, inferredAnchor.y == 688,
          inferredAnchor.width == 198, inferredAnchor.height == 206 else {
        print("FAIL: current Codex pet-anchor inference regressed")
        return false
    }

    let weeklyOnly = parseLocalSnapshot([
        "primary": ["used_percent": 100, "window_minutes": 10_080, "resets_at": futureReset]
    ], now: now)
    guard weeklyOnly?.fiveHour == nil, weeklyOnly?.weekly?.remainingPercent == 0 else {
        print("FAIL: weekly-only data was duplicated into the five-hour window")
        return false
    }

    let reversedWindows = parseLocalSnapshot([
        "primary": ["used_percent": 25, "window_minutes": 10_080, "resets_at": futureReset],
        "secondary": ["used_percent": 10, "window_minutes": 300, "resets_at": futureReset]
    ], now: now)
    guard reversedWindows?.fiveHour?.remainingPercent == 90,
          reversedWindows?.weekly?.remainingPercent == 75 else {
        print("FAIL: windows were mapped by field order instead of duration")
        return false
    }

    let legacyWindows = parseLocalSnapshot([
        "primary": ["used_percent": 20, "resets_at": futureReset],
        "secondary": ["used_percent": 30, "resets_at": futureReset]
    ], now: now)
    guard legacyWindows?.fiveHour?.remainingPercent == 80,
          legacyWindows?.weekly?.remainingPercent == 70 else {
        print("FAIL: legacy primary/secondary mapping regressed")
        return false
    }

    let primaryPanel = panelFrame(
        for: PetAnchor(x: 119, y: 688, width: 198, height: 206),
        screen: CGRect(x: 0, y: 0, width: 1470, height: 956),
        primaryTop: 956
    )
    let secondaryPanel = panelFrame(
        for: PetAnchor(x: 1600, y: 100, width: 100, height: 100),
        screen: CGRect(x: 1470, y: 0, width: 1920, height: 1080),
        primaryTop: 956
    )
    guard primaryPanel.origin == CGPoint(x: 143, y: 9),
          secondaryPanel.origin == CGPoint(x: 1575, y: 703) else {
        print("FAIL: multi-display panel placement regressed")
        return false
    }

    print("PASS: usage parsing, pet detection, and panel placement")
    return true
}

if CommandLine.arguments.contains("--self-test") {
    exit(runSelfTests() ? EXIT_SUCCESS : EXIT_FAILURE)
}

if CommandLine.arguments.contains("--print-pet-state") {
    let state = readPetState()
    if let anchor = state.anchor {
        print("open=\(state.isOpen) x=\(Int(anchor.x)) y=\(Int(anchor.y)) width=\(Int(anchor.width)) height=\(Int(anchor.height))")
    } else {
        print("open=\(state.isOpen) anchor=unavailable")
    }
    exit(state.isOpen && state.anchor != nil ? EXIT_SUCCESS : EXIT_FAILURE)
}

if CommandLine.arguments.contains("--print-codex-state") {
    let matches = NSWorkspace.shared.runningApplications.filter(isCodexApplication)
    if matches.isEmpty {
        print("running=false")
        exit(EXIT_FAILURE)
    }
    for app in matches {
        print("running=true name=\(app.localizedName ?? "unknown") bundle=\(app.bundleIdentifier ?? "unknown")")
    }
    exit(EXIT_SUCCESS)
}

if let previewIndex = CommandLine.arguments.firstIndex(of: "--render-preview"),
   CommandLine.arguments.indices.contains(previewIndex + 1) {
    _ = NSApplication.shared
    let view = OverlayView(frame: CGRect(x: 0, y: 0, width: 150, height: 44))
    view.snapshot = LimitSnapshot(
        fiveHour: RateWindow(usedPercent: 2, resetsAt: nil),
        weekly: RateWindow(usedPercent: 17, resetsAt: nil),
        reached: false
    )
    if let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
        view.cacheDisplay(in: view.bounds, to: bitmap)
        if let png = bitmap.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[previewIndex + 1]))
            exit(EXIT_SUCCESS)
        }
    }
    exit(EXIT_FAILURE)
}

if CommandLine.arguments.contains("--print-usage") {
    if let snapshot = readLatestLocalRateLimits(now: Date()) {
        let fiveHour = (snapshot.fiveHour?.remainingPercent).map(String.init) ?? "unknown"
        let weekly = (snapshot.weekly?.remainingPercent).map(String.init) ?? "unknown"
        print("fiveHourRemaining=\(fiveHour) weeklyRemaining=\(weekly)")
        exit(EXIT_SUCCESS)
    }
    print("usage snapshot unavailable")
    exit(EXIT_FAILURE)
}

let app = NSApplication.shared
let delegate = LimitOverlayApp()
app.delegate = delegate
app.run()
