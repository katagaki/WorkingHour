//
//  Item.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/09.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
