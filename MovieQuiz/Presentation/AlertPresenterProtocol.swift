import Foundation
import UIKit

protocol AlertPresenterProtocol {
    func show(model result: AlertModel) -> UIAlertController
}
