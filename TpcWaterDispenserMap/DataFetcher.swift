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
    
    func download() {
        print(">> 正在下載資料集...")
        dataArray = nil
        
        dispenserResults = Array<Dictionary<String,Any>>()
        tapWaterResults = Array<Dictionary<String,Any>>()
        fetchOffset = 0
        
        downloadInfoJson()
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
    
    private func downloadInfoJson() {
        httpGET_withFetchJsonObject(URLString: infoUrlString) { json in
            if let json = json,
               let wdUrlStr = json["WaterDispenser"] as? String,
               let twUrlStr = json["TapWater"] as? String
            {
                self.dispenserUrlString = wdUrlStr
                self.tapWaterUrlString = twUrlStr
            }
            self.downloadDispenserData()
        }
    }
    
    
    private func downloadDispenserData() {
        fetchDispenser(limit: fetchLimit, offset: fetchOffset) { json in
            var resultsCount = 0
            if let json = json,
               let result = json["result"] as? Dictionary<String,Any>,
               let results = result["results"] as? Array<Dictionary<String,Any>>
            {
                self.dispenserResults?.append(contentsOf: results)
                resultsCount = results.count
            }
            
            if resultsCount >= self.fetchLimit {
                self.fetchOffset += self.fetchLimit
                self.downloadDispenserData()
            } else {
                self.fetchOffset = 0
                self.downloadTapWaterData()
            }
        }
    }
    
    private func downloadTapWaterData() {
        fetchTapWater(limit: fetchLimit, offset: fetchOffset) { json in
            var resultsCount = 0
            if let json = json,
               let result = json["result"] as? Dictionary<String,Any>,
               let results = result["results"] as? Array<Dictionary<String,Any>>
            {
                self.tapWaterResults?.append(contentsOf: results)
                resultsCount = results.count
            }
            
            if resultsCount >= self.fetchLimit {
                self.fetchOffset += self.fetchLimit
                self.downloadTapWaterData()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.convertResultsToDataArray()
                }
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
    
    private func fetchDispenser(limit: Int, offset: Int, callback: @escaping (Dictionary<String,Any>?) -> Void) {
        httpGET_withFetchJsonObject(URLString: "\(dispenserUrlString)&limit=\(limit)&offset=\(offset)", callback: callback)
    }
    
    private func fetchTapWater(limit: Int, offset: Int, callback: @escaping (Dictionary<String,Any>?) -> Void) {
        httpGET_withFetchJsonObject(URLString: "\(tapWaterUrlString)&limit=\(limit)&offset=\(offset)", callback: callback)
    }
    
    
    // MARK: - HTTP GET
    
    private func httpGET_withFetchJsonObject(URLString: String, callback: @escaping (Dictionary<String,Any>?) -> Void) {
        httpRequestWithFetchJsonObject(httpMethod: "GET", URLString: URLString, parameters: nil, callback: callback)
    }
    
    
    // MARK: - HTTP Request with Method
    
    private func httpRequestWithFetchJsonObject(httpMethod: String,
                                                URLString: String,
                                                parameters: Dictionary<String,Any>?,
                                                callback: @escaping (Dictionary<String,Any>?) -> Void)
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
        
        // Task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    callback(nil)
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    callback(responseJSON)
                } else {
                    callback(nil)
                }
            }
        }
        task.resume()
    }
}
