import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate, AlertPresenterDelegate, StatisticServiceDelegate {
    
    private let questionAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var correctAnswers = 0
    private var currentQuestionIndex = 0
    private var alertPresent: AlertPresenterProtocol?
    private var statistic: StatisticServiceProtocol?
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        
        questionFactory = QuestionFactory(delegate: self)

        questionFactory?.requestNextQuestion()
        
        // делегат алерт
        let alertPresent = AlertPresenter()
        alertPresent.delegate = self
        self.alertPresent = alertPresent
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
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Private functions
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showQuestionOrResults() {
        // Блок показывает результат
        if currentQuestionIndex == questionAmount - 1 {
            
            // handler (в замыканиях обычно использовались weak self, нужно подобное применять здесь???)
            let repeatQuiz: ((UIAlertAction) -> Void)? = repeatQuiz
            guard let handler = repeatQuiz else { return }
            
            // Вызываем метод сохранения сезультата
            statistic?.store(correct: correctAnswers, total: questionAmount)
            
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
            
            let resultAlert = AlertModel(title: "Этот раунд окончен!", message: "Ваш результат: \(correctAnswers)/\(questionAmount)\n Количество сыгранных квизов: \(gameCountGet)\n Рекорд: \(recordGet.correct)/\(recordGet.total) (\(dateString))\n Средняя точность: \(String(format: "%.2f", totalAccuracyGet))%", buttonText: "Сыграть ещё раз", completion: handler) // Экз. модели
            
            guard let alert = alertPresent?.showResult(quiz: resultAlert) else { return } // Экз. класса
            
            self.present(alert, animated: true, completion: nil) // Вызов алерта
        } else {
            // Блок показывает след. вопрос
            currentQuestionIndex += 1
            
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }

        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        // Выключаем кнопки
        self.yesButton.isEnabled = false
        self.noButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            // Активируем кнопки
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
            // Убираем рамку
            self.imageView.layer.borderWidth = 0
            // Показываем след. вопрос
            self.showQuestionOrResults()
        }
    }
    
    // repeatQuiz нужен чтобы создать handler
    private func repeatQuiz(action: UIAlertAction) {
        self.currentQuestionIndex = 0
        self.correctAnswers = 0
        self.questionFactory?.requestNextQuestion()
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionAmount)")
        return questionStep
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
