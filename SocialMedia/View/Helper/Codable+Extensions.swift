//
//  Codable+Extensions.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/10/24.
//

import SwiftUI

extension Encodable {
    func asDictionary() -> [String: Any] {
        // получение данных
        guard let data = try? JSONEncoder().encode(self) else {
            return [:]
        }
        
        // JSONSerialization преобразование в json type
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json ?? [:]
        } catch {
            return [:]
        }
    }
}

