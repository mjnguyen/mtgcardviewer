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

    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
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
    let cmc: Int
    let mana_cost: String?
    let type_line: String
    let oracle_text: String?
    let flavor_text: String?
    var imageURL: URL?
}

class CardFilter: Identifiable {
    var searchText: String = ""
    var artistName: String = ""
    var rarity: Rarity = .all
    var setName: String = ""
}

class CardService: ObservableObject {
    @Published var cards: [Card] = []
    @Published var total_cards: Int = 0
    @Published var currentFilter: CardFilter = CardFilter()
    @Published var currentCard: Card?
    @Published var error: CardFetchErrorResponse?

    func fetchCards( completion: @escaping (([Card]) -> Void), onError: @escaping (String) -> Void) {
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
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data else {
                let msg = ("No data in response: \(error?.localizedDescription ?? "Unknown error")")
                onError(msg)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                if let errorResponse = try? JSONDecoder().decode(CardFetchErrorResponse.self, from: data) {
                    let details = errorResponse.details
                    let msg = ("Error getting information: \(details)")
                    onError(msg)
                }
                else {
                    print ("Error response: " + (error?.localizedDescription ?? "unknown error"))
                }
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(CardFetchResponse.self, from: data)
                if true {
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
                        return
                    }
                }
            } catch {
                print("Failed to decode data response: " + error.localizedDescription)
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
    let cmc: Int
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

struct CardDetail {
    let title: String
    let value: String
}


struct CardDataDetailsView: View {
    let card: Card

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .topLeading),
                GridItem(.flexible(minimum: 10, maximum: 20), alignment: .center),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 20) {
                ForEach(cardDetails.filter { !$0.value.isEmpty }, id: \.title) { detail in
                    CardDetailRow(title: detail.title, value: detail.value)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .border(Color.black)
    }

    var cardDetails: [CardDetail] {
        [
            CardDetail(title: "Name", value: card.name),
            CardDetail(title: "Artist", value: card.artist),
            CardDetail(title: "Mana Cost", value: card.mana_cost ?? "N/A"),
            CardDetail(title: "Set", value: card.set_name),
            CardDetail(title: "Type", value: card.type_line),
            CardDetail(title: "Oracle Text", value: card.oracle_text ?? ""),
            CardDetail(title: "Flavor Text", value: card.flavor_text ?? ""),
        ]
    }

}
