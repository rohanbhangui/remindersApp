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
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil)
            {
                println("Error: " + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0
            {
                let pm = placemarks[0] as! CLPlacemark
                self.displayLocationInfo(pm)
            }
            else
            {
                println("Error with the data.")
            }
        })
    }
    
    func displayLocationInfo(placemark: CLPlacemark)
    {
        
        self.manager.stopUpdatingLocation()
        println(placemark.locality)
        println(placemark.thoroughfare)
        println(placemark.postalCode)
        println(placemark.administrativeArea)
        println(placemark.country)
        println("------------")
        
        //let userLocation = locationMapViewer.userLocation
        
        let region = MKCoordinateRegionMakeWithDistance(
            placemark.location.coordinate, 2000, 2000)
        
        locationMapViewer.setRegion(region, animated: true)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "action:")
        longPress.minimumPressDuration = 0.7
        locationMapViewer.addGestureRecognizer(longPress)
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
    {
        println("Error: " + error.localizedDescription)
    }
    
    func action(gestureRecognizer:UIGestureRecognizer) {
        var touchPoint = gestureRecognizer.locationInView(self.locationMapViewer)
        var newCoord:CLLocationCoordinate2D = locationMapViewer.convertPoint(touchPoint, toCoordinateFromView: self.locationMapViewer)
        
        let annotationsToRemove = self.locationMapViewer.annotations.filter { $0 !== self.locationMapViewer.userLocation }
        locationMapViewer.removeAnnotations( annotationsToRemove )
        
        var newAnotation = MKPointAnnotation()
        newAnotation.coordinate = newCoord
        newAnotation.title = "Event Location"
        //newAnotation.subtitle = "New Subtitle"
        
        locationMapViewer.addAnnotation(newAnotation)
        
        var getLat: CLLocationDegrees = newAnotation.coordinate.latitude
        var getLon: CLLocationDegrees = newAnotation.coordinate.longitude
        
        
        var pinLocation: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
        
        
        CLGeocoder().reverseGeocodeLocation(pinLocation, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil)
            {
                println("Error: " + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0
            {
                let pm = placemarks[0] as! CLPlacemark
                println(pm.locality)
                println(pm.thoroughfare)
                println(pm.postalCode)
                println(pm.administrativeArea)
                println(pm.country)
                println("------------")
            }
            else
            {
                println("Error with the data.")
            }
        })
        
    }
    
    @IBAction func unwindToMainMenu(segue: UIStoryboardSegue) {
        
    }
    
}



