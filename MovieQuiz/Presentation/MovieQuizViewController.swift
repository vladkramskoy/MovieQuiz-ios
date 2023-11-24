import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate, StatisticServiceDelegate {
    
    private let presenter = MovieQuizPresenter()
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var correctAnswers = 0
    private var alertPresenter: AlertPresenterProtocol?
    private var statistic: StatisticServiceProtocol?
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)

        showLoadingIndicator()
        questionFactory?.loadData()
        
        // алерт и след.квиз
        let alertPresenter = AlertPresenter()
        self.alertPresenter = alertPresenter
        // делегат статистика
        let statistic = StatisticServiceImplementation()
        statistic.delegate = self
        self.statistic = statistic
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Private functions
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let alertError = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать ещё раз") { [weak self] _ in
            guard let self = self else { return }
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            showLoadingIndicator()
            questionFactory?.loadData()
        }
        
        guard let alert = alertPresenter?.show(model: alertError) else { return }
        present(alert, animated: true, completion: nil)
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showQuestionOrResults() {
        // Блок показывает результат
        if presenter.isLastQuestion() {
            
            // handler (в замыканиях обычно использовались weak self, нужно подобное применять здесь???)
            let repeatQuiz: ((UIAlertAction) -> Void)? = repeatQuiz
            guard let handler = repeatQuiz else { return }
            
            // Вызываем метод сохранения сезультата
            statistic?.store(correct: correctAnswers, total: presenter.questionAmount)
            
            // Безопасно извлекаем рекорд и счетчик игр из User Defaults
            guard let recordGet = statistic?.bestGame,
                  let gameCountGet = statistic?.gamesCount,
                  let totalAccuracyGet = statistic?.totalAccuracy
            else {
                return
            }
            // Конвертируем сохраненную дату рекорда в нужный формат
            let recordDate = recordGet.date
            let dateString = recordDate.dateTimeString
            
            let resultAlert = AlertModel(title: "Этот раунд окончен!",
                                         message: """
                                         Ваш результат: \(correctAnswers)/\(presenter.questionAmount)
                                         Количество сыгранных квизов: \(gameCountGet)
                                         Рекорд: \(recordGet.correct)/\(recordGet.total) (\(dateString))
                                         Средняя точность: \(String(format: "%.2f", totalAccuracyGet))%
                                         """,
                                         buttonText: "Сыграть ещё раз",
                                         completion: handler) // Экз. модели
            
            guard let alert = alertPresenter?.show(model: resultAlert) else { return } // Экз. класса
            
            self.present(alert, animated: true, completion: nil) // Вызов алерта
        } else {
            // Блок показывает след. вопрос
            presenter.switchToNextQuestion()
            
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }

        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        enableButtons(enable: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            enableButtons(enable: true)
            // Убираем рамку
            self.imageView.layer.borderWidth = 0
            // Показываем след. вопрос
            self.showQuestionOrResults()
        }
    }
    
    // repeatQuiz нужен чтобы создать handler
    private func repeatQuiz(action: UIAlertAction) {
        self.presenter.resetQuestionIndex()
        self.correctAnswers = 0
        self.questionFactory?.requestNextQuestion()
    }
    
    private func enableButtons(enable: Bool) {
        if enable {
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
        } else {
            self.yesButton.isEnabled = false
            self.noButton.isEnabled = false
        }
    }
   
    // MARK: - Functions
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}
