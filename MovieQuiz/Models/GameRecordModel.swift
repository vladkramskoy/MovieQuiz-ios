import Foundation

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date
    
    // Этот лучше, чем другой GameRecord? Да/Нет
    func isBetterThan(_ another: GameRecord) -> Bool {
         correct > another.correct
     }
 }
