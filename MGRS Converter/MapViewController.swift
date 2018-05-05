//
//  MapViewController.swift
//  MGRS Converter
//
//  Created by John Ayers on 5/4/18.
//  Copyright © 2018 Blacksmith Developers. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mgrsLabel: UILabel!
    @IBOutlet var latLonLabel: UILabel!
    
    let mapPin = MKPointAnnotation()
    
    override func loadView() {
        super.loadView()
        
        let segmentedControl = UISegmentedControl(items: ["Standard", "Satellite", "Hybrid"])
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(segmentedControl)
        
        let topConstraint = segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        let margins = view.layoutMarginsGuide
        let leadingConstraint = segmentedControl.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
        let trailingConstraint = segmentedControl.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        topConstraint.isActive = true
        leadingConstraint.isActive = true
        trailingConstraint.isActive = true
        
        segmentedControl.addTarget(self, action: #selector(MapViewController.mapTypeChanged(_:)), for: .valueChanged)
        
        latLonLabel.alpha = 0.0
        mgrsLabel.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if  appDelegate.sentCoordinates{
            if let coords = appDelegate.coordinates {
                coordinatesRecieved(coordinates: coords)
            }
            appDelegate.sentCoordinates = false
            appDelegate.coordinates = nil
        }
    }
    
    @objc func mapTypeChanged(_ segControl: UISegmentedControl){
        mapView.mapType = MKMapType.init(rawValue: UInt(segControl.selectedSegmentIndex)) ?? .standard
    }
    
    @IBAction func captureUserPressedLocation(sender: UILongPressGestureRecognizer){
        if sender.state != UIGestureRecognizerState.began {return}
        let touchLoc = sender.location(in: mapView)
        let locCoord = mapView.convert(touchLoc, toCoordinateFrom: mapView)
//        print("Tapped \(locCoord.latitude), \(locCoord.longitude)")
        coordinatesRecieved(coordinates: locCoord)
    }
    
    func coordinatesRecieved(coordinates: CLLocationCoordinate2D)
    {
        let locCoord = coordinates
        updateLabels(lat: locCoord.latitude, lon: locCoord.longitude)
        let region = MKCoordinateRegion(center: locCoord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        mapView.removeAnnotation(mapPin)
        mapPin.coordinate = locCoord
        mapView.addAnnotation(mapPin)
    }
    
    func updateLabels(lat: Double, lon: Double){
        
        let latLon = LatLon(lat: lat, lon: lon)
        latLonLabel.alpha = 0.5
        latLonLabel.text = "Lat/Lon:\n\(latLon.toString(format: DMSFormat.degreesMinutesSeconds, decimalPlaces: 2, newLinesForEachCoord: true))"
        do{
            let mgrs = try latLon.toUTM().toMGRS()
            mgrsLabel.alpha = 0.5
            mgrsLabel.text = "MGRS: \n\(mgrs.toString())"
        }
        catch {
            return
        }
    }
}
