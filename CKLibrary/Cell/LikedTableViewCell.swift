//
//  LikedTableViewCell.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/09/02.
//

import UIKit

class LikedTableViewCell: UITableViewCell {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageMask: UIView!
    @IBOutlet weak var bookImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bookImage.layer.cornerRadius = 3
        self.bookImage.layer.borderWidth = 1
        self.bookImage.layer.borderColor = UIColor.quaternarySystemFill.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
