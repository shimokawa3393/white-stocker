//
//  Item.swift
//  WhiteStocker
//
//  Created by Shouhei Shimokawa on 2026/08/15.
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
