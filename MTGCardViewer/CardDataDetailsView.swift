//
//  CardDataDetailsView.swift
//  MTGCardViewer
//
//  Created by Michael Nguyen on 6/13/25.
//

import SwiftUI

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

struct CardDetail {
    let title: String
    let value: String
}
