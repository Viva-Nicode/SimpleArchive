import CoreData
import Foundation

@objc(AudioComponentEntity)
public class AudioComponentEntity: MemoComponentEntity {
    
    override func convertToModel() -> any PageComponent {
        let audioComponent = AudioComponent(
            id: self.id,
            renderingOrder: self.renderingOrder,
            isMinimumHeight: self.isMinimumHeight,
            creationDate: self.creationDate,
            title: self.title,
            contents: self.convertToContents()
        )

        return audioComponent
    }

    override func updatePageComponentEntityContents(
        in ctx: NSManagedObjectContext,
        componentModel: any PageComponent
    ) {
        if let audioComponent = componentModel as? AudioComponent,
            let mostRecentAction = audioComponent.actions.last
        {
            switch mostRecentAction {
                case .appendAudio(let appendedIndices, let tracks):
                    let audioEntities = self.mutableOrderedSetValue(forKey: "audios")

                    for (index, audioTrack) in zip(appendedIndices, tracks).sorted(by: { $0.0 < $1.0 }) {
                        let audioEntity = AudioComponentTrackEntity(context: ctx)

                        audioEntity.id = audioTrack.id
                        audioEntity.title = audioTrack.title
                        audioEntity.artist = audioTrack.artist
                        audioEntity.createData = audioTrack.createData
                        audioEntity.fileExtension = audioTrack.fileExtension.rawValue
                        audioEntity.thumbnail = audioTrack.thumbnail
                        audioEntity.lyrics = audioTrack.lyrics

                        audioEntities.insert(audioEntity, at: index)
                    }

                case .removeAudio(let removedAudioID):
                    let fetch = AudioComponentTrackEntity.findTrackByID(removedAudioID)
                    if let trackEntity = try? ctx.fetch(fetch).first {
                        ctx.delete(trackEntity)
                    }

                case .applyAudioMetadata(let audioID, let metadata):
                    let fetch = AudioComponentTrackEntity.findTrackByID(audioID)
                    if let trackEntity = try? ctx.fetch(fetch).first {
                        if let title = metadata.title {
                            trackEntity.title = title
                        }
                        if let artist = metadata.artist {
                            trackEntity.artist = artist
                        }
                        if let thumbnail = metadata.thumbnail {
                            trackEntity.thumbnail = thumbnail
                        }
                        if let lyrics = metadata.lyrics {
                            trackEntity.lyrics = lyrics
                        }
                    }

                    if self.sortBy == AudioTrackSortBy.name.rawValue {
                        let audioEntities = self.mutableOrderedSetValue(forKey: "audios")
                        let audioEntityList = audioEntities.array
                            .map { $0 as! AudioComponentTrackEntity }
                            .sorted(by: { $0.title < $1.title })
                        audioEntities.removeAllObjects()
                        audioEntityList.forEach { audioEntities.add($0) }
                    }

                case .sortAudioTracks(let sortBy):
                    self.sortBy = sortBy.rawValue
                    let audioEntities = self.mutableOrderedSetValue(forKey: "audios")

                    switch sortBy {
                        case .name:
                            // NSSortDescriptor를 이용한 정렬과 sorted가 다국어 정렬순서가 다름.
                            // NSSortDescriptor : 영어 -> 한국어 -> 일본어
                            // sorted : 영어 -> 일본어 -> 한국어
                            let audioEntityList = audioEntities.array
                                .map { $0 as! AudioComponentTrackEntity }
                                .sorted(by: { $0.title < $1.title })

                            audioEntities.removeAllObjects()
                            audioEntityList.forEach { audioEntities.add($0) }

                        case .createDate:
                            let sortDescriptor = NSSortDescriptor(key: "createData", ascending: false)
                            audioEntities.sort(using: [sortDescriptor])

                        default:
                            break
                    }

                case .moveAudioOrder(let src, let des):
                    let audioEntities = self.mutableOrderedSetValue(forKey: "audios")
                    let fromIndexSet = IndexSet(integer: src)

                    audioEntities.moveObjects(at: fromIndexSet, to: des)
                    self.sortBy = AudioTrackSortBy.manual.rawValue
            }
        }
    }
    
    private func convertToContents() -> AudioComponentContents {
        var contents = AudioComponentContents()
        contents.sortBy = .init(rawValue: self.sortBy)!

        let audioEntities = self.mutableOrderedSetValue(forKey: "audios")
        let audioList = audioEntities.array as! [AudioComponentTrackEntity]

        contents.tracks = audioList.map {
            AudioTrack(
                id: $0.id,
                title: $0.title,
                artist: $0.artist,
                thumbnail: $0.thumbnail,
                lyrics: $0.lyrics,
                fileExtension: .init(rawValue: $0.fileExtension)!,
                createData: $0.createData)
        }

        return contents
    }
}
