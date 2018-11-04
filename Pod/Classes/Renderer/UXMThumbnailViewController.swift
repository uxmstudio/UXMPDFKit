//
//  UXMThumbnailViewController.swift
//  Pods
//
//  Created by Chris Anderson on 11/14/16.
//
//

import UIKit

public protocol UXMThumbnailViewControllerDelegate : class {
    func thumbnailCollection(_ collection: UXMThumbnailViewController, didSelect page: Int)
}

open class UXMThumbnailViewController: UIViewController {
    
    var document: UXMPDFDocument!
    
    var collectionView: UICollectionView!
    
    public weak var delegate: UXMThumbnailViewControllerDelegate?
    
    private var flowLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20)
        layout.minimumLineSpacing = 20.0
        layout.minimumInteritemSpacing = 0.0
        return layout
    }

    public init(document: UXMPDFDocument) {
        super.init(nibName: nil, bundle: nil)
        self.document = document
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.collectionView.register(UXMThumbnailViewCell.self, forCellWithReuseIdentifier: "ThumbnailCell")

        self.setupUI()
    }
    
    func setupUI() {
        
        self.title = "Pages"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done",
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(UXMThumbnailViewController.tappedDone))
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = UIColor.white
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    @IBAction func tappedDone() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension UXMThumbnailViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let document = self.document else {
            return 0
        }
        return document.pageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! UXMThumbnailViewCell

        let page = indexPath.row + 1
        cell.configure(document: document, page: page)
        
        return cell
    }
}

extension UXMThumbnailViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.thumbnailCollection(self, didSelect: indexPath.row + 1)
    }
}

extension UXMThumbnailViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let bounds = document.boundsForPDFPage(indexPath.row + 1)
        return CGSize(width: 100, height: 100 / bounds.width * bounds.height)
    }
}
