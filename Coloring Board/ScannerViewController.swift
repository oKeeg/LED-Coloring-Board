//
//  ScannerViewController.swift
//  Coloring Board
//
//  Created by Keegan Hutchins on 12/20/18.
//  Copyright © 2018 Neehaw. All rights reserved.
//

import UIKit
import CoreBluetooth

final class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BluetoothSerialDelegate {

//MARK: IBOutlets
    let alert = UIAlertController(title: "Disconnected", message: "You have been disconnected", preferredStyle: .alert)
    let resolve = UIAlertAction(title: "OK", style: .cancel){ (resolve) in
        
    }
    
    @IBOutlet weak var tryAgainButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    
//MARK: Variables
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tryAgainButton.isEnabled = false
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        serial.delegate = self
        
        if serial.centralManager.state != .poweredOn {
            title = "Bluetooth not turned on"
            return
        }
        serial.startScan()
        Timer.scheduledTimer(timeInterval: 7, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func scanTimeOut() {
        serial.stopScan()
        tryAgainButton.isEnabled = true
        title = "Done scanning"
    }
    
    func connectTimeOut() {
        if let _ = serial.connectedPeripheral {
            return
        }
        
        if let _ = selectedPeripheral {
            serial.disconnect()
            selectedPeripheral = nil
        }
        
        // failed to connect
        self.present(alert, animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let label = cell.viewWithTag(1) as! UILabel
        label.text = peripherals[(indexPath as NSIndexPath).row].peripheral.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        serial.stopScan()
        selectedPeripheral = peripherals[(indexPath as NSIndexPath).row].peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(ScannerViewController.connectTimeOut), userInfo: nil, repeats: false)
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append(peripheral: peripheral, RSSI: theRSSI)
        peripherals.sort { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        self.present(alert, animated: true, completion: nil)
        
        tryAgainButton.isEnabled = true
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        
        tryAgainButton.isEnabled = true
        self.present(alert, animated: true, completion: nil)

    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
        dismiss(animated: true, completion: nil)
    }
    
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
            dismiss(animated: true, completion: nil)
        }
    }
    

    @IBAction func cancel(_ sender: AnyObject) {
        serial.stopScan()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tryAgain(_ sender: AnyObject) {
        peripherals = []
        tableView.reloadData()
        tryAgainButton.isEnabled = false
        title = "Scanning ..."
        serial.startScan()
        Timer.scheduledTimer(timeInterval: 7, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }
    
}
