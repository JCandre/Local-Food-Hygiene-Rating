//
//  detailsViewController.swift
//  Search Hygiene
//
//  Created by Joel Cummings on 17/04/2018.
//  Copyright © 2018 Joel Cummings. All rights reserved.
//

import UIKit
import MapKit

class detailsViewController: UIViewController {
    //MARK: Properties
    
    var data: locations? //This value is either passed by `tableViewController` in the `prepare(for:sender:)`
    
    @IBOutlet weak var lblID: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblAddress2: UILabel!
    @IBOutlet weak var lblAddress3: UILabel!
    @IBOutlet weak var lblPostCode: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblRating: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var detailsMap: MKMapView!
    @IBOutlet weak var lblCoordinates: UILabel!
    @IBOutlet weak var imgRating: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //check data variables for missing information before trying to apply to labels
        if data?.id != nil { lblID.text = data?.id
        } else { lblID.text = "Error" }
        
        if data?.BusinessName != nil {
            lblName.text = data?.BusinessName
            navigationItem.title = data?.BusinessName
        } else { lblName.text = "Error"}
        
        if data?.AddressLine1 != nil { lblAddress.text = data?.AddressLine1
        } else { lblAddress.text = "Error" }
        
        if data?.AddressLine2 != nil { lblAddress2.text = data?.AddressLine2
        } else { lblAddress2.text = "Error" }
        
        if data?.AddressLine3 != nil { lblAddress3.text = data?.AddressLine3
        } else { lblAddress3.text = " " }
        
        if data?.PostCode != nil { lblPostCode.text = data?.PostCode
        } else { lblPostCode.text = "Error" }
        
        if data?.RatingDate != nil { lblDate.text = data?.RatingDate
        } else { lblDate.text = "Error" }
        
        if data?.RatingValue != nil {
            if data?.RatingValue != "-1"{ lblRating.text = data?.RatingValue
            } else { lblRating.text = "Exempt" }
            
            let selectIMG = data?.RatingValue
            imgRating.image = UIImage(named: "rating_large_\(selectIMG!)")
        } else {
            lblRating.text = "Error"
        }
        
        if data?.Longitude != nil && data?.Latitude != nil {
            let Latitude = data?.Latitude
            let Longitude = data?.Longitude
            lblCoordinates.text = "Lat:\(Latitude!) Long:\(Longitude!)"
            
        } else {
            lblCoordinates.text = "Lat:Error Long:Error"
        }
        
        //MARK: Map view configuration
        // Span sets the map zoom, location... region tells the map where to focus using
        //the span and location
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        //String to double conversion for longitude and latitude, for use in location
        let Latitude = (data?.Latitude as NSString?)?.doubleValue
        let Longitude = (data?.Longitude as NSString?)?.doubleValue
        let Location:  CLLocationCoordinate2D = CLLocationCoordinate2DMake(Latitude!, Longitude!)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(Location, span)
        //use the region to set the map
        detailsMap.setRegion(region, animated: true)
        //the type of map displayed
        detailsMap.mapType = .standard
        
        //MARK: Map annotation
        //Configure annotation parameters and custom pin
        let annotation = customPin()
        let selectPin = data?.RatingValue
        annotation.image = UIImage(named: "pin_\(selectPin!)")
        annotation.coordinate = CLLocationCoordinate2DMake(Latitude!, Longitude!)
        annotation.title = data?.BusinessName
        
        if data?.DistanceKM != nil {
        //Round down distance to 3 decimal places before showing
        let i = (data?.DistanceKM! as NSString?)?.doubleValue
        let distance = Double(round(1000*i!)/1000)
        lblDistance.text = "\(distance)Km Away"
        annotation.subtitle = (data?.AddressLine1)! + "\n" + (data?.PostCode)! + "\n" + "\(distance)Km Away"
        } else {
            lblDistance.text = "Unavailable"
            annotation.subtitle = (data?.AddressLine1)! + "\n" + (data?.PostCode)!
        }
        
        //add annotation to the map view
        detailsMap.addAnnotation(annotation)
    }//End viewDidLoad
    
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
    }//End mapView func

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }//End didReceiveMemoryWarning
    
}//End detailsViewController
