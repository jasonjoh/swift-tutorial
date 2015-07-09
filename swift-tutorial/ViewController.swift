//
//  ViewController.swift
//  swift-tutorial
//
//  Created by Jason Johnston on 7/7/15.
//  Copyright (c) 2015 Jason Johnston. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var logInButton: UIButton!
    var loggedIn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func logInButtonTapped(sender : AnyObject) {
        var authMgr = AuthenticationManager.sharedInstance
        
        if (loggedIn){
            // Logout and change the button to read "Log in"
            authMgr.logout()
            self.logInButton.setTitle("Log in", forState: UIControlState.Normal)
            self.loggedIn = false
        }
        else {
            // Attempt to get a token
            authMgr.getToken() {
                (authenticated: Bool, token: String) -> Void in
                
                if (authenticated) {
                    // Change the button to read "Log out"
                    NSLog("Authentication successful, token: %@", token)
                    self.logInButton.setTitle("Log out", forState: UIControlState.Normal)
                    self.loggedIn = true
                }
                else {
                    NSLog("Authentication failed: %@", token)
                }
            }
        }
    }
}

