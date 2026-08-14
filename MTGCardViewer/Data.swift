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
    var setName: String
    let cardFaces: [CardFaces]?
    let power: String?
    let toughness: String?
    let cmc: Double
    let manaCost: String?
    let typeLine: String
    let oracleText: String?
    let flavorText: String?
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
    @Published var totalCards: Int = 0
    @Published var currentFilter: CardFilter = CardFilter()
    @Published var currentCard: Card?
    @Published var error: CardFetchErrorResponse?

    private var activeTask: URLSessionDataTask?

    func fetchCards(completion: @escaping (([Card]) -> Void), onError: @escaping (CardSearchError) -> Void) {
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
        if !searchTerms.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: searchTerms))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            print("Invalid URL")
            return
        }

        print("URL: \(url)")
        error = nil
        activeTask?.cancel()
        activeTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            guard let data else {
                let serviceError = CardSearchError(errorDescription: error?.localizedDescription, searchErrorType: .data)
                DispatchQueue.main.async { onError(serviceError) }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                if let errorResponse = try? JSONDecoder().decode(CardFetchErrorResponse.self, from: data) {
                    let serviceError = CardSearchError(errorDescription: errorResponse.details, searchErrorType: .noResults)
                    DispatchQueue.main.async { onError(serviceError) }
                } else {
                    let serviceError = CardSearchError(errorDescription: error?.localizedDescription, searchErrorType: .data)
                    DispatchQueue.main.async { onError(serviceError) }
                }
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(CardFetchResponse.self, from: data)
                DispatchQueue.main.async {
                    let cards = decodedResponse.data.compactMap { cardData -> Card in
                        var imageURL: URL?
                        if let urlString = cardData.imageURIs?["normal"] {
                            imageURL = URL(string: urlString)
                        } else if let urlString = cardData.cardFaces?.first?.imageURIs?["normal"] {
                            imageURL = URL(string: urlString)
                        }
                        return Card(
                            name: cardData.name,
                            rarity: cardData.rarity,
                            artist: cardData.artist ?? "Unknown",
                            set: cardData.set,
                            setName: cardData.setName,
                            cardFaces: cardData.cardFaces,
                            power: cardData.power,
                            toughness: cardData.toughness,
                            cmc: cardData.cmc,
                            manaCost: cardData.manaCost,
                            typeLine: cardData.typeLine,
                            oracleText: cardData.oracleText ?? "",
                            flavorText: cardData.flavorText,
                            imageURL: imageURL
                        )
                    }
                    self.updateCards(cards, decodedResponse.totalCards)
                    completion(cards)
                }
            } catch {
                let serviceError = CardSearchError(errorDescription: error.localizedDescription, searchErrorType: .unknown)
                DispatchQueue.main.async { onError(serviceError) }
            }
        }
        activeTask?.resume()
    }

    func updateCards(_ results: [Card], _ total: Int) {
        cards = results
        totalCards = total
    }

    func setCurrentCard(_ card: Card) {
        currentCard = card
    }
}

struct CardFetchResponse: Decodable {
    let totalCards: Int
    let data: [CardData]

    enum CodingKeys: String, CodingKey {
        case totalCards = "total_cards"
        case data
    }
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

    var failureReason: String? {
        switch searchErrorType {
        case .emptySearchFields: return "Please fill in search criteria"
        case .noResults:         return "No Results"
        case .network:           return "Network Error"
        default:                 return "Unknown Error"
        }
    }

    var errorDescription: String?
    var recoverySuggestion: String?
    var helpAnchor: String?
    var searchErrorType: CardSearchErrorType
}

struct CardFaces: Decodable {
    let imageURIs: [String: String]?
    let object: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case imageURIs = "image_uris"
        case object, name
    }
}

struct CardData: Decodable {
    let name: String
    let rarity: Rarity
    let artist: String?
    let set: String
    let setName: String
    let cardFaces: [CardFaces]?
    var power: String?
    var toughness: String?
    let cmc: Double
    let manaCost: String?
    let typeLine: String
    let oracleText: String?
    let flavorText: String?
    let imageURIs: [String: String]?

    enum CodingKeys: String, CodingKey {
        case name, rarity, artist, set, cmc, power, toughness
        case setName    = "set_name"
        case cardFaces  = "card_faces"
        case manaCost   = "mana_cost"
        case typeLine   = "type_line"
        case oracleText = "oracle_text"
        case flavorText = "flavor_text"
        case imageURIs  = "image_uris"
    }
}
