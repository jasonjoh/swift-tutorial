//
//  CalendarViewController.swift
//  swift-tutorial
//
//  Created by Jason Johnston on 4/3/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//  Licensed under the MIT license. See LICENSE.txt in the project root for license information.
//

import UIKit

class CalendarViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataSource:EventsDataSource?
    
    let service = OutlookService.shared()
    
    func loadUserData() {
        service.getUserEmail() {
            email in
            if let unwrappedEmail = email {
                NSLog("Hello \(unwrappedEmail)")
                
                self.service.getEvents() {
                    events in
                    if let unwrappedEvents = events {
                        self.dataSource = EventsDataSource(events: unwrappedEvents["value"].arrayValue)
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
        
        if (service.isLoggedIn) {
            loadUserData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
