import UIKit

protocol ComponentFullScreenViewType {
    associatedtype ContentViewType: UIView
    func getContentView() -> ContentViewType
    func getView() -> UIView!
    var titleLabel: UILabel { get set }
    var creationDateLabel: UILabel { get set }
    var containerStackView: UIStackView { get set }
    var componentContentViewContainer: UIView { get set }
    var toolBarView: UIView { get set }
    var redCircleView: UIView { get set }
    var yellowCircleView: UIView { get set }
    var greenCircleView: UIView { get set }
    var componentInformationView: UIStackView { get set }
    var toolbarColor: UIColor? { get }
}
