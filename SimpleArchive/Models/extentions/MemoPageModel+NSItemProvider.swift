import MobileCoreServices
import UniformTypeIdentifiers

extension MemoPageModel: NSItemProviderReading {

    static var readableTypeIdentifiersForItemProvider: [String] {
        [UTType.data.identifier]
    }

    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        do {
            let pageModel = try JSONDecoder().decode(MemoPageModel.self, from: data)
            return pageModel as! Self
        } catch (let error) {
            print(error.localizedDescription)
            fatalError()
        }
    }
}

extension MemoPageModel: NSItemProviderWriting {

    static var writableTypeIdentifiersForItemProvider: [String] {
        [UTType.data.identifier]
    }

    func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping @Sendable (Data?, (any Error)?) -> Void
    ) -> Progress? {
        let progress = Progress(totalUnitCount: 100)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            progress.completedUnitCount = 100
            completionHandler(data, nil)
        } catch (let error) {
            print(error.localizedDescription)
            completionHandler(nil, error)
        }
        return progress
    }
}
