import XCTest

final class MovieQuizUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws { // Вызывается перед тестом
        try super.setUpWithError()
        
        app = XCUIApplication()
        app.launch()
        
        continueAfterFailure = false // Продолжать или нет, после неудачи
    }
    
    override func tearDownWithError() throws { // Вызывается после теста
        try super.tearDownWithError()
        
        app.terminate()
        app = nil
    }
    
    func testYesButton() {
        sleep(3) // Функция sleep обеспечит задержку на 3 сек.
        
        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation // Создаем скрин UI элемента, свойство pngRep. вернет скрин в виде Data
        
        app.buttons["Yes"].tap()
        sleep(3)
        
        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation
        
        XCTAssertNotEqual(firstPosterData, secondPosterData) // Либо XCTAssertFalse(firstPoster == secondPoster)
        
        /*
         Так же можно проверять существование объекта с помощью кл. слова exist, напр. XCTAssertTrue(firstPoster.exists)
         */
    }
    
    func testNoButton() {
        sleep(3)
        
        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation
        
        app.buttons["No"].tap()
        sleep(3)
        
        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation
        
        XCTAssertNotEqual(firstPosterData, secondPosterData)
    }
    
    func testIndexLabel() {
        app.buttons["Yes"].tap()
        sleep(1)
        
        let indexLabel = app.staticTexts["Index"]
        
        XCTAssertEqual(indexLabel.label, "2/10")
        sleep(1)
        
        app.buttons["No"].tap()
        sleep(1)
        
        XCTAssertEqual(indexLabel.label, "3/10")
    }
    
    func testAlertDismiss() {
        sleep(2)
        for _ in 1...10 {
            app.buttons["Yes"].tap()
            sleep(2)
        }
        sleep(1)
        
        let alert = app.alerts["Result"]
        let button = app.buttons["Repeat"]
        
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "Сыграть ещё раз")
        XCTAssertEqual(alert.label, "Этот раунд окончен!")
        
        /*
         В учебнике использовали id только для алерта (alert.buttons.firstMatch.label)
         firstMatch возвращает текст первой кнопки
         */
        
        alert.buttons.firstMatch.tap()
        sleep(2)
        
        let indexLabel = app.staticTexts["Index"]
        
        XCTAssertFalse(alert.exists)
        XCTAssertTrue(indexLabel.label == "1/10")
        
    }
}
