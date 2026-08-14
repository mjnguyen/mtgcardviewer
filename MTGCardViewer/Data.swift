//
//  Data.swift
//  MTGCardViewer
//
//  Created by Michael Nguyen on 3/16/24.
//

import SwiftUI


enum Rarity: String, CaseIterable, Equatable, Decodable {
    case all = "All Rarity"
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case mythic = "mythic"
    case special = "special"
    case bonus = "bonus"

}

enum CardType: String, CaseIterable, Equatable, Decodable {
    case all = "All Card Types"
    case enchantment = "enchantment"
    case sorcery = "sorcery"
    case instant = "instant"
    case creature = "creature"
    case artifact = "artifact"
    case land = "land"
    case planeswalker = "planeswalker"
    case battle = "battle"
    // Supertypes
    case legendary = "legend"
    case snow = "snow"

}

struct Card: Identifiable {
    let id = UUID()
    var name: String
    var rarity: Rarity
    var artist: String
    let set: String
    var set_name: String
    let card_faces: [CardFaces]?
    let power: String?
    let toughness: String?
    let cmc: Double
    let mana_cost: String?
    let type_line: String
    let oracle_text: String?
    let flavor_text: String?
    var imageURL: URL?
}

struct CardFilter {
    var searchText: String = ""
    var artistName: String = ""
    var rarity: Rarity = .all
    var setName: String = ""
    var cardType: CardType = .all
}


class CardService: ObservableObject {
    @Published var cards: [Card] = []
    @Published var total_cards: Int = 0
    @Published var currentFilter: CardFilter = CardFilter()
    @Published var currentCard: Card?
    @Published var error: CardFetchErrorResponse?

    func fetchCards( completion: @escaping (([Card]) -> Void), onError: @escaping (CardSearchError) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.scryfall.com"
        components.path = "/cards/search"

        var queryItems = [URLQueryItem]()
        var searchTerms = ""
        if !currentFilter.searchText.isEmpty {
            searchTerms += currentFilter.searchText
        }

        if !currentFilter.artistName.isEmpty {
            searchTerms += " a:\"" + currentFilter.artistName + "\""
        }
        if !currentFilter.setName.isEmpty {
            searchTerms += " e:" + currentFilter.setName
        }

        if currentFilter.rarity != .all {
            searchTerms += " rarity:" + currentFilter.rarity.rawValue
        }

        if currentFilter.cardType != .all {
            searchTerms += " t:" + currentFilter.cardType.rawValue
        }

        if searchTerms.count > 0 {
            queryItems.append(URLQueryItem(name: "q", value: searchTerms))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            print("Invalid URL")
            return
        }

        print("URL: \(url)")
        error = nil
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            guard let data else {
                let serviceError = CardSearchError(errorDescription: error?.localizedDescription, searchErrorType: .data)
                DispatchQueue.main.async { onError(serviceError) }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                if let errorResponse = try? JSONDecoder().decode(CardFetchErrorResponse.self, from: data) {
                    let details = errorResponse.details
                    let serviceError = CardSearchError(errorDescription: details, searchErrorType: .noResults)
                    DispatchQueue.main.async { onError(serviceError) }
                }
                else {
                    let serviceError = CardSearchError(errorDescription: error?.localizedDescription, searchErrorType: .data)
                    DispatchQueue.main.async { onError(serviceError) }
                }
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(CardFetchResponse.self, from: data)
                DispatchQueue.main.async {
                    let cards = decodedResponse.data.compactMap { cardData in
                        var imageURL: URL?
                        if let imageURLString = cardData.image_uris?["normal"] {
                            imageURL = URL(string: imageURLString)
                        }
                        else if let card_faces = cardData.card_faces, let imageURLString = card_faces.first?.image_uris?["normal"] {
                            imageURL = URL(string: imageURLString)
                        }
                        return Card(name: cardData.name, rarity: cardData.rarity, artist: cardData.artist ?? "Unknown", set: cardData.set, set_name: cardData.set_name, card_faces: cardData.card_faces, power: cardData.power, toughness: cardData.toughness, cmc: cardData.cmc, mana_cost: cardData.mana_cost, type_line: cardData.type_line, oracle_text: cardData.oracle_text ?? "", flavor_text: cardData.flavor_text, imageURL: imageURL)
                    }
                    self.updateCards(cards, decodedResponse.total_cards)
                    completion(cards)
                }
            } catch {
                let serviceError = CardSearchError(errorDescription: error.localizedDescription, searchErrorType: .unknown)
                DispatchQueue.main.async { onError(serviceError) }
            }
        }.resume()
    }

    func updateCards(_ results: [Card], _ total: Int) {
        cards = results
        total_cards = total
    }

    func setCurrentCard(_ card: Card) {
        currentCard = card
    }

}

struct CardFetchResponse: Decodable {
    let has_more: Bool
    let total_cards: Int
    let object: String
    let next_page: String?
    let data: [CardData]
}

struct CardFetchErrorResponse: Decodable {
    let object: String
    let code: String
    let status: Int
    let details: String
}

struct CardSearchError: Error, LocalizedError {
    enum CardSearchErrorType {
        case emptySearchFields
        case noResults
        case network
        case data
        case unknown
    }

    /// A localized message describing the reason for the failure.
    var failureReason: String? {
        switch searchErrorType {
        case .emptySearchFields:
            return "Please fill in search criteria"
        case .noResults:
            return "No Results"
        case .network:
            return "Network Error"
        default:
            return "Unknown Error"
        }
    }

    /// A localized message describing what error occurred.
    var errorDescription: String?

    /// A localized message describing how one might recover from the failure.
    var recoverySuggestion: String?

    /// A localized message providing "help" text if the user requests help.
    var helpAnchor: String?


    var searchErrorType: CardSearchErrorType
}

struct CardFaces: Decodable {
    let image_uris: [String: String]?
    let object: String
    let name: String
}

struct CardData: Decodable {
    let name: String
    let rarity: Rarity
    let artist: String?
    let set: String
    let set_name: String
    let card_faces: [CardFaces]?
    var power: String? = ""
    var toughness: String? = ""
    let cmc: Double
    let mana_cost: String?
    let type_line: String
    let oracle_text: String?
    let flavor_text: String?
    let image_uris: [String: String]?
}

struct CardDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        Text(title + ":")
            .bold()

        Spacer()
        Text(value)
            .padding(.leading, 5)
    }
}
