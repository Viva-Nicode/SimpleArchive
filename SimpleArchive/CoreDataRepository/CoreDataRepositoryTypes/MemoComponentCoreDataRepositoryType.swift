import Combine
import Foundation

protocol MemoComponentCoreDataRepositoryType {
    @discardableResult
    func createComponentEntity(parentPageID: UUID, component: any PageComponent) -> AnyPublisher<Void, Error>
    
    @discardableResult
    func updateComponentContentChanges(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error>
    
    func updateComponentFolding(componentID: UUID, isFolding: Bool)

    func updateComponentName(componentID: UUID, newName: String)
    
    func updateComponentOrdered(componentID: UUID, renderingOrdered: [UUID])

    func removeComponentEntity(componentID: UUID)
}
