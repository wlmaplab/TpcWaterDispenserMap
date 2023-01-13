//
//  DataFetcher.swift
//  TpcWaterDispenserMap
//
//  Created by Riddle Ling on 2023/1/10.
//

import Foundation
import MapKit


enum WaterType {
    case waterDispenser
    case tapWater
}


struct WaterDispenser: Identifiable {
    let id = UUID()
    let coordinate : CLLocationCoordinate2D
    let address : String
    let info : String
    let waterType : WaterType
}


@MainActor
class DataFetcher: ObservableObject {
    
    @Published var dataArray : [WaterDispenser]?
    private var allData: [WaterDispenser]?
    
    private let fetchLimit = 1000
    private var fetchOffset = 0
    private var dispenserResults : Array<Dictionary<String,Any>>?
    private var tapWaterResults : Array<Dictionary<String,Any>>?
    
    private let infoUrlString = "https://wlmaplab.github.io/json/tpc-water-dispenser-dataset.json"
    private var dispenserUrlString = ""
    private var tapWaterUrlString = ""
    
    
    // MARK: - Functions
    
    func download() async {
        print(">> 正在下載資料集...")
        dataArray = nil
        
        dispenserResults = Array<Dictionary<String,Any>>()
        tapWaterResults = Array<Dictionary<String,Any>>()
        fetchOffset = 0
        
        await downloadInfoJson()
    }
    
    func loadData(_ value: Int) {
        if value == 1 {  // dispenser
            var tmpArray = [WaterDispenser]()
            if let array = allData {
                for item in array {
                    if item.waterType == .waterDispenser {
                        tmpArray.append(item)
                    }
                }
                dataArray = tmpArray
            }
        } else if value == 2 {  // tapWater
            var tmpArray = [WaterDispenser]()
            if let array = allData {
                for item in array {
                    if item.waterType == .tapWater {
                        tmpArray.append(item)
                    }
                }
                dataArray = tmpArray
            }
        } else {
            dataArray = allData
        }
        print(">> dataArray count: \(dataArray?.count ?? 0)")
    }
    
    
    // MARK: - Download Data
    
    private func downloadInfoJson() async {
        if let json = try? await httpGET_withFetchJsonObject(URLString: infoUrlString),
           let wdUrlStr = json["WaterDispenser"] as? String,
           let twUrlStr = json["TapWater"] as? String
        {
            dispenserUrlString = wdUrlStr
            tapWaterUrlString = twUrlStr
            await downloadDispenserData()
        }
    }
    
    private func downloadDispenserData() async {
        var resultsCount = 0
        if let json = try? await fetchDispenser(limit: fetchLimit, offset: fetchOffset),
           let result = json["result"] as? Dictionary<String,Any>,
           let results = result["results"] as? Array<Dictionary<String,Any>>
        {
            dispenserResults?.append(contentsOf: results)
            resultsCount = results.count
            
            if resultsCount >= fetchLimit {
                fetchOffset += fetchLimit
                await downloadDispenserData()
            } else {
                fetchOffset = 0
                await downloadTapWaterData()
            }
        }
    }
    
    private func downloadTapWaterData() async {
        var resultsCount = 0
        if let json = try? await fetchTapWater(limit: fetchLimit, offset: fetchOffset),
           let result = json["result"] as? Dictionary<String,Any>,
           let results = result["results"] as? Array<Dictionary<String,Any>>
        {
            tapWaterResults?.append(contentsOf: results)
            resultsCount = results.count
            
            if resultsCount >= fetchLimit {
                fetchOffset += fetchLimit
                await downloadTapWaterData()
            } else {
                convertResultsToDataArray()
            }
        }
    }
    
