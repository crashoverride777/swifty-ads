import UIKit

final class ConsentSelectionViewController: UITableViewController {

    // MARK: - Types

    private enum Row: CaseIterable {
        case EEA
        case notEEA
        case disabled

        var title: String {
            switch self {
            case .EEA:
                return "Inside EEA (GDPR)"
            case .notEEA:
                return "Outside EEA (no GDPR)"
            case .disabled:
                return "Disabled"
            }
        }
    }

    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType
    private let rows = Row.allCases
    private var selectedRow: (SwiftyAdsEnvironment.ConsentConfiguration.Geography) -> Void

    // MARK: - Initialization

    init(swiftyAds: SwiftyAdsType, selectedRow: @escaping (SwiftyAdsEnvironment.ConsentConfiguration.Geography) -> Void) {
        self.swiftyAds = swiftyAds
        self.selectedRow = selectedRow
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

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
        switch row {
        case .EEA:
            selectedRow(.EEA)
        case .notEEA:
            selectedRow(.notEEA)
        case .disabled:
            selectedRow(.disabled)
        }
    }
}
