//
//  SearchVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/24.
//

import UIKit
import CoreData
import SwiftyJSON
import Kingfisher

struct resultBook {
    var title: String
    var author: String
    var cno: String
    var publisher: String
    var publishYear: Int
    var callNumber: String
}

class SearchVC: UIViewController, UITextFieldDelegate{
    
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dismissButton: UIButton!
    
    //navigation bar seperator
    let border = CALayer()
    
    //table spinner
    let spinner = UIActivityIndicatorView(style: .medium)
    
    //table empty message view
    let emptyMessageView = UIView()
    
    var presentPage: Int = 0
    var resultBooks: [resultBook] = []
    var isTheEnd: Bool = false
    var isSearching: Bool!
    
    //recent search list from core data
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchTextField.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.isSearching = true
        self.searchTextField.becomeFirstResponder()
        
        //set table spinner
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(32))
        self.tableView.tableFooterView = UIView()
        
        searchView.layer.cornerRadius = 8
        if let borderColor = UIColor(named: "TopBarShadowColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.navigationView.frame.size.height - 1, width: self.navigationView.frame.size.width, height: 1)
        self.navigationView.layer.addSublayer(border)
                
        //empty table message
        emptyMessageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50)
        let emptyMessageLabel = UILabel()
        emptyMessageLabel.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 50)
        emptyMessageLabel.text = "찾으시는 책이 없는 것 같아요."
        emptyMessageLabel.font = UIFont(name: "NanumSquareRoundOTFR", size: 15)
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.textColor = UIColor(named: "LabelThird")
        emptyMessageView.addSubview(emptyMessageLabel)
        
        self.searchTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
    }
    
    
    
    //init before search begin
    func searchInit() {
        self.tableView.setContentOffset(CGPoint.zero, animated: false)
        resultBooks = []
        isTheEnd = false
        presentPage = 1
    }
    
    //dismiss button to dismiss
    @IBAction func dismissButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: false)
    }
    
    //check text field is empty, then show recent search table
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text == "" {
            self.isSearching = true
            self.tableView.tableFooterView = UIView()
            self.reloadTable()
        }
    }

    //text field return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if(searchTextField.isEqual(self.searchTextField)){
            self.searchTextField.resignFirstResponder()
            if let text = self.searchTextField.text {
                self.search(text: text)
            }
        }
        return true
    }
    
    //text to search
    func search(text: String) {
        self.appendRecentSearch(text: text)
        self.isSearching = false
        self.searchInit()
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchHTMLParsing(text: text, page: self.presentPage, completion: self.reloadTable)
        }
        self.tableView.tableFooterView = spinner
    }
    
    //reload table
    func reloadTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    //parse html form cklibrary
    func fetchHTMLParsing(text: String, page: Int, completion: @escaping () -> ()){
        let urlAddress = "http://library.ck.ac.kr/cheetah/api/search?otwa1=IDX&otbool1=A&otod1=\(text)&otopt=all&stype=B&tab=basic&sp=\(page)"
        let encodeUrl = urlAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        guard let url = URL(string: encodeUrl) else { return }
        do {
            let response = try String(contentsOf: url, encoding: .utf8)
            let json = JSON.init(parseJSON: response)
            let elements = json["ListItem"]["BasicItem"]
            if elements.count != 0 {
                for index in 0...elements.count-1 {
                    if let title = elements[index]["Title"].string,
                       let author = elements[index]["Author"].string,
                       let cno = elements[index]["Cno"].string,
                       let publishYear = elements[index]["PublishYear"].int,
                       let callNumber = elements[index]["CallNumber"].string,
                       let publisher = elements[index]["Publisher"].string {
                        let title = removeSpecialChar(string: title)
                        let author = removeSpecialChar(string: author)
                        let searchResultBook = resultBook.init(title: title, author: author, cno: cno, publisher: publisher, publishYear: publishYear, callNumber: callNumber)
                        
                        resultBooks.append(searchResultBook)
                    }
                }
            } else {
                self.isTheEnd = true
                DispatchQueue.main.async {
                    self.tableView.tableFooterView = UIView()
                }
            }
            completion()
        } catch {
            DispatchQueue.main.async {
                self.tableView.tableFooterView =  self.emptyMessageView
            }
        }
        
    }  
    
    
}

//function for Core Data
extension SearchVC {
    //fetch list from core data
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SearchRecord")
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    //delete selected object from core data
    func delete(object: NSManagedObject) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        context.delete(object)
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    //append searched item to core data
    func appendRecentSearch(text: String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "SearchRecord", into: context)
        object.setValue(text, forKey: "text")
        
        //check and remove duplicate object
        for (index, recrd) in self.list.enumerated() {
            let listText = recrd.value(forKey: "text") as? String
            if text == listText {
                let record = self.list[index]
                context.delete(record)
            }
        }
        //append object
        do {
            try context.save()
            self.list.append(object)
            list = { return self.fetch() }()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    //remove selected recent search item
    @objc func removeRecentSearch(_ sender: UIButton) {
        let record = self.list[self.list.count - sender.tag - 1]
        if self.delete(object: record) {
            self.list.remove(at: sender.tag)
            list = { return self.fetch() }()
            self.tableView.reloadData()
        }
    }
    
    //remove all 
    @objc func removeAllRecentSearch(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SearchRecord")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            list = { return self.fetch() }()
            self.tableView.reloadData()
        } catch {
            context.rollback()
        }
    }
}

