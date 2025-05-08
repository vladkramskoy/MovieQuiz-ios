import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func show(quiz step: QuizStepViewModel)
    
    func highlightImageBorder(isCorrect: Bool, border: Bool)

    func showLoadingIndicator()
    func hideLoadingIndicator()

    func enableButtons(enable: Bool)
    
    func showNetworkError(message: String)
}
