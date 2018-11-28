//
//  mapViewController.swift
//  Search Hygiene
//
//  Created by Joel Cummings on 18/04/2018.
//  Copyright © 2018 Joel Cummings. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class mapViewController: UIViewController, LocationServiceDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchView: UIView!
    var isSearchMenuHidden = true
    @IBOutlet weak var topMenuConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchFilter: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoUpdateBtnLabel: UIBarButtonItem!
    @IBOutlet weak var lblCurLocation: UILabel!
    var urlComponents = URLComponents()
    let scheme = "http"
    let host = "radikaldesign.co.uk"
    let path = "/sandbox/hygiene.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set location and map delegate
        locationService.sharedInstance.delegate = self
        mapView.delegate = self
        
        //initialize search menu constant with -285 (Hidden
        topMenuConstraint.constant = -285;
        
        //Set app background colour
        self.view.backgroundColor = UIColor( red: CGFloat(92/255.0), green: CGFloat(219/255.0), blue: CGFloat(149/255.0), alpha: CGFloat(1.0) )
        
    }//End viewDidLoad
    
    //Update view each time it appears
    //Also If a query Search was triggered in table view, change map zoom to help show all results
    override func viewWillAppear(_ animated: Bool) {
        //call current location for user pin
        let Latitude = locationService.sharedInstance.locationManager?.location?.coordinate.latitude
        let Longitude = locationService.sharedInstance.locationManager?.location?.coordinate.longitude
        if locationAutoBool.sharedInstance.isAutoLocation{
            //update button label if changed by other views
            autoUpdateBtnLabel.title = "Auto"
            // Span sets the map zoom, location... region tell teh map where to focus using
            //the span and location
            let span: MKCoordinateSpan = MKCoordinateSpanMake(0.03, 0.03)
            //String to double conversion for longitude and latitude, for use in location
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Latitude!, Longitude!)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            //use the region to set the map
            mapView.setRegion(region, animated: true)
            //the type of map displayed
            mapView.mapType = .standard
        } else {
            //update button label if changed by other views
            autoUpdateBtnLabel.title = "Filtered"
            // Span sets the map zoom, location... region tell teh map where to focus using
            //the span and location
            let span: MKCoordinateSpan = MKCoordinateSpanMake(0.40, 0.40)
            //String to double conversion for longitude and latitude, for use in location
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Latitude!, Longitude!)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            //use the region to set the map
            mapView.setRegion(region, animated: true)
            //the type of map displayed
            mapView.mapType = .standard
        }
        //Get name of current location
        reverseGeocode()
        //Add pins for the stored locations in the table view
        updatePins()
    }//End viewWillAppear
    
    //Function to configure and return a each individual pin and set the pin image
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else {
            return nil
        }
        let annotationIdentifier = "AnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil{
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView!.canShowCallout = true
        }
        else {
            annotationView!.annotation = annotation
        }
        
        let customPinAnnotation = annotation as! customPin
        annotationView!.image = customPinAnnotation.image
        return annotationView
    } //End mapView func
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }//End didReceiveMemoryWarning
    
    
    //Allow the app to update locations as you travel or only show search query
    @IBAction func autoUpdateBtn(_ sender: Any) {
        //Check whether auto updating is enabled or not to trigger different actions
        if locationAutoBool.sharedInstance.isAutoLocation  {
            //True so switch everything to false state
            autoUpdateBtnLabel.title = "Filtered"
            locationAutoBool.sharedInstance.isAutoLocation = false
            locationService.sharedInstance.stopUpdatingLocation()
            
        } else {
            //False so switch everything to true state
            autoUpdateBtnLabel.title = "Auto"
            locationAutoBool.sharedInstance.isAutoLocation = true
            locationService.sharedInstance.startUpdatingLocation()
            
            //Reupdate stored locations to current position
            let Latitude = locationService.sharedInstance.locationManager?.location?.coordinate.latitude
            let Longitude = locationService.sharedInstance.locationManager?.location?.coordinate.longitude
            //query to get the data from using current location
            let queryOP = URLQueryItem(name: "op", value: "s_loc")
            let queryItem1 = URLQueryItem(name: "lat", value: "\(Latitude!)")
            let queryItem2 = URLQueryItem(name: "long", value: "\(Longitude!)")
            let Items = [queryOP, queryItem1, queryItem2]
            updateLocations(queryItem: Items)
        }
    }//End autoUpdateBtn
    
    //Toggle the search menu
    @IBAction func btnSearch(_ sender: Any) {
        searchToggle()
    }//End btnSearch
    
    //Close search menu
    @IBAction func qryCancel(_ sender: Any) {
        searchToggle()
    }//End qryCancel
    
    //Search menu
    @IBAction func qrySearch(_ sender: Any) {
        //Check for text in search bar first, other show alert
        if searchBar.text != ""{
            //Segment search between Name and Postcode then trigger search request
            if searchFilter.selectedSegmentIndex == 0 //First segment
            {
                print("Name segment was selected")
                if let text = searchBar.text {
                    print("Search query: \(text)")
                    //Breack up search query items for encoding, before server call
                    let queryOP = URLQueryItem(name: "op", value: "s_name")
                    let queryItem1 = URLQueryItem(name: "name", value: "\(text)")
                    let Items = [queryOP, queryItem1]
                    updateLocations(queryItem: Items)
                    
                }
                //Hide search menu after server call and update Auto location to false to stop location update clearing search results
                searchToggle()
                autoUpdateBtnLabel.title = "Filtered"
                locationAutoBool.sharedInstance.isAutoLocation = false
            } else if searchFilter.selectedSegmentIndex == 1 //Second segment
            {
                print("Postcode segment was selected")
                if let text = searchBar.text{
                    print("Search query: \(text)")
                    //Breack up search query items for encoding, before server call
                    let queryOP = URLQueryItem(name: "op", value: "s_postcode")
                    let queryItem1 = URLQueryItem(name: "postcode", value: "\(text)")
                    let Items = [queryOP, queryItem1]
                    updateLocations(queryItem: Items)
                    
                }
                //Hide search menu after server call and update Auto location to false to stop location update clearing search results
                searchToggle()
                autoUpdateBtnLabel.title = "Filtered"
                locationAutoBool.sharedInstance.isAutoLocation = false
            }
            
        } else {
            //Alert user to empty search box
            print("Nothing in search bar")
            let alert = UIAlertController(title: "Alert", message: "Please enter query first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }//End quearySearch
    
    
    // Hide or show the search menu
    func searchToggle(){
        //search menu hide toggle and animation
        if isSearchMenuHidden{
            topMenuConstraint.constant = 0
            
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            topMenuConstraint.constant = -285
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
        isSearchMenuHidden = !isSearchMenuHidden
    }//End searchToggle
    
    
    //MARK: Server data decoder
    func updateLocations(queryItem: [URLQueryItem]){
        print ("Locations array update triggered")
        //Combine and encode URL components for server call
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = queryItem
        
        let fullURL = urlComponents.url
        print(fullURL!)

        //Configure the URLSession
        URLSession.shared.dataTask(with: fullURL!) { (data, response, error) in
            guard let data = data else {print("error with the data"); return}
            do{
                //Decode JSON response to locations object array
                storedLocations.sharedInstance.locationsArray = try JSONDecoder().decode([locations].self, from: data);
                //Print the size of the locations array
                print("Locations pulled from server: \(storedLocations.sharedInstance.locationsArray.count)")
                
                //Add the new location pins to map
                self.updatePins()
                
                //Adjust map zoom to show results and update user location pin
                let span: MKCoordinateSpan = MKCoordinateSpanMake(0.40, 0.40)
                //call current location for user pin
                let cLatitude = locationService.sharedInstance.locationManager?.location?.coordinate.latitude
                let cLongitude = locationService.sharedInstance.locationManager?.location?.coordinate.longitude
                let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(cLatitude!, cLongitude!)
                let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
                //use the region to set the map
                self.mapView.setRegion(region, animated: true)
                //the type of map displayed
                self.mapView.mapType = .standard
            } catch let err {
                print ("Error: ", err)
            }
            
            }.resume() //start the network call
        
        //update map to reflect new stored locations
    }//End updateLocations
    
    func updatePins(){
        //remove map annotations
        let allAnnotations = mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        
        //Add new pins
        for i in storedLocations.sharedInstance.locationsArray{
            //update map to reflect new stored locations
            //add an annotation for each of the Location objects in the array
            let annotation = customPin()
            let Latitude = Double(i.Latitude)
            let Longitude = Double(i.Longitude)
            annotation.image = UIImage(named: "pin_\(i.RatingValue)")
            annotation.coordinate = CLLocationCoordinate2DMake(Latitude!, Longitude!)
            annotation.title = i.BusinessName
            if i.DistanceKM != nil{
                //Round down distance to decimal places
                let d  = (i.DistanceKM! as NSString).doubleValue
                let distance = Double(round(1000*d)/1000)
                annotation.subtitle = i.AddressLine1! + "\n" + i.PostCode + "\n" + "\(distance)Mm Away"
            } else {
                annotation.subtitle = i.AddressLine1! + "\n" + i.AddressLine2! + "\n" + i.PostCode
            }
            self.mapView.addAnnotation(annotation)
        }
    }//End updatePins
    
    
    //Update user pin if location change triggered
    func tracingLocation(_ currentLocation: CLLocation) {
        print("Tracing location triggered for map")
        if locationAutoBool.sharedInstance.isAutoLocation {
            let Longitude = String(currentLocation.coordinate.longitude)
            let Latitude = String(currentLocation.coordinate.latitude)
            
            // Span sets the map zoom, location... region tell teh map where to focus using
            //the span and location
            let span: MKCoordinateSpan = MKCoordinateSpanMake(0.03, 0.03)
            //String to double conversion for longitude and latitude, for use in location
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(Double(Latitude)!, Double(Longitude)!)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            //use the region to set the map
            mapView.setRegion(region, animated: true)
            //the type of map displayed
            mapView.mapType = .standard
            
            //query to get the data from using current location
            let queryOP = URLQueryItem(name: "op", value: "s_loc")
            let queryItem1 = URLQueryItem(name: "lat", value: "\(Latitude)")
            let queryItem2 = URLQueryItem(name: "long", value: "\(Longitude)")
            let Items = [queryOP, queryItem1, queryItem2]
            updateLocations(queryItem: Items)
            
            //Get name of current location
            reverseGeocode()
            
        } else {
            print("Stored locations update denied")
        }
    }//End tracingLocation
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        print("tracing Location Error : \(error.description)")
    }
    
    //Reverse Geocode to get the location name and which country it is in from the locationManager
    func reverseGeocode (){
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation((locationService.sharedInstance.locationManager?.location!)!, completionHandler: { (placemarks, error) in
            if error == nil {
                let curLocation = placemarks?[0]
                let locality = curLocation?.locality
                let country = curLocation?.country
                
                self.lblCurLocation.text = "\(locality!), \(country!)".capitalized
            } else {
                //error occured during geocoding
                if let error = error {
                    self.lblCurLocation.text = "Error geocoding"
                    print("Error reverse geocoding \(error)")
                }
            }
            
        })
    } //End reverseGeocode
    
} //End mapViewController
