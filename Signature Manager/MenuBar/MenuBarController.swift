//
//  MenuBarController.swift
//  Signature Manager
//
//  Created by Marc Büttner on 05.09.25.
//

import SwiftUI
import Combine
import Sparkle


public protocol MenuBarPresenting: AnyObject {
    func showLiveActivity(_ show: Bool)
    func setLiveActivityProgress(_ value: Double)
    func setIcon(state: MenuBarIconState, toolTip: String)
}
public enum MenuBarIconState { case ok, updating, error }


final class MenuBarController: NSObject, ObservableObject, MenuBarPresenting, NSMenuDelegate {
    
    @AppStorage("showHelloView") var showHelloView: Bool = false
    @AppStorage("graph.lastUpdate") private var lastUpdateTimestamp: String = ""
    
    @ObservedObject private var menuBarLiveActivity: MenuBarLiveActivity

    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    private let statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()

    private weak var currentContentView: NSView?
    private var liveActivityContainer: NSView?
    private var progressLayer: CAShapeLayer?
    private var trackLayer: CAShapeLayer?
    private var titleLabel: NSTextField?
    private let liveActivityHeight: CGFloat = 24
    private let leftPadding: CGFloat = 6
    private let rightPadding: CGFloat = 12
    private let spacing: CGFloat = 8
    private let indicatorDiameter: CGFloat = 20
    private let indicatorLineWidth: CGFloat = 3.5

    init(menuBarLiveActivity: MenuBarLiveActivity) {
        self.menuBarLiveActivity = menuBarLiveActivity
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        
        UpdateManager.shared.menuBarPresenter = self
        UpdateManager.shared.liveActivity = menuBarLiveActivity

        constructMenu()
        statusItem.menu?.delegate = self
        
        applyStatus(menuBarLiveActivity.status) //BASIC

        menuBarLiveActivity.$showLiveActivity
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                guard let self else { return }
                if visible {
                    self.showLiveActivityView()
                } else {
                    self.applyStatus(self.menuBarLiveActivity.status)
                }
            }
            .store(in: &cancellables)

        menuBarLiveActivity.$progress
            .receive(on: RunLoop.main)
            .sink { [weak self] val in
                self?.updateProgress(to: CGFloat(val))
            }
            .store(in: &cancellables)

