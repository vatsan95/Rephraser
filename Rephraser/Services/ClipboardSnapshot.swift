import AppKit

// MARK: - Clipboard Snapshot

/// Captures and restores the FULL clipboard state (all pasteboard item types).
/// This preserves rich text, images, files, and any other content the user had copied.
struct ClipboardSnapshot {
    private let items: [[(NSPasteboard.PasteboardType, Data)]]
    let changeCount: Int
    let isEmpty: Bool

    /// Capture the current clipboard state
    static func capture() -> ClipboardSnapshot {
        let pb = NSPasteboard.general
        var allItems: [[(NSPasteboard.PasteboardType, Data)]] = []

        for item in pb.pasteboardItems ?? [] {
            var typeDataPairs: [(NSPasteboard.PasteboardType, Data)] = []
            for type in item.types {
                if let data = item.data(forType: type) {
                    typeDataPairs.append((type, data))
                }
            }
            if !typeDataPairs.isEmpty {
                allItems.append(typeDataPairs)
            }
        }

        return ClipboardSnapshot(
            items: allItems,
            changeCount: pb.changeCount,
            isEmpty: allItems.isEmpty
        )
    }

    /// Restore the clipboard to this snapshot's state
    func restore() {
        let pb = NSPasteboard.general
        pb.clearContents()

        for typeDataPairs in items {
            let item = NSPasteboardItem()
            for (type, data) in typeDataPairs {
                item.setData(data, forType: type)
            }
            pb.writeObjects([item])
        }
    }
}
