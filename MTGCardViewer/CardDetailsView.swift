import SwiftUI
import SDWebImageSwiftUI
import SDWebImage

struct CardDetailsView: View {
    let card: Card
    @Binding var isPresented: Bool
    @State var currentIndex: Int
    let cards: [Card]

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    init(card: Card, isPresented: Binding<Bool>, cards: [Card]) {
        self.card = card
        self._isPresented = isPresented
        self.cards = cards
        let initialIndex = cards.firstIndex(where: { $0.id == card.id }) ?? 0
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        VStack {
            if isPortrait {
                PortraitView(card: cards[currentIndex], isPresented: $isPresented, currentIndex: $currentIndex, cards: cards)
            } else {
                LandscapeView(card: cards[currentIndex], isPresented: $isPresented, currentIndex: $currentIndex, cards: cards)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var isPortrait: Bool {
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            return true
        }
        return UIDevice.current.orientation.isPortrait
    }
}

private extension Color {
    static let offWhite = Color(red: 225/255, green: 225/255, blue: 245/255)
}

private extension CardDetailsView {
    struct PortraitView: View {
        let card: Card
        @Binding var isPresented: Bool
        @Binding var currentIndex: Int
        let cards: [Card]

        var body: some View {
            GeometryReader { geo in
            VStack(spacing: 0) {
                // Card Image taking 20% of vertical space
                WebImage(url: card.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height * 0.20, alignment: .top)
                        .clipped()
                } placeholder: {
                    ProgressView().foregroundColor(Color.blue)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .overlay(alignment: .center) {
                    HStack {
                        if currentIndex > 0 {
                            Button {
                                currentIndex -= 1
                            } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.7))
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(.leading)
                        }
                        
                        Spacer()
                        
                        if currentIndex < (cards.count - 1) {
                            Button {
                                currentIndex += 1
                            } label: {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.7))
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing)
                        }
                    }
                }

                // Card Details taking remaining space
                CardDataDetailsView(card: card)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.thinMaterial)
            .overlay(alignment: .topTrailing) {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .padding()
            }
        }
        } // GeometryReader
    }

    struct LandscapeView: View {
        let card: Card
        @Binding var isPresented: Bool
        @Binding var currentIndex: Int
        let cards: [Card]

        var body: some View {
            NavigationStack {
                HStack {
                    WebImage(url: card.imageURL) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaledToFit()
                            .frame(height: 300, alignment: .leading)
                    } placeholder: {
                        ProgressView().foregroundColor(Color.blue)
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .overlay(alignment: .center) {
                        HStack {
                            if currentIndex > 0 {
                                Button {
                                    currentIndex -= 1
                                } label: {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white.opacity(0.7))
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .padding(.leading)
                            }
                            Spacer()
                            if currentIndex < (cards.count - 1) {
                                Button {
                                    currentIndex += 1
                                } label: {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white.opacity(0.7))
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing)
                            }
                        }
                    }

                    CardDataDetailsView(card: card)
                }
                .background(.thinMaterial)
                .overlay(alignment: .topTrailing) {
                    Button {
                        isPresented.toggle()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
    }
}

struct CardDetailsView_Previews: PreviewProvider {
    @State static var isPresented: Bool = true
    static var previews: some View {
        let exampleCard = Card(name: "Example Card", rarity: Rarity.common, artist: "John Doe", set: "SOM", setName: "Sample Set", cardFaces: nil, power: "0", toughness: "1", cmc: 1, manaCost: "{1}", typeLine: "Enchantment", oracleText: "-", flavorText: "---", imageURL: URL(string: "https://www.cardkingdom.com/mtg/tarkir-dragonstorm/mardu-devotee")!)
        CardDetailsView(card: exampleCard, isPresented: $isPresented, cards: [exampleCard])
//            .previewLayout(.sizeThatFits)
    }
}
