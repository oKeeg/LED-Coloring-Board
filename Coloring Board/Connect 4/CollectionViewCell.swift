//
//  CollectionViewCell.swift
//  Coloring Board
//
//  Created by Keegan Hutchins on 12/23/18.
//  Copyright © 2018 Neehaw.com. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewCell: UICollectionViewCell{
    
    @IBOutlet var CoinImage: UIImageView!
    func displayContent(image: UIImage){
        CoinImage.image = image
    }
}
