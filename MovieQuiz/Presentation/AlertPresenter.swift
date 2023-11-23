import UIKit

final class AlertPresenter: AlertPresenterProtocol {
    
    func show(model resultAlert: AlertModel) -> UIAlertController {
        let alertController = UIAlertController(
            title: resultAlert.title,
            message: resultAlert.message,
            preferredStyle: .alert)
        
        alertController.view.accessibilityIdentifier = "Result" // Создаю id для использования в UI тестах
        
        let action = UIAlertAction(title: resultAlert.buttonText, style: .default, handler: resultAlert.completion)
        
        action.accessibilityIdentifier = "Repeat" // Создаю id для использования в UI тестах
        
        alertController.addAction(action)
        
        return alertController
    }
}
