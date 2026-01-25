//
//  AudioComponentTrackEntity+CoreDataProperties.swift
//  SimpleArchive
//
//  Created by Nicode . on 12/11/25.
//
//

import CoreData
import Foundation

extension AudioComponentTrackEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AudioComponentTrackEntity> {
        return NSFetchRequest<AudioComponentTrackEntity>(entityName: "AudioComponentTrackEntity")
    }

    @nonobjc public class func findTrackByID(_ id: UUID) -> NSFetchRequest<AudioComponentTrackEntity> {
        let request = NSFetchRequest<AudioComponentTrackEntity>(entityName: "AudioComponentTrackEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return request
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var artist: String
    @NSManaged public var thumbnail: Data
    @NSManaged public var fileExtension: String
    @NSManaged public var createData: Date
    @NSManaged public var lyrics: String
    @NSManaged public var audioComponent: AudioComponentEntity
}

extension AudioComponentTrackEntity: Identifiable {

}
