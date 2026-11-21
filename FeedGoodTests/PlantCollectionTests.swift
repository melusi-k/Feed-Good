import XCTest
@testable import FeedGood

final class PlantCollectionTests: XCTestCase {
    func testSearchNameAndSpeciesIgnoresCaseAccentsAndOuterWhitespace() {
        let fern = Plant(name: "Férn by window", species: "Nephrolepis exaltata")
        let aloe = Plant(name: "Kitchen", species: "Aloe vera")
        let all = [fern, aloe]
        XCTAssertEqual(PlantCollection.plants(from: all, query: " FERN ", sort: .name).map(\.id), [fern.id])
        XCTAssertEqual(PlantCollection.plants(from: all, query: "ALOE", sort: .name).map(\.id), [aloe.id])
        XCTAssertEqual(PlantCollection.plants(from: all, query: "exalt", sort: .name).map(\.id), [fern.id])
        XCTAssertTrue(PlantCollection.plants(from: all, query: "not saved", sort: .name).isEmpty)
        XCTAssertEqual(PlantCollection.plants(from: all, query: " \n ", sort: .name).count, 2)
        XCTAssertTrue(PlantCollection.plants(from: [], query: "", sort: .name).isEmpty)
    }

    func testNameAndRecentlyAddedOrdersAreDeterministic() {
        let older = Plant(name: "Zulu", createdAt: Date(timeIntervalSince1970: 1))
        let newer = Plant(name: "aloe", createdAt: Date(timeIntervalSince1970: 2))
        let same = Plant(name: "Áloe", createdAt: newer.createdAt)
        let all = [older, newer, same]
        XCTAssertEqual(PlantCollection.plants(from: all, query: "", sort: .name).last?.id, older.id)
        XCTAssertEqual(PlantCollection.plants(from: all, query: "", sort: .recentlyAdded).last?.id, older.id)
        for sort in PlantCollectionSort.allCases {
            let a = PlantCollection.plants(from: all, query: "", sort: sort).map(\.id)
            let b = PlantCollection.plants(from: all.reversed(), query: "", sort: sort).map(\.id)
            XCTAssertEqual(a, b)
            XCTAssertEqual(Set(a).count, 3)
            XCTAssertEqual(a.prefix(2), [newer.id, same.id].sorted { $0.uuidString < $1.uuidString }[...])
        }
    }

    func testDifferentSortModesAndSourceUpdates() {
        let a = Plant(name: "Aloe", createdAt: Date(timeIntervalSince1970: 1))
        let z = Plant(name: "Zulu", createdAt: Date(timeIntervalSince1970: 2))
        XCTAssertEqual(PlantCollection.plants(from: [z, a], query: "", sort: .name).map(\.id), [a.id, z.id])
        XCTAssertEqual(PlantCollection.plants(from: [a, z], query: "", sort: .recentlyAdded).map(\.id), [z.id, a.id])
        a.species = "Updated species"
        XCTAssertEqual(PlantCollection.plants(from: [a, z], query: "updated", sort: .name).map(\.id), [a.id])
        a.name = "Zz"
        XCTAssertEqual(PlantCollection.plants(from: [a, z], query: "", sort: .name).last?.id, a.id)
        XCTAssertEqual(a.name, "Zz")
        XCTAssertEqual(a.species, "Updated species")
    }
}
