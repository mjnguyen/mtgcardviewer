import SwiftUI
import SDWebImageSwiftUI
import SDWebImage

struct ContentView: View {

    @State private var hasServiceError = false
    @State private var serviceError: CardSearchError?
    @State private var cards: [Card] = [Card]()

    @State private var orientationChanged = false
    @State private var isShowingModal = false
    @State private var imageWidth = 300.0

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @ObservedObject
    private var cardService: CardService = CardService()

    var body: some View {
        NavigationView {
            let isFullScreenLayout = (sizeClass == verticalSizeClass && sizeClass == .regular)
            let isLandscape = (verticalSizeClass != .regular || isFullScreenLayout || UIDevice.current.orientation.isLandscape)
            let layout = isLandscape ? AnyLayout(HStackLayout(alignment: .top, spacing: 0)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 0))

            layout {
                searchView
                    .frame(maxWidth: .infinity, maxHeight: 800, alignment: .leading)
                    .padding(.vertical)
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

            }

        }
        .background(.thinMaterial)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientationChanged.toggle()
        }
    }

    private var resultView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach($cards) { card in
                    VStack {
                        WebImage(url: card.imageURL.wrappedValue) { image in
                            image.resizable()
                                .frame(minWidth: 150, maxHeight: .infinity, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                                .onTapGesture {
                                    cardService.setCurrentCard(card.wrappedValue)
                                    isShowingModal.toggle()
                                }
                        } placeholder: {
                            ProgressView().foregroundColor(Color.blue)
                        }
                        .onSuccess { image, data, cacheType in
                            imageWidth = image.size.width

                        }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()

                        Text(card.name.wrappedValue)
                            .font(.headline)
                            .frame(maxWidth: imageWidth)
                        Text("\(String(describing: card.rarity.wrappedValue))")
                            .font(.subheadline)
                            .frame(maxWidth: imageWidth)
                        Text("Artist: \(card.artist.wrappedValue)")
                            .font(.subheadline)
                            .frame(maxWidth: imageWidth)
                        Text("\(card.set_name.wrappedValue)")
                            .font(.subheadline).italic().bold()
                            .frame(maxWidth: imageWidth)

                    }
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
                CardDetailsView(card: currentCard, isPresented: $isShowingModal)
            }
        })
    }

    private var searchView: some View {
        List {
            TextField("Card name", text: $cardService.currentFilter.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()
                .listRowSeparator(.hidden)

            TextField("Artist", text: $cardService.currentFilter.artistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()
                .listRowSeparator(.hidden)

            TextField("Set", text: $cardService.currentFilter.setName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()
                .listRowSeparator(.hidden)

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
            .opacity(0.2)
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
            .opacity(0.2)
            .padding(0)

            fetchButton
                .frame(maxWidth: .infinity, maxHeight: 60, alignment: .center)
                .listRowSeparator(.hidden)
                .padding(0)
                .alert(isPresented: $hasServiceError, error: serviceError) {_ in } message: { error in
                        Text(error.recoverySuggestion ?? "")
                }

            if self.cards.count > 0 {
                let total_cards = cardService.total_cards
                Text("\(cards.count) of \(total_cards) Cards Shown")
                    .font(.subheadline)
                    .padding(0)
                    .frame(maxWidth: .infinity, maxHeight:50, alignment: .center)
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .navigationTitle("MTG Card Viewer")

    }

    private var fetchButton: some View {
        Button("Fetch Cards") {
            cardService.fetchCards() { results in
                self.cards = results
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

    private var errorMessageView: some View {
        Text("\(serviceError?.failureReason ?? "")")
            .font(.subheadline)
            .foregroundStyle(.red)
            .bold()
            .italic()
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
