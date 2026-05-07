import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class TextMemoContentsSummaryGeneratingModel {
    private let cannotAssistText =
        "The text is too short or does not contain content that can be summarized.\n??( ˙꒳​˙ ≡ ˙꒳​˙ )??"
    func summation(input: String) async -> String {
        if input.isEmpty { return cannotAssistText }
        let instructions = "Read the given text and concisely summarize its main topic and key points"
        let session = LanguageModelSession(instructions: instructions)
        let opt = GenerationOptions(
            sampling: .random(probabilityThreshold: 1.0),
            maximumResponseTokens: max(input.count, 600)
        )
        let summaryResult = try? await session.respond(to: input, generating: String.self, options: opt)
        if let content = summaryResult?.content {
            if content.filter({ $0.isLetter }).count <= 50 { return cannotAssistText }
            return await LanguageTranslator.translate(input: content)
        } else {
            return cannotAssistText
        }
    }
}

@available(iOS 26.0, *)
final class LanguageTranslator {
    private init() {}
    private static let instructions = "주어진 텍스트를 한글로 번역하세요"
    static func translate(input: String) async -> String {
        (try? await LanguageModelSession(instructions: instructions)
            .respond(
                to: input,
                generating: String.self,
                options: GenerationOptions(sampling: .greedy, maximumResponseTokens: Int.max)
            )
            .content) ?? "??( ˙꒳​˙ ≡ ˙꒳​˙ )??"
    }
}
