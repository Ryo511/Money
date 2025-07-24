//
//  LocationManager.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/17.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var location: CLLocation?
    @Published var placeName: String = ""
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        self.location = latestLocation
        
        locationManager.stopUpdatingLocation()
        
        geocoder.reverseGeocodeLocation(latestLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let place = placemarks?.first {
                DispatchQueue.main.async {
                    self.placeName = place.name ?? "不明地點"
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失敗: \(error.localizedDescription)")
    }
}
