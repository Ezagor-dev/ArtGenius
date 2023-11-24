//
//  HistoryManager.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import Foundation

class HistoryManager {
    static let shared = HistoryManager()
    private let historyKey = "PromptHistory"

    func saveHistory(history: [HistoryItem]) {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Unable to save history: \(error)")
        }
    }

    func loadHistory() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([HistoryItem].self, from: data)
        } catch {
            print("Unable to load history: \(error)")
            return []
        }
    }
}
