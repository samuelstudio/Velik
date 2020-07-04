//
//  LocationService.swift
//  Fietscomputer
//
//  Created by Grigory Avdyushin on 30/04/2020.
//  Copyright © 2020 Grigory Avdyushin. All rights reserved.
//

import MapKit
import Combine
import CoreLocation

class LocationService: NSObject, Service {

    let shouldAutostart = true

    enum State {
        case idle
        case monitoring
    }

    private let manager: CLLocationManager
    private var cancellable = Set<AnyCancellable>()

    private let speedPublisher = CurrentValueSubject<CLLocationSpeed, Never>(0)
    private(set) var speed: AnyPublisher<CLLocationSpeed, Never>

    private let locationPublisher = PassthroughSubject<CLLocation, Never>()
    private(set) var location: AnyPublisher<CLLocation, Never>

    private let statePublisher = CurrentValueSubject<State, Never>(.idle)
    private(set) var state: AnyPublisher<State, Never>

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        self.speed = speedPublisher.eraseToAnyPublisher()
        self.state = statePublisher.eraseToAnyPublisher()
        self.location = locationPublisher.eraseToAnyPublisher()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.showsBackgroundLocationIndicator = true
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
    }

    func start() {
        manager.startMonitoringSignificantLocationChanges()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        statePublisher.send(.monitoring)
    }

    func stop() {
        statePublisher.send(.idle)
        manager.stopMonitoringSignificantLocationChanges()
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
}

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else {
            return
        }
        speedPublisher.send(last.speed)
        locations.forEach {
            locationPublisher.send($0)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error)
    }
}
