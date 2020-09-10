//
//  HomeVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/31.
//

import UIKit
import SwiftSoup
import Alamofire
import SwiftyJSON
	
struct book {
    var title: String
    var author: String
    var cno: String
}

class HomeVC: UIViewController {

    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    var bestBooks: [book] = []
    var newBooks: [book] = []
    var recBooks: [book] = []
    var contentList: [String] = []
    
    //navigation bar seperator
    let border = CALayer()
    
    //table empty message view
    let emptyMessageView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchButton.layer.cornerRadius = 8

        //search bar seperator
        if let borderColor = UIColor(named: "TopBarShadowColor") { self.border.backgroundColor = borderColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.navigationView.frame.size.height - 1, width: self.navigationView.frame.size.width, height: 1)
        self.navigationView.layer.addSublayer(border)
        
        //parse from cklibrary
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchHTMLParsing(completion: self.reloadData)
        }
        
        //table refresh controller
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.alpha = 0.6
        self.tableView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl?.beginRefreshing()
        
        //empty table message
        emptyMessageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50)
        let emptyMessageLabel = UILabel()
        emptyMessageLabel.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 50)
        emptyMessageLabel.text = "리스트를 불러올 수 없습니다."
        emptyMessageLabel.font = UIFont(name: "NanumSquareRoundOTFR", size: 15)
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.textColor = UIColor(named: "LabelThird")
        emptyMessageView.addSubview(emptyMessageLabel)
    }
    
    //reload when table pull
    @objc func pullToRefresh(_ sender: Any) {
        self.reloadData()
    }
    
    //reload data and table
    func reloadData(){
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    //html parsing
    func fetchHTMLParsing(completion: @escaping () -> ()){
        let urlAddress = "http://library.ck.ac.kr/Cheetah/CKM/Index"
        guard let url = URL(string: urlAddress) else {
            DispatchQueue.main.async {
                self.tableView.tableFooterView = self.emptyMessageView
            }
            return
        }
        do {
            let html = try String(contentsOf: url, encoding: .utf8)
            let doc : Document = try SwiftSoup.parse(html)
            let bestBook: Elements = try doc.select("div.bestBook").select("#owl-bestBook").select("a")
            for element in bestBook.array() {
                let title = removeSpecialChar(string: try element.select(".book-name").text())
                let author = removeSpecialChar(string: try element.select(".book-author").text())
                let cno = try String(element.attr("href").dropFirst(44))
                let bestBook = book.init(title: title, author: author, cno: cno)
                bestBooks.append(bestBook)
            }
            
            let newBook: Elements = try doc.select("div.newBook").select("#owl-newBook").select("a")
            for element in newBook.array() {
                let title = removeSpecialChar(string: try element.select(".book-name").text())
                let author = removeSpecialChar(string: try element.select(".book-author").text())
                let cno = try String(element.attr("href").dropFirst(44))
                let newBook = book.init(title: title, author: author, cno: cno)
                newBooks.append(newBook)
            }
            
            let recBook: Elements = try doc.select("div.recBook").select("#owl-recBook").select("a")
            for element in recBook.array() {
                let title = removeSpecialChar(string: try element.select(".book-name").text())
                let author = removeSpecialChar(string: try element.select(".book-author").text())
                let cno = try String(element.attr("href").dropFirst(44))
                let recBook = book.init(title: title, author: author, cno: cno)
                recBooks.append(recBook)
            }
            self.contentList = ["이번 달 인기도서", "신규도서", "청강 20선"]
        } catch {
            DispatchQueue.main.async {
                self.tableView.tableFooterView = self.emptyMessageView
            }
        }
        completion()
        
    }

}

//table delegate
extension HomeVC: UITableViewDelegate {
    //select row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let collageVC = self.storyboard?.instantiateViewController(withIdentifier: "CollageTableVC") as? CollageTableVC else {
            return
        }
        collageVC.bestBooks = self.bestBooks
        collageVC.recBooks = self.recBooks
        collageVC.newBooks = self.newBooks
        collageVC.contentList = self.contentList
        collageVC.selectedCollage = indexPath.row
        show(collageVC, sender: indexPath)
    }
    
    //highlight row
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }
    }
    //unhighlight row
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }
}

//table data source
extension HomeVC: UITableViewDataSource {
    //row of section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentList.count
    }
    
    //set cell for row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell", for: indexPath) as! HomeTableViewCell
        cell.tableTitle.text = self.contentList[indexPath.row]
        cell.collectionView.tag = indexPath.row
        
        switch indexPath.row {
        case 0:
            cell.books = bestBooks
        case 1:
            cell.books = newBooks
        case 2:
            cell.books = recBooks
        default:
            break
        }
        
        cell.reloadColelction()
        return cell
    }
}

//collectionview delegate
extension HomeVC: UICollectionViewDelegate {
    //cell highlight
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }
    }
    
    //cell unhighlight
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }
    
    //cell selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let detailView = self.storyboard?.instantiateViewController(withIdentifier: "BookDetailVC") as? BookDetailVC else {
            return
        }
        
        switch collectionView.tag {
        case 0:
            let selectedBook = bestBooks[indexPath.row]
            detailView.cno = selectedBook.cno
            detailView.bookTitle = selectedBook.title
            detailView.author = selectedBook.author
            show(detailView, sender: indexPath)
        case 1:
            let selectedBook = newBooks[indexPath.row]
            detailView.cno = selectedBook.cno
            detailView.bookTitle = selectedBook.title
            detailView.author = selectedBook.author
            show(detailView, sender: indexPath)
        case 2:
            let selectedBook = recBooks[indexPath.row]
            detailView.cno = selectedBook.cno
            detailView.bookTitle = selectedBook.title
            detailView.author = selectedBook.author
            show(detailView, sender: indexPath)
        default:
            break
        }
    }
}

extension HomeVC {
    //call every time when scrolled
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView {
            searchBarCheck(contentOffset: scrollView.contentOffset.y)
        }
        
    }
    //check is bar at the top
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
