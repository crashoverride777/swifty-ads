//
//  NativeAdViewController.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 21/12/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class NativeAdViewController: UICollectionViewController {

    // MARK: - Types

    enum Section: CaseIterable {
        case one
        case two
        case three
    }

    // MARK: - Properties

    private let sections = Section.allCases

    // MARK: - Init

    init() {
        let layout = UICollectionViewFlowLayout()
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        collectionView.backgroundColor = .white
        collectionView.register(NativeAdCell.self, forCellWithReuseIdentifier: String(describing: NativeAdCell.self))
        collectionView.register(NativeAdTextCell.self, forCellWithReuseIdentifier: String(describing: NativeAdTextCell.self))
    }

    // MARK: - UITableViewDelegate

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        switch section {
        case .one:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: NativeAdTextCell.self), for: indexPath)
            return cell
        case .two:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: NativeAdCell.self), for: indexPath)
            return cell
        case .three:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: NativeAdTextCell.self), for: indexPath)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NativeAdViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: collectionView.bounds.width, height: 200)
        return size
    }

}