    private func convertResultsToDataArray() {
        var tmpArray = [WaterDispenser]()
        
        if let results1 = dispenserResults {
            for info in results1 {
                if let item = createWaterDispenserItem(info) {
                    tmpArray.append(item)
                }
            }
            print(">> dispenser count: \(results1.count)")
        }
        
        if let results2 = tapWaterResults {
            for info in results2 {
                if let item = createTapWaterItem(info) {
                    tmpArray.append(item)
                }
            }
            print(">> tapWater count: \(results2.count)")
        }
        
        allData = tmpArray
        loadData(0)
    }
    
    
    // MARK: - WaterDispenser Item
    
    private func createWaterDispenserItem(_ info: Dictionary<String,Any>) -> WaterDispenser? {
        let latitude = Double("\(info["緯度"] ?? "")")
        let longitude = Double("\(info["經度"] ?? "")")
        
        if let lat = latitude, let lng = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let address = "\(info["場所名稱"] ?? "")（\(info["場所地址"] ?? "")）"
            let info = "【公共飲水機】\n\n◎ 場所名稱：\(info["場所名稱"] ?? "")\n◎ 場所地址：\(info["場所地址"] ?? "")\n◎ 開放時間：\(info["場所開放時間"] ?? "")\n◎ 連絡電話：\(info["連絡電話"] ?? "")\n◎ 飲水台數：\(info["飲水台數"] ?? "")"
            return WaterDispenser(coordinate: coordinate, address: address, info: info, waterType: .waterDispenser)
        }
        return nil
    }
    
    private func createTapWaterItem(_ info: Dictionary<String,Any>) -> WaterDispenser? {
        let latitude = Double("\(info["緯度"] ?? "")")
        let longitude = Double("\(info["經度"] ?? "")")
        
        if let lat = latitude, let lng = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let address = "\(info["場所名稱"] ?? "")（\(info["地址"] ?? "")）"
            let info = "【自來水直飲臺】\n\n◎ 場所名稱：\(info["場所名稱"] ?? "")\n◎ 場所地址：\(info["地址"] ?? "")\n◎ 開放時間：\(info["場所開放時間"] ?? "")\n◎ 連絡電話：\(info["連絡電話"] ?? "")\n◎ 直飲臺編號：\(info["直飲臺編號"] ?? "")\n◎ 狀態：\(info["狀態"] ?? "")\n◎ 狀態異動日期時間：\(info["狀態異動日期時間"] ?? "")\n◎ 大腸桿菌數：\(info["大腸桿菌數"] ?? "")\n◎ 最近採樣日期時間：\(info["最近採樣日期時間"] ?? "")"
            return WaterDispenser(coordinate: coordinate, address: address, info: info, waterType: .tapWater)
        }
        return nil
    }
    
    
    // MARK: - Fetch Data
    
    private func fetchDispenser(limit: Int, offset: Int) async throws -> [String: Any]? {
        let json = try await httpGET_withFetchJsonObject(URLString: "\(dispenserUrlString)&limit=\(limit)&offset=\(offset)")
        return json
    }
    
    private func fetchTapWater(limit: Int, offset: Int) async throws -> [String: Any]? {
        let json = try await httpGET_withFetchJsonObject(URLString: "\(tapWaterUrlString)&limit=\(limit)&offset=\(offset)")
        return json
    }
    
    
    // MARK: - HTTP GET
    
    private func httpGET_withFetchJsonObject(URLString: String) async throws -> [String: Any]? {
        let json = try await httpRequestWithFetchJsonObject(httpMethod: "GET", URLString: URLString, parameters: nil)
        return json
    }
    
    
    // MARK: - HTTP Request with Method
    
    private func httpRequestWithFetchJsonObject(httpMethod: String,
                                                URLString: String,
                                                parameters: Dictionary<String,Any>?) async throws -> [String: Any]?
    {
        // Create request
        let url = URL(string: URLString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        // Header
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        // Body
        if let parameterDict = parameters {
            // parameter dict to json data
            let jsonData = try? JSONSerialization.data(withJSONObject: parameterDict)
            // insert json data to the request
            request.httpBody = jsonData
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let json = json as? [String: Any] {
            return json
        }
        return nil
    }
}