        menuBarLiveActivity.$status
            .receive(on: RunLoop.main)
            .sink { [weak self] newStatus in
                guard let self else { return }
                if !self.menuBarLiveActivity.showLiveActivity {
                    self.applyStatus(newStatus)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleHelloViewDidContinue), name: .HelloViewDidContinue, object: nil)
    }

    private func constructMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let infoItem = NSMenuItem()
        infoItem.title = lastUpdateTimestamp.isEmpty
            ? String(localized: "UP_TO_DATE")
            : String(localized: "UP_TO_DATE \(lastUpdateTimestamp)")
        infoItem.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
        infoItem.isEnabled = false
        _ = !showHelloView ? menu.addItem(infoItem) : nil

        menu.addItem(.separator())

        let updateItem = NSMenuItem(title: String(localized: "UPDATE_SIGNATURES"), action: #selector(didTapUpdateSignatures), keyEquivalent: "r")
        updateItem.image = NSImage(systemSymbolName: "arrow.trianglehead.2.clockwise", accessibilityDescription: nil)
        updateItem.target = self
        _ = !showHelloView ? menu.addItem(updateItem) : nil

        menu.addItem(.separator())

        let softwareUpdateItem = NSMenuItem(title: String(localized: "CHECK_FOR_SOFTWAREUPDATES"), action: #selector(didTapSoftwareUpdates), keyEquivalent: "")
        softwareUpdateItem.image = NSImage(systemSymbolName: "gear.badge", accessibilityDescription: nil)
        softwareUpdateItem.target = self
        menu.addItem(softwareUpdateItem)

        let settingsItem = NSMenuItem(title: String(localized: "SETTINGS"), action: #selector(didTapSettings), keyEquivalent: ".")
        settingsItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        settingsItem.target = self
        _ = !showHelloView ? menu.addItem(settingsItem) : nil

        let exitItem = NSMenuItem(title: String(localized: "QUIT_SIGNATURE_MANAGER"), action: #selector(didTapQuit), keyEquivalent: "q")
        exitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        exitItem.target = self
        menu.addItem(exitItem)

        statusItem.menu = menu
    }

    private func rebuildMenu() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.constructMenu()
            self.statusItem.menu?.delegate = self
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        constructMenu()
        statusItem.menu?.delegate = self
    }
    
    @objc private func handleHelloViewDidContinue() {
        rebuildMenu()
    }

    @objc private func didTapUpdateSignatures() {
        UpdateManager.shared.start(remoteRequested: false)
    }

    @objc private func didTapSoftwareUpdates() {
        updaterController.updater.checkForUpdates()
    }

    @objc private func didTapSettings() {
        let openWindow = Environment(\.openWindow).wrappedValue
        NotificationCenter.default.post(name: .ShowAppInDock, object: nil)
        openWindow(id: "content")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .BringWindowToFront, object: nil)
        }
    }

    @objc private func didTapQuit() {
        AppManager.quit()
    }

    private func applyStatus(_ status: MenuBarStatus) {
        guard let button = statusItem.button else {
            Logger.shared.log(position: "MenuBarController.applyStatus", type: "CRITICAL", content: "NSStatusBarButton is nil; cannot apply status")
            return
        }
        tearDownLiveActivityIfNeeded()
        statusItem.length = NSStatusItem.squareLength
        button.subviews.forEach { $0.removeFromSuperview() }

        let img = NSImage(named: status.iconName)
            ?? NSImage(systemSymbolName: status.iconName, accessibilityDescription: nil)
        button.image = img
        button.image?.isTemplate = status.isTemplate
        button.toolTip = status.tooltip
    }

    private func tearDownLiveActivityIfNeeded() {
        guard let button = statusItem.button else { return }
        button.subviews.forEach { $0.removeFromSuperview() }
        currentContentView = nil
        liveActivityContainer = nil
        progressLayer = nil
        trackLayer = nil
        titleLabel = nil
    }

    private func textSize(_ string: String, font: NSFont) -> CGSize {
        (string as NSString).size(withAttributes: [.font: font])
    }

    private func showLiveActivityView() {
        guard let button = statusItem.button else {
            Logger.shared.log(position: "MenuBarController.showLiveActivityView", type: "CRITICAL", content: "NSStatusBarButton is nil; cannot show live activity")
            return
        }

        let font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let text = String(localized: "UPDATING_SIGNATURES")
        let textSz = textSize(text, font: font)

        let liveActivityWidth = leftPadding + indicatorDiameter + spacing + textSz.width + rightPadding
        statusItem.length = liveActivityWidth

        let container = NSView(frame: NSRect(x: 0, y: 0, width: liveActivityWidth, height: liveActivityHeight))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.systemBlue.cgColor
        container.layer?.cornerRadius = liveActivityHeight / 2
        container.layer?.masksToBounds = true

        let indicatorFrame = NSRect(x: leftPadding,
                                    y: (liveActivityHeight - indicatorDiameter) / 2,
                                    width: indicatorDiameter,
                                    height: indicatorDiameter)
        let indicatorView = NSView(frame: indicatorFrame)
        indicatorView.wantsLayer = true

        let center = CGPoint(x: indicatorDiameter / 2, y: indicatorDiameter / 2)
        let radius = (indicatorDiameter - indicatorLineWidth) / 2
        let startAngle = CGFloat.pi
        let endAngle   = startAngle - 2*CGFloat.pi

        let path = CGMutablePath()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        let track = CAShapeLayer()
        track.path = path
        track.strokeColor = NSColor.white.withAlphaComponent(0.28).cgColor
        track.fillColor = NSColor.clear.cgColor
        track.lineWidth = indicatorLineWidth
        indicatorView.layer?.addSublayer(track)

        let progress = CAShapeLayer()
        progress.path = path
        progress.strokeColor = NSColor.white.cgColor
        progress.fillColor = NSColor.clear.cgColor
        progress.lineWidth = indicatorLineWidth
        progress.lineCap = .round
        progress.strokeStart = 0.0
        progress.strokeEnd = CGFloat(menuBarLiveActivity.progress)
        indicatorView.layer?.addSublayer(progress)

        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)

        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.alignmentMode = .left
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        textLayer.font = ctFont
        textLayer.fontSize = font.pointSize
        textLayer.frame = CGRect(
            x: indicatorFrame.maxX + spacing,
            y: (liveActivityHeight - textSz.height)/2,
            width: textSz.width,
            height: textSz.height
        )

        container.addSubview(indicatorView)
        container.layer?.addSublayer(textLayer)

        button.title = ""
        button.image = nil
        button.subviews.forEach { $0.removeFromSuperview() }
        attachCentered(container, to: button)

        currentContentView = container
        liveActivityContainer = container
        progressLayer = progress
        trackLayer = track
        titleLabel = nil

        //button.toolTip = String(localized: "SIGANTURE_MANAGER_UPDATING_TT")
    }

    private func attachCentered(_ view: NSView, to button: NSStatusBarButton) {
        view.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            view.widthAnchor.constraint(equalToConstant: view.frame.width),
            view.heightAnchor.constraint(equalToConstant: view.frame.height)
        ])
    }

    private func updateProgress(to value: CGFloat) {
        if menuBarLiveActivity.showLiveActivity {
            if progressLayer == nil { showLiveActivityView() }
            if progressLayer == nil {
                Logger.shared.log(position: "MenuBarController.updateProgress", type: "CRITICAL", content: "Progress layer is nil after attempting to show live activity")
            }
            progressLayer?.strokeEnd = max(0.0, min(1.0, value))
        }
    }

    func showLiveActivity(_ show: Bool) {
        DispatchQueue.main.async {
            self.menuBarLiveActivity.showLiveActivity = show
            if !show {
                // auf Icon zurückspringen
                self.applyStatus(self.menuBarLiveActivity.status)
            }
        }
    }

    func setLiveActivityProgress(_ value: Double) {
        DispatchQueue.main.async {
            self.menuBarLiveActivity.progress = value
        }
    }

    func setIcon(state: MenuBarIconState, toolTip: String) {
        DispatchQueue.main.async {
            switch state {
            case .ok:       self.menuBarLiveActivity.status = .ok
            case .updating: self.menuBarLiveActivity.status = .updating
            case .error:    self.menuBarLiveActivity.status = .error
            }

            if !self.menuBarLiveActivity.showLiveActivity {
                self.applyStatus(self.menuBarLiveActivity.status)
            }
            self.statusItem.button?.toolTip = toolTip
        }
    }
}

