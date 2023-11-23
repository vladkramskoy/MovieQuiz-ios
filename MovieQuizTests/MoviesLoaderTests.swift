import XCTest
@testable import MovieQuiz

class MoviesLoaderTests: XCTestCase {
    func testSuccessLoading() throws {
        // Given
        let stubNetworkClient = StubNetworkClient(emulatorError: false) // мы говорим, что не хотим эмулировать ошибку
        let loader = MoviesLoader(networkClient: stubNetworkClient)
        
        // When
        
        // так как функция загрузки фильмов - асинхронная, нужно ожидание
        let expectation = expectation(description: "Loading expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .success(_):
                // сравниваем данные с тем, что мы предполагали
                expectation.fulfill()
            case .failure(_):
                // мы не ожидаем, что пришла ошибка; если она появится, надо будет провалить тест
                XCTFail("Unexpected failure") // эта функция проваливает тест
            }
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testFailureLoading() throws {
        // Given
        let stubNetworkClient = StubNetworkClient(emulatorError: true) // эмулируем ошибку
        let loader = MoviesLoader(networkClient: stubNetworkClient)
        
        // When
        
        // с ожиданием думаю, аналогично
        let expectation = expectation(description: "Loading expectation")
        
        loader.loadMovies { result in
            // Then
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error) // наоборот ожидаем ошибку, завершаем тест положительно
                expectation.fulfill()
            case .success(_):
                XCTFail("Unexpected failure") // мы эмулируем ошибку, поэтому не ожидаем успешного кейса. Если таковой возникнет - проваливаем тест
            }
        }
        
        waitForExpectations(timeout: 1)
    }
}

// Создаем тестовую версию сетевого клиента
struct StubNetworkClient: NetworkRouting {
    enum TestError: Error { // тестовая ошибка
        case test
    }
    
    let emulatorError: Bool // этот параметр нужен, чтобы заглушка эмулировала либо ошибку сети, либо успешный ответ
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        if emulatorError {
            handler(.failure(TestError.test))
        } else {
            handler(.success(expectedResponce))
        }
    }
    
    private var expectedResponce: Data {
        """
                {
                   "errorMessage" : "",
                   "items" : [
                      {
                         "crew" : "Dan Trachtenberg (dir.), Amber Midthunder, Dakota Beavers",
                         "fullTitle" : "Prey (2022)",
                         "id" : "tt11866324",
                         "imDbRating" : "7.2",
                         "imDbRatingCount" : "93332",
                         "image" : "https://m.media-amazon.com/images/M/MV5BMDBlMDYxMDktOTUxMS00MjcxLWE2YjQtNjNhMjNmN2Y3ZDA1XkEyXkFqcGdeQXVyMTM1MTE1NDMx._V1_Ratio0.6716_AL_.jpg",
                         "rank" : "1",
                         "rankUpDown" : "+23",
                         "title" : "Prey",
                         "year" : "2022"
                      },
                      {
                         "crew" : "Anthony Russo (dir.), Ryan Gosling, Chris Evans",
                         "fullTitle" : "The Gray Man (2022)",
                         "id" : "tt1649418",
                         "imDbRating" : "6.5",
                         "imDbRatingCount" : "132890",
                         "image" : "https://m.media-amazon.com/images/M/MV5BOWY4MmFiY2QtMzE1YS00NTg1LWIwOTQtYTI4ZGUzNWIxNTVmXkEyXkFqcGdeQXVyODk4OTc3MTY@._V1_Ratio0.6716_AL_.jpg",
                         "rank" : "2",
                         "rankUpDown" : "-1",
                         "title" : "The Gray Man",
                         "year" : "2022"
                      }
                    ]
                  }
                """.data(using: .utf8) ?? Data()
    }
}