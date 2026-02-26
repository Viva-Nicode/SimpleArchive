import Combine
import UIKit

@MainActor final class MemoPageViewModel: NSObject, ViewModelType {
    typealias Input = MemoPageViewInput
    typealias Output = MemoPageViewOutput

    private var output = PassthroughSubject<Output, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var memoPage: MemoPageModel

    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType
    private var componentFactory: any ComponentFactoryType

    init(
        componentFactory: any ComponentFactoryType,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        memoPage: MemoPageModel,
    ) {
        self.componentFactory = componentFactory
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.memoPage = memoPage
        super.init()
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    @discardableResult
    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(.viewDidLoad(memoPage))

                case .willCreateNewComponent(let componentType):
                    createNewComponent(with: componentType)

                case .willRemovePageComponent(let componentIndex):
                    removeComponent(componentID: componentIndex)

                case .willChangeComponentOrder(let sourceIndex, let destinationIndex):
                    changeComponentOrder(sourceIndex: sourceIndex, destinationIndex: destinationIndex)

                case .willRenameComponent(let componentID, let newName):
                    renamePageComponent(componentID, newName)

                case .willToggleFoldingComponent(let componentID):
                    togglePageComponentFolding(componentID: componentID)

                case .willMaximizePageComponent(let componentID):
                    maximizeComponent(componentID: componentID)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func createNewComponent(with: ComponentType) {
        componentFactory.setCreator(creator: with.getComponentCreator())
        let newComponent = componentFactory.createComponent()

        memoPage.appendChildComponent(component: newComponent)
        memoComponentCoredataReposotory.createComponentEntity(parentPageID: memoPage.id, component: newComponent)
        output.send(.didAppendComponentAt(memoPage.compnentSize - 1))
    }

    private func renamePageComponent(_ componentID: UUID, _ newName: String) {
        performWithComponentAt(componentID) { index, component in
            component.title = newName
            memoComponentCoredataReposotory.updateComponentName(componentID: componentID, newName: newName)
            output.send(.didRenameComponent(componentIndex: index, newName: newName))
        }
    }

    private func togglePageComponentFolding(componentID: UUID) {
        performWithComponentAt(componentID) { index, component in
            component.isMinimumHeight.toggle()
            memoComponentCoredataReposotory.updateComponentFolding(
                componentID: componentID,
                isFolding: component.isMinimumHeight)
            output.send(
                .didToggleFoldingComponent(
                    componentIndex: index,
                    isMinimized: component.isMinimumHeight
                )
            )
        }
    }

    private func maximizeComponent(componentID: UUID) {
        performWithComponentAt(componentID) { index, component in
            if component.isMinimumHeight {
                component.isMinimumHeight.toggle()
                memoComponentCoredataReposotory.updateComponentFolding(
                    componentID: componentID,
                    isFolding: component.isMinimumHeight)
                output.send(
                    .didToggleFoldingComponent(
                        componentIndex: index,
                        isMinimized: component.isMinimumHeight
                    )
                )
            } else {
                output.send(.didMaximizePageComponent(componentIndex: index))
            }
        }
    }

    private func removeComponent(componentID: UUID) {
        if let removedComponent = memoPage.removeChildComponentById(componentID) {
            memoComponentCoredataReposotory.removeComponentEntity(componentID: removedComponent.item.id)
            output.send(.didRemovePageComponent(componentIndex: removedComponent.index))
        }
    }

    private func changeComponentOrder(sourceIndex: Int, destinationIndex: Int) {
        let componentID = memoPage.changeComponentRenderingOrder(src: sourceIndex, des: destinationIndex)
        memoComponentCoredataReposotory.updateComponentOrdered(
            componentID: componentID,
            renderingOrdered: memoPage.getComponents.map { $0.id })
    }

    private func performWithComponentAt(_ componentID: UUID, task: (Int, any PageComponent) -> Void) {
        if let pageComponent = memoPage[componentID] {
            task(pageComponent.index, pageComponent.item)
        }
    }
}

enum MemoPageViewInput {
    case viewDidLoad
    case willCreateNewComponent(ComponentType)
    case willRemovePageComponent(componentID: UUID)
    case willChangeComponentOrder(Int, Int)
    case willRenameComponent(componentID: UUID, newName: String)
    case willToggleFoldingComponent(componentID: UUID)
    case willMaximizePageComponent(componentID: UUID)
}

enum MemoPageViewOutput {
    case viewDidLoad(MemoPageModel)
    case didAppendComponentAt(Int)
    case didRemovePageComponent(componentIndex: Int)
    case didRenameComponent(componentIndex: Int, newName: String)
    case didToggleFoldingComponent(componentIndex: Int, isMinimized: Bool)
    case didMaximizePageComponent(componentIndex: Int)
}
