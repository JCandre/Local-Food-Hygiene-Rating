//
//  mainViewController.swift
//  Search Hygiene
//
//  Created by Joel Cummings on 17/04/2018.
//  Copyright © 2018 Joel Cummings. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import os.log

class mainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LocationServiceDelegate{
    
    //MARK: Properties
    @IBOutlet weak var topMenuConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainTableView: UITableView!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchFilter: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoUpdateBtnLabel: UIBarButtonItem!
    @IBOutlet weak var lblCurrentLocal: UILabel!
    var isSearchMenuHidden = true
    var urlComponents = URLComponents()
    let scheme = "http"
    let host = "radikaldesign.co.uk"
    let path = "/sandbox/hygiene.php"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize search menu constant with -285 (Hidden)
        topMenuConstraint.constant = -285;
        
        //Set app background colour
        self.view.backgroundColor = UIColor( red: CGFloat(92/255.0), green: CGFloat(219/255.0), blue: CGFloat(149/255.0), alpha: CGFloat(1.0) )
    
        //Trigger location tracking
        locationService.sharedInstance.startUpdatingLocation()
        locationService.sharedInstance.delegate = self
        
        //Set TableView datasource and delegate
        mainTableView.dataSource = self as UITableViewDataSource
        mainTableView.delegate = self as UITableViewDelegate
        
        
    }//End viewDidLoad
    
    //Update view each time it appears
    override func viewWillAppear(_ animated: Bool) {
        //interupt the main thread and update the table with the retrived data
        DispatchQueue.main.async {
            //Update table view with new data
            self.mainTableView.reloadData();
            
        }
        //update button label if changed by other views
        if locationAutoBool.sharedInstance.isAutoLocation{
            autoUpdateBtnLabel.title = "Auto"
        } else {
            autoUpdateBtnLabel.title = "Filtered"
        }
        
        //Get name of current location
        reverseGeocode()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Toggle the search menu (Show/Hide)
    @IBAction func SearchBtn(_ sender: UIBarButtonItem) {
        searchToggle()
    }//End searchBtn
    
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
            //Breack up search query items for encoding, before server call
            let queryOP = URLQueryItem(name: "op", value: "s_loc")
            let queryItem1 = URLQueryItem(name: "lat", value: "\(Latitude!)")
            let queryItem2 = URLQueryItem(name: "long", value: "\(Longitude!)")
            let Items = [queryOP, queryItem1, queryItem2]
            updateLocations(queryItem: Items)
        }
    }//End autoUpdateBtn
    
    
    //Close search menu if showing
    @IBAction func queryCancel(_ sender: Any) {
        searchToggle()
    } //End queryCancel
    
    //Search mean
    @IBAction func querySearch(_ sender: Any) {
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
        
    } //End querySearch
    
    
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
    
    //MARK: LocationService Delegate
    //Update coordinates everytime there is a locaiont update triggered by location service
    func tracingLocation(_ currentLocation: CLLocation) {
        print("Tracing location triggered")
        
        //If allowed to update stored locations automatically when traveling, do so
        if locationAutoBool.sharedInstance.isAutoLocation {
            let Longitude = String (currentLocation.coordinate.longitude)
            let Latitude = String(currentLocation.coordinate.latitude)
            //Breack up search query items for encoding, before server call
            let queryOP = URLQueryItem(name: "op", value: "s_loc")
            let queryItem1 = URLQueryItem(name: "lat", value: "\(Latitude)")
            let queryItem2 = URLQueryItem(name: "long", value: "\(Longitude)")
            let Items = [queryOP, queryItem1, queryItem2]
            updateLocations(queryItem: Items)
    
        } else {
            print("Stored locations update denied")
        }

    } //End tracingLocation
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        print("tracing Location Error : \(error.description)")
    } //EndtracingLocationDidFailWithError
    
    //MARK: Server data decoder
    func updateLocations(queryItem: [URLQueryItem]){
        print("Update table view triggered")
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
                
                //interupt the main thread and update the table with the retrived data
                DispatchQueue.main.async {
                    //Update table view with new data
                    self.mainTableView.reloadData();
                }
                //Print the size of the locations array
                print("Locations pulled from server: \(storedLocations.sharedInstance.locationsArray.count)")
            } catch let err {
                print ("Error: ", err)
            }
            
        }.resume() //start the network call
        //Trigger verse geocoding update to new location
        reverseGeocode()
        
    } //End updateLocations
    
    //MARK: - Table view data source
    //protocal methods that gives the table view the correct behaviour
    
    //Func to tell the table view how many sections to display
    func numberOfSections(in tableView: UITableView) -> Int {
        //Number of sections to show
        return 1
    } //End numberOfSections
    
    //Number of rows to display. Match the number of objects in the eateries array
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storedLocations.sharedInstance.locationsArray.count
    } //End tableView numberOfRowsInSection
    
    //Provides a cell to display for a given row. Only asking for cells in rows that are being displayed
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "tableViewCell"
        
        //Downcast the type of cell to my custom cell subclass
        //as? downcasts the returned object from the class
        //guard let safely unwraps the optional
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? tableViewCell else {
            fatalError("The dequeued cell is not an instance of mainTableViewCell.")
        }
        
        //Get the appropraite location from the locations arary for the data source layout
        let locations = storedLocations.sharedInstance.locationsArray[indexPath.row]
        
        //configure cell labels and images
        cell.lblName.text = locations.BusinessName.capitalized
        cell.lblPostCode.text = locations.PostCode.capitalized
        cell.lblAddress.text = locations.AddressLine3?.capitalized
        let selectImg = locations.RatingValue
        cell.cellImage.image = UIImage(named: "rating_large_\(selectImg)")
        cell.cellImage.layer.cornerRadius = (cell.cellImage.frame.width) / 100
        cell.cellImage.layer.masksToBounds = true
        
        return cell
    } //End tableView cellForRowAt
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        //Similar to if statements, Switch statement to consider a value and compare it against other possible matching patterns, then execute appropriate block of
        //code for the first matching pattern. Good for selecting between multiple options
        //Dsiplay the correct location data in the location's detail scene
        switch(segue.identifier ?? "") {
        case "AddItem":
            os_log("Adding new eatery", log: OSLog.default, type: .debug )
            
        case "showDetail":
            guard let details = segue.destination as? detailsViewController
                else {
                    fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedLocationCell = sender as? tableViewCell
                else{
                    fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = mainTableView.indexPath(for: selectedLocationCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            
            let selectedLocation = storedLocations.sharedInstance.locationsArray[indexPath.row]
            details.data = selectedLocation
            
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
        
    }// End prepare
    
    //Reverse Geocode to get the location name and which country it is in from the locationManager
    func reverseGeocode (){
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation((locationService.sharedInstance.locationManager?.location!)!, completionHandler: { (placemarks, error) in
            if error == nil {
                let curLocation = placemarks?[0]
                let locality = curLocation?.locality
                let country = curLocation?.country
                
                self.lblCurrentLocal.text = "\(locality!), \(country!)".capitalized
            } else {
                //error occured during geocoding
                if let error = error {
                    self.lblCurrentLocal.text = "Error geocoding"
                    print("Error reverse geocoding \(error)")
                }
            }
            
        })
    } //End reverseGeocode
    
}//End mainViewController class

