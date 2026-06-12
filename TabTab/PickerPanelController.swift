import AppKit
import SafariServices

final class PickerPanelController: NSWindowController {
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private var tabs: [TabSnapshot] = []
    private var selectedIndex = 0
    private var windowID: String?

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: panel)
        configureContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureContent() {
        guard let contentView = window?.contentView else { return }

        let effect = NSVisualEffectView()
        effect.material = .hudWindow
        effect.state = .active
        effect.blendingMode = .behindWindow
        effect.translatesAutoresizingMaskIntoConstraints = false
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 12

        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 28
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.delegate = self
        tableView.dataSource = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
        column.width = 380
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        effect.addSubview(scrollView)
        contentView.addSubview(effect)
        effect.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            effect.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            effect.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            effect.topAnchor.constraint(equalTo: contentView.topAnchor),
            effect.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: effect.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: effect.trailingAnchor, constant: -12),
            scrollView.topAnchor.constraint(equalTo: effect.topAnchor, constant: 12),
            scrollView.bottomAnchor.constraint(equalTo: effect.bottomAnchor, constant: -12),
        ])
    }

    func open(for windowID: String, backward: Bool) {
        self.windowID = windowID
        guard let history = TabHistoryStore.window(for: windowID) else { return }

        tabs = history.mruTabs.reversed()
        guard !tabs.isEmpty else { return }

        selectedIndex = min(1, tabs.count - 1)
        if backward {
            selectedIndex = max(0, selectedIndex - 1)
        }

        tableView.reloadData()
        selectRow(selectedIndex)
        positionNearMouse()
        window?.orderFrontRegardless()
    }

    func step(backward: Bool) {
        guard !tabs.isEmpty else { return }
        if backward {
            selectedIndex = max(0, selectedIndex - 1)
        } else {
            selectedIndex = min(tabs.count - 1, selectedIndex + 1)
        }
        selectRow(selectedIndex)
    }

    func commitSelection() {
        guard let windowID, tabs.indices.contains(selectedIndex) else {
            dismissPicker()
            return
        }
        let tabID = tabs[selectedIndex].id
        Task {
            _ = try? await SFSafariApplication.dispatchMessage(
                withName: TabTabConstants.ExtensionCommand.activateTab.rawValue,
                toExtensionWithIdentifier: TabTabConstants.extensionBundleID,
                userInfo: ["tabID": tabID, "windowID": windowID]
            )
            await MainActor.run {
                self.dismissPicker()
            }
        }
    }

    func dismissPicker() {
        window?.orderOut(nil)
        tabs = []
        windowID = nil
    }

    private func selectRow(_ index: Int) {
        guard tabs.indices.contains(index) else { return }
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView.scrollRowToVisible(index)
    }

    private func positionNearMouse() {
        let mouse = NSEvent.mouseLocation
        var frame = window?.frame ?? .zero
        frame.origin = NSPoint(x: mouse.x - frame.width / 2, y: mouse.y - frame.height - 24)

        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main {
            let visible = screen.visibleFrame
            frame.origin.x = min(max(frame.origin.x, visible.minX + 8), visible.maxX - frame.width - 8)
            frame.origin.y = min(max(frame.origin.y, visible.minY + 8), visible.maxY - frame.height - 8)
        }

        window?.setFrame(frame, display: true)
    }
}

extension PickerPanelController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        tabs.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("cell")
        let view = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView ?? {
            let cell = NSTableCellView()
            cell.identifier = identifier
            let field = NSTextField(labelWithString: "")
            field.lineBreakMode = .byTruncatingTail
            field.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(field)
            cell.textField = field
            NSLayoutConstraint.activate([
                field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                field.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                field.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            ])
            return cell
        }()

        view.textField?.stringValue = tabs[row].displayTitle
        view.textField?.font = row == selectedIndex
            ? .systemFont(ofSize: 13, weight: .semibold)
            : .systemFont(ofSize: 13)
        return view
    }
}
