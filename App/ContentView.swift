import Photos
import SwiftUI

struct ContentView: View {
    @StateObject private var deck = DayDeck()
    @State private var showReview = false

    var body: some View {
        NavigationStack {
            Group {
                if deck.hasAccess { deckView }
                else if deck.authorization == .notDetermined { ProgressView() }
                else { deniedView }
            }
            .navigationTitle("On This Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DatePicker("Date", selection: $deck.date, displayedComponents: .date).labelsHidden()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Today") { deck.date = .now }
                        Toggle("Show photos I kept", isOn: $deck.showKept)
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(isPresented: $showReview) { ReviewView(deck: deck) }
        }
        .task { await deck.start() }
        .onChange(of: deck.date) { deck.reload() }
        .onChange(of: deck.showKept) { deck.reload() }
        .onOpenURL { _ in deck.date = .now } // the widget opens onthisday://today
    }

    private var deckView: some View {
        VStack(spacing: 16) {
            if deck.isLoading {
                Spacer(); ProgressView("Finding photos…"); Spacer()
            } else if let asset = deck.current {
                Text("\(deck.remaining) left").font(.subheadline).foregroundStyle(.secondary)
                ZStack {
                    if let next = deck.next {
                        AssetImage(asset: next)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .scaleEffect(0.94)
                            .opacity(0.5)
                    }
                    SwipeCard(asset: asset) { decision in
                        withAnimation { deck.decide(decision) }
                    }
                    .id(asset.localIdentifier)
                }
                .padding(.horizontal)
                controls
            } else {
                Spacer()
                ContentUnavailableView(
                    deck.assets.isEmpty ? "Nothing from this day" : "All done for this day",
                    systemImage: deck.assets.isEmpty ? "calendar" : "checkmark.circle",
                    description: Text(deck.assets.isEmpty ? "No photos from this date in past years." : "Come back tomorrow for the next batch.")
                )
                Spacer()
            }

            if !deck.marked.isEmpty {
                Button { showReview = true } label: {
                    Label("Review \(deck.marked.count) to delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private var controls: some View {
        HStack(spacing: 36) {
            roundButton("xmark", .red) { withAnimation { deck.decide(.delete) } }
            roundButton("arrow.uturn.backward", .gray) { withAnimation { deck.undo() } }
                .disabled(deck.history.isEmpty)
            roundButton("heart.fill", .green) { withAnimation { deck.decide(.keep) } }
        }
    }

    private func roundButton(_ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color(.secondarySystemBackground)))
        }
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("Photos access needed", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Allow full access to Photos in Settings so the app can find and delete photos.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
        }
    }
}
