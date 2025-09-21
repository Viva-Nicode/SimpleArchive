import Combine
import Foundation

struct MemoPageCoreDataRepository: MemoPageCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
    }

    func fixPages(pageIds: [UUID]) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in

            guard let fixedDirectoryID = SystemDirectories.fixedFileDirectory.getId() else { return }

            let fetchFixedDirectoryEntityRequest = MemoDirectoryEntity.findDirectoryEntityById(id: fixedDirectoryID)
            let fetchFixedDirectoryEntityResult = try ctx.fetch(fetchFixedDirectoryEntityRequest)

            for pageId in pageIds {
                let fetchRequest = MemoPageEntity.findPageById(id: pageId)
                let fetchResult = try ctx.fetch(fetchRequest)

                fetchResult.first!.containingDirectory.removeFromPages(fetchResult.first!)
                fetchFixedDirectoryEntityResult.first!.addToPages(fetchResult.first!)
            }
        }
    }

    func unfixPages(parentDirectoryId: UUID, pageIds: [UUID]) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            let fetchParentDirectoryEntityRequest = MemoDirectoryEntity.findDirectoryEntityById(id: parentDirectoryId)
            let fetchParentDirectoryEntityResult = try ctx.fetch(fetchParentDirectoryEntityRequest)

            for id in pageIds {
                let fetchRequest = MemoPageEntity.findPageById(id: id)
                let fetchResult = try ctx.fetch(fetchRequest)

                fetchResult.first!.containingDirectory.removeFromPages(fetchResult.first!)
                fetchParentDirectoryEntityResult.first!.addToPages(fetchResult.first!)
            }
        }
    }
}
