import Foundation

struct PageComponentChangeObject {

    var componentIdChanged: UUID
    var title: String?
    var isMinimumHeight: Bool?

    var componentIdListRenderingOrdered: [UUID]?

    init(
        componentIdChanged: UUID,
        title: String? = nil,
        isMinimumHeight: Bool? = nil,
        componentIdListRenderingOrdered: [UUID]? = nil
    ) {
        self.componentIdChanged = componentIdChanged
        self.title = title
        self.isMinimumHeight = isMinimumHeight
        self.componentIdListRenderingOrdered = componentIdListRenderingOrdered
    }
}
