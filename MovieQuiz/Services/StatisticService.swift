import Foundation

final class StatisticServiceImplementation: StatisticServiceProtocol {
    weak var delegate: StatisticServiceDelegate?
    
    func store(correct count: Int, total amount: Int) {
        
        // Сохраняем текущий результат в структуру имеющую тип GameRecord
        let currentResult = GameRecord(correct: count, total: amount, date: Date())
        
        // Получаем сохраненный рекорд
        let recordGet = bestGame
        
        // Сравниваем, если рекорд бит, перезаписываем
        if currentResult.isBetterThan(recordGet) {
            bestGame = currentResult
        }
        
        // Сохраняем кол-во вопросов и ответов
        var countCorrect = userDefaults.integer(forKey: Keys.correct.rawValue)
        var countTotal = userDefaults.integer(forKey: Keys.total.rawValue)
        countCorrect += count
        countTotal += amount
        userDefaults.set(countCorrect, forKey: Keys.correct.rawValue)
        userDefaults.set(countTotal, forKey: Keys.total.rawValue)
        
        // Ув. счетчик игр
        gamesCount += 1
    }
    
    var totalAccuracy: Double {
        get {
            let valueCorrecr = userDefaults.double(forKey: Keys.correct.rawValue)
            let valueTotal = userDefaults.double(forKey: Keys.total.rawValue)
            return valueCorrecr / valueTotal * 100
        }
    }
    
    var gamesCount: Int {
        get {
            return userDefaults.integer(forKey: Keys.gamesCount.rawValue) // возв. значение при запросе
        }
        set {
            userDefaults.set(newValue, forKey: Keys.gamesCount.rawValue) // сохр. новое значение при изменении
        }
    }
    
    // Get достает рекорд из ud, set при изменении переменной bestGame запишет это значение обратно в ud
    var bestGame: GameRecord {

        get {
            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
                  let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
                return .init(correct: 0, total: 0, date: Date())
            }

            return record
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                print("Невозможно сохранить результат")
                return
            }

            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
    
    // Более короткий способ записи в UD. Используется в bestGame
    private let userDefaults = UserDefaults.standard
    
    // Вместо обычных ключей нам предлагается использовать текущий enum, в котором указаны все сущности которые мы должны сохранить в UD
    private enum Keys: String {
        case correct, total, bestGame, gamesCount
    }
}


