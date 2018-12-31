//
//  SelectedColorView.swift
//  Coloring Board
//
//  Created by Keegan Hutchins on 12/27/18.
//  Copyright © 2018 Neehaw. All rights reserved.
//

import UIKit

class SelectedColorView: UIView {
    var color: UIColor!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(frame: CGRect, color: UIColor) {
        super.init(frame: frame)
        
        setViewColor(color)
    }
    
    func setViewColor(_ _color: UIColor) {
        color = _color
        setBackgroundColor()
    }
    
    func setBackgroundColor() {
        backgroundColor = color
    }
}
