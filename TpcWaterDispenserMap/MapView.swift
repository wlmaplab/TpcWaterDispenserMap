//
//  MapView.swift
//  TpcWaterDispenserMap
//
//  Created by Riddle Ling on 2023/1/10.
//

import SwiftUI
import MapKit


struct MapView: UIViewRepresentable {
    typealias UIViewType = WaterDispenserMapView
    private let mapView = WaterDispenserMapView()
    
    func makeUIView(context: Self.Context) -> Self.UIViewType {
        mapView.moveToSite()
        mapView.setup()
        
        return mapView
    }
            
    func updateUIView(_ nsView: Self.UIViewType, context: Self.Context) {
        
    }
    
    // MARK: - Functions
    
    func moveToUserLocation() {
        mapView.moveToUserLocation()
    }
    
    func moveToPlace() {
        mapView.moveToPlace()
    }
    
    func addPlace(_ mapItem: MKMapItem?) {
        mapView.addPlace(mapItem)
    }
    
    func addData(_ array: [WaterDispenser]) {
        mapView.addWaterDispenserData(array)
    }
}


class WaterDispenserMapView: MKMapView, MKMapViewDelegate {
    
    //台北車站
    let taipeiSiteCoordinate = CLLocationCoordinate2D(latitude: 25.046856,
                                                      longitude: 121.516923)
    
    private var firstTimeMoveToUserLocation = true
    private var placeAnnotation : MapPin?
    private var selectedAnnotation : MapPin?
    
    func setup() {
        self.delegate = self
        self.isPitchEnabled = false
        self.moveToSite()
        
        self.showsUserLocation = true
        self.showsCompass = false
        self.addCompassButton()
        
        self.showsScale = false
        self.addScaleView()
    }
    
    func moveToSite() {
        let region = MKCoordinateRegion(center: taipeiSiteCoordinate,
                                        latitudinalMeters: 500,
                                        longitudinalMeters: 500)
        
        self.setRegion(region, animated: false)
    }
    
    func moveToUserLocation() {
        guard let location = self.userLocation.location else { return }
        self.setCenter(location.coordinate, animated: true)
    }
    
    func moveToPlace() {
        guard let placeAnnotation = self.placeAnnotation else { return }
        self.setCenter(placeAnnotation.coordinate, animated: true)
        self.selectAnnotation(placeAnnotation, animated: true)
    }
    
    func addPlace(_ mapItem: MKMapItem?) {
        if let oldPlaceAnnotation = self.placeAnnotation {
            self.removeAnnotation(oldPlaceAnnotation)
        }
        
        guard let place = mapItem else {
            self.placeAnnotation = nil
            return
        }
        
        let annotation = MapPin(coordinate: place.placemark.coordinate,
                                image: UIImage(named: "PlacePin"),
                                address: place.name,
                                info: nil)
        
        self.placeAnnotation = annotation
        self.addAnnotation(annotation)
        self.setCenter(annotation.coordinate, animated: false)
        self.selectAnnotation(annotation, animated: true)
    }
    
    func addWaterDispenserData(_ array: [WaterDispenser]) {
        self.removeAnnotations(self.annotations)
        
        var pins = [MapPin]()
        for item in array {
            let image : UIImage?
            switch item.waterType {
            case .waterDispenser: image = UIImage(named: "WDPin")
            case .tapWater : image = UIImage(named: "TapWaterPin")
            }
            let annotation = MapPin(coordinate: item.coordinate,
                                    image: image,
                                    address: item.address,
                                    info: item.info)
            pins.append(annotation)
        }
        self.addAnnotations(pins)
    }
    
    private func addCompassButton() {
        let compassButton = MKCompassButton(mapView: self)
        compassButton.compassVisibility = .adaptive
        self.addSubview(compassButton)
        
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            compassButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            compassButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10)
        ])
    }
    
    private func addScaleView() {
        let scaleView = MKScaleView(mapView: self)
        scaleView.scaleVisibility = .adaptive
        scaleView.legendAlignment = .trailing
        self.addSubview(scaleView)
        
        scaleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scaleView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
            scaleView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
    }
    
    
    // MARK: - MKMapView Delegate
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let location = userLocation.location else { return }
        
        if firstTimeMoveToUserLocation {
//            print("緯度:\(location.coordinate.latitude), 經度: \(location.coordinate.longitude)")
            firstTimeMoveToUserLocation = false
            
            let region = MKCoordinateRegion(center: location.coordinate,
                                            latitudinalMeters: 500,
                                            longitudinalMeters: 500)
            
            self.setRegion(region, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MapPin {
            let identifier = "WaterDispenserPin"
            var annoView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? PinAnnotationView
            if annoView == nil {
                annoView = PinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            
            let anno = annotation as! MapPin
            setMapAnnotationView(annoView, annotation: anno)
            let text = anno.info ?? anno.address
            setCalloutViewWith(annotationView: annoView, text: "\(text ?? "")")
            
            return annoView
        }
        return nil
    }
    
    // MARK: - MapAnnotationView / Detail Callout View
        
    func setMapAnnotationView(_ annotationView: PinAnnotationView?, annotation: MapPin) {
        annotationView?.image      = annotation.image
        annotationView?.coordinate = annotation.coordinate
        
        annotationView?.selectedAction = { [weak self] (coordinate) in
            self?.selectedAnnotationAction(annotation, coordinate: coordinate)
        }
    }
    
    func setCalloutViewWith(annotationView: MKAnnotationView?, text: String) {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = text
        
        annotationView?.detailCalloutAccessoryView = label
        annotationView?.canShowCallout = true
        
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        button.addTarget(self, action: #selector(openAppleMaps), for: .touchUpInside)
        
        let symbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let symbolImage = UIImage(systemName: "location.circle.fill", withConfiguration: symbolConfiguration)
        
        button.setImage(symbolImage, for: .normal)
        annotationView?.rightCalloutAccessoryView = button
    }
    
    @objc func openAppleMaps() {
        guard let coordinate1 = self.userLocation.location?.coordinate else { return }
        let placemark1 = MKPlacemark(coordinate: coordinate1)
        
        guard let coordinate2 = self.selectedAnnotation?.coordinate else { return }
        let placemark2 = MKPlacemark(coordinate: coordinate2)
    
        let mapItem1 = MKMapItem(placemark: placemark1)
        let mapItem2 = MKMapItem(placemark: placemark2)
                
        mapItem1.name = "現在位置"
        mapItem2.name = self.selectedAnnotation?.address ?? "目標飲水機"
                
        MKMapItem.openMaps(with: [mapItem1, mapItem2],
                           launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
    
    
    // MARK: - Selected Annotation Action
        
    func selectedAnnotationAction(_ annotation: MapPin, coordinate: CLLocationCoordinate2D) {
        self.selectedAnnotation = annotation
        let coord = CLLocationCoordinate2D(latitude: coordinate.latitude + 0.0003, longitude: coordinate.longitude)
        self.setCenter(coord, animated: true)
    }
}


class MapPin: NSObject, MKAnnotation {
    var coordinate : CLLocationCoordinate2D
    var image : UIImage?
    var address : String?
    var info : String?
    
    init(coordinate: CLLocationCoordinate2D, image: UIImage?, address: String?, info: String?) {
        self.coordinate = coordinate
        self.image = image
        self.address = address
        self.info = info
    }
}

class PinAnnotationView: MKAnnotationView {

    var coordinate : CLLocationCoordinate2D
    var selectedAction : ((_ coordinate: CLLocationCoordinate2D) -> Void)?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            if let action = selectedAction {
                action(coordinate)
            }
        }
    }
}
