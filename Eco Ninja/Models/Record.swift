//
//  Record.swift
//  Eco Ninja
//
//  Created by Maggie on 2025/2/26.
//

import Foundation
import SwiftData

// https://www.researchgate.net/figure/Description-of-food-items-included-in-12-main-food-groups_tbl1_11757308 11 food categories (fish and meat is combined)
enum Category: String, Codable, CaseIterable {
    case grains = "穀物"
    case dairy = "乳製品"
    case fruit = "水果類"
    case eggs = "雞蛋類"
    case protein = "蛋白質"
    case veggies = "蔬菜類"
    case fats = "脂肪類"
    case legumes = "堅果類"
    case sugar = "糖製品"
    case nabeverages = "無酒精飲品"
    case abeverages = "含酒精飲品"
    case medicine = "藥物"
    case makeup = "保養品"
}

@Model
final class Record {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: Category
    var exp: Date
    
    init(id: UUID = UUID(), name: String, category: Category, exp: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.exp = exp
    }
}
