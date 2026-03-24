import Foundation
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct AudioSearchResult {
    var title: String
    var artist: String
}

@available(iOS 26.0, *)
@Generable
struct AudioSearchingResult {
    @Guide(description: "Top 10 music list with the highest keyword match rate", .maximumCount(5))
    var audioResults: [AudioSearchResult]
}

@available(iOS 26.0, *)
final class AudioSearcherModel {
    private var sessions: [LanguageModelSession] = []
    private let inst: String = {
        let url = Bundle.main.url(forResource: "inst", withExtension: "txt")!
        let text = try! String(contentsOf: url, encoding: .utf8)
        return text
    }()

    func search(input: String) async -> AudioSearchingResult {
        let session = LanguageModelSession(instructions: inst)
        sessions.append(session)

        do {
            let result = try await session.respond(
                to: input,
                generating: AudioSearchingResult.self,
                options: GenerationOptions(sampling: .greedy)
            )

            var ids: [Int] = []
            sessions.enumerated()
                .forEach { i, _ in
                    if !sessions[i].isResponding {
                        ids.append(i)
                    }
                }
            sessions.remove(atOffsets: .init(ids))

            return result.content
        } catch {
            myLog("error: \(error.localizedDescription)")
            return AudioSearchingResult(audioResults: [])
        }

    }

    func newContextualSession(with originalSession: LanguageModelSession) -> LanguageModelSession {
        let allEntries = originalSession.transcript
        let condensedEntries = [allEntries.first, allEntries.last].compactMap { $0 }
        let condensedTranscript = Transcript(entries: condensedEntries)
        let newSession = LanguageModelSession(transcript: condensedTranscript)
        newSession.prewarm()
        return newSession
    }
}
