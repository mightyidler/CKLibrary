//
//  SearchTableViewCell.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/25.
//

import UIKit

class SearchTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImageView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let cellImageView = cellImageView {
            cellImageView.layer.cornerRadius = 4
            cellImageView.layer.borderWidth = 1
            cellImageView.layer.borderColor = UIColor.quaternarySystemFill.cgColor
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
