import Combine
import Foundation

final class TextEditorComponentInteractor {
    let pageComponent: TextEditorComponent

    var trackingSnapshot: TextEditorComponentSnapshot
    private let memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType

    init(
        textEditorComponent: TextEditorComponent,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
    ) {
        self.pageComponent = textEditorComponent
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.trackingSnapshot = TextEditorComponentSnapshot(
            contents: pageComponent.componentContents,
            description: "",
            saveMode: .automatic,
            modificationHistory: [])
    }

    func saveTextEditorComponentContentsChange(contents: String) {
        let action = makeTextEditActionFromContentsDiff(
            originContents: pageComponent.componentContents,
            editedContents: contents)

        pageComponent.componentContents = contents
        pageComponent.actions.append(action)

        trackingSnapshot.snapshotContents = contents
        trackingSnapshot.modificationHistory.append(action)

        memoComponentCoredataReposotory.updateComponentContentChanges(
            modifiedComponent: pageComponent,
            snapshot: trackingSnapshot)
    }

    func undoTextEditorComponentContents() -> String? {
        guard
            let action = pageComponent.actions.popLast(),
            let snapshotAction = trackingSnapshot.modificationHistory.popLast(),
            action == snapshotAction
        else { return nil }

        let currentContents = pageComponent.componentContents
        let undidText = undoingText(action: action, contents: currentContents)

        pageComponent.componentContents = undidText
        trackingSnapshot.snapshotContents = undidText

        memoComponentCoredataReposotory.updateComponentContentChanges(
            modifiedComponent: pageComponent,
            snapshot: trackingSnapshot)

        return undidText
    }

    private func makeTextEditActionFromContentsDiff(originContents: String, editedContents: String)
        -> TextEditorComponentAction
    {
        let originChars = Array(originContents)
        let editedChars = Array(editedContents)

        var prefix = 0
        while prefix < min(originChars.count, editedChars.count),
            originChars[prefix] == editedChars[prefix]
        {
            prefix += 1
        }

        var suffix = 0
        while suffix < min(originChars.count - prefix, editedChars.count - prefix),
            originChars[originChars.count - 1 - suffix] == editedChars[editedChars.count - 1 - suffix]
        {
            suffix += 1
        }

        let oldRange = prefix..<(originChars.count - suffix)
        let newRange = prefix..<(editedChars.count - suffix)

        let removedText = String(originChars[oldRange])
        let insertedText = String(editedChars[newRange])

        if removedText.isEmpty, !insertedText.isEmpty {
            return .insert(range: prefix..<prefix, text: insertedText)
        } else {
            return .replace(range: oldRange, from: removedText, to: insertedText)
        }
    }

    private func undoingText(action: TextEditorComponentAction, contents: String) -> String {
        switch action {
            case .insert(let range, let insertedText):
                let start = contents.index(contents.startIndex, offsetBy: range.lowerBound)
                let end = contents.index(start, offsetBy: insertedText.count)

                return contents.replacingCharacters(in: start..<end, with: "")

            case .replace(let range, let fromText, let toText):
                let start = contents.index(contents.startIndex, offsetBy: range.lowerBound)
                let end = contents.index(start, offsetBy: toText.count)

                return contents.replacingCharacters(in: start..<end, with: fromText)
        }
    }

    func saveTrackedSnapshotManual(description: String) {
        trackingSnapshot.description = description
        trackingSnapshot.saveMode = .manual
        trackingSnapshot.makingDate = Date()

        memoComponentCoredataReposotory.updateComponentSnapshotInfo(
            componentID: pageComponent.id,
            snapshot: trackingSnapshot)
		
        pageComponent.insertTrackingSnapshot(trackingSnapshot: trackingSnapshot)
        
		trackingSnapshot = TextEditorComponentSnapshot(
			contents: pageComponent.componentContents,
            description: "",
			saveMode: .automatic,
            modificationHistory: [])
    }
}
