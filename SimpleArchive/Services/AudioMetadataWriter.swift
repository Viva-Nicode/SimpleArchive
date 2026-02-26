import Foundation
import SFBAudioEngine

protocol AudioMetadataWriterType {
    func saveMetaDataWritingTask(trackID: UUID, audioURL: URL)
    func removeMetaDataWritingTask(trackID: UUID)
    func writeSavedMetaDataOnAudioFile(audioTracks: [AudioTrack])
    func writeMetaDataOnAudioFile(audioTrack: AudioTrack, url: URL)
}

final class AudioMetadataWriter: AudioMetadataWriterType {
    private let metaDataWritingTaskQueue = DispatchQueue(label: "SimpleArchive.AudioMetadataWriting", qos: .background)
    private let userDefaults = UserDefaults.standard
    private let taskKey = "AudioMetadataWriteBackCache"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()
    private struct MetaDataWritingInfo: Codable {
        let audioID: UUID
        let audioUrlString: String

        init(audioID: UUID, audioUrl: URL) {
            self.audioID = audioID
            self.audioUrlString = "\(audioUrl)"
        }
    }

    func saveMetaDataWritingTask(trackID: UUID, audioURL: URL) {
        metaDataWritingTaskQueue.sync {
            var tasks = loadTasks()
            tasks[trackID] = MetaDataWritingInfo(audioID: trackID, audioUrl: audioURL)
            saveTasks(tasks)
        }
    }

    func removeMetaDataWritingTask(trackID: UUID) {
        metaDataWritingTaskQueue.sync {
            var tasks = loadTasks()
            tasks.removeValue(forKey: trackID)
            saveTasks(tasks)
        }
    }

    func writeSavedMetaDataOnAudioFile(audioTracks: [AudioTrack]) {
        metaDataWritingTaskQueue.sync {
            lock.lock()
            defer { lock.unlock() }

            let savedWritingTasks = loadTasks()

            if savedWritingTasks.isEmpty {
                myLog("No metadata required for writing")
                return
            }

            var wroteAudioTrackIds = Set<UUID>()

            for (audioTrackID, savedTaskInfo) in savedWritingTasks {
                if let trackNeededWriting = audioTracks.first(where: { $0.id == audioTrackID }),
                    let audioURL = URL(string: savedTaskInfo.audioUrlString)
                {
                    if writeOnFile(audioTrack: trackNeededWriting, trackURL: audioURL) {
                        myLog("\(trackNeededWriting.title) : Write Complete")
                        wroteAudioTrackIds.insert(audioTrackID)
                    }
                }
            }

            if !wroteAudioTrackIds.isEmpty {
                var latestTasks = loadTasks()
                wroteAudioTrackIds.forEach { latestTasks.removeValue(forKey: $0) }
                saveTasks(latestTasks)
            }
        }
    }

    func writeMetaDataOnAudioFile(audioTrack: AudioTrack, url: URL) {
        metaDataWritingTaskQueue.sync { _ = writeOnFile(audioTrack: audioTrack, trackURL: url) }
    }

    private func writeOnFile(audioTrack: AudioTrack, trackURL: URL) -> Bool {
        do {
            let audioFile = try AudioFile(readingPropertiesAndMetadataFrom: trackURL)
            let frontCoverThumbnail = AttachedPicture(imageData: audioTrack.thumbnail, type: .frontCover)
            let otherThumbnail = AttachedPicture(imageData: audioTrack.thumbnail, type: .other)
            let audioMetadata = AudioMetadata(dictionaryRepresentation: [
                .attachedPictures: [
                    frontCoverThumbnail.dictionaryRepresentation,
                    otherThumbnail.dictionaryRepresentation,
                ] as NSArray,
                .title: NSString(string: audioTrack.title),
                .artist: NSString(string: audioTrack.artist),
                .lyrics: NSString(string: audioTrack.lyrics),
                .additionalMetadata: NSDictionary(dictionary: ["SimpleArchiveAudioID": audioTrack.id]),
            ])

            audioFile.metadata = audioMetadata

            try audioFile.writeMetadata()
            return true
        } catch {
            myLog(error.localizedDescription)
            return false
        }
    }

    private func loadTasks() -> [UUID: MetaDataWritingInfo] {
        guard let rawData = userDefaults.data(forKey: taskKey) else {
            return [:]
        }

        guard let decodedTasks = try? decoder.decode([UUID: MetaDataWritingInfo].self, from: rawData) else {
            userDefaults.removeObject(forKey: taskKey)
            return [:]
        }

        return decodedTasks
    }

    private func saveTasks(_ tasks: [UUID: MetaDataWritingInfo]) {
        guard !tasks.isEmpty else {
            userDefaults.removeObject(forKey: taskKey)
            return
        }

        guard let encodedTasks = try? encoder.encode(tasks) else { return }
        userDefaults.set(encodedTasks, forKey: taskKey)
    }
}
