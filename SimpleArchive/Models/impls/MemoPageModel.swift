import Foundation

final class MemoPageModel: NSObject, Codable, StorageItem {

    var id: UUID
    var name: String
    var creationDate: Date
    var isSingleComponentPage: Bool
    weak var parentDirectory: MemoDirectoryModel?

    private var components: [any PageComponent]

    init(
        id: UUID = UUID(),
        name: String,
        creationDate: Date = Date(),
        isSingleComponentPage: Bool = false,
        parentDirectory: MemoDirectoryModel? = nil,
        components: [any PageComponent] = []
    ) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.components = components
        self.parentDirectory = parentDirectory
        self.isSingleComponentPage = isSingleComponentPage
        super.init()
        self.parentDirectory?.insertChildItem(item: self)
    }

    deinit { print("deinit MemoPageModel : \(name)") }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(isSingleComponentPage, forKey: .isSingleComponentPage)
        try container.encode(components.compactMap { $0 as? TextEditorComponent }, forKey: .textComponents)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.isSingleComponentPage = try container.decode(Bool.self, forKey: .isSingleComponentPage)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.components = []
        self.components.append(contentsOf: try container.decode([TextEditorComponent].self, forKey: .textComponents))
        self.parentDirectory = nil
    }

    enum CodingKeys: String, CodingKey {
        case id, creationDate, name, textComponents, isSingleComponentPage
    }

    func removeStorageItem() {
        parentDirectory?.removeChildItemByID(with: self.id)
        parentDirectory = nil
    }

    func getFileInformation() -> StorageItemInformationType {
        PageInformation(
            id: id,
            name: name,
            filePath: getFilePath(),
            created: creationDate,
            containedComponentCount: components.count)
    }

    var compnentSize: Int { components.count }

    var getComponents: [any PageComponent] { components }

    subscript(_ ID: UUID) -> OperationResultItem<any PageComponent>? {
        if let index = components.firstIndex(where: { $0.id == ID }) {
            return OperationResultItem(index: index, item: components[index])
        }
        return nil
    }

    subscript(_ index: Int) -> any PageComponent {
        components[index]
    }

    @discardableResult
    func removeChildComponentById(_ ID: UUID) -> OperationResultItem<any PageComponent>? {
        if let index = components.firstIndex(where: { $0.id == ID }) {
            return OperationResultItem(index: index, item: components.remove(at: index))
        }
        return nil
    }

    func appendChildComponent(component: any PageComponent) {
        component.renderingOrder = (components.map { $0.renderingOrder }.max() ?? -1) + 1
        components.append(component)
    }

    func changeComponentRenderingOrder(src: Int, des: Int) -> UUID {
        let movedComponent = components.remove(at: src)
        components.insert(movedComponent, at: des)
        (0..<components.count).forEach { components[$0].renderingOrder = $0 }
        return movedComponent.id
    }
}
