import Foundation
import UIKit

protocol AlertPresenterProtocol {
    func showResult(quiz result: AlertModel) -> UIAlertController
}
