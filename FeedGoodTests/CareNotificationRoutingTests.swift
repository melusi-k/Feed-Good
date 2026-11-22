import Foundation
import Testing
@testable import FeedGood

@MainActor
struct CareNotificationRoutingTests {
    @Test func validResponseOpensPlantRouteAndConsumptionClearsOnlyMatchingRoute() {
        let router = CareNotificationRouter()
        let taskID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let plantID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let payload = CareNotificationPayload.make(taskID: taskID, plantID: plantID)
        router.open(userInfo: payload)

        let route = router.destination
        #expect(route?.taskID == taskID)
        #expect(route?.plantID == plantID)

        let otherRoute = CareNotificationDestination(taskID: UUID(), plantID: UUID())
        router.consume(otherRoute)
        #expect(router.destination == route)

        if let route { router.consume(route) }
        #expect(router.destination == nil)
    }

    @Test func malformedAndUnrelatedNotificationPayloadsDoNotCreateRoutes() {
        let router = CareNotificationRouter()
        router.open(userInfo: [:])
        #expect(router.destination == nil)

        router.open(userInfo: [
            CareNotificationPayload.taskIDKey: "invalid",
            CareNotificationPayload.plantIDKey: UUID().uuidString
        ])
        #expect(router.destination == nil)
    }
}
