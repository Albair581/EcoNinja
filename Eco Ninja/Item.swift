//
//  Item.swift
//  Eco Ninja
//
//  Created by Maggie on 2025/2/26.
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
