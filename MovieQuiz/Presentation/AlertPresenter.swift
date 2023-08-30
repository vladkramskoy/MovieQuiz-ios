import Foundation
import UIKit

class AlertPresenter: AlertPresenterProtocol {
    weak var delegate: AlertPresenterDelegate?
    
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
