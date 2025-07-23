//
//  LocationManager.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/17.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
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
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(latestLocation) { placemarks, error in
            if let place = placemarks?.first {
                self.placeName = place.name ?? "不明地點"
            }
        }
    }
}
