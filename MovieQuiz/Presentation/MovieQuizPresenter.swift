import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    private let statisticService: StatisticServiceProtocol!
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewController?
    
    private let questionAmount: Int = 10
    private var currentQuestionIndex = 0
    private var currentQuestion: QuizQuestion?
    private var correctAnswers = 0
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController as? MovieQuizViewController
        
        statisticService = StatisticServiceImplementation()
        
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
    
    // MARK: - Private functions
    
    private func didAnswer(isCorrectAnswer: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isCorrectAnswer
        
        if isCorrectAnswer {
            correctAnswers += 1
        }
        
        proceedWithAnswer(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func proceedWithAnswer(isCorrect: Bool) {

        viewController?.highlightImageBorder(isCorrect: isCorrect, border: true)
        
        viewController?.enableButtons(enable: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            viewController?.enableButtons(enable: true)
            // Убираем рамку
            viewController?.highlightImageBorder(isCorrect: isCorrect, border: false)
            // Показываем след. вопрос
            proceedToNextQuestionOrResults()
        }
    }
    
    private func proceedToNextQuestionOrResults() {
        // Блок показывает результат
        if self.isLastQuestion() {
            
            // handler
            let repeatQuiz: ((UIAlertAction) -> Void)? = repeatQuiz
            guard let handler = repeatQuiz else { return }
            
            // Вызываем метод сохранения сезультата
                self.statisticService?.store(correct: correctAnswers, total: questionAmount)
            
            // Безопасно извлекаем рекорд и счетчик игр из User Defaults
            guard let recordGet = self.statisticService?.bestGame,
                  let gameCountGet = self.statisticService?.gamesCount,
                  let totalAccuracyGet = self.statisticService?.totalAccuracy
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
}
