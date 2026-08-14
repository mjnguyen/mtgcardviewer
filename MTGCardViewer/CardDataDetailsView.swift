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
            VStack(alignment: .leading, spacing: 12) {
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
            CardDetail(title: "Name",        value: card.name),
            CardDetail(title: "Artist",      value: card.artist),
            CardDetail(title: "Mana Cost",   value: card.manaCost ?? "N/A"),
            CardDetail(title: "Set",         value: card.setName),
            CardDetail(title: "Type",        value: card.typeLine),
            CardDetail(title: "Oracle Text", value: card.oracleText ?? ""),
            CardDetail(title: "Flavor Text", value: card.flavorText ?? ""),
        ]
    }
}

struct CardDetail {
    let title: String
    let value: String
}

struct CardDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .bold()
                .frame(width: 90, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
