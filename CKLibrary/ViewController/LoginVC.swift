//
//  LoginVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/26.
//

import UIKit
import SwiftSoup
import Alamofire
import SwiftyJSON

class LoginVC: UIViewController {
    var window: UIWindow?
    
    @IBOutlet weak var idView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var loginMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        idView.layer.cornerRadius = 8
        passwordView.layer.cornerRadius = 8
        loginButton.layer.cornerRadius = 8
        
        idTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.idTextField.becomeFirstResponder()
    }
    
    //touched outside of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
    }
    
    
    //login button clicked
    @IBAction func loginButtonAction(_ sender: UIButton) {
        let isTextFieldsEmpty = (idTextField.text?.isEmpty)! || (passwordTextField.text?.isEmpty)!
        preLogin(isTextFieldsEmpty: isTextFieldsEmpty)
    }
    
    //skip login button
    @IBAction func skipLoginButton(_ sender: UIButton) {
        self.transitionToMain()
    }
    
    //transition to mainVC
    func transitionToMain() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarVC = storyboard.instantiateViewController(withIdentifier: "TabBarVC")
            let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
            tabBarVC.view.addSubview(overlayView)
            self.view.window!.rootViewController = tabBarVC
            UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                overlayView.alpha = 0
            }, completion: { finished in
                overlayView.removeFromSuperview()
            })
        }
    }
    
    
    //check text field and start login process
    func preLogin(isTextFieldsEmpty: Bool) {
        if isTextFieldsEmpty {
            //is empty
            DispatchQueue.main.async {
                self.loginButton.shake()
                self.loginMessageLabel.text = "아이디와 비밀번호를 입력해주세요"
            }
        } else {
            //is not empty
            if let id = idTextField.text, let pass = passwordTextField.text {
                //auth school
                DispatchQueue.global(qos: .userInitiated).async {
                    self.authCK(id: id, pass: pass)
                }
            }
        }
    }
    
    func loginFailed(message: String) {
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            self.loginButton.isEnabled = true
            self.loginMessageLabel.text = message
            self.loginButton.shake()
        }
    }
}

//text field delegate
extension LoginVC: UITextFieldDelegate {
    //when keyboard return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //return when text field on id field
        if (textField.isEqual(self.idTextField)){
            self.passwordTextField.becomeFirstResponder()
        }
        //return when text field on pw field
        else if (textField.isEqual(self.passwordTextField)){
            self.passwordTextField.resignFirstResponder()
            
            let isTextFieldsEmpty = (idTextField.text?.isEmpty)! || (passwordTextField.text?.isEmpty)!
            preLogin(isTextFieldsEmpty: isTextFieldsEmpty)
        }
        return true
    }
}

extension LoginVC {
    func authCK(id: String, pass: String){
        DispatchQueue.main.async {
            self.view.endEditing(true)
            self.view.isUserInteractionEnabled = false
            self.indicator.startAnimating()
            self.loginButton.isEnabled = false
            self.loginMessageLabel.text = ""
        }
        
        let parameters = "loginId=\(id)&loginpwd=\(pass)"
        let postData =  parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "http://library.ck.ac.kr/Cheetah/Login/Login")!,timeoutInterval: Double.infinity)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("ASP.NET_SessionId=anzrg0w5g20f5ib40ryzg4mi", forHTTPHeaderField: "Cookie")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    self.loginFailed(message: "네트워크를 확인해주세요")
                    return
                }
                if let html = String(data: data, encoding: .utf8){
                    do {
                        let doc : Document = try SwiftSoup.parse(html)
                        let bestBook: Elements = try doc.select("ul.quick_right").select("li").select("a")
                        if let name = try bestBook.first()?.text() {
                            //login succese
                            
                            //save information in user defaults
                            UserDefaults.standard.setValue(id, forKey: "id")
                            UserDefaults.standard.setValue(pass, forKey: "password")
                            UserDefaults.standard.setValue(name.dropLast(2), forKey: "name")
                            UserDefaults.standard.synchronize()
                            
                            //transition for homeVC
                            self.transitionToMain()
                        } else {
                            //wrong login information
                            self.loginFailed(message: "아이디와 비밀번호를 확인해주세요")
                        }
                    } catch{
                        //fail to check information
                        self.loginFailed(message: "네트워크를 확인해주세요")
                    }
                    
                }
            }
            task.resume()
        }
    }
}
