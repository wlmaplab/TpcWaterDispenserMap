//
//  ContentView.swift
//  TpcWaterDispenserMap
//
//  Created by Riddle Ling on 2023/1/10.
//

import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    
    @ObservedObject var dataFetcher = DataFetcher()
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isShowPlaceSearchView = false
    @State private var mapItem : MKMapItem?
    @State private var segmentedValue = 0
    
    private let mapView = MapView()
    
    var body: some View {
        ZStack {
            mapView
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    VStack(spacing: 0) {
                        Button(action: {
                            isShowPlaceSearchView.toggle()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .frame(width: 45, height: 45, alignment: .center)
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(colorScheme == .dark ? .white : .blue)
                        }
                        .sheet(isPresented: $isShowPlaceSearchView){
                            PlaceSearchView(isShowPlaceSearchView: $isShowPlaceSearchView, mapItem: $mapItem)
                        }
                        
                        if mapItem != nil {
                            Divider()
                                .frame(width: 45)
                                .background(colorScheme == .dark ? Color.white : Color(UIColor(white: 0.9, alpha: 1.0)))
                            
                            Button(action: {
                                mapView.moveToPlace()
                            }) {
                                Image(systemName: "mappin")
                                    .frame(width: 45, height: 45, alignment: .center)
                                    .font(.system(size: 20, weight: .medium, design: .default))
                                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                            }
                        }
                        
                        Divider()
                            .frame(width: 45)
                            .background(colorScheme == .dark ? Color.white : Color(UIColor(white: 0.9, alpha: 1.0)))
                        
                        Button(action: {
                            mapView.moveToUserLocation()
                        }) {
                            Image(systemName: "figure.stand")
                                .frame(width: 45, height: 45, alignment: .center)
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(colorScheme == .dark ? .white : .blue)
                        }
                    }
                    .background(Color(colorScheme == .dark ? .systemGray4 : .white))
                    .cornerRadius(10)
                    .padding(8)
                    .shadow(color: Color(colorScheme == .dark ? .systemGray6 : UIColor(white: 0.8, alpha: 1.0)),
                            radius: 4, x: 0, y: 0),
                    alignment: .topTrailing
                )
                .overlay(
                    SegmentedControlView(selectedValue: $segmentedValue)
                        .onChange(of: segmentedValue) { value in
                            print("segmentedValue: \(value)")
                            dataFetcher.loadData(value)
                        },
                    alignment: .bottom
                )
                .onReceive(dataFetcher.$dataArray) { dataArray in
                    if dataArray != nil {
                        mapView.addData(dataArray!)
                    }
                }
                .onChange(of: mapItem) { newMapItem in
                    mapView.addPlace(newMapItem)
                }
                .onAppear {
                    Task {
                        await dataFetcher.download()
                    }
                }
            
            
            if dataFetcher.dataArray == nil {
                DownloadProgressView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DownloadProgressView: View {
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            ProgressView()
                .scaleEffect(1.2, anchor: .center)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
            Text("下載座標資料...")
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
        }
        .frame(width: 185, height: 110, alignment: .center)
        .background(Color(UIColor(white: 0.35, alpha: 1.0)))
        .cornerRadius(18)
    }
}

struct SegmentedControlView: View {
    @Binding var selectedValue : Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedValue) {
                Text("全部").tag(0)
                Text("飲水機").tag(1)
                Text("直飲臺").tag(2)
            }
            .pickerStyle(.segmented)
            .background(Color(colorScheme == .dark ? UIColor(white: 0, alpha: 1) : UIColor(white: 0.7, alpha: 0.5)))
            .cornerRadius(8)
        }
        .padding(25)
    }
}
