//
//  LocationProvider.swift
//  TpcWaterDispenserMap
//
//  Created by Riddle Ling on 2023/1/10.
//

import Foundation
import CoreLocation

class LocationProvider: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationProvider()
    
    private let locationManager: CLLocationManager
    public private(set) var isStop = true
    public private(set) var currentLocation : CLLocation?
    
    
    // MARK: - Init
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    
    // MARK: - Functions
        
    func start() {
        isStop = false
        locationManager.startUpdatingLocation()
    }
    
    func stop() {
        isStop = true
        locationManager.stopUpdatingLocation()
    }
    
    
    // MARK: - CLLocationManager Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
//        print("location: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        currentLocation = location
    }
}
