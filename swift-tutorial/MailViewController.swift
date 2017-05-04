//
//  MailViewController.swift
//  swift-tutorial
//
//  Created by Jason Johnston on 4/3/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//  Licensed under the MIT license. See LICENSE.txt in the project root for license information.
//

import UIKit

class MailViewController: UIViewController {
    
    @IBOutlet var loginButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: MessagesDataSource?
    
    let service = OutlookService.shared()
    
    func setLogInState(loggedIn: Bool) {
        if (loggedIn) {
            loginButton.setTitle("Log Out", for: UIControlState.normal)
        }
        else {
            loginButton.setTitle("Log In", for: UIControlState.normal)
        }
    }
    
    @IBAction func loginButtonTapped(sender: AnyObject) {
        if (service.isLoggedIn) {
            // Logout
            service.logout()
            setLogInState(loggedIn: false)
        } else {
            // Login
            service.login(from: self) {
                error in
                if let unwrappedError = error {
                    NSLog("Error logging in: \(unwrappedError)")
                } else {
                    NSLog("Successfully logged in.")
                    self.setLogInState(loggedIn: true)
                    self.loadUserData()
                }
            }
        }
    }
    
    func loadUserData() {
        service.getUserEmail() {
            email in
            if let unwrappedEmail = email {
                NSLog("Hello \(unwrappedEmail)")
                
                self.service.getInboxMessages() {
                    messages in
                    if let unwrappedMessages = messages {
                        self.dataSource = MessagesDataSource(messages: unwrappedMessages["value"].arrayValue)
                        self.tableView.dataSource = self.dataSource
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.estimatedRowHeight = 90;
        tableView.rowHeight = UITableViewAutomaticDimension
        
        setLogInState(loggedIn: service.isLoggedIn)
        if (service.isLoggedIn) {
            loadUserData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

