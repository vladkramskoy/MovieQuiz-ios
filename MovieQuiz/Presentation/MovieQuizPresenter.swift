import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    let questionAmount: Int = 10
    var currentQuestionIndex = 0
    var currentQuestion: QuizQuestion?
    var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewController?
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    // MARK: QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
            viewController?.showNetworkError(message: message)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Functions
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionAmount)")
        return questionStep
    }
    
    func showQuestionOrResults() {
        // Блок показывает результат
        if self.isLastQuestion() {
            
            // handler (в замыканиях обычно использовались weak self, нужно подобное применять здесь???)
            let repeatQuiz: ((UIAlertAction) -> Void)? = repeatQuiz
            guard let handler = repeatQuiz else { return }
            
            // Вызываем метод сохранения сезультата
                viewController?.statistic?.store(correct: correctAnswers, total: questionAmount)
            
            // Безопасно извлекаем рекорд и счетчик игр из User Defaults
            guard let recordGet = viewController?.statistic?.bestGame,
                  let gameCountGet = viewController?.statistic?.gamesCount,
                  let totalAccuracyGet = viewController?.statistic?.totalAccuracy
            else {
                return
            }
            // Конвертируем сохраненную дату рекорда в нужный формат
            let recordDate = recordGet.date
            let dateString = recordDate.dateTimeString
            
            let resultAlert = AlertModel(title: "Этот раунд окончен!",
                                         message: """
                                         Ваш результат: \(correctAnswers)/\(questionAmount)
                                         Количество сыгранных квизов: \(gameCountGet)
                                         Рекорд: \(recordGet.correct)/\(recordGet.total) (\(dateString))
                                         Средняя точность: \(String(format: "%.2f", totalAccuracyGet))%
                                         """,
                                         buttonText: "Сыграть ещё раз",
                                         completion: handler) // Экз. модели
            
            guard let alert = viewController?.alertPresenter?.show(model: resultAlert) else { return } // Экз. класса
            
            viewController?.present(alert, animated: true, completion: nil) // Вызов алерта
        } else {
            // Блок показывает след. вопрос
            self.switchToNextQuestion()
            
            questionFactory?.requestNextQuestion()
        }
    }
    
    // repeatQuiz нужен чтобы создать handler
    func repeatQuiz(action: UIAlertAction) {
        self.restartGame()
    }
    
    func yesButtonClicked(_ sender: UIButton) {
        didAnswer(isCorrectAnswer: true)
    }
    
    func noButtonClicked(_ sender: UIButton) {
        didAnswer(isCorrectAnswer: false)
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isCorrectAnswer
        
        if isCorrectAnswer {
            correctAnswers += 1
        }
        
        viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}
