//
//  locationService.swift
//  Search Hygiene
//
//  Created by Joel Cummings on 17/04/2018.
//  Copyright © 2018 Joel Cummings. All rights reserved.
//

import UIKit
import CoreLocation

protocol LocationServiceDelegate {
    func tracingLocation(_ currentLocation: CLLocation)
    func tracingLocationDidFailWithError(_ error: NSError)
}

class locationService: NSObject, CLLocationManagerDelegate  {
    //Allow the location sever to called by other view controllers
    static let sharedInstance: locationService = {
        let instance = locationService()
        return instance
    }()
    
    //Store user's location for both current and what locaion manager containts
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var delegate: LocationServiceDelegate?
    
    override init(){
        super.init()
        
        self.locationManager = CLLocationManager()
        guard let locationManager = self.locationManager else {
            return
        }
        
        //Check if device location services is enabled first
        if CLLocationManager.locationServicesEnabled(){
            print("location services enabled")
            //Check if app use of location is authorised
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                print("No access")
                //request for permission when the app is either open or running in the background
                locationManager.requestAlwaysAuthorization()
                
                //request permission only when the app is open
                //locationManager.requestWhenInUseAuthorization()
                
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access authorized")
                //Location accuracy setting
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                //Only trigger new update if the device has moved beyond a specific distance in meters
                locationManager.distanceFilter = 50
                locationManager.delegate = self
            }
        } else {
            //If device location service is disabled, give the user the option to change it
            print("Location services disabled. Enabled location service in device settings")
            //locationDisabledPopup()
        }
    }//End init override
    
    //Start location polling func
    func startUpdatingLocation() {
        print("Location manager running")
        self.locationManager?.startUpdatingLocation()
    }
    
    //End location polling func
    func stopUpdatingLocation() {
        print("Location manager stopped")
        self.locationManager?.stopUpdatingLocation()
    }
    
    //Show popup to the user if device location services are disbaled
    func locationDisabledPopup(){
        let alert = UIAlertController(title: "Location disabled",
                                      message: "In order to view NearBy locations and ratings we need your device location service enabled",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Stay disabled", comment: "Do nothing action"), style: .default, handler: { _ in
            NSLog("The \"Disbaled\" alert occured.")}))
        
    }
    
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        //get last location as current location
        currentLocation = location
        
        //get real time locaion
        updateLocation(location)
    }
    
    fileprivate func updateLocation(_ currentLocation: CLLocation){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tracingLocation(currentLocation)
    }
    
    fileprivate func updateLocationDidFailWithError(_ error: NSError) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.tracingLocationDidFailWithError(error)
    }
    
}//End locationService
