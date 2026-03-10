import Combine
import Foundation

protocol MemoComponentCoreDataRepositoryType {
    @discardableResult
    func createComponentEntity(parentPageID: UUID, component: any PageComponent) -> AnyPublisher<Void, Error>

    @discardableResult
    func updateComponentContentChanges(modifiedComponent: any PageComponent, snapshot: any ComponentSnapshotType)
        -> AnyPublisher<Void, any Error>
	
	@discardableResult
	func updateComponentContentChanges(modifiedComponent: any PageComponent)
		-> AnyPublisher<Void, any Error>

    func updateComponentFolding(componentID: UUID, isFolding: Bool)

    func updateComponentName(componentID: UUID, newName: String)

    func updateComponentOrdered(componentID: UUID, renderingOrdered: [UUID])

    func removeComponentEntity(componentID: UUID)

    func updateComponentSnapshotInfo(componentID: UUID, snapshot: any ComponentSnapshotType)
}
