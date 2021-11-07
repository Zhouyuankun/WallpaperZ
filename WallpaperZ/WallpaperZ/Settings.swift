//
//  Settings.swift
//  WallpaperZ
//
//  Created by celeglow on 2021/11/6.
//

import Foundation

struct Settings: Codable {
    var use: Int
    var names: [String]
}

func getSettingFromJSON(_ fileurl: URL) -> Settings?{
    var json: Settings?
    var data: Data?
    do {
        data = try Data(contentsOf: fileurl)
    } catch (let error) {
        print(error)
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    do {
        json = try decoder.decode(Settings.self, from: data!)
    } catch (let error) {
        print(error)
    }
    
    guard let result = json else {
        return nil
    }
    
    return result
    
}

func writeSettingsToJSON(_ fileurl: URL, settings: Settings) {
    let encodedData = try! JSONEncoder().encode(settings)
    try! encodedData.write(to: fileurl)
}


