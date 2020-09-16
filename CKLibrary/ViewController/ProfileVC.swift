//
//  ProfileVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/25.
//

import UIKit
import CoreData
import Kingfisher

class ProfileVC: UIViewController {
    var window: UIWindow?
    private lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    let border = CALayer()
    
    //table empty message view
    let emptyMessageView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        setprofile()
        
        self.logoutButton.layer.cornerRadius = 8
        if let shadowColor = UIColor(named: "TopBarShadowColor") { self.border.backgroundColor = shadowColor.cgColor }
        self.border.opacity = 0.0
        border.frame = CGRect(x: 0, y: self.navigationBarView.frame.size.height - 1, width: self.navigationBarView.frame.size.width, height: 1)
        self.navigationBarView.layer.addSublayer(border)
        
        
        self.tableView.tableFooterView = UIView ()
        
        //empty table message
        emptyMessageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50)
        let emptyMessageLabel = UILabel()
        emptyMessageLabel.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 50)
        emptyMessageLabel.text = "저장한 책이 없습니다."
        emptyMessageLabel.font = UIFont(name: "NanumSquareRoundOTFR", size: 15)
        emptyMessageLabel.textAlignment = .center
        emptyMessageLabel.textColor = UIColor(named: "LabelThird")
        emptyMessageView.addSubview(emptyMessageLabel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if idLabel.text != UserDefaults.standard.value(forKey: "name") as? String {
            setprofile()
        }
        list = { return self.fetch() }()
        self.tableView.reloadData()
    }
    
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Liked")
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    func setprofile() {
        //check logined
        if UserDefaults.exists(key: "id") && UserDefaults.exists(key: "password") && UserDefaults.exists(key: "name") {
            //information exist: set profile
            if let name = UserDefaults.standard.value(forKey: "name") as? String {
                nameLabel.text = name
            }
            if let id = UserDefaults.standard.value(forKey: "id") as? String {
                idLabel.text = id
            }
        } else {
            //information dosn't exist:
            self.logoutButton.setTitle("로그인", for: .normal)
        }
        
        
    }

    @IBAction func logoutButtonAction(_ sender: UIButton) {
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
    
}



extension ProfileVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailView = self.storyboard?.instantiateViewController(withIdentifier: "BookDetailVC") as? BookDetailVC else {
            return
        }
        let book = self.list[indexPath.row]
        let title = book.value(forKey: "title") as? String
        let author = book.value(forKey: "author") as? String
        let cno = book.value(forKey: "cno") as? String
        
        detailView.cno = cno
        detailView.bookTitle = title
        detailView.author = author
        show(detailView, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
            let book = self.list[indexPath.row]
            if self.delete(object: book) {
                self.list.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                
            }
            completionHandler(true)
        }
        //deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.title = "제거"
        deleteAction.backgroundColor = .systemRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
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


extension ProfileVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        headerView.backgroundColor = UIColor(named: "BackgroundColor")
        let label = UILabel()
        label.frame = CGRect.init(x: 20, y: 5, width: 100, height: headerView.frame.height-10)
        label.text = "저장 목록"
        label.font = UIFont(name: "NanumSquareRoundOTFEB", size: 20)
        label.textColor = UIColor(named: "LabelSecond")
        headerView.addSubview(label)
        
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DispatchQueue.main.async {
            if self.list.isEmpty {
                self.tableView.tableFooterView = self.emptyMessageView
            } else {
                self.tableView.tableFooterView = UIView()
            }
        }
        return self.list.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "likedList", for: indexPath) as! LikedTableViewCell
        
        let book = self.list[indexPath.row]
        let title = book.value(forKey: "title") as? String
        let author = book.value(forKey: "author") as? String
        
        cell.titleLabel.text = title
        cell.authorLabel.text = author
        
        if let cno = book.value(forKey: "cno") {
            let url = URL(string: "http://library.ck.ac.kr/Cheetah/Shared/CoverImage?Cno=\(cno)")
            let processor = DownsamplingImageProcessor(size: cell.bookImage.bounds.size)
                |> ResizingImageProcessor(referenceSize: CGSize(width: 62.0, height: 90), mode: .aspectFill)
            cell.bookImage.kf.setImage(
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
}


extension ProfileVC {
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
