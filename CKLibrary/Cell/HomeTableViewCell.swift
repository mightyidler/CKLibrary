//
//  HomeTableViewCell.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/31.
//

import UIKit
import SwiftSoup
import Alamofire
import Kingfisher
import SwiftyJSON

class HomeTableViewCell: UITableViewCell {

    @IBOutlet weak var tableTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var books: [book] = []
    var section: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.dataSource =  self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func reloadColelction() {
        self.collectionView.reloadData()
    }
}

extension HomeTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCollectionCell", for: indexPath) as! BookCollectionCell
        
        if let title = cell.titleText {
            title.text = books[indexPath.row].title
        }
        if let author = cell.authorText {
            author.text = books[indexPath.row].author
        }

        
        //need to check 61 * 91
        let cno = books[indexPath.row].cno
        if let imageView = cell.bookImage {
            if let url = URL(string: "http://library.ck.ac.kr/Cheetah/Shared/CoverImage?Cno=\(cno)") {
                let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                    |> ResizingImageProcessor(referenceSize: CGSize(width: 110.0, height: 159.0), mode: .aspectFill)
                
                imageView.kf.setImage(
                    with: url,
                    placeholder: UIImage(named: "placeholderImage"),
                    options: [
                        .processor(processor),
                        .transition(.fade(0.1)),
                        .scaleFactor(UIScreen.main.scale),
                        .cacheOriginalImage
                    ])
            }
        }
        return cell
    }
}
