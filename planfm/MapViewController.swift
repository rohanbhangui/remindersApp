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
import AddressBookUI

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    
    @IBOutlet weak var locationMapViewer: MKMapView!
    var manager:CLLocationManager!
    var locationStatus : NSString = "Not Started"
    
    var locationString:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Setup our Location Manager
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        //for the mapView method
        locationMapViewer.delegate = self
        
        //check for authority to use location services
        switch CLLocationManager.authorizationStatus() {
        
        //if not determined request always authority
        case .NotDetermined:
            manager.requestAlwaysAuthorization()
        
        // if authorizedwheninuse restricted or denied request a change in settings to always
        case .AuthorizedWhenInUse, .Restricted, .Denied:
            let alertController = UIAlertController(
                title: "Background Location Access Disabled",
                message: "In order to provide you with accurate locations, please set this app's location access to 'Always'",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        
        // if already always authorized start updating
        case .AuthorizedAlways:
            manager.startUpdatingLocation()
        
        // by default request always authorized
        default:
            manager.requestAlwaysAuthorization()
        }
        
        //show the location of user (locationManager func will take care of animation and zooming)
        locationMapViewer.showsUserLocation = true
        
        
        //long press event added for pin drop
        let longPress = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        
        //time for the longpress
        longPress.minimumPressDuration = 0.5
        
        // add gesture to mapViewer (TODO: Look into adding event using storyboard)
        locationMapViewer.addGestureRecognizer(longPress)
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //for pin drop
    func mapView(mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
            
            if annotation is MKUserLocation {
                //return nil so map view draws "blue dot" for standard user location
                return nil
            }
            
            //TODO: figure out what this block means
            let reuseId = "pin"
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.canShowCallout = true
                pinView!.animatesDrop = true
                
            }
            else {
                pinView!.annotation = annotation
            }
            
            return pinView
    }
    
    //for determining the location of the user
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
                self.displayUserLocation(pm)
                
            }
            else
            {
                println("Error with the data.")
            }
        })
    }
    
    //in case of an error (kind of like "super" used in classes in java
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
    {
        println("Error: " + error.localizedDescription)
    }
    
    func displayUserLocation(placemark: CLPlacemark)
    {
        //stop updating location of user (TODO: check if updates later on when moving; SOLUTION: leave commented if you want location to auto update)
        //TODO: Look into zoom in lag when focusing on region
        self.manager.stopUpdatingLocation()
        
        //sets region to focus on for mapview
        let region = MKCoordinateRegionMakeWithDistance(
            placemark.location.coordinate, 2000, 2000)
        
        //animates the "zooming" and "panning" to the region to focus on
        locationMapViewer.setRegion(region, animated: true)
        
        
    }
    
    
    //longpress action for pin drop
    func longPressAction(gestureRecognizer:UIGestureRecognizer) {
        
        //to do it at the start of tht event
        if gestureRecognizer.state == .Began {
            
            //to remove all existing pin drops
            let annotationsToRemove = self.locationMapViewer.annotations.filter { $0 !== self.locationMapViewer.userLocation }
            locationMapViewer.removeAnnotations( annotationsToRemove )
            
            //get the touch event and convert to coordinates (lat and long)
            var touchPoint = gestureRecognizer.locationInView(self.locationMapViewer)
            var newCoord:CLLocationCoordinate2D = locationMapViewer.convertPoint(touchPoint, toCoordinateFromView: self.locationMapViewer)
            
            //annotation generation
            var newAnotation = MKPointAnnotation()
            newAnotation.coordinate = newCoord
            newAnotation.title = "Event Location"
            
            //adding annotation
            locationMapViewer.addAnnotation(newAnotation)
            
            //shows annotation label automatically
            locationMapViewer.selectAnnotation(newAnotation, animated: true)
            
            
            //convert coordinates to a CLLocation
            var getLat: CLLocationDegrees = newAnotation.coordinate.latitude
            var getLon: CLLocationDegrees = newAnotation.coordinate.longitude
            
            var pinLocation: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
            
            //Reverse Geo decoder (convert coordinates to nearest(?) address
            CLGeocoder().reverseGeocodeLocation(pinLocation, completionHandler: {(placemarks, error)->Void in
                
                if (error != nil)
                {
                    println("Error: " + error.localizedDescription)
                    return
                }
                
                if placemarks.count > 0
                {
                    let pm = placemarks[0] as! CLPlacemark
                    
                    let address = ABCreateStringWithAddressDictionary(pm.addressDictionary, false);
                    
                    //generate location string (REMOVE: OUTDATED)
                    //self.locationString = "\(pm.thoroughfare) \(pm.postalCode) \(pm.locality), \(pm.country)"
                    
                    //self.locationString = "\(pm.areasOfInterest[0])"
                    
                    var inputString = "\(pm.areasOfInterest[0])"
                    var countArr = pm.areasOfInterest.count
                    var areasOfInterestBool: Bool = false
                    
                    if countArr > 1 {
                        areasOfInterestBool = true
                    }
                    
                    if areasOfInterestBool == false {
                        self.locationString = "\(address)"
                    }
                    else {
                        self.locationString = "\(inputString) (\(address))"
                    }
                }
                else
                {
                    println("Error with the data.")
                }
            })
        }
    }
    
    //unwind event (does nothing as unwind is controlled in FeedController.swift)
    @IBAction func unwindToMainMenu(segue: UIStoryboardSegue) {
    }
    
    //for the find me button used to update location without live tracking
    @IBAction func findMeLocator(sender: UIBarButtonItem) {
        println("clicked find me")
        
        self.manager.startUpdatingLocation()
        
        CLGeocoder().reverseGeocodeLocation(manager.location, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil)
            {
                println("Error: " + error.localizedDescription)
                return
            }
            
            if placemarks.count > 0
            {
                let pm = placemarks[0] as! CLPlacemark
                self.displayUserLocation(pm)
                
            }
            else
            {
                println("Error with the data.")
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        let feedController = segue.destinationViewController as! FeedController
        
        //TO EXPLORE: directly set input value
        //currently sets variable in FeedController.swift file which is used my UITextField
        feedController.whereLocation = locationString
        
    }
    
}



