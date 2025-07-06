//
//  Item.swift
//  BoardCap AI
//
//  Created by Abdul Moiz on 25/6/25.
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
