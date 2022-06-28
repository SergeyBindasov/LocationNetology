//
//  ViewController.swift
//  LocationNetology
//
//  Created by Sergey on 27.06.2022.
//

import UIKit
import MapKit
import CoreLocation

class LocationViewController: UIViewController {
    
    private lazy var mapView = MKMapView()
    
    private lazy var locationManager = CLLocationManager()
    
    private lazy var press = UILongPressGestureRecognizer(target: self, action: #selector(pressDone))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        configureMap()
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        mapView.addGestureRecognizer(press)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .done, target: self, action: #selector(deleteAllPins))
    }
}

extension LocationViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserLocationPermissions()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2500, longitudinalMeters: 2500)
        mapView.setRegion(region, animated: true)
    }
}

extension LocationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 135/255.0, green: 189/255.0, blue: 216/255.0, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
    }
}

extension LocationViewController {
    
    @objc func pressDone() {
        let location = press.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        addPins(coordinates: coordinate)
        /// ЧТОБЫ НА КАРТЕ БЫЛ ТОЛЬКО ОДИН МАРШРУТ
        //removeLastPin()
    }
    
    @objc func deleteAllPins() {
        mapView.annotations.forEach { [weak self] pin in
            self?.mapView.removeAnnotation(pin)
        }
        mapView.overlays.forEach { [weak self] roadPath in
            self?.mapView.removeOverlay(roadPath)
        }
    }
    
    func removeLastPin() {
        guard let lastPath = mapView.overlays.first else { return }
        if mapView.annotations.count > 1 {
            mapView.annotations.forEach { [weak self] pin in
                self?.mapView.removeAnnotation(pin)
            }
        }
        mapView.removeOverlay(lastPath)
    }
    
    func addPins(coordinates: CLLocationCoordinate2D) {
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
        mapView.addAnnotation(pin)
        addRoute(coordinates: coordinates)
    }
    
    private func addRoute(coordinates: CLLocationCoordinate2D) {
        let directionRequest = MKDirections.Request()
        
        let sourcePlaceMark = MKPlacemark(coordinate: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        
        let destinationPlaceMark = MKPlacemark(coordinate: coordinates)
        let destinationMapItem = MKMapItem(placemark: destinationPlaceMark)
        
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] response, error -> Void in
            guard let self = self else {
                return
            }
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            self.mapView.delegate = self
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func checkUserLocationPermissions() {
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            
        case .denied, .restricted:
            print("Попросить пользователя зайти в настрйки")
            
        @unknown default:
            fatalError("Не обрабатываемый статус")
        }
    }
    
    func configureMap() {
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.mapType = .hybrid
    }
    
    func setupLayout() {
        view.backgroundColor = .white
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
