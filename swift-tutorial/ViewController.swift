//
//  ViewController.swift
//  swift-tutorial
//
//  Created by Jason Johnston on 7/7/15.
//  Copyright (c) 2015 Jason Johnston. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var logInButton: UIButton!
    @IBOutlet var msgTable: UITableView!
    var loggedIn: Bool = false
    var messages = NSArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.msgTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
                    
                    // Get messages
                    // Pass in the ADALDependencyResolve from the AuthenticationManager
                    self.getMessages(authMgr.dependencyResolver)
                    
                }
                else {
                    NSLog("Authentication failed: %@", token)
                }
            }
        }
    }
    
    func getMessages(dependencyResolver: ADALDependencyResolver) {
        var apiEndpoint = "https://outlook.office365.com/api/v1.0"
        var client = MSOutlookClient(url: apiEndpoint, dependencyResolver: dependencyResolver)
        
        // Select at most 10 messages (.top(10))
        // Return only the subject, date/time received, and from fields (.select())
        // Sort by date/time received, newest first (.orderBy())
        client.me.messages.top(10).select("Subject,DateTimeReceived,From").orderBy("DateTimeReceived DESC").readWithCallback({
            (messages: [AnyObject]!, error: MSOrcError!) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                
                for msg in messages {
                    var olMsg: MSOutlookMessage = msg as! MSOutlookMessage
                    NSLog(olMsg.Subject)
                }
                
                // Save the results and refresh the table view
                self.messages = messages
                self.msgTable.reloadData()
            })
        })
    }
    
    // Called when loading data to see how many rows to render
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of messages
        return self.messages.count
    }
    
    // Called to render each row in the table
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = self.msgTable.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        
        // Get the message from the array and cast to a MSOutlookMessage object
        var outlookMessage : MSOutlookMessage = self.messages.objectAtIndex(indexPath.row) as! MSOutlookMessage
        
        // Format the received date/time
        var formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        var received = formatter.stringFromDate(outlookMessage.DateTimeReceived)
        
        // Setting to 0 should allow the line to wrap to multiple lines
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = String(format: "%@ From: %@ - %@", received, outlookMessage.From.EmailAddress.Name, outlookMessage.Subject)
        
        return cell
    }
    
    // Empty function
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}

