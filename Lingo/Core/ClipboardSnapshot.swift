import AppKit

struct ClipboardSnapshot {
    struct Item: Equatable {
        let dataByType: [NSPasteboard.PasteboardType: Data]
    }

    let items: [Item]

    static func capture(from pasteboard: NSPasteboard) -> ClipboardSnapshot {
        let items: [Item] = pasteboard.pasteboardItems?.map { item in
            let dataByType = Dictionary(uniqueKeysWithValues: item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            })
            return Item(dataByType: dataByType)
        } ?? []
        return ClipboardSnapshot(items: items)
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !items.isEmpty else { return }

        let restoredItems = items.map { snapshot -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in snapshot.dataByType {
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(restoredItems)
    }
}
