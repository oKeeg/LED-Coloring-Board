//
//  SwiftHSVColorPicker.swift
//  Coloring Board
//
//  Created by Keegan Hutchins on 12/27/18.
//  Copyright © 2018 Neehaw. All rights reserved.
//

import UIKit

open class SwiftHSVColorPicker: UIView, ColorWheelDelegate, BrightnessViewDelegate {
    var colorWheel: ColorWheel!
    var brightnessView: BrightnessView!
    var selectedColorView: SelectedColorView!

    open var color: UIColor!
    var hue: CGFloat = 1.0
    var saturation: CGFloat = 1.0
    var brightness: CGFloat = 1.0
    var HUE = "0"
    var SAT = "0"
    var BRI = "0"
    var hasTouched = false
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    open func setViewColor(_ color: UIColor) {
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        let ok: Bool = color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        if (!ok) {
            print("SwiftHSVColorPicker: exception <The color provided to SwiftHSVColorPicker is not convertible to HSV>")
        }
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.color = color
        
        setup()
    }
    
    func setup() {
        let views = self.subviews
        for view in views {
            view.removeFromSuperview()
        }
        
        let selectedColorViewHeight: CGFloat = 44.0
        let brightnessViewHeight: CGFloat = 26.0
        let colorWheelSize = min(self.bounds.width, self.bounds.height - selectedColorViewHeight - brightnessViewHeight)
        
        let centeredX = (self.bounds.width - colorWheelSize) / 2.0
        
        selectedColorView = SelectedColorView(frame: CGRect(x: centeredX, y:0, width: colorWheelSize, height: selectedColorViewHeight), color: self.color)
        self.addSubview(selectedColorView)
        
        colorWheel = ColorWheel(frame: CGRect(x: centeredX, y: selectedColorView.frame.maxY, width: colorWheelSize, height: colorWheelSize), color: self.color)
        colorWheel.delegate = self
        self.addSubview(colorWheel)
        
        brightnessView = BrightnessView(frame: CGRect(x: centeredX, y: colorWheel.frame.maxY, width: colorWheelSize, height: brightnessViewHeight), color: self.color)
        brightnessView.delegate = self
        self.addSubview(brightnessView)
    }
    
    func hueAndSaturationSelected(_ hue: CGFloat, saturation: CGFloat) {
        self.hue = hue
        self.saturation = saturation
        self.color = UIColor(hue: self.hue, saturation: self.saturation, brightness: self.brightness, alpha: 1.0)
        brightnessView.setViewColor(self.color)
        selectedColorView.setViewColor(self.color)
 
        if(colorWheel.hasTouched){
            HUE = String(format: "%.2f", hue)
            SAT = String(format: "%.2f", saturation)
            BRI = String(format: "%.2f", brightness)
            hasTouched = true
        }
    }
    
    func brightnessSelected(_ brightness: CGFloat) {
        self.brightness = brightness
        self.color = UIColor(hue: self.hue, saturation: self.saturation, brightness: self.brightness, alpha: 1.0)
        colorWheel.setViewBrightness(brightness)
        BRI = String(format: "%.2f", brightness)
        selectedColorView.setViewColor(self.color)
    }
}
