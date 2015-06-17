//
//  MapViewController.swift
//  planfm
//
//  Created by Rohan Bhangui on 2015-06-17.
//  Copyright (c) 2015 Rohan Bhangui. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    
    @IBOutlet weak var locationMapViewer: MKMapView!
    var manager:CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Setup our Location Manager
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
        locationMapViewer.showsUserLocation = true
        
        var span = MKCoordinateSpanMake(0.5, 0.5)
        let location = manager.location.coordinate
        var region = MKCoordinateRegion(center: location, span: span)
        
        locationMapViewer.setRegion(region, animated: true)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "My Location"
        
        println("\(manager.location.coordinate)")
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}



