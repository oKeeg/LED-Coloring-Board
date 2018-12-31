//
//  BluetoothSerial.swift
//  Coloring Board
//
//  Created by Keegan Hutchins on 12/20/18.
//  Copyright © 2018 Neehaw. All rights reserved.
//
//

import UIKit
import CoreBluetooth

var serial: BluetoothSerial!
protocol BluetoothSerialDelegate {
    /// state of the CBCentralManager changes (e.g. when bluetooth is turned on/off)
    func serialDidChangeState()
    /// Called when a peripheral disconnected
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?)

    func serialDidReceiveString(_ message: String)
    func serialDidReceiveBytes(_ bytes: [UInt8])
    func serialDidReceiveData(_ data: Data)
    func serialDidReadRSSI(_ rssi: NSNumber)
    
    /// Called when a new peripheral is discovered while scanning. Also gives the RSSI (signal strength)
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?)

    /// Called when a peripheral is connected (but not yet ready for communication)
    func serialDidConnect(_ peripheral: CBPeripheral)
    
    /// Called when a pending connection failed
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?)

    /// Called when a peripheral is ready for communication
    func serialIsReady(_ peripheral: CBPeripheral)
}

extension BluetoothSerialDelegate {
    func serialDidReceiveString(_ message: String) {}
    func serialDidReceiveBytes(_ bytes: [UInt8]) {}
    func serialDidReceiveData(_ data: Data) {}
    func serialDidReadRSSI(_ rssi: NSNumber) {}
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {}
    func serialDidConnect(_ peripheral: CBPeripheral) {}
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {}
    func serialIsReady(_ peripheral: CBPeripheral) {}
}


final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var delegate: BluetoothSerialDelegate!
    var centralManager: CBCentralManager!
    var pendingPeripheral: CBPeripheral?
    var connectedPeripheral: CBPeripheral?
    weak var writeCharacteristic: CBCharacteristic?
        var isReady: Bool {
        get {
            return centralManager.state == .poweredOn &&
                   connectedPeripheral != nil &&
                   writeCharacteristic != nil
        }
    }
    var isScanning: Bool {
        return centralManager.isScanning
    }
    
    var isPoweredOn: Bool {
        return centralManager.state == .poweredOn
    }
    
    /// UUID of the service to look for.
    var serviceUUID = CBUUID(string: "FFE0")
    /// UUID of the characteristic to look for.
    var characteristicUUID = CBUUID(string: "FFE1")
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    init(delegate: BluetoothSerialDelegate) {
        super.init()
        self.delegate = delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
        func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        // start scanning for peripherals with correct service UUID
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
        // retrieve peripherals that are already connected
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        for peripheral in peripherals {
            delegate.serialDidDiscoverPeripheral(peripheral, RSSI: nil)
        }
    }
        func stopScan() {
        centralManager.stopScan()
    }
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        } else if let p = pendingPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
    }
    
    /// The didReadRSSI delegate function will be called after calling this function
    func readRSSI() {
        guard isReady else { return }
        connectedPeripheral!.readRSSI()
    }
        func sendMessageToDevice(_ message: String) {
        guard isReady else { return }
        
        if let data = message.data(using: String.Encoding.utf8) {
            connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
        }
    }
        func sendBytesToDevice(_ bytes: [UInt8]) {
        guard isReady else { return }
        
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
        func sendDataToDevice(_ data: Data) {
        guard isReady else { return }
        
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        delegate.serialDidDiscoverPeripheral(peripheral, RSSI: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        delegate.serialDidConnect(peripheral)
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        pendingPeripheral = nil
        delegate.serialDidDisconnect(peripheral, error: error as NSError?)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        pendingPeripheral = nil
        delegate.serialDidFailToConnect(peripheral, error: error as NSError?)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        connectedPeripheral = nil
        pendingPeripheral = nil
        delegate.serialDidChangeState()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // discover the 0xFFE1 characteristic for all services (though there should only be one)
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // check whether the characteristic we're looking for (0xFFE1) is present - just to be sure
        for characteristic in service.characteristics! {
            if characteristic.uuid == characteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                writeCharacteristic = characteristic
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                delegate.serialIsReady(peripheral)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        guard data != nil else { return }
        delegate.serialDidReceiveData(data!)
        if let str = String(data: data!, encoding: String.Encoding.utf8) {
            delegate.serialDidReceiveString(str)
        }
        var bytes = [UInt8](repeating: 0, count: data!.count / MemoryLayout<UInt8>.size)
        (data! as NSData).getBytes(&bytes, length: data!.count)
        delegate.serialDidReceiveBytes(bytes)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate.serialDidReadRSSI(RSSI)
    }
}
