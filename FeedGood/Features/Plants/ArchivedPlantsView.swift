import SwiftUI
import SwiftData

struct ArchivedPlantsView: View {
    @Query(sort: \Plant.createdAt, order: .reverse) private var plants: [Plant]
    @State private var query = ""
    @AppStorage("plantCollectionSort") private var sortRaw = PlantCollectionSort.recentlyAdded.rawValue

    private var sort: PlantCollectionSort { PlantCollectionSort(rawValue: sortRaw) ?? .recentlyAdded }
    private var visiblePlants: [Plant] { PlantCollection.archived(from: plants, query: query, sort: sort) }

    var body: some View {
        List {
            if visiblePlants.isEmpty {
                ContentUnavailableView {
                    Label("No archived plants", systemImage: "archivebox")
                } description: {
                    Text(query.isEmpty ? "Plants you archive will stay here with their stories and photos." : "Try another plant name or species.")
                } actions: {
                    if !query.isEmpty {
                        Button("Clear search") { query = "" }
                    }
                }
            } else {
                ForEach(visiblePlants) { plant in
                    NavigationLink {
                        PlantDetailView(plant: plant)
                    } label: {
                        HStack(spacing: 12) {
                            PlantPhotoView(photoData: plant.photoData)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plant.name).font(.headline)
                                if !plant.species.isEmpty {
                                    Text(plant.species).font(.subheadline).foregroundStyle(FeedGoodTheme.muted)
                                }
                                let plantTags = (plant.tags ?? []).sorted { $0.name < $1.name }
                                if plantTags.isEmpty == false {
                                    Text(plantTags.map(\.name).joined(separator: " · "))
                                        .font(.caption).foregroundStyle(FeedGoodTheme.muted)
                                        .accessibilityIdentifier("archived.tags.\(plant.name)")
                                }
                                if let archivedAt = plant.archivedAt {
                                    Text("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(FeedGoodTheme.muted)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .accessibilityIdentifier("plants.archived.row.\(plant.name)")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $query, prompt: "Plant name or species")
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Archived plants")
    }
}
