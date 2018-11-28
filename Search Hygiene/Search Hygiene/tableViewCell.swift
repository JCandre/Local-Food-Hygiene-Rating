//
//  tableViewCell.swift
//  Search Hygiene
//
//  Created by Joel Cummings on 17/04/2018.
//  Copyright © 2018 Joel Cummings. All rights reserved.
//

import UIKit

class tableViewCell: UITableViewCell {

    //Add view table cell IBoutlets here
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblPostCode: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var lblAddress: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
