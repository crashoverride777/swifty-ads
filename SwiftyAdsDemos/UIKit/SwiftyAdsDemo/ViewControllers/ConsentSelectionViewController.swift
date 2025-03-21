import UIKit

final class ConsentSelectionViewController: UITableViewController {

    // MARK: - Types

    enum Row: CaseIterable {
        case EEA
        case other
        case disabled

        var title: String {
            switch self {
            case .EEA:
                return "Inside EEA (GDPR)"
            case .other:
                return "Outside EEA (no GDPR)"
            case .disabled:
                return "Disabled"
            }
        }
    }

    // MARK: - Properties

    private let rows = Row.allCases
    private var selection: (Row) -> Void

    // MARK: - Initialization

    init(selection: @escaping (Row) -> Void) {
        self.selection = selection
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Consent Configuration"
        tableView.register(BasicCell.self, forCellReuseIdentifier: String(describing: BasicCell.self))
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BasicCell.self), for: indexPath) as! BasicCell
        cell.configure(title: row.title, accessoryType: .disclosureIndicator)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        selection(row)
    }
}
