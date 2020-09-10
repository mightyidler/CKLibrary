//
//  CollageTableVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/09/06.
//

import UIKit
import Kingfisher

class CollageTableVC: UIViewController {
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    
    var bestBooks: [book] = []
    var newBooks: [book] = []
    var recBooks: [book] = []
    var contentList: [String] = []
    
    var selectedCollage: Int!
    var selectedBooks: [book] = []
    
    let border = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.tableFooterView = UIView ()
        textField.tintColor = .clear
        self.createPickerView()
        self.dismissPickerView()
        self.tableView.reloadData()
        
        if let borderColor = UIColor(named: "TopBarShadowColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.navigationBar.frame.size.height - 1, width: self.navigationBar.frame.size.width, height: 1)
        self.navigationBar.layer.addSublayer(border)
        
        switch selectedCollage {
        case 0:
            selectedBooks = bestBooks
        case 1:
            selectedBooks = newBooks
        case 2:
            selectedBooks = recBooks
        default:
            break
        }
        self.textField.text = self.contentList[selectedCollage]
    }
    
    @objc func pullToRefresh(_ sender: Any) {
        self.reloadTable()
    }

    func reloadTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func previewButtonClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func createPickerView() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.backgroundColor = UIColor(named: "BackgroundColor")
        pickerView.selectRow(selectedCollage, inComponent: 0, animated: true)
        textField.inputView = pickerView
    }

    func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        toolBar.backgroundColor = UIColor(named: "BackgroundColor")
        let button = UIBarButtonItem(title: "확인", style: .plain, target: self, action: #selector(self.action))
        button.tintColor = UIColor(named: "LabelSecond")
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([flexSpace,  button], animated: true)
        toolBar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolBar
    }
    
    @objc func action() {
        self.tableView.reloadData()
        self.tableView.setContentOffset(CGPoint.zero, animated: false)
        view.endEditing(true)
    }
}


extension CollageTableVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailView = self.storyboard?.instantiateViewController(withIdentifier: "BookDetailVC") as? BookDetailVC else {
            return
        }
        let book = self.selectedBooks[indexPath.row]
        let title = book.title
        let author = book.author
        let cno = book.cno
        
        detailView.cno = cno
        detailView.bookTitle = title
        detailView.author = author
        show(detailView, sender: indexPath)
    }
}

extension CollageTableVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollageCell", for: indexPath) as! CollageTableViewCell
        switch selectedCollage {
        case 0:
            selectedBooks = bestBooks
        case 1:
            selectedBooks = newBooks
        case 2:
            selectedBooks = recBooks
        default:
            break
        }
        
        if let title = cell.bookTitle {
            title.text = self.selectedBooks[indexPath.row].title
        }
        if let author = cell.bookAuthor {
            author.text = self.selectedBooks[indexPath.row].author
        }
        if let image = cell.bookImageVIew {
            let cno = self.selectedBooks[indexPath.row].cno
            let url = URL(string: "http://library.ck.ac.kr/Cheetah/Shared/CoverImage?Cno=\(cno)")
            let processor = DownsamplingImageProcessor(size: image.bounds.size)
                |> ResizingImageProcessor(referenceSize: CGSize(width: 62.0, height: 90), mode: .aspectFill)
            image.kf.setImage(
                with: url,
                placeholder: UIImage(named: "placeholderImage"),
                options: [
                    .processor(processor),
                    .transition(.fade(0.1)),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                    
                ])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }
    }
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }
}


extension CollageTableVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return contentList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return contentList[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        textField.text = contentList[row]
        self.selectedCollage = row
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
}


extension CollageTableVC {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView {
            searchBarCheck(contentOffset: scrollView.contentOffset.y)
        }
    }
    func searchBarCheck(contentOffset: CGFloat) {
        if contentOffset < 20.0 {
            //is top
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.border.opacity = 0.0
            })
        } else {
            //is not top
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.border.opacity = 1.0
            })
        }
    }
}
