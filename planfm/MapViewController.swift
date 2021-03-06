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

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var findMeLocatorButton: UIBarButtonItem!
    
    @IBOutlet weak var locationMapViewer: MKMapView!
    var manager:CLLocationManager!
    var locationStatus : NSString = "Not Started"
    
    var locationString:String!
    
    var trackingToggle:Bool = false
    var trackingDirectionToggle:Bool = false
    var toggleOnce:Bool = true
    
    var findMeState:Int = 1
    
    let longPress = UILongPressGestureRecognizer()
    let panningSwipe = UIPanGestureRecognizer()
    let rotateGesture = UIRotationGestureRecognizer()
    
    var newAnotation = MKPointAnnotation()
    
    var annotationDragState:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //long press event added for pin drop
        let longPress = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        
        longPress.delegate = self
        
        //time for the longpress
        longPress.minimumPressDuration = 0.75
        
        // add gesture to mapViewer (TODO: Look into adding event using storyboard)
        locationMapViewer.addGestureRecognizer(longPress)
        
        //panning event for turning off tracking when panning map
        let panningSwipe = UIPanGestureRecognizer(target: self, action: "panningAction")
        
        panningSwipe.delegate = self
        
        // add gesture to mapViewer (TODO: Look into adding event using storyboard)
        locationMapViewer.addGestureRecognizer(panningSwipe)
        
        
        //panning event for turning off tracking when panning map
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: "rotateGestureAction")
        
        rotateGesture.delegate = self

        
        // add gesture to mapViewer (TODO: Look into adding event using storyboard)
        locationMapViewer.addGestureRecognizer(rotateGesture)
        
        panningSwipe.requireGestureRecognizerToFail(longPress)
        
        
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
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //for pin drop
    func mapView(mapView: MKMapView,
        viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
            
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
                pinView!.draggable = true
                
            }
            else {
                pinView!.annotation = annotation
            }
            
            return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == MKAnnotationViewDragState.Starting {
            print("start drag")
            
            annotationDragState = true
            
        }
        
        if newState == MKAnnotationViewDragState.Dragging {
            print("dragging")
        }
        
        if newState == MKAnnotationViewDragState.Ending {
            print("ending drag")
            
            annotationDragState = false
            
            //convert coordinates to a CLLocation
            let getLat: CLLocationDegrees = newAnotation.coordinate.latitude
            let getLon: CLLocationDegrees = newAnotation.coordinate.longitude
            
            let pinLocation: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
            
            //Reverse Geo decoder (convert coordinates to nearest(?) address
            CLGeocoder().reverseGeocodeLocation(pinLocation, completionHandler: {(placemarks, error)->Void in
                
                if (error != nil)
                {
                    print("Error: " + error!.localizedDescription)
                    return
                }
                
                if placemarks!.count > 0
                {
                    let pm = placemarks![0]
                    
                    let address = ABCreateStringWithAddressDictionary(pm.addressDictionary!,!false);
                    
                    print("\(pm.areasOfInterest)")
                    
                    
                    var areasOfInterestBool: Bool = false
                    var inputString = ""
                    
                    // if you select roads surrounding apple HQ produced nil error. Below checks for that
                    if pm.areasOfInterest != nil {
                        
                        let arrCount = pm.areasOfInterest!.count
                        if arrCount == 0 {
                            inputString = ""
                        }
                        else {
                            inputString = "\(pm.areasOfInterest![0])"
                            areasOfInterestBool = true
                        }
                    }
                    
                    
                    if areasOfInterestBool == false {
                        self.locationString = "\(address)"
                    }
                    else {
                        self.locationString = "\(inputString) (\(address))"
                    }
                    
                    print("location: \(self.locationString)")
                    self.newAnotation.title = self.locationString
                }
                else
                {
                    print("Error with the data.")
                }
            })
            
            //shows annotation label automatically (temporarily disabled pending callout hidden on animate)
            locationMapViewer.selectAnnotation(newAnotation, animated: true)
            
        }
        
    }
    
    //by default UIGestureRecognizer does not recognize simultaneous gestures and so the bool must be changed
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            
        if gestureRecognizer is UILongPressGestureRecognizer {
            return false
        }
        else {
            return true
        }
    }

    //for determining the location of the user
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil)
            {
                print("Error: " + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0
            {
                let pm = placemarks![0] 
                self.displayUserLocation(pm)
                
            }
            else
            {
                print("Error with the data.")
            }
        })
    }
    
    //in case of an error (kind of like "super" used in classes in java
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print("Error: " + error.localizedDescription)
    }
    
    func displayUserLocation(placemark: CLPlacemark)
    {
        //TODO: Look into zoom in lag when focusing on region
        
        if trackingToggle == false && trackingDirectionToggle == false {
            self.manager.stopUpdatingLocation()
            self.manager.stopUpdatingHeading()
        }
        else if trackingToggle == true && trackingDirectionToggle == false {
            self.manager.startUpdatingLocation()
            self.manager.stopUpdatingHeading()
        }
        if trackingToggle == true && trackingDirectionToggle == true {
            self.manager.startUpdatingLocation()
            self.manager.startUpdatingHeading()
        }
        
        
        //sets region to focus on for mapview
        let region = MKCoordinateRegionMakeWithDistance(
            placemark.location!.coordinate, 2000, 2000)
        
        //animates the "zooming" and "panning" to the region to focus on
        locationMapViewer.setRegion(region, animated: true)
        
        
    }
    
    //longpress action for pin drop
    func longPressAction(gestureRecognizer:UILongPressGestureRecognizer) {
        
        //to do it at the start of tht event
        if gestureRecognizer.state == .Began && annotationDragState == false {
            
            panningAction()
            
            //disable rotate and panning events when long pressing
            locationMapViewer.scrollEnabled = false
            locationMapViewer.removeGestureRecognizer(rotateGesture)
            locationMapViewer.removeGestureRecognizer(panningSwipe)
            
            //to remove all existing pin drops
            let annotationsToRemove = self.locationMapViewer.annotations.filter { $0 !== self.locationMapViewer.userLocation }
            locationMapViewer.removeAnnotations( annotationsToRemove )
            
            //get the touch event and convert to coordinates (lat and long)
            let touchPoint = gestureRecognizer.locationInView(self.locationMapViewer)
            let newCoord:CLLocationCoordinate2D = locationMapViewer.convertPoint(touchPoint, toCoordinateFromView: self.locationMapViewer)
            
            //annotation generation
            newAnotation.coordinate = newCoord
            newAnotation.title = "Event Location"
            
            
            //shows annotation label automatically (temporarily disabled pending callout hidden on animate)
            locationMapViewer.selectAnnotation(newAnotation, animated: true)
            
            //adding annotation
            locationMapViewer.addAnnotation(newAnotation)
            
            
            //convert coordinates to a CLLocation
            let getLat: CLLocationDegrees = newAnotation.coordinate.latitude
            let getLon: CLLocationDegrees = newAnotation.coordinate.longitude
            
            let pinLocation: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
            
            //Reverse Geo decoder (convert coordinates to nearest(?) address
            CLGeocoder().reverseGeocodeLocation(pinLocation, completionHandler: {(placemarks, error)->Void in
                
                if (error != nil)
                {
                    print("Error: " + error!.localizedDescription)
                    return
                }
                
                if placemarks!.count > 0
                {
                    let pm = placemarks![0]
                    
                    let address = ABCreateStringWithAddressDictionary(pm.addressDictionary!, false);
                    
                    print("\(pm.areasOfInterest)")
                    
                    
                    var areasOfInterestBool: Bool = false
                    var inputString = ""
                    
                    // if you select roads surrounding apple HQ produced nil error. Below checks for that
                    if pm.areasOfInterest != nil {
                        
                        let arrCount = pm.areasOfInterest!.count
                        if arrCount == 0 {
                            inputString = ""
                        }
                        else {
                            inputString = "\(pm.areasOfInterest![0])"
                            areasOfInterestBool = true
                        }
                    }
                    
                    
                    if areasOfInterestBool == false {
                        self.locationString = "\(address)"
                    }
                    else {
                        self.locationString = "\(inputString) (\(address))"
                    }
                    
                    print("location: \(self.locationString)")
                    self.newAnotation.title = self.locationString
                }
                else
                {
                    print("Error with the data.")
                }
            })
        }
        
        //renable the panning and rotate gestures on the end state of the longpress event
        else if gestureRecognizer.state == .Ended {
            print("cancelled touches")
            locationMapViewer.addGestureRecognizer(rotateGesture)
            locationMapViewer.addGestureRecognizer(panningSwipe)
            locationMapViewer.scrollEnabled = true
            
        }
    }
    
    //active when rotate gesture is captured and tracking is on
    func rotateGestureAction() {
        
        if trackingToggle == true && trackingDirectionToggle == true {
            trackingDirectionToggle = false
            findMeState = 2
            findMeLocatorButton.title = "Active Track"
            locationMapViewer.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        }
    }
    
    //for the panning of map if tracking is enabled
    func panningAction( ) {
        if trackingToggle == true {
            trackingToggle = false
            trackingDirectionToggle = false
            findMeState = 1
            findMeLocatorButton.title = "Find Me"
            locationMapViewer.setUserTrackingMode(MKUserTrackingMode.None, animated: true)
        }
    }

    //unwind event (does nothing as unwind is controlled in FeedController.swift)
    @IBAction func unwindToMainMenu(segue: UIStoryboardSegue) {
    }
    
    //for the find me button used to update location without live tracking
    @IBAction func findMeLocator(sender: UIBarButtonItem) {
        
        switch findMeState {
            
        //find me state: heading and following off
        case 0:
            trackingToggle = false
            trackingDirectionToggle = false
            findMeState = 1
            findMeLocatorButton.title = "Find Me"
            locationMapViewer.setUserTrackingMode(MKUserTrackingMode.None, animated: true)
        
        // following on heading off
        case 1:
            trackingToggle = true
            findMeState = 2
            findMeLocatorButton.title = "Active Track"
            locationMapViewer.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
            
        //heading and following both on
        case 2:
            trackingDirectionToggle = true
            findMeState = 0
            findMeLocatorButton.title = "Active Track w/ Pos"
            locationMapViewer.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: true)
            
        default:
            print("println")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        let feedController = segue.destinationViewController as! FeedController
        
        //TO EXPLORE: directly set input value
        //currently sets variable in FeedController.swift file which is used my UITextField
        feedController.whereLocation = locationString
        
    }
    
}



