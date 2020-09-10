//
//  CollageTableViewCell.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/09/07.
//

import UIKit

class CollageTableViewCell: UITableViewCell {


    @IBOutlet weak var bookAuthor: UILabel!
    @IBOutlet weak var bookTitle: UILabel!
    @IBOutlet weak var imageMaskView: UIView!
    @IBOutlet weak var bookImageVIew: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageMaskView.layer.cornerRadius = 3
        self.imageMaskView.layer.borderWidth = 1
        self.imageMaskView.layer.borderColor = UIColor.quaternarySystemFill.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
