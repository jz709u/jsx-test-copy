import CoreSpotlight
import Foundation

final class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    private init() {}

    func index(_ bookings: [[String: Any]]) {
        let items: [CSSearchableItem] = bookings.compactMap { b in
            guard
                let code = b["confirmationCode"] as? String,
                let origin = b["origin"] as? String,
                let dest = b["destination"] as? String,
                let depTime = b["departureTime"] as? String
            else { return nil }

            let attrs = CSSearchableItemAttributeSet(itemContentType: "public.content")
            attrs.title = "\(origin) → \(dest)"
            attrs.contentDescription = "\(depTime) · \(code)"
            attrs.keywords = [origin, dest, code, "JSX", "flight", "booking"]

            let item = CSSearchableItem(
                uniqueIdentifier: "jsx.booking.\(code)",
                domainIdentifier: "com.jsx.bookings",
                attributeSet: attrs
            )
            item.expirationDate = .distantFuture
            return item
        }
        CSSearchableIndex.default().indexSearchableItems(items) { _ in }
    }

    func deleteAll() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: ["com.jsx.bookings"]
        ) { _ in }
    }
}
