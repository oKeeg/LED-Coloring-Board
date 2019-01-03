//
//  SerialViewController.swift
//  Coloring Board
//
//  Created by Keegan Hutchins on 12/20/18.
//  Copyright © 2018 Neehaw. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore

//Stores values
struct defaultsKeys {
    static let savedNames = "savedNames"
    static let nameData = "nameData"
}

class SerialViewController: UIViewController, UITextFieldDelegate,
BluetoothSerialDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource{
    //MARK: IBOutlets
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var collectionView: UICollectionView!
    let reuseIdentifier = "cell"
    @IBOutlet weak var collectionViewPallet: UICollectionView!
    @IBOutlet weak var colorPicker: SwiftHSVColorPicker!
    var selectedColor: UIColor = UIColor.white
    
    @IBOutlet weak var clearColorsButton: UIButton!
    @IBOutlet weak var addToPalletButton: UIButton!
    @IBOutlet weak var savePictureButton: UIButton!
    @IBOutlet weak var loadPictureButton: UIButton!
    
    @IBOutlet weak var fillBucket: UIButton!
    @IBOutlet weak var undoArrow: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var AnimationPopup: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    var effect: UIVisualEffect!
    
    var lastUsedCell: [[String]] = [[/*rowNum, hue, sat, bri*/]]
    
    var currentHue = "0"
    var currentSat = "0"
    var currentBri = "0"
    var clickedPallet = false
    
    var fillBucketOn = false
    
    let items = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87"]
    
    var palletItems: [[String]] = [["0.32", "1.07", "1"]]
    let tableViewAnimations = ["Fade Color", "Breathing Rainbow", "Moving Rainbow"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serial = BluetoothSerial(delegate: self)
        NotificationCenter.default.addObserver(self, selector: #selector(SerialViewController.reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
        colorPicker.setViewColor(selectedColor)
        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.dataSource = self
        tableView.delegate = self
        loadUIView()
        reloadView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    func loadUIView(){
        collectionView.layer.borderWidth = 1
        clearColorsButton.layer.cornerRadius = 7.0
        clearColorsButton.layer.borderWidth = 1
        addToPalletButton.layer.cornerRadius = 7.0
        addToPalletButton.layer.borderWidth = 1
        savePictureButton.layer.cornerRadius = 7.0
        savePictureButton.layer.borderWidth = 1
        loadPictureButton.layer.cornerRadius = 7.0
        loadPictureButton.layer.borderWidth = 1
        effect = blurView.effect
        blurView.effect = nil
        blurView.center.x = -500
        AnimationPopup.layer.cornerRadius = 15
    }
    func animateIn(){
        self.view.addSubview(AnimationPopup)
        AnimationPopup.center = self.view.center
        blurView.center.x = self.view.center.x
        AnimationPopup.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        AnimationPopup.alpha = 0
        
        UIView.animate(withDuration: 0.5){
            self.blurView.effect = self.effect
            self.AnimationPopup.alpha = 1
            self.AnimationPopup.transform = CGAffineTransform.identity
        }
    }
    func animateOut(){
        UIView.animate(withDuration: 0.3, animations:{
            self.AnimationPopup.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.AnimationPopup.alpha = 0
            
            self.blurView.effect = nil
        }){ (sucess: Bool) in
            self.AnimationPopup.removeFromSuperview()
        }
        blurView.isUserInteractionEnabled = false
    }
    func reloadView() {
        serial.delegate = self
        
        if serial.isReady {
            navItem.title = serial.connectedPeripheral!.name
            barButton.title = "Disconnect"
            barButton.tintColor = UIColor.red
            barButton.isEnabled = true
        } else if serial.centralManager.state == .poweredOn {
            navItem.title = "Bluetooth Serial"
            barButton.title = "Connect"
            barButton.tintColor = view.tintColor
            barButton.isEnabled = true
        } else {
            navItem.title = "Bluetooth Serial"
            barButton.title = "Connect"
            barButton.tintColor = view.tintColor
            barButton.isEnabled = false
        }
    }
    
    
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadView()
        //        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        //        hud?.mode = MBProgressHUDMode.text
        //        hud?.labelText = "Disconnected"
        //        hud?.hide(true, afterDelay: 1.0)
    }
    
    func serialDidChangeState() {
        reloadView()
        //        if serial.centralManager.state != .poweredOn {
        //            let hud = MBProgressHUD.showAdded(to: view, animated: true)
        //            hud?.mode = MBProgressHUDMode.text
        //            hud?.labelText = "Bluetooth turned off"
        //            hud?.hide(true, afterDelay: 1.0)
        //        }
    }
    
    
    
    /*CHANGE THIS*/
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !serial.isReady {
            _ = UIAlertController(title: "Not connected", message: "What am I supposed to send this to?", preferredStyle: .alert)
            return true
        }
        var msg = ""
        msg += "\n"
        serial.sendMessageToDevice(msg)
        return true
    }
    
    @IBAction func barButtonPressed(_ sender: AnyObject) {
        if serial.connectedPeripheral == nil {
            performSegue(withIdentifier: "ShowScanner", sender: self)
        } else {
            serial.disconnect()
            reloadView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count:Int?
        if(collectionView == self.collectionView){
            count = items.count
        }
        if(collectionView == self.collectionViewPallet){
            count = palletItems.count
        }
        return count!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell:UICollectionViewCell?
        if(collectionView == self.collectionView){
            let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CVCell
            
            cell1.myLabel.text = items[indexPath.item]
            cell1.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            
            cell = cell1
        }
        if(collectionView == self.collectionViewPallet){
            let cell2 = collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath)
            let hue: CGFloat = CGFloat((palletItems[indexPath.row][0] as NSString).doubleValue)
            let sat: CGFloat = CGFloat((palletItems[indexPath.row][1] as NSString).doubleValue)
            let bri: CGFloat = CGFloat((palletItems[indexPath.row][2] as NSString).doubleValue)
            cell2.backgroundColor = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: 1)
            cell2.layer.cornerRadius = 10.0
            cell = cell2
        }
        return cell!
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(colorPicker!.hasTouched){
            clickedPallet = false
            colorPicker!.hasTouched = false
        }
        if(!clickedPallet){
            currentHue = self.colorPicker!.HUE
            currentSat = self.colorPicker!.SAT
            currentBri = self.colorPicker!.BRI
        }
        
        if(collectionView == self.collectionView){
            let selectedCell = collectionView.cellForItem(at: indexPath)
            selectedCell?.backgroundColor = UIColor(hue: NumberFormatter().number(from: currentHue) as! CGFloat, saturation: NumberFormatter().number(from: currentSat) as! CGFloat, brightness: NumberFormatter().number(from: currentBri) as! CGFloat, alpha: 1)
            if(serial.isReady){
                if(!fillBucketOn){
                    lastUsedCell.append(["\(indexPath.row)", "\(currentHue)", "\(currentSat)", "\(currentBri)"])
                    serial.sendMessageToDevice("P;\(indexPath.row);\(currentHue);\(currentSat);\(currentBri)\n")
                    print("sent no fill")
                }else{
                    let cells = self.collectionView.visibleCells
                    for cell in cells {
                        cell.backgroundColor = UIColor(hue: NumberFormatter().number(from: currentHue) as! CGFloat, saturation: NumberFormatter().number(from: currentSat) as! CGFloat, brightness: NumberFormatter().number(from: currentBri) as! CGFloat, alpha: 1)
                    }
                    serial.sendMessageToDevice("F;\(0);\(currentHue);\(currentSat);\(currentBri)\n")
                    print("sent filled")
                }
                
            }
            print("HUE \(currentHue), SAT \(currentSat), BRI \(currentBri), Cell \(indexPath.row)")
        }
        
        if(collectionView == self.collectionViewPallet){
            deleteCellBorder()
            
            let selectedCell = collectionViewPallet.cellForItem(at: indexPath)
            currentHue = palletItems[indexPath.row][0]
            currentSat = palletItems[indexPath.row][1]
            currentBri = palletItems[indexPath.row][2]
            selectedCell?.layer.borderColor = UIColor.black.cgColor
            selectedCell?.layer.borderWidth = 1.0
            clickedPallet = true
        }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewAnimations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tbCell", for: indexPath)
        cell.textLabel?.text = tableViewAnimations[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        serial.sendMessageToDevice("A;\(indexPath.row)\n")
    }
    func deleteCellBorder(){
        for newCell in 0...palletItems.count{
            let newPath = IndexPath(row: newCell-1, section: 0)
            let selectedCell = collectionViewPallet.cellForItem(at: newPath)
            selectedCell?.layer.borderColor = UIColor.clear.cgColor
            selectedCell?.layer.borderWidth = 0
        }
        
    }
    
    @IBAction func clearColors(_ sender: UIButton) {
        for i in 0...items.count{
            let indexPath = IndexPath(row: i, section: 0)
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1)
        }
        if(serial.isReady){
            serial.sendMessageToDevice("z\n")
        }
    }
    @IBAction func clearPalletColors(_ sender: UIButton) {
        palletItems.append([colorPicker!.HUE, colorPicker!.SAT, colorPicker!.BRI])
        let indexPath = IndexPath(row: palletItems.count, section: 0)
        let cell = collectionViewPallet.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath)
        let hue: CGFloat = CGFloat((palletItems[indexPath.row-1][0] as NSString).doubleValue)
        let sat: CGFloat = CGFloat((palletItems[indexPath.row-1][1] as NSString).doubleValue)
        let bri: CGFloat = CGFloat((palletItems[indexPath.row-1][2] as NSString).doubleValue)
        cell.backgroundColor = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: 1)
        collectionViewPallet.reloadData()
    }
    @IBAction func connect4Button(_ sender: UIBarButtonItem) {
        serial.disconnect()
    }
    @IBAction func pressedFillBucket(_ sender: UIButton) {
        if(fillBucketOn){
            fillBucket.layer.borderWidth = 0
            fillBucket.layer.cornerRadius = 0
            fillBucketOn = false
        }else{
            fillBucket.layer.borderWidth = 1
            fillBucket.layer.cornerRadius = 7
            fillBucketOn = true
        }
    }
    @IBAction func pressedUndo(_ sender: UIButton) {
//
//        if(lastUsedCell.indices.contains(0)){
//
//            let indexPath = IndexPath(row: Int(lastUsedCell.last![0])!, section: 0)
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
//
//            let HUE = NumberFormatter().number(from: lastUsedCell.last![1])
//            let SAT = NumberFormatter().number(from: lastUsedCell.last![2])
//            let BRI = NumberFormatter().number(from: lastUsedCell.last![3])
//
//            cell.backgroundColor = UIColor(hue: CGFloat(HUE!), saturation: CGFloat(SAT!), brightness: CGFloat(BRI!), alpha: 1)
//            collectionViewPallet.reloadData()
//
//            serial.sendMessageToDevice("P;\(lastUsedCell.last![0]);\(lastUsedCell.last![1]);\(lastUsedCell.last![2]);\(lastUsedCell.last![3])\n")
//            lastUsedCell.removeLast()
//        }else{
//            print("There is no more to undo")
//        }
    }
    @IBAction func pressedEffectButton(_ sender: UIButton) {
        animateIn()
    }
    @IBAction func closePopup(_ sender: UIButton) {
        animateOut()
    }
    @IBAction func savePicture(_ sender: UIButton) {
    }
    @IBAction func loadPicture(_ sender: UIButton) {
    }
}
