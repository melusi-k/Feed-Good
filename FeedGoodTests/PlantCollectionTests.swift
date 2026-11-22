import Foundation
import Testing
@testable import FeedGood

struct PlantCollectionTests {
    @Test func searchNameAndSpeciesIgnoresCaseAccentsAndOuterWhitespace() {
        let fern = Plant(name: "Férn by window", species: "Nephrolepis exaltata")
        let aloe = Plant(name: "Kitchen", species: "Aloe vera")
        let all = [fern, aloe]
        #expect(PlantCollection.plants(from: all, query: " FERN ", sort: .name).map(\.id) == [fern.id])
        #expect(PlantCollection.plants(from: all, query: "ALOE", sort: .name).map(\.id) == [aloe.id])
        #expect(PlantCollection.plants(from: all, query: "exalt", sort: .name).map(\.id) == [fern.id])
        #expect(PlantCollection.plants(from: all, query: "not saved", sort: .name).isEmpty)
        #expect(PlantCollection.plants(from: all, query: " \n ", sort: .name).count == 2)
        #expect(PlantCollection.plants(from: [], query: "", sort: .name).isEmpty)
    }

    @Test func nameAndRecentlyAddedOrdersAreDeterministic() {
        let older = Plant(name: "Zulu", createdAt: Date(timeIntervalSince1970: 1))
        let newer = Plant(name: "aloe", createdAt: Date(timeIntervalSince1970: 2))
        let same = Plant(name: "Áloe", createdAt: newer.createdAt)
        let all = [older, newer, same]
        #expect(PlantCollection.plants(from: all, query: "", sort: .name).last?.id == older.id)
        #expect(PlantCollection.plants(from: all, query: "", sort: .recentlyAdded).last?.id == older.id)
        for sort in PlantCollectionSort.allCases {
            let a = PlantCollection.plants(from: all, query: "", sort: sort).map(\.id)
            let b = PlantCollection.plants(from: all.reversed(), query: "", sort: sort).map(\.id)
            #expect(a == b)
            #expect(Set(a).count == 3)
            #expect(a.prefix(2) == [newer.id, same.id].sorted { $0.uuidString < $1.uuidString }[...])
        }
    }

    @Test func differentSortModesAndSourceUpdates() {
        let a = Plant(name: "Aloe", createdAt: Date(timeIntervalSince1970: 1))
        let z = Plant(name: "Zulu", createdAt: Date(timeIntervalSince1970: 2))
        #expect(PlantCollection.plants(from: [z, a], query: "", sort: .name).map(\.id) == [a.id, z.id])
        #expect(PlantCollection.plants(from: [a, z], query: "", sort: .recentlyAdded).map(\.id) == [z.id, a.id])
        a.species = "Updated species"
        #expect(PlantCollection.plants(from: [a, z], query: "updated", sort: .name).map(\.id) == [a.id])
        a.name = "Zz"
        #expect(PlantCollection.plants(from: [a, z], query: "", sort: .name).last?.id == a.id)
        #expect(a.name == "Zz")
        #expect(a.species == "Updated species")
    }
}
