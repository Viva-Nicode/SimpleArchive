import Foundation
import SFBAudioEngine


final class AppSandBoxDataManager {
    private var fileManager = FileManager.default
    private var musicArchiveDirectoryURL: URL

    init() {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        musicArchiveDirectoryURL = documentsDir.appendingPathComponent("SimpleArchiveMusics")
    }
	
	private func readAudioMetadata(audioURL: URL) -> AudioTrackMetadata {
		var metadata = AudioTrackMetadata()
		metadata.audioURL = audioURL

		if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: audioURL) {
			metadata.duration = audioFile.properties.duration

			if let metadataTitle = audioFile.metadata.title, !metadataTitle.isEmpty {
				metadata.title = metadataTitle
			}
			if let metadataArtist = audioFile.metadata.artist, !metadataArtist.isEmpty {
				metadata.artist = metadataArtist
			}
			if let metadataLyrics = audioFile.metadata.lyrics, !metadataLyrics.isEmpty {
				metadata.lyrics = metadataLyrics
			}
			if let metadataThumbnail = audioFile.metadata.attachedPictures(ofType: .frontCover).first {
				metadata.thumbnail = metadataThumbnail.imageData
			} else if let metadataOtherThumbnail = audioFile.metadata.attachedPictures(ofType: .other).first {
				metadata.thumbnail = metadataOtherThumbnail.imageData
			}
		}
		return metadata
	}

	func readAllAudioMetadata() -> [AudioTrackMetadata] {
		var results: [AudioTrackMetadata] = []

		do {
			let fileURLs = try fileManager.contentsOfDirectory(
				at: musicArchiveDirectoryURL,
				includingPropertiesForKeys: [.isRegularFileKey],
				options: [.skipsHiddenFiles]
			)

			let audioExtensions = ["mp3", "wav", "m4a", "aac"]

			for fileURL in fileURLs {
				let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])

				guard resourceValues.isRegularFile == true else { continue }
				guard audioExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }

				let metadata = readAudioMetadata(audioURL: fileURL)
				results.append(metadata)
			}

		} catch {
			print("에러 발생: \(error)")
		}

		return results
	}
	
	func totalAudioFileSize() -> Int64 {
		var totalSize: Int64 = 0

		let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "caf"]

		if let enumerator = fileManager.enumerator(
			at: musicArchiveDirectoryURL,
			includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
			options: [.skipsHiddenFiles]
		) {
			for case let fileURL as URL in enumerator {
				do {
					let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])

					guard values.isRegularFile == true else { continue }
					guard audioExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }

					totalSize += Int64(values.fileSize ?? 0)
				} catch {
					print("파일 읽기 실패: \(fileURL.lastPathComponent)")
				}
			}
		}

		return totalSize
	}
}
