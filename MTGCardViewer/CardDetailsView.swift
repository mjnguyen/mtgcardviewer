import SwiftUI
import SDWebImageSwiftUI
import SDWebImage

struct CardDetailsView: View {
    let card: Card
    @Binding var isPresented: Bool

    @State var orientationChanged: Bool = true

    var body: some View {
        VStack {
            if UIDevice.current.orientation.isPortrait {
                PortraitView(card: card, isPresented: $isPresented)
            } else {
                LandscapeView(card: card, isPresented: $isPresented)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(20)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientationChanged.toggle()
        }
        .id(orientationChanged) // Force view update by changing its identifier

    }
}

private extension CardDetailsView {
    struct PortraitView: View {
        let card: Card
        @Binding var isPresented: Bool

        var body: some View {
            NavigationView {
                VStack {
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

                    Spacer()

                    CardDataDetailsView(card: card)
                }
                .padding()
                .navigationBarItems(trailing: Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(Color.gray)
                })
            }
        }

    }

    struct LandscapeView: View {
        let card: Card

        @Binding var isPresented: Bool

        var body: some View {
            NavigationView {
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

                    CardDataDetailsView(card: card)
                }
                .padding()
                .navigationBarItems(trailing: Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(Color.gray)
                })
            }
        }
    }
}

struct CardDetailsView_Previews: PreviewProvider {
    @State static var isPresented: Bool = true
    static var previews: some View {

        CardDetailsView(card: Card(name: "Example Card", rarity: Rarity.common, artist: "John Doe", set: "SOM", set_name: "Sample Set", card_faces: nil, power: "0", toughness: "1", cmc: 1, mana_cost: "{1}", type_line: "Enchantment", oracle_text: "-", flavor_text: "---", imageURL: URL(string: "https://example.com/image.jpg")!), isPresented: $isPresented)
            .previewLayout(.sizeThatFits)
    }
}


