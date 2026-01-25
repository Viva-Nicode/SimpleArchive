//
//  AudioComponentEntity+CoreDataProperties.swift
//  SimpleArchive
//
//  Created by Nicode . on 9/23/25.
//
//

import CoreData
import Foundation

extension AudioComponentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AudioComponentEntity> {
        return NSFetchRequest<AudioComponentEntity>(entityName: "AudioComponentEntity")
    }

    @nonobjc public class func findAudioComponentEntityById(id: UUID) -> NSFetchRequest<AudioComponentEntity> {
        let fetchRequest = NSFetchRequest<AudioComponentEntity>(entityName: "AudioComponentEntity")
        let fetchPredicate = NSPredicate(
            format: "%K == %@", (\AudioComponentEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @NSManaged public var audios: NSMutableOrderedSet
    @NSManaged public var sortBy: String

}
