import UIKit

final class BasicCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String, accessoryType: UITableViewCell.AccessoryType) {
        textLabel?.text = title
        textLabel?.numberOfLines = 2

        self.accessoryType = accessoryType
    }
}
