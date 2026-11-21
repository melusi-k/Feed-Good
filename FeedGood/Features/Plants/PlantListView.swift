import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.createdAt, order: .reverse) private var plants: [Plant]
    @State private var showingAddPlant = false

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    ContentUnavailableView {
                        Label("Your garden starts here", systemImage: "leaf")
                    } description: {
                        Text("Add your first plant and start its growing journey.")
                    } actions: {
                        Button("Add a plant") { showingAddPlant = true }
                            .buttonStyle(.borderedProminent)
                            .tint(FeedGoodTheme.leaf)
                    }
                } else {
                    List {
                        Section {
                            ForEach(plants) { plant in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plant.name)
                                        .font(.headline)
                                    if !plant.species.isEmpty {
                                        Text(plant.species)
                                            .font(.subheadline)
                                            .foregroundStyle(FeedGoodTheme.muted)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deletePlants)
                        } header: {
                            Text("My Plants")
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(FeedGoodTheme.background)
            .navigationTitle("Feed Good")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPlant = true
                    } label: {
                        Label("Add plant", systemImage: "plus")
                    }
                    .accessibilityIdentifier("plants.add")
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                AddPlantView()
            }
        }
        .tint(FeedGoodTheme.leaf)
    }

    private func deletePlants(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(plants[index])
        }
    }
}
