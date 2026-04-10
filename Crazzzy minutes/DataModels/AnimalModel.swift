import SwiftData
import Foundation

// для каждой единицы животного
@Model
class AnimalModel {
    var id = UUID()
    
    var animalType: AnimalType
    var status: AnimalStatus
    var name: String
    var number: Int
    
    var incomes: [Int]
    var expence: [Int]
    
    init(id: UUID = UUID(), animalType: AnimalType, status: AnimalStatus, name: String, number: Int, incomes: [Int], expence: [Int]) {
        self.id = id
        self.animalType = animalType
        self.status = status
        self.name = name
        self.number = number
        self.incomes = incomes
        self.expence = expence
    }
}

enum AnimalStatus: String, CaseIterable, Codable {
    case sale, dead, forMeat
}

enum AnimalType: String, CaseIterable, Codable {
    case cow, chicken, hare, sheep
    
    var asset: String {
        switch self {
        case .cow:
            "tab1-d"
        case .chicken:
            "tab2-d"
        case .hare:
            "tab3-d"
        case .sheep:
            "tab4-d"
        }
    }
}

// синглтон модель
@Model
class CategoryModel {
    var id = UUID()
    
    var expences: [AnimalType: [Int]]
    var incomes: [AnimalType: [Int]]
    
    init(id: UUID = UUID(), expences: [AnimalType : [Int]], incomes: [AnimalType : [Int]]) {
        self.id = id
        self.expences = expences
        self.incomes = incomes
    }
}

@Model
class AviaryModel {
    var id = UUID()
    var date = Date()
    var name: String
    
    var animalType: AnimalType
    @Relationship(deleteRule: .cascade) var animals: [AnimalModel]
    
    init(id: UUID = UUID(), date: Date = Date(), name: String, animalType: AnimalType, animals: [AnimalModel]) {
        self.id = id
        self.date = date
        self.name = name
        self.animalType = animalType
        self.animals = animals
    }
}
