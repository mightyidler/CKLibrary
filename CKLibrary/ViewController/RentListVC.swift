//
//  RentListVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/25.
//

import UIKit
import SwiftSoup
import Alamofire
import Kingfisher
import SwiftyJSON

struct rentedBook {
    var title: String
    var cno: String
    var dates: String
    var status: String
}

class RentListVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBarView: UIView!
    
    let border = CALayer()
    
    //table empty message view, label
    let emptyMessageView = UIView()
    let emptyMessageLabel = UILabel()
    
    let userData = UserDefaults.standard
    var currentId: String!
    var currentPw: String!
    
    var isLoading: Bool!
    
    var rentedBooks: [rentedBook] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        self.isLoading = true
        
        self.tableView.tableFooterView = UIView ()
        
        currentId = UserDefaults.standard.value(forKey: "id") as? String
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadRentList()
        }
        
        
        if let shadowColor = UIColor(named: "TopBarShadowColor") { self.border.backgroundColor = shadowColor.cgColor }
        
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.navigationBarView.frame.size.height - 1, width: self.navigationBarView.frame.size.width, height: 1)
        self.navigationBarView.layer.addSublayer(border)
        
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.alpha = 0.6
        self.tableView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl?.beginRefreshing()
        
        //empty table message view
        emptyMessageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50)
        //empty table message label
        emptyMessageLabel.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 50)
        emptyMessageLabel.text = "대여목록이 존재하지 않습니다."
        emptyMessageLabel.font = UIFont(name: "NanumSquareRoundOTFR", size: 15)
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.textColor = UIColor(named: "LabelThird")
        emptyMessageView.addSubview(emptyMessageLabel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.tableView.refreshControl?.beginRefreshing()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc func pullToRefresh(_ sender: Any) {
        self.loadRentList()
    }
    
    func loadRentList() {
        //check logined
        if UserDefaults.exists(key: "id") && UserDefaults.exists(key: "password") && UserDefaults.exists(key: "name") {
            //information exist: load rented list
            if let idNumber = userData.value(forKey: "id") as? String,
               let password = userData.value(forKey: "password")as? String {
                DispatchQueue.main.async {
                    self.rentedBooks = []
                    self.tableView.reloadData()
                }
                self.authCK(id: idNumber, pass: password, completion: getRentList)
            }
        } else {
            //information dosn't exist:
            DispatchQueue.main.async {
                self.emptyMessageLabel.text = "로그인 정보가 필요합니다."
                self.tableView.tableFooterView = self.emptyMessageView
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    func reloadTable() {
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    
    
}
extension RentListVC: UITableViewDelegate {
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
extension RentListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rentedBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let listCell = tableView.dequeueReusableCell(withIdentifier: "ListTableCell", for: indexPath)
        
        if let imageView = listCell.viewWithTag(1) as? UIImageView {
            let url = URL(string: "http://library.ck.ac.kr/Cheetah/Shared/CoverImage?Cno=\(self.rentedBooks[indexPath.row].cno)")
            let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                |> ResizingImageProcessor(referenceSize: CGSize(width: 62.0, height: 90), mode: .aspectFill)
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
        if let title = listCell.viewWithTag(2) as? UILabel {
            title.text = self.rentedBooks[indexPath.row].title
        }
        if let dates = listCell.viewWithTag(3) as? UILabel {
            dates.text = self.rentedBooks[indexPath.row].dates
        }
        
//        if let status = listCell.viewWithTag(4) as? UIButton {
//            let statusText = self.rentedBooks[indexPath.row].status
//            status.setBackgroundColor(UIColor.lightGray, for: .disabled)
//            status.setTitle(statusText, for: .normal)
//            if statusText != "연장가능" {
//                status.isEnabled = false
//            }
//        }
        
        return listCell
    }
    
    func authCK(id: String, pass: String, completion: @escaping () -> ()){
        let parameters = "loginId=\(id)&loginpwd=\(pass)"
        let postData =  parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "http://library.ck.ac.kr/Cheetah/Login/Login")!,timeoutInterval: Double.infinity)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("ASP.NET_SessionId=anzrg0w5g20f5ib40ryzg4mi", forHTTPHeaderField: "Cookie")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            if let html = String(data: data, encoding: .utf8){
                do {
                    let doc : Document = try SwiftSoup.parse(html)
                    let bestBook: Elements = try doc.select("ul.quick_right").select("li").select("a")
                    if let name = try bestBook.first()?.text() {
                        self.currentId = id
                        self.currentPw = pass
                        //login succese
                    } else {
                        //login fail
                        UserDefaults.standard.removeObject(forKey: "name")
                        UserDefaults.standard.removeObject(forKey: "id")
                        UserDefaults.standard.removeObject(forKey: "password")
                        UserDefaults.standard.synchronize()
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                        let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
                        loginVC.view.addSubview(overlayView)
                        self.view.window!.rootViewController = loginVC
                        UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                            overlayView.alpha = 0
                        }, completion: { finished in
                            overlayView.removeFromSuperview()
                        })
                    }
                    completion()
                }
                catch{
                    DispatchQueue.main.async {
                        self.tableView.tableFooterView = self.emptyMessageView
                    }
                }
                
            }
        }
        
        task.resume()
    }
    
    
    func getRentList(){
        let id: String = self.currentId
        let pass: String = self.currentPw
        let parameters = "loginId=\(id)&loginpwd=\(pass)"
        let postData =  parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "http://library.ck.ac.kr/Cheetah/Mylibrary/LentListView")!,timeoutInterval: Double.infinity)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("ASP.NET_SessionId=anzrg0w5g20f5ib40ryzg4mi", forHTTPHeaderField: "Cookie")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            if let html = String(data: data, encoding: .utf8){
                print(html)
                do {
                    let doc : Document = try SwiftSoup.parse(html)
                    let paragraph: Elements = try doc.select("div.paragraph")
                    let books = paragraph.first()
                    if let table = try books?.select("tbody").select("tr"){
                        for element in table.array() {
                            if try element.select("td").count < 2 {
                                DispatchQueue.main.async {
                                    self.tableView.tableFooterView = self.emptyMessageView
                                }
                            }else {
                                let title = try element.select("td").eq(1).text().components(separatedBy: ["=", "+", "/", ":", ",", ".", ";"]).joined()
                                let cno = try String(element.select("td").eq(1).select("a").attr("href").dropFirst(44))
                                let dates = "\(try element.select("td").eq(3).text())~\(try element.select("td").eq(4).text())"
                                let status = try element.select("td").eq(5).text()
                                let book = rentedBook.init(title: title, cno: cno, dates: dates, status: status)
                                self.rentedBooks.append(book)
                                
                            }
                            self.reloadTable()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.tableView.tableFooterView = self.emptyMessageView
                        }
                    }
                }
                catch{
                    DispatchQueue.main.async {
                        self.tableView.tableFooterView = self.emptyMessageView
                    }
                }
            }
        }
        task.resume()
    }
    
}

extension RentListVC {
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
