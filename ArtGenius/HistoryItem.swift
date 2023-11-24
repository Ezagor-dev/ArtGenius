//
//  HistoryItem.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import Foundation

struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let prompt: String
    let imageBase64: String
}
