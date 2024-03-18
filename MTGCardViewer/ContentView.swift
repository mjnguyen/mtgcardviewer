import SwiftUI
import SDWebImageSwiftUI
import SDWebImage

struct ContentView: View {

    @State private var errorMessage: String?
    @State private var orientationChanged = false
    @State private var isShowingModal = false

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
                if (!isFullScreenLayout) {
                    resultView
                        .frame(maxWidth: .infinity, alignment: .center)
                        .layoutPriority(4)

                }
            }
            if isFullScreenLayout {
                resultView
                    .frame(maxWidth: .infinity, alignment: .center)

            }

        }
        .background(Color.secondary).opacity(0.8)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientationChanged.toggle()
        }
        .id(orientationChanged) // Force view update by changing its identifier

    }

    private var resultView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach($cardService.cards) { card in
                    VStack {
                        WebImage(url: card.imageURL.wrappedValue) { image in
                            image.resizable()
                                .frame(minWidth: 200, maxHeight: .infinity, alignment: .center)
                                .onTapGesture {
                                    cardService.setCurrentCard(card.wrappedValue)
                                    isShowingModal.toggle()
                                }
                        } placeholder: {
                            ProgressView().foregroundColor(Color.blue)
                        }
                        .onSuccess { image, data, cacheType in
//                            print("\(cacheType) - \(image)")
                        }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()

                        Text(card.name.wrappedValue)
                            .font(.headline)
                        Text("\(String(describing: card.rarity.wrappedValue))")
                            .font(.subheadline)
                        Text("Artist: \(card.artist.wrappedValue)")
                            .font(.subheadline)
                        Text("\(card.set_name.wrappedValue)")
                            .font(.subheadline).italic().bold()

                    }
                }
            }
            .frame(maxWidth: .infinity)
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
            
            TextField("Artist", text: $cardService.currentFilter.artistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()
            
            TextField("Set", text: $cardService.currentFilter.setName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .bold()
            
            Picker("Rarity", selection: $cardService.currentFilter.rarity) {
                ForEach(Rarity.allCases, id: \.self) { value in
                    Text(value.localizedName)
                        .tag(value)
                }
            }
            .pickerStyle(.navigationLink)
            .font(.subheadline)
            .bold()
            .padding(5)
            
            fetchButton
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            
            
            if $cardService.cards.count > 0 {
                let total_cards = cardService.total_cards
                Text("\($cardService.cards.count) of \(total_cards) Cards Shown")
                    .font(.subheadline)
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, maxHeight:50, alignment: .center)
            }

            if errorMessage != nil {
                errorMessageView
                    .frame(maxHeight:150, alignment: .center)
                    .padding()
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .navigationTitle("MTG Card Viewer")

    }

    private var fetchButton: some View {
        Button("Fetch Cards") {
            cardService.fetchCards() { results in
                self.errorMessage = nil
            } onError: { message in
                self.errorMessage = message
            }

        }
        .font(.title3)
        .frame(width: 200, height: 50, alignment: .center)
        .border(Color.black, width: 2.0)
        .shadow(radius: 10)
        .padding(10)
    }

    private var errorMessageView: some View {
        Text("\(errorMessage ?? "")")
            .font(.subheadline)
            .foregroundStyle(.red)
            .bold()
            .italic()
            .padding()
            .border(Color.indigo, width: 1)
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
