//
//  ViewController.swift
//  LabAssignment1
//
//  Created by Jaspinder Singh on 15/05/21.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    //MARK:- IBOutlets

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var stepper: UIStepper!
    
    //MARK:- Variables
    var coordinates = [CLLocationCoordinate2D]()
    var coordinateCount = 0
    private var oldValue: Double = 0
    private var userLocation: CLLocationCoordinate2D?
    private var locationManager = CLLocationManager()
    fileprivate let request = MKDirections.Request()
    
    //MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
    }
    
    //MARK:- SetUp Views
    private func initViews() {
        
        oldValue = stepper.value
        request.transportType = .automobile
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Check for Location Services
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        if let userLocation = locationManager.location?.coordinate {
            self.userLocation = userLocation
        }
        
        locationManager.startUpdatingLocation()
        
        // add long press gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapPress))
        tapGesture.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(tapGesture)
    }
    
    //MARK:- Tab Gesture on Map
    @objc func tapPress(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        if coordinates.count < 3 {
            setupMapView(coordinate)
        } else {
            if coordinates.contains(where: { first in
                return first.latitude == coordinate.latitude && first.longitude == coordinate.longitude
            }) {
                setupMapView(coordinate)
            } else {
                mapView.removeAnnotations(mapView.annotations)
                mapView.removeOverlays(mapView.overlays)
                coordinates = []
                setupMapView(coordinate)
            }
        }
    }
    
    
    // Location manager delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        let lat = userLocation.coordinate.latitude
        let long = userLocation.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.5
        let longDelta: CLLocationDegrees = 0.5
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        self.userLocation = location
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    //MARK:- Instance Methods
    func setupMapView(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        if coordinates.contains(where: { first in
            return first.latitude == coordinate.latitude && first.longitude == coordinate.longitude
        }) {
            let index = coordinates.firstIndex { first in
                return first.latitude == coordinate.latitude && first.longitude == coordinate.longitude
            }!
            coordinates.remove(at: index)
            mapView.removeAnnotation(annotation)
        } else {
            mapView.addAnnotation(annotation)
            coordinates.append(annotation.coordinate)
        }
        
        let titleForMarker = (coordinates.count == 1 ? "A" : coordinates.count == 2 ? "B" : "C")
        annotation.title = titleForMarker + "\n" + titleForMarker + "-Current = " + distanceBetweenTwoPath(userLocation!, coordinates[coordinates.count-1]).description
        if coordinates.count == 3 {
            let locations = coordinates.map {$0}
            let polyline = MKPolyline(coordinates: locations, count: locations.count)
            mapView.addOverlay(polyline)
            let polygon = MKPolygon(coordinates: locations, count: locations.count)
            mapView.addOverlay(polygon)
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        for i in 0..<coordinates.count {
            reSetupMapView(coordinates[i], i+1)
        }
    }
    
    
    func reSetupMapView(_ coordinate: CLLocationCoordinate2D, _ counter: Int) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        let titleForMarker = (counter == 1 ? "A" : counter == 2 ? "B" : "C")
        if coordinates.count == 1 {
            annotation.title = titleForMarker + "\n" + titleForMarker + "-Current = " + distanceBetweenTwoPath(userLocation!, coordinates[counter-1]).description
        } else if coordinates.count == 2 {
            var distanceBetweenTwo = distanceBetweenTwoPath(coordinates[0], coordinates[1])
            if titleForMarker == "A" {
                distanceBetweenTwo = "A-B=" + distanceBetweenTwo
            } else if titleForMarker == "B" {
                distanceBetweenTwo = "B-A=" + distanceBetweenTwo
            }
            
            annotation.title = titleForMarker + "\n" + titleForMarker + "-Current = " + distanceBetweenTwoPath(userLocation!, coordinates[counter-1]).description +
            "\n" + distanceBetweenTwo
            
        } else if coordinates.count == 3 {
            
            var distanceBetweenTwo = ""
            if titleForMarker == "A" {
                distanceBetweenTwo = "A-B=" + distanceBetweenTwoPath(coordinates[0], coordinates[1]) + "\n" + "A-C=" + distanceBetweenTwoPath(coordinates[0], coordinates[2])
            } else if titleForMarker == "B" {
                distanceBetweenTwo = "B-A=" + distanceBetweenTwoPath(coordinates[0], coordinates[1]) + "\n" + "B-C=" + distanceBetweenTwoPath(coordinates[1], coordinates[2])
            } else if titleForMarker == "C" {
                distanceBetweenTwo = "C-A=" + distanceBetweenTwoPath(coordinates[0], coordinates[2]) + "\n" + "C-B=" + distanceBetweenTwoPath(coordinates[1], coordinates[2])
            }
            
            annotation.title = titleForMarker + "\n" + titleForMarker + "-Current = " + distanceBetweenTwoPath(userLocation!, coordinates[counter-1]).description +
                "\n" + distanceBetweenTwo
        }
        if counter == 3 {
            let locations = coordinates.map {$0}
            let polyline = MKPolyline(coordinates: locations, count: locations.count)
            mapView.addOverlay(polyline)
            let polygon = MKPolygon(coordinates: locations, count: locations.count)
            mapView.addOverlay(polygon)
        }
    }
    
    func distanceBetweenTwoPath(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> String {
        var distanceInMeters = CLLocationDistance()
        if coordinates.count > 0 {
            let coordinate1 = CLLocation(latitude: first.latitude, longitude: first.longitude)
            let coordinate2 = CLLocation(latitude: second.latitude, longitude: second.longitude)
            //Decalare distanceInMeters as global variables so that you can show distance on subtitles
            distanceInMeters = coordinate1.distance(from: coordinate2)
            print(distanceInMeters/1000)
        }
        return String(format: "%.1f", distanceInMeters/1000.0) + " km"
//        String(format: "%.2f", distanceInMeters/1000.0)
    }
    
    @IBAction func getRouteButtonClicked(_ sender: Any) {
        makeRoute()
    }
    
    
    func makeRoute() {
        mapView.removeOverlays(mapView.overlays)
        if mapView.overlays.count == 0 {
            for i in 0..<coordinates.count {
                if i+1 < coordinates.count {
                    getRoute(coordinates[i], coordinates[i + 1])
                } else {
                    getRoute(coordinates[i], coordinates[0])
                }
            }
        }
    }
    
    // Get route between locations
    func getRoute(_ initial: CLLocationCoordinate2D?, _ destination: CLLocationCoordinate2D?) {
        guard let currentLocation = initial, let destination = destination else {
            return
        }
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        let directions = MKDirections(request: request)
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else {
                print(error?.localizedDescription ?? "")
                return
            }
            let route = unwrappedResponse.routes[0]
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }
    
    @IBAction func zoomInOut(_ sender: UIStepper) {
        if sender.value > oldValue {
            oldValue += 1
            let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta / 2, longitudeDelta: mapView.region.span.longitudeDelta / 2)
            let region = MKCoordinateRegion(center: mapView.region.center, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            oldValue -= 1
            let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta * 2, longitudeDelta: mapView.region.span.longitudeDelta * 2)
            let region = MKCoordinateRegion(center: mapView.region.center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
}

extension ViewController: MKMapViewDelegate {
    // This Function is needed to add overlays
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.red
            rendrer.lineWidth = 5
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 5
            return rendrer
        } else {
            let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
            renderer.strokeColor = UIColor.red.withAlphaComponent(0.65)
            if self.request.transportType == .walking {
                renderer.lineDashPattern = [0, 10]
            }
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        coordinates.removeAll { (loc) -> Bool in
            return loc.latitude == view.annotation?.coordinate.latitude
        }
        mapView.removeAnnotation(view.annotation!)
        mapView.removeOverlays(mapView.overlays)
    }
}


