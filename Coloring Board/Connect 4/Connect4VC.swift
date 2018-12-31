//
//  Connect4VC.swift
//  Coloring Board
//
//  Created by Keegan Hutchins on 12/27/18.
//  Copyright © 2018 Neehaw. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import QuartzCore

class Connect4VC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate, BluetoothSerialDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var whoWonLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var playingAgainstLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var Player1Turn = true
    var hasWon = false
    var WhoWon = "Player 1"
    var pressedResetButton = false
    var enemyTypes = ["Easy", "Hard", "Two Players"]
    var gameType = "Easy"
    var moveNum = 0
    
    
    var gameBoard = ["0", "0", "0", "0", "0", "0", "0",
                     "0", "0", "0", "0", "0", "0", "0",
                     "0", "0", "0", "0", "0", "0", "0",
                     "0", "0", "0", "0", "0", "0", "0",
                     "0", "0", "0", "0", "0", "0", "0",
                     "0", "0", "0", "0", "0", "0", "0"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.dataSource = self
        pickerView.delegate = self
        whoWonLabel.isHidden = true
        collectionView.isHidden = true
        serial = BluetoothSerial(delegate: self)
        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
        cell.displayContent(image: #imageLiteral(resourceName: "test"))
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        var rowCounter = Int(floor(Double(indexPath.row / 6)))
        var row = 0
        if(rowCounter == 0){
            row = indexPath.row
        }else{
            row = indexPath.row + (5 * rowCounter)
        }
        if(rowCounter > 0){
            rowCounter = indexPath.row * rowCounter
        }
        print("row counter: \(rowCounter)")
        print("row: \(row)")
        if(gameBoard[indexPath.row] == "0"){                  //If space is available
            if(indexPath.row % 6 == 0){ // if pressed firstRow
                if(Player1Turn){
                    moveNum = moveNum+1
                    cell.displayContent(image: #imageLiteral(resourceName: "red"))
                    gameBoard[indexPath.row] = "1"
                    serial.sendMessageToDevice("P;\(row);\(0);\(100);\(100)\n")
                    Player1Turn = false
                }else{
                    if(gameType == "Two Players"){
                        cell.displayContent(image: #imageLiteral(resourceName: "yellow"))
                        gameBoard[indexPath.row] = "2"
                        serial.sendMessageToDevice("P;\(row);\(60);\(100);\(100)\n")
                        
                        Player1Turn = true
                    }
                }
                checkWin();
                if(gameType != "Two Players"){
                    findBestMove()
                }
            }else{
                if(gameBoard[indexPath.row-1] != "0"){
                    if(Player1Turn){
                        moveNum = moveNum+1
                        cell.displayContent(image: #imageLiteral(resourceName: "red"))
                        gameBoard[indexPath.row] = "1"
                        serial.sendMessageToDevice("P;\(row);\(0);\(100);\(100)\n")
                        Player1Turn = false
                    }else{
                        if(gameType == "Two Players"){
                            cell.displayContent(image: #imageLiteral(resourceName: "yellow"))
                            gameBoard[indexPath.row] = "2"
                            serial.sendMessageToDevice("P;\(row);\(60);\(100);\(100)\n")
                            
                            Player1Turn = true
                        }
                    }
                    checkWin();
                    if(gameType != "Two Players"){
                        findBestMove()
                    }
                }
            }
        }
    }
    var numInRow = 0
    var onP1 = true
    func checkWin(){
        ///Left and Right!!
        for item in 0...gameBoard.count-1{
            if(gameBoard[item] == "1"){
                if(!onP1){
                    numInRow = 0
                }
                onP1 = true
                numInRow = numInRow+1
            }else if(gameBoard[item] == "2"){
                if(onP1){
                    numInRow = 0
                }
                onP1 = false
                numInRow = numInRow+1
            }else{
                numInRow = 0
            }
            //Has Got 4 and Who Won
            if(numInRow == 4){
                didWin()
            }
        }
        
        
        //UP and DOWN PIECES
        for i in 0...6{
            for item in stride(from: i, to: gameBoard.count-1, by: 7) {
                if(gameBoard[item] == "1"){
                    if(!onP1){
                        numInRow = 0
                    }
                    onP1 = true
                    numInRow = numInRow+1
                }else if(gameBoard[item] == "2"){
                    if(onP1){
                        numInRow = 0
                    }
                    onP1 = false
                    numInRow = numInRow+1
                }else{
                    numInRow = 0
                }
                //Has Got 4 and Who Won
                if(numInRow == 4){
                    didWin()
                }
            }
        }
        
        //Diaginal(left to right) PIECES
        for i in 0...6{
            for item in stride(from: i, to: gameBoard.count-1, by: 8) {
                if(gameBoard[item] == "1"){
                    if(!onP1){
                        numInRow = 0
                    }
                    onP1 = true
                    numInRow = numInRow+1
                }else if(gameBoard[item] == "2"){
                    if(onP1){
                        numInRow = 0
                    }
                    onP1 = false
                    numInRow = numInRow+1
                }else{
                    numInRow = 0
                }
                //Has Got 4 and Who Won
                if(numInRow == 4){
                    didWin()
                }
            }
        }
        //Diaginal(left to right) PIECES
        for i in 0...6{
            for item in stride(from: i, to: gameBoard.count-1, by: 6) {
                if(gameBoard[item] == "1"){
                    if(!onP1){
                        numInRow = 0
                    }
                    onP1 = true
                    numInRow = numInRow+1
                }else if(gameBoard[item] == "2"){
                    if(onP1){
                        numInRow = 0
                    }
                    onP1 = false
                    numInRow = numInRow+1
                }else{
                    numInRow = 0
                }
                //Has Got 4 and Who Won
                if(numInRow == 4){
                    didWin()
                }
            }
        }
    }
    func findBestMove(){
        
        if(gameType == "Hard"){
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // change 2 to desired number of s
                self.gameBoard[38] = "2"
                let indexPath = IndexPath(row: 38, section: 0)
                let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
                cell.displayContent(image: #imageLiteral(resourceName: "yellow"))
                self.Player1Turn = true
            }
            self.collectionView.reloadData()
        }
    }
    func didWin(){
        hasWon = true
        if(onP1){
            WhoWon = "Player 1"
        }else{
            WhoWon = "Player 2"
        }
        whoWonLabel.isHidden = false
        whoWonLabel.text = "\(WhoWon) has won!!"
    }
    @IBAction func pressedReset(_ sender: UIButton) {
        pressedResetButton = true;
        for index in 0...gameBoard.count-1{
            gameBoard[index] = "0"
            let indexPath = IndexPath(row: index, section: 0)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
            //clear board
            serial.sendMessageToDevice("z\n")
            cell.displayContent(image: #imageLiteral(resourceName: "test"))
        }
        moveNum = 0
        hasWon = false
        whoWonLabel.isHidden = true
        collectionView.reloadData()
        
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return enemyTypes.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return enemyTypes[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        gameType = enemyTypes[row]
    }
    
    @IBAction func pressedBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func startGame(_ sender: UIButton) {
        collectionView.isHidden = false
        playButton.isHidden = true
        playingAgainstLabel.isHidden = true
        pickerView.isHidden = true
    }
    func reloadView() {
        serial.delegate = self
        serial.sendMessageToDevice("z\n")
    }
    func serialDidChangeState() {
        reloadView()
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadView()
    }
}
