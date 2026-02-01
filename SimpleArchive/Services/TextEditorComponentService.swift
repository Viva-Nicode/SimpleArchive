import Combine
import Foundation

final class TextEditorComponentInteractor {
    private var textEditorComponent: TextEditorComponent
    private let memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType

    init(
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        textEditorComponent: TextEditorComponent
    ) {
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.textEditorComponent = textEditorComponent
    }

    func saveTextEditorComponentContentsChange(contents: String) {
        let action = makeTextEditActionFromContentsDiff(
            originContents: textEditorComponent.componentContents,
            editedContents: contents)
        textEditorComponent.componentContents = contents
        textEditorComponent.setCaptureState(to: .needsCapture)
        textEditorComponent.actions.append(action)
        memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: textEditorComponent)
    }

    func undoTextEditorComponentContents() -> String? {
        guard let action = textEditorComponent.actions.popLast() else { return nil }
        let currentContents = textEditorComponent.componentContents
        let undidText = undoingText(action: action, contents: currentContents)

        textEditorComponent.componentContents = undidText
        memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: textEditorComponent)
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
}
