//
//  RootViewController.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 21/02/2021.
//  Copyright © 2021 Dominik Ringler. All rights reserved.
//

import UIKit

final class RootViewController: UITableViewController {

    // MARK: - Types

    enum Row: CaseIterable {
        case EEA
        case notEEA

        var title: String {
            switch self {
            case .EEA:
                return "Inside EEA"
            case .notEEA:
                return "Outside EEA"
            }
        }
    }

    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType
    private let rows = Row.allCases
    private var selectedRow: (SwiftyAdsDebugGeography) -> Void

    // MARK: - Initialization

    init(swiftyAds: SwiftyAdsType, selectedRow: @escaping (SwiftyAdsDebugGeography) -> Void) {
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
        navigationItem.title = "Select Demo Geography"
        tableView.register(RootCell.self, forCellReuseIdentifier: String(describing: RootCell.self))
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
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RootCell.self), for: indexPath) as! RootCell
        cell.configure(title: row.title, accessoryType: .disclosureIndicator)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        switch row {
        case .EEA:
            selectedRow(.EEA)
            let demoSelectionViewController = DemoSelectionViewController(swiftyAds: swiftyAds, geography: .EEA)
            let navigationController = UINavigationController(rootViewController: demoSelectionViewController)
            navigationController.modalPresentationStyle = .overFullScreen
            present(navigationController, animated: true)
        case .notEEA:
            selectedRow(.notEEA)
            let demoSelectionViewController = DemoSelectionViewController(swiftyAds: swiftyAds, geography: .notEEA)
            let navigationController = UINavigationController(rootViewController: demoSelectionViewController)
            navigationController.modalPresentationStyle = .overFullScreen
            present(navigationController, animated: true)
        }
    }
}