//table delegate
extension SearchVC: UITableViewDelegate {
    //row selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //if recent search state: select row for search
        guard !isSearching else {
            self.searchTextField.resignFirstResponder()
            let text = self.list[self.list.count - indexPath.row - 1].value(forKey: "text") as? String
            if let text = text {
                self.searchTextField.text = text
                self.search(text: text)
            }
            return
        }
        
        //if search result state: select row for show detailVC
        guard let detailView = self.storyboard?.instantiateViewController(withIdentifier: "BookDetailVC") as? BookDetailVC else {
            return
        }
        let cno = resultBooks[indexPath.row].cno
        let bookTitle = resultBooks[indexPath.row].title
        let author = resultBooks[indexPath.row].author
        detailView.cno = cno
        detailView.bookTitle = bookTitle
        detailView.author = author
        show(detailView, sender: indexPath)
    }
    
    //prepare to display cell
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //if search state: return to escape
        guard !isSearching else { return }
        
        //if result state: load more item when table reach bottom
        tableView.addLoading(indexPath) {
            if self.isTheEnd == false {
                if let text = self.searchTextField.text {
                    self.presentPage+=1
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.fetchHTMLParsing(text: text, page: self.presentPage, completion: self.reloadTable)
                    }
                }
            }
        }
    }
    
    //highlight table row
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }
    }
    
    //unhighlight table row
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }
}

//table data source
extension SearchVC: UITableViewDataSource {
    //set section header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //search state
        if isSearching {
            //header
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            headerView.backgroundColor = UIColor(named: "BackgroundColor")
            
            //header label
            let label = UILabel()
            label.frame = CGRect.init(x: 20, y: 5, width: 100, height: headerView.frame.height-10)
            label.text = "최근 검색어"
            label.font = UIFont(name: "NanumSquareRoundOTFEB", size: 17)
            label.textColor = UIColor(named: "LabelSecond")
            
            //header button for remove all recent search list
            let button = UIButton()
            button.frame = CGRect.init(x: headerView.frame.width - 84 , y: 5, width: 80, height: headerView.frame.height-10)
            button.setTitle("모두 제거", for: .normal)
            button.titleLabel?.font = UIFont(name: "NanumSquareRoundOTFB", size: 15)
            button.setTitleColor(UIColor(named: "LabelThird"), for: .normal)
            button.tintColor = UIColor.black
            button.addTarget(self, action: #selector(removeAllRecentSearch(_:)), for: .touchUpInside)
            
            headerView.addSubview(label)
            headerView.addSubview(button)
            return headerView
        }
        
        //result state
        return nil
    }
    
    //set section header height
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //serch state
        if isSearching {
            return 50
        }
        
        //result state
        return 0
    }
    
    //return table row count
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //search state: maximum 9 item for recent search list
        if isSearching {
            guard self.list.count < 9 else {
                return 9
            }
            return self.list.count
        }
        
        //result state: if result it empty show errorView and return resultBooks count
        else {
            if self.resultBooks.count == 0 {
                DispatchQueue.main.async {
                    self.tableView.tableFooterView = self.emptyMessageView
                }
            }
            return self.resultBooks.count
        }
    }
    
    //set cell for row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //search state:
        if isSearching {
            let recentSearchCell = tableView.dequeueReusableCell(withIdentifier: "recentSearchCell", for: indexPath)
            if let text = recentSearchCell.viewWithTag(1) as? UILabel {
                text.text = self.list[self.list.count - indexPath.row - 1].value(forKey: "text") as? String
                
                //hide seperator
                recentSearchCell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                recentSearchCell.directionalLayoutMargins = .zero
            }
            
            if let button = recentSearchCell.viewWithTag(2) as? UIButton {
                button.tag = indexPath.row
                button.addTarget(self, action: #selector(removeRecentSearch(_:)), for: .touchUpInside)
            }
            return recentSearchCell
        }
        
        //result state: set book inforamtions
        else if !isSearching {
            let resultCell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath)
            //check resultBook item exist in indexPath row
            if self.resultBooks.indices.contains(indexPath.row) {
                let cno = self.resultBooks[indexPath.row].cno
                if let imageView = resultCell.viewWithTag(1) as? UIImageView {
                    let url = URL(string: "http://library.ck.ac.kr/Cheetah/Shared/CoverImage?Cno=\(cno)")
                    let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                        |> ResizingImageProcessor(referenceSize: CGSize(width: 82.0, height: 118.0), mode: .aspectFill)
                    imageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(named: "BookPlaceHolder"),
                        options: [
                            .processor(processor),
                            .scaleFactor(UIScreen.main.scale),
                            .transition(.fade(0.1)),
                        ])
                }
                if let title = resultCell.viewWithTag(2) as? UILabel {
                    title.text = self.resultBooks[indexPath.row].title
                }
                if let content = resultCell.viewWithTag(3) as? UILabel {
                    content.text = "\(self.resultBooks[indexPath.row].publishYear) · \(self.resultBooks[indexPath.row].author) · \(self.resultBooks[indexPath.row].publisher)"
                }
                if let callNumber = resultCell.viewWithTag(4) as? UILabel {
                    callNumber.text = self.resultBooks[indexPath.row].callNumber
                }
            }
            return resultCell
        }
        //else state:
        return UITableViewCell()
    }
}

extension UITableView{
    func addLoading(_ indexPath:IndexPath, closure: @escaping (() -> Void)){
        if let lastVisibleIndexPath = self.indexPathsForVisibleRows?.last {
            if indexPath == lastVisibleIndexPath && indexPath.row == self.numberOfRows(inSection: 0) - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    closure()
                    
                }
            }
        }
    }
}

extension SearchVC {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBarCheck(contentOffset: scrollView.contentOffset.y)
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
