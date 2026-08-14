import SwiftUI
import SDWebImageSwiftUI
import SDWebImage

struct ContentView: View {

    @State private var hasServiceError = false
    @State private var serviceError: CardSearchError?
    @State private var isShowingModal = false

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @StateObject
    private var cardService: CardService = CardService()

    var body: some View {
        NavigationStack {
            let isFullScreenLayout = (sizeClass == verticalSizeClass && sizeClass == .regular)
            let isLandscape = (verticalSizeClass != .regular || isFullScreenLayout || UIDevice.current.orientation.isLandscape)
            let layout = isLandscape ? AnyLayout(HStackLayout(alignment: .top, spacing: 0)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 0))

            layout {
                searchView
                    .padding()
                    .background(.thinMaterial)
                    .border(Color.black, width: 1.0)
                if (!isFullScreenLayout) {
                    resultView
                        .frame(maxWidth: .infinity, alignment: .center)


                }
            }
            if isFullScreenLayout {
                resultView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()

            }

        }
        .background(.thinMaterial)
    }

    private var resultView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 20) {
                ForEach(cardService.cards) { card in
                    VStack {
                        WebImage(url: card.imageURL) { image in
                            image.resizable()
                                .scaledToFit()
                                .onTapGesture {
                                    cardService.setCurrentCard(card)
                                    isShowingModal = true
                                }
                        } placeholder: {
                            ProgressView().foregroundColor(Color.blue)
                        }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()

                        Text(card.name)
                            .font(.headline)
                        Text(card.rarity.rawValue.capitalized)
                            .font(.subheadline)
                        Text("Artist: \(card.artist)")
                            .font(.subheadline)
                        Text(card.setName)
                            .font(.subheadline).italic().bold()
                    }
                    .frame(width: 200)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .sheet(isPresented: $isShowingModal, content: {
            if let currentCard = cardService.currentCard {
                CardDetailsView(card: currentCard, isPresented: $isShowingModal, cards: cardService.cards)
            }
        })
    }

    private var searchView: some View {
        VStack(alignment: .leading) {
            TextField("Card name", text: $cardService.currentFilter.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()

            TextField("Artist", text: $cardService.currentFilter.artistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()

            TextField("Set", text: $cardService.currentFilter.setName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()

            HStack(alignment: .top, spacing: 16) {
                Picker("Rarity", selection: $cardService.currentFilter.rarity) {
                    ForEach(Rarity.allCases, id: \.self) { value in
                        Text(value.rawValue)
                            .foregroundColor(.black)
                            .foregroundStyle(.ultraThickMaterial)
                            .tag(value)
                            .bold()
                    }
                }
                .border(Color.black, width: 1.0)
                .listRowSeparator(.hidden)
                .pickerStyle(.automatic)
                .font(.subheadline)
                .bold()
                .padding(0)


                Picker("Card Type", selection: $cardService.currentFilter.cardType) {
                    ForEach(CardType.allCases, id: \.self) { value in
                        Text(value.rawValue)
                            .foregroundColor(.black)
                            .foregroundStyle(.ultraThickMaterial)
                            .tag(value)
                            .bold()
                    }
                }
                .border(Color.black, width: 1.0)
                .listRowSeparator(.hidden)
                .pickerStyle(.automatic)
                .font(.subheadline)
                .bold()
                .padding(0)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            fetchButton
                .frame(maxWidth: .infinity, maxHeight: 60, alignment: .center)
                .listRowSeparator(.hidden)
                .padding(0)
                .alert(isPresented: $hasServiceError, error: serviceError) {_ in } message: { error in
                        Text(error.recoverySuggestion ?? "")
                }

            if cardService.cards.count > 0 {
                Text("\(cardService.cards.count) of \(cardService.totalCards) Cards Shown")
                    .font(.subheadline)
                    .padding(0)
                    .frame(maxWidth: .infinity, maxHeight:50, alignment: .center)
            }

            Spacer()
            Text("Version \(Bundle.main.releaseVersionNumber ?? "Unknown") (\(Bundle.main.buildVersionNumber ?? "Unknown"))")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("MTG Card Viewer")

    }

    private var fetchButton: some View {
        Button("Fetch Cards") {
            cardService.fetchCards() { _ in
                self.hasServiceError = false
                self.serviceError = nil
            } onError: { serviceError in
                self.hasServiceError = true
                self.serviceError = serviceError
            }

        }
        .font(.title3)
        .frame(width: 200, height: 50, alignment: .center)
        .border(Color.black, width: 2.0)
        .shadow(radius: 10)
        .padding(10)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
