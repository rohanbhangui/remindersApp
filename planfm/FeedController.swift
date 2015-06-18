//
//  FeedController.swift
//  planfm
//
//  Created by Rohan Bhangui on 2015-06-14.
//  Copyright (c) 2015 Rohan Bhangui. All rights reserved.
//

import UIKit

class FeedController: UIViewController {
    
    @IBOutlet weak var planName: UITextField!
    @IBOutlet weak var planDateTime: UITextField!
    @IBOutlet weak var planLocation: UITextField!
    
    var whereLocation: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.        
        
        
        //planLocation.text = whereLocation!
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func editingWhen(sender: UITextField) {
        
        var datePickerView:UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.DateAndTime
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: Selector("datePickerValueChanged:"), forControlEvents: UIControlEvents.ValueChanged)

    }
    
    func datePickerValueChanged (sender:UIDatePicker) {
        var dateformatter = NSDateFormatter()
        dateformatter.dateStyle = NSDateFormatterStyle.FullStyle
        dateformatter.dateFormat = "EEE, MMM d h:mm a"
        planDateTime.text = dateformatter.stringFromDate(sender.date)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    @IBAction func editingWhere(sender: UITextField) {
        planDateTime.endEditing(true)
        performSegueWithIdentifier("openMapViewer", sender: nil)
    }
    
    @IBAction func unwindToMainMenu(segue: UIStoryboardSegue) {
        
    }

}

