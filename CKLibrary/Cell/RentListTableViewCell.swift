//
//  RentListTableViewCell.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/25.
//

import UIKit

class RentListTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImageView: UIView!
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
