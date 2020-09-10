//
//  BookDetailVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/24.
//

import UIKit
import CoreData
import SwiftSoup
import Alamofire
import Kingfisher
import SwiftyJSON
import CoreHaptics
import SWXMLHash
import Lottie

struct bookState {
    var status: String
    var callNumber: String
    var position: String
}


class BookDetailVC: UIViewController {
    
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var bookImage: UIImageView!
    @IBOutlet weak var bookImageMask: UIView!
    @IBOutlet weak var bookImageShadow: UIView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookAuthorLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var likeButton: UIButton!
    
    //navigation View seperator
    let border = CALayer()
    
    //book informations
    var cno: String!
    var bookTitle: String!
    var author: String!
    var bookstates: [bookState] = []
    var idNumber: String!
    var likedListIndex: Int!
    var bookDescription: String!
    
    //table sections
    private let sections: [String] = ["책 소개", "자료 현황"]
    
    //table spinner
    let spinner = UIActivityIndicatorView(style: .medium)
    
    //table empty message view
    let emptyMessageView = UIView()
    
    //core data
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    //haptic feedback
    let feedBack: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.feedBack.prepare()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //information init
        idNumber = UserDefaults.standard.string(forKey: "id")
        if let cno = cno, let bookTitle = bookTitle, let author = author {
            setImage(cno: cno)
            bookTitleLabel.text = bookTitle
            bookAuthorLabel.text = author
        }
        self.checkIsLiked()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchHTML()
        }
        
        //interface init
        self.bookImageMask.layer.cornerRadius = 6
        self.bookImageShadow.layer.cornerRadius = 6
        self.bookImageShadow.layer.borderWidth = 1
        self.bookImageShadow.layer.borderColor = UIColor.quaternarySystemFill.cgColor
        
        //set table spinner
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(32))
        self.tableView.tableFooterView = spinner
        
        //navigation seperator
        if let borderColor = UIColor(named: "TopBarShadowColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.navigationView.frame.size.height - 1, width: self.navigationView.frame.size.width, height: 1)
        self.navigationView.layer.addSublayer(border)

        //empty table message
        emptyMessageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50)
        let emptyMessageLabel = UILabel()
        emptyMessageLabel.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 50)
        emptyMessageLabel.text = "자료 현황이 존재하지 않습니다."
        emptyMessageLabel.font = UIFont(name: "NanumSquareRoundOTFR", size: 15)
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.textColor = UIColor(named: "LabelThird")
        emptyMessageView.addSubview(emptyMessageLabel)
    }
    
    //fetch liked list from core data
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Liked")
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    //append liked book
    func appendLikedList(title: String, author: String, cno: String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let object = NSEntityDescription.insertNewObject(forEntityName: "Liked", into: context)
        
        object.setValue(title, forKey: "title")
        object.setValue(author, forKey: "author")
        object.setValue(cno, forKey: "cno")
        
        do {
            try context.save()
            self.list.append(object)
            list = { return self.fetch() }()
            checkIsLiked()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    //remove liked book
    func removeFromLikedList() -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let object = self.list[likedListIndex]
        
        context.delete(object)
        do {
            try context.save()
            list = { return self.fetch() }()
            checkIsLiked()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    //check this book liked
    func checkIsLiked() {
        for (index, book) in self.list.enumerated() {
            let cno = book.value(forKey: "cno") as? String
            if self.cno == cno {
                self.likeButton.isSelected = true
                self.likedListIndex = index
            }
        }
        
    }
    
    //dismiss button to dismiss
    @IBAction func dismissButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //set image
    func setImage(cno: String) {
        if let imageView = self.bookImage {
            if let url = URL(string: "http://library.ck.ac.kr/Cheetah/Shared/CoverImage?Cno=\(cno)") {
                let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                    |> ResizingImageProcessor(referenceSize: CGSize(width: 82.0, height: 118.0), mode: .aspectFill)
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
    }
    
    func fetchHTML() {
        if let cno = cno {
            guard let url = URL(string: "http://library.ck.ac.kr/cheetah/api/detail?Cno=\(cno)") else { return }
            do {
                let response = try String(contentsOf: url, encoding: .utf8)
                let json = JSON.init(parseJSON: response)
                let isbn = json["ISBN"]
                if isbn.count != 0 {
                    if let isbn = isbn[0].string {
                        loadBookInformation(isbn: isbn)
                    }
                }
                
                let elements = json["RnoList"]
                if elements.count != 0 {
                    for index in 0...elements.count-1 {
                        if let status = elements[index]["CFType"].string,
                           let callNumber = elements[index]["CallNumber"].string,
                           let position = elements[index]["Position"].string {
                            let trimCallNumber = self.trimBlankChar(string: callNumber)
                            let book = bookState.init(status: status, callNumber: trimCallNumber, position: position)
                            bookstates.append(book)
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.tableView.tableFooterView = UIView()
                    }
                }
                else {
                    //empty book list
                    DispatchQueue.main.async {
                        self.tableView.tableFooterView = self.emptyMessageView
                    }
                }
            } catch {
                //error
                DispatchQueue.main.async {
                    self.tableView.tableFooterView = self.emptyMessageView
                }
            }
        }
    }
    
    func loadBookInformation(isbn : String) {
        if let str = isbn.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            let headers: HTTPHeaders = [
                "X-Naver-Client-Id": "XXvKMajKC3BZiMi9CoKo",
                "X-Naver-Client-Secret": "FaE5Ayah6c"
            ]
            AF.request("https://openapi.naver.com/v1/search/book_adv.xml?d_isbn=\(str)", headers: headers).response { response in
                switch response.result {
                case .success(let value):
                    let xml = SWXMLHash.parse(value!)
                    let description = xml["rss"]["channel"]["item"]["description"].element?.text
                    if let description = description {
                        self.bookDescription = description
                        self.tableView.reloadData()
                    }
                    break
                case .failure(let error):
                    print(error)
                    break
                }
            }
            
        }
    }
    

    @IBAction func likeButtonAction(_ sender: UIButton) {
        if self.likeButton.isSelected == false {
            if self.appendLikedList(title: self.bookTitle, author: self.author, cno: self.cno) == true {
                self.likeButton.isSelected = true
                self.feedBack.notificationOccurred(.success)
                DispatchQueue.main.async {
                    let animationView = AnimationView(name:"heart")
                    self.view.addSubview(animationView)
                    animationView.frame = CGRect(x: 0, y: 0, width: 250, height: 250)
                    animationView.center = self.view.center
                    animationView.contentMode = .scaleAspectFit
                    animationView.play { (finished) in
                        animationView.removeFromSuperview()
                    }
                }
            }
        }
        else if self.likeButton.isSelected == true {
            if self.removeFromLikedList() == true {
                self.likeButton.isSelected = false
                self.feedBack.notificationOccurred(.success)
            }
        }
        
    }
    
}

extension BookDetailVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        
        //need more time for AR
        guard false else {
            let dialogMessage = UIAlertController(title: "AR 도서 찾기는 준비중입니다.", message: nil, preferredStyle: .alert)
            let when = DispatchTime.now() + 1
            self.present(dialogMessage, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                dialogMessage.dismiss(animated: true, completion: nil)
            }
            
            return
        }
        
        guard bookstates[indexPath.row].position == "자료열람실" else {
            let dialogMessage = UIAlertController(title: "AR도서 찾기는 자료열람실만 지원합니다.", message: nil, preferredStyle: .alert)
            let when = DispatchTime.now() + 1
            self.present(dialogMessage, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                dialogMessage.dismiss(animated: true, completion: nil)
            }
            
            return
        }
        guard bookstates[indexPath.row].status == "대출가능" else {
            let dialogMessage = UIAlertController(title: "대출이 불가능한 도서입니다.", message: nil, preferredStyle: .alert)
            let when = DispatchTime.now() + 1
            self.present(dialogMessage, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: when){
                dialogMessage.dismiss(animated: true, completion: nil)
            }
            return
        }
        guard let findBookVC = self.storyboard?.instantiateViewController(withIdentifier: "FindBookVC") as? FindBookVC else {
            return
        }
        findBookVC.bookTitle = self.bookTitle
        findBookVC.bookAuthor = self.author
        findBookVC.bookCno = self.cno
        findBookVC.bookPosition = bookstates[indexPath.row].position
        findBookVC.bookCallNumber = bookstates[indexPath.row].callNumber
        show(findBookVC, sender: indexPath)
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

extension BookDetailVC: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return sections[section]
//    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        headerView.backgroundColor = UIColor(named: "BackgroundColor")
        let label = UILabel()
        label.frame = CGRect.init(x: 20, y: 5, width: 100, height: headerView.frame.height-10)
        label.text = sections[section]
        label.font = UIFont(name: "NanumSquareRoundOTFEB", size: 20)
        label.textColor = UIColor(named: "LabelSecond")
        headerView.addSubview(label)
        
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return bookstates.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let descriptionCell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath)
            if let label = descriptionCell.viewWithTag(1) as? UILabel {
                label.text = bookDescription
            }
            return descriptionCell
        } else if indexPath.section == 1 {
            let listCell = tableView.dequeueReusableCell(withIdentifier: "listCell", for: indexPath)
            if let position = listCell.viewWithTag(1) as? UILabel {
                position.text = self.bookstates[indexPath.row].position
            }
            if let callNumber = listCell.viewWithTag(2) as? UILabel {
                callNumber.text = self.bookstates[indexPath.row].callNumber
            }
            if let status = listCell.viewWithTag(3) as? UILabel {
                status.text = self.bookstates[indexPath.row].status
            }
            return listCell
        } else {
            return UITableViewCell()
        }
    }
    
    
}

extension BookDetailVC {
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
