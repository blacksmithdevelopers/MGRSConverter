//
//  ViewController.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/1/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var mgrsCoordsEnteredLabel: UILabel!
    @IBOutlet var mgrsCoordsDisplayedLabel: UILabel!
    @IBOutlet var latlonCoordsEnteredLabel: UILabel!
    @IBOutlet var latlonCoordsDisplayedLabel: UILabel!
    
    @IBOutlet var mgrsEnteredText: UITextField!
    @IBOutlet var latEnteredText: UITextField!
    @IBOutlet var lonEnteredText: UITextField!
    
    @IBOutlet var conversionLabel: UILabel!
    @IBOutlet var conversionDisplay: UILabel!
    @IBOutlet var newCoordsLabel: UILabel!
    @IBOutlet var newCoordsDisplay: UILabel!
    
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var seeOnMapButton: UIButton!
    
    var storedLatLon: LatLon?
    
    @IBAction func convertToLatLon() {
        if let mgrsEntered = mgrsEnteredText.text, mgrsEntered.count > 0 {
            do{
                let mgrs = try Mgrs.parse(fromString: mgrsEntered)
                let utm = try mgrs.toUTM()
                let latLon = utm.toLatLonE()
                
                latlonCoordsEnteredLabel.alpha = 0.0
                latlonCoordsDisplayedLabel.alpha = 0.0
                mgrsCoordsEnteredLabel.alpha = 1.0
                mgrsCoordsDisplayedLabel.alpha = 1.0
                mgrsCoordsDisplayedLabel.text = mgrs.toString(precision: 5)
                
                conversionLabel.alpha = 1.0
                conversionDisplay.alpha = 1.0
                conversionDisplay.text = "MGRS --> Lat/Lon"
                newCoordsLabel.alpha = 1.0
                newCoordsDisplay.alpha = 1.0
                newCoordsDisplay.text = latLon.toString(format: .degreesMinutesSeconds, decimalPlaces: 4)
                clearButton.alpha = 1.0
                seeOnMapButton.alpha = 1.0
                mgrsEnteredText.text = ""
                
                storedLatLon = latLon
                view.endEditing(true)
            }
            catch MgrsError.invalidFormat(let format) {
                displayAlertController(msg: format, thrower: .mgrs)
                return
            }
            catch MgrsError.invalidGrid(let grid) {
                displayAlertController(msg: grid, thrower: .mgrs)
                return
            }
            catch MgrsError.invalidZone(let zone) {
                displayAlertController(msg: zone, thrower: .mgrs)
                return
            }
            catch MgrsError.invalidBand(let band) {
                displayAlertController(msg: band, thrower: .mgrs)
                return
            }
            catch MgrsError.invalidEasting(let easting) {
                displayAlertController(msg: easting, thrower: .mgrs)
                return
            }
            catch MgrsError.invalidNorthing(let northing) {
                displayAlertController(msg: northing, thrower: .mgrs)
                return
            }
            catch UtmError.badLatLon(let err) {
                displayAlertController(msg: err, thrower: .utm )
                return
            }
            catch UtmError.invalidEasting(let easting) {
                displayAlertController(msg: easting, thrower: .utm)
                return
            }
            catch UtmError.invalidNorthing(let northing) {
                displayAlertController(msg: northing, thrower: .utm)
                return
            }
            catch UtmError.invalidZone(let zone) {
                displayAlertController(msg: zone, thrower: .utm)
                return
            }
            catch {
                displayAlertController(msg: "Unknown error occurred", thrower: .unk )
                return
            }
        } else {
            displayAlertController(msg: "Invalid MGRS Entered", thrower: .unk)
        }
    }
    @IBAction func convertToMGRS() {
        if let latEntered = latEnteredText.text, latEntered.count > 0, let lonEntered = lonEnteredText.text, lonEntered.count > 0 {
            do{
                let latLon = try LatLon.parseLatLon(stringToParse: "\(latEntered), \(lonEntered)")
                let utm = try latLon.toUTM()
                let mgrs = try utm.toMGRS()
                
                mgrsCoordsEnteredLabel.alpha = 0.0
                mgrsCoordsDisplayedLabel.alpha = 0.0
                latlonCoordsEnteredLabel.alpha = 1.0
                latlonCoordsDisplayedLabel.alpha = 1.0
                
                latlonCoordsDisplayedLabel.text =  latLon.toString(format: .degreesMinutesSeconds, decimalPlaces: 4)
                
                conversionLabel.alpha = 1.0
                conversionDisplay.alpha = 1.0
                conversionDisplay.text = "Lat/Lon --> MGRS"
                newCoordsLabel.alpha = 1.0
                newCoordsDisplay.alpha = 1.0
                newCoordsDisplay.text = mgrs.toString(precision: 5)
                clearButton.alpha = 1.0
                seeOnMapButton.alpha = 1.0
                mgrsEnteredText.text = ""
                latEnteredText.text = ""
                lonEnteredText.text = ""
                storedLatLon = latLon
                view.endEditing(true)
            }
            catch LatLonError.parseError(let err){
                displayAlertController(msg: err, thrower: .latLon )
                return
            }
            catch UtmError.badLatLon(let err) {
                displayAlertController(msg: err, thrower: .utm )
                return
            }
            catch UtmError.invalidEasting(let easting) {
                displayAlertController(msg: easting, thrower: .utm)
                return
            }
            catch UtmError.invalidNorthing(let northing) {
                displayAlertController(msg: northing, thrower: .utm)
                return
            }
            catch UtmError.invalidZone(let zone) {
                displayAlertController(msg: zone, thrower: .utm)
                return
            }
            catch MgrsError.invalidZone(let zone) {
                displayAlertController(msg: zone, thrower: .mgrs)
                return
            }
            catch MgrsError.invalidBand(let band) {
                displayAlertController(msg: band, thrower: .mgrs)
                return
            }
            catch {
                displayAlertController(msg: "Unknown error occurred", thrower: .unk )
                return
            }
            
        } else {
            displayAlertController(msg: "Invalid Lat/Lon Entered", thrower: .unk)
        }
    }
    
    @IBAction func clearResults() {
        clearDisplay()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "seeCoordsOnMap"?:
            if let latLon = storedLatLon {
                let toSend = CLLocationCoordinate2D(latitude: latLon.lat, longitude: latLon.lon)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.coordinates = toSend
                appDelegate.sentCoordinates = true
                
                self.tabBarController?.selectedIndex = 1
            }
        default:
            preconditionFailure("A segue was requested that does not exist")
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func backgroundTapped() {
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearDisplay()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clearDisplay(){
        conversionLabel.alpha = 0.0
        conversionDisplay.alpha = 0.0
        newCoordsLabel.alpha = 0.0
        newCoordsDisplay.alpha = 0.0
        clearButton.alpha = 0.0
        seeOnMapButton.alpha = 0.0
        mgrsCoordsEnteredLabel.alpha = 0.0
        mgrsCoordsDisplayedLabel.alpha = 0.0
        latlonCoordsEnteredLabel.alpha = 0.0
        latlonCoordsDisplayedLabel.alpha = 0.0
        mgrsEnteredText.text = ""
        latEnteredText.text = ""
        lonEnteredText.text = ""
        storedLatLon = nil
        view.endEditing(true)
    }
    
    func displayAlertController(msg: String, thrower: errorOrigin){
        let title: String
        switch thrower{
        case .mgrs:
            title = "Error Converting to MGRS"
        case .utm:
            title = "Error Converting to UTM"
        case .latLon:
            title = "Error Converting to Lat Lon"
        case .unk:
            title = "Error"
        }
        let converterAction = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default){ _ in
        }
        converterAction.addAction(okAction)
        
        present(converterAction, animated: true, completion: nil)
    }

    enum errorOrigin: Error{
        case mgrs
        case utm
        case latLon
        case unk
    }

}

