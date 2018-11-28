//
//  locationClass.swift
//  Search Hygiene
//
//  Created by Joel Cummings on 17/04/2018.
//  Copyright © 2018 Joel Cummings. All rights reserved.
//

import Foundation

//Codeable to automatically deseralize
//Json to create object/s of this class

class locations: Codable{
    //MARK: Properties
    
    let id: String //The ID of the inspection record.
    let BusinessName: String //The name of the establishment
    let AddressLine1: String? //The first line of the establishment’s address
    let AddressLine2: String? //The second line of the establishment’s address (might be empty)
    let AddressLine3: String? //The third line of the establishment’s address (is often empty)
    let PostCode: String //The establishment’s Post Code
    let RatingValue: String //The 1-5 hygiene rating. Note: some ratings are -1, which means “Exempt”
    let RatingDate: String //The date the rating was awarded
    let Longitude: String //The longitude of the establishment’s location
    let Latitude: String //The latitude of the establishment’s location
    let DistanceKM: String? //The establishment’s distance from the user in KM

}
