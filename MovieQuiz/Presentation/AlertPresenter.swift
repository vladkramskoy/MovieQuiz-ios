import Foundation
import UIKit

final class AlertPresenter: AlertPresenterProtocol {
    
    func showResult(quiz resultAlert: AlertModel) -> UIAlertController {
        let alertController = UIAlertController(
            title: resultAlert.title,
            message: resultAlert.message,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: resultAlert.buttonText, style: .default, handler: resultAlert.completion)
        
        alertController.addAction(action)
        
        return alertController
    }
}
