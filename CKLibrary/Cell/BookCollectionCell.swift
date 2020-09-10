//
//  BookCollectionCell.swift
//  retailer
//
//  Created by mightyidler on 2020/06/13.
//  Copyright © 2020 mightyidler. All rights reserved.
//

import UIKit

class BookCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var bookImage: UIImageView!
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var authorText: UILabel!
    @IBOutlet weak var bookCoverView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let bookImage = bookImage {
            bookImage.layer.cornerRadius = 5
            bookImage.layer.borderWidth = 1
            bookImage.layer.borderColor = UIColor.quaternarySystemFill.cgColor
        }
    }
    
}
