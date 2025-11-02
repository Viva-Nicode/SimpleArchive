//
//  AudioComponentEntity+CoreDataProperties.swift
//  SimpleArchive
//
//  Created by Nicode . on 9/23/25.
//
//

import Foundation
import CoreData


extension AudioComponentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AudioComponentEntity> {
        return NSFetchRequest<AudioComponentEntity>(entityName: "AudioComponentEntity")
    }

    @NSManaged public var detail: String
}
