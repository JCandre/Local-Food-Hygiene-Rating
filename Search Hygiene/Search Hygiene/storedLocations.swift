//
//  storedLocations.swift
//  Search Hygiene
//
//  Created by Joel Cummings on 18/04/2018.
//  Copyright © 2018 Joel Cummings. All rights reserved.
//

import Foundation

class storedLocations{
    //Use this class to store locations for access in other view controllers
    static let sharedInstance = storedLocations()
    var locationsArray = [locations]() //Declare and init with default value (empty array of Eatery objects)
}
