import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.createdAt, order: .reverse) private var plants: [Plant]
    @State private var showingAddPlant = false
    @State private var query = ""
    @AppStorage("plantCollectionSort") private var sortRaw = PlantCollectionSort.recentlyAdded.rawValue

    private var sort: PlantCollectionSort { PlantCollectionSort(rawValue: sortRaw) ?? .recentlyAdded }
    private var visiblePlants: [Plant] { PlantCollection.plants(from: plants, query: query, sort: sort) }

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
                            if visiblePlants.isEmpty {
                                ContentUnavailableView {
                                    Label("No matching plants", systemImage: "magnifyingglass")
                                } description: {
                                    Text("Try a plant name or the species you saved.")
                                } actions: {
                                    Button("Clear search") { query = "" }.accessibilityIdentifier("plants.search.clear")
                                }.accessibilityIdentifier("plants.search.empty")
                            }
                            ForEach(visiblePlants) { plant in
                                NavigationLink {
                                    PlantDetailView(plant: plant)
                                } label: {
                                    HStack(spacing: 12) {
                                        PlantPhotoView(photoData: plant.photoData)
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                                }
                                .accessibilityIdentifier("plants.row.\(plant.name)")
                            }
                        } header: {
                            Text("My Plants")
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .searchable(text: $query, prompt: "Plant name or species")
            .background(FeedGoodTheme.background)
            .navigationTitle("Feed Good")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort plants", selection: $sortRaw) {
                            ForEach(PlantCollectionSort.allCases) { option in Text(option.title).tag(option.rawValue) }
                        }
                    } label: {
                        Label("Sort: \(sort.title)", systemImage: "arrow.up.arrow.down")
                    }
                    .accessibilityIdentifier("plants.sort")
                }
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
}
