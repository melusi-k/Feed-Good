import SwiftUI
import SwiftData

/// One care task that Today shows, paired with the plant it belongs to.
struct TodayCareItem: Identifiable {
    let task: CareTask
    let plant: Plant
    let state: CareDueState
    var id: UUID { task.id }
}

/// Selects the care work Today shows from the existing care routine. No second store.
enum TodayCare {
    /// Enabled tasks that are overdue, due today, or due within `upcomingDays` calendar days.
    /// Ordered by due date, then plant name.
    static func items(
        from tasks: [CareTask],
        now: Date = .now,
        calendar: Calendar = .current,
        upcomingDays: Int = 7
    ) -> [TodayCareItem] {
        let today = calendar.startOfDay(for: now)
        let horizon = calendar.date(byAdding: .day, value: upcomingDays, to: today) ?? today
        return tasks
            .compactMap { task -> TodayCareItem? in
                guard task.isEnabled, let plant = task.plant else { return nil }
                let state = CareSchedule.state(for: task.dueDate, now: now, calendar: calendar)
                if state == .upcoming, calendar.startOfDay(for: task.dueDate) > horizon { return nil }
                return TodayCareItem(task: task, plant: plant, state: state)
            }
            .sorted {
                if $0.task.dueDate != $1.task.dueDate { return $0.task.dueDate < $1.task.dueDate }
                return $0.plant.name.localizedCaseInsensitiveCompare($1.plant.name) == .orderedAscending
            }
    }
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.createdAt, order: .reverse) private var plants: [Plant]
    @Query(sort: \CareTask.dueDate) private var careTasks: [CareTask]
    @Binding var selectedTab: AppTab
    @State private var showingAddPlant = false
    @State private var completing: TodayCareItem?
    @State private var careError: String?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var careItems: [TodayCareItem] { TodayCare.items(from: careTasks) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    masthead
                    welcome
                    dailyThought
                    careCheckIn
                    myGarden
                    journalPrompt
                    footer
                }
                .padding(.horizontal, FeedGoodTheme.contentPadding)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
            .background(FeedGoodTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddPlant) {
                AddPlantView()
            }
            .confirmationDialog(
                "Record care",
                isPresented: Binding(get: { completing != nil }, set: { if !$0 { completing = nil } }),
                titleVisibility: .visible,
                presenting: completing
            ) { item in
                Button("Record \(item.task.title) for \(item.plant.name)") { record(item) }
                    .accessibilityIdentifier("today.care.confirm")
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("This adds it to \(item.plant.name)’s care history and schedules the next one.")
            }
            .alert("Care not saved", isPresented: Binding(get: { careError != nil }, set: { if !$0 { careError = nil } })) {
                Button("OK") { careError = nil }
            } message: {
                Text(careError ?? "")
            }
        }
        .tint(FeedGoodTheme.leaf)
    }

    private func record(_ item: TodayCareItem) {
        do {
            try CareRecorder.complete(item.task, note: "", in: modelContext)
        } catch {
            careError = "Couldn’t save this care event. Your routine has not changed. Try again."
        }
    }

    private var masthead: some View {
        HStack(alignment: .center) {
            HStack(spacing: 9) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FeedGoodTheme.leaf)
                Text("feed good")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(FeedGoodTheme.leaf)
            }
            Spacer()
            Button {
                selectedTab = .plants
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .frame(width: 42, height: 42)
                    .background(FeedGoodTheme.surface, in: Circle())
            }
            .accessibilityLabel("My plants")
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(FeedGoodTheme.muted)

            Text("Let’s check in\non your plants.")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .tracking(-1.1)
                .lineSpacing(-1)
                .foregroundStyle(FeedGoodTheme.soil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("today.welcome")

            Text("A little attention goes a long way.")
                .font(.system(size: 15))
                .foregroundStyle(FeedGoodTheme.muted)
        }
        .padding(.top, 5)
    }

    private var dailyThought: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("A THOUGHT FOR TODAY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(FeedGoodTheme.leaf.opacity(0.72))

                Text("Growth happens\none small moment\nat a time.")
                    .font(.system(size: 21, weight: .medium, design: .serif))
                    .lineSpacing(1)
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .accessibilityIdentifier("today.dailyThought")

                Text("Take a moment to notice something new.")
                    .font(.system(size: 12))
                    .foregroundStyle(FeedGoodTheme.leaf.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(FeedGoodTheme.sage.opacity(0.32))
                    .frame(width: 88, height: 88)
                Image(systemName: "leaf")
                    .font(.system(size: 39, weight: .light))
                    .rotationEffect(.degrees(-28))
                    .foregroundStyle(FeedGoodTheme.leaf)
                Image(systemName: "sparkle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.moss)
                    .offset(x: 32, y: -30)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FeedGoodTheme.mist.opacity(0.82), in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius, style: .continuous))
    }

    private var careCheckIn: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeading("A moment of care", eyebrow: "YOUR GARDEN TODAY")

            if plants.isEmpty {
                careMessage(
                    title: "Your garden is waiting",
                    detail: "Add a plant and start getting to know what makes it happy.",
                    action: "Meet your first plant"
                ) { showingAddPlant = true }
            } else if careItems.isEmpty {
                careMessage(
                    title: "Nothing due today",
                    detail: "No care is due or coming up this week. Add a care routine to a plant and it will show up here.",
                    action: "Visit your plants"
                ) { selectedTab = .plants }
            } else {
                VStack(spacing: 10) {
                    ForEach(careItems) { item in
                        careRow(item)
                    }
                }
            }
        }
        .padding(19)
        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius, style: .continuous))
    }

    private func careMessage(title: String, detail: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .frame(width: 42, height: 42)
                    .background(FeedGoodTheme.mist, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FeedGoodTheme.soil)
                    Text(detail)
                        .font(.system(size: 13))
                        .lineSpacing(3)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Button(action: perform) {
                HStack(spacing: 8) {
                    Text(action)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FeedGoodTheme.surface)
                .padding(.horizontal, 17)
                .frame(height: 45)
                .background(FeedGoodTheme.leaf, in: Capsule())
            }
            .accessibilityIdentifier("today.careCheckIn.action")
        }
    }

    private func dueLabel(_ item: TodayCareItem) -> String {
        switch item.state {
        case .overdue: return "Overdue · since \(item.task.dueDate.formatted(date: .abbreviated, time: .omitted))"
        case .due: return "Due today"
        case .upcoming: return "Due \(item.task.dueDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))"
        }
    }

    private func careRow(_ item: TodayCareItem) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                PlantDetailView(plant: item.plant)
            } label: {
                HStack(spacing: 12) {
                    PlantPhotoView(photoData: item.plant.photoData)
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.task.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(FeedGoodTheme.soil)
                            .lineLimit(1)
                        Text(item.plant.name)
                            .font(.system(size: 12))
                            .foregroundStyle(FeedGoodTheme.muted)
                            .lineLimit(1)
                        Text(dueLabel(item))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(item.state == .overdue ? Color.red : FeedGoodTheme.leaf)
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("today.care.row.\(item.plant.name).\(item.task.title)")

            Button("Done") { completing = item }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FeedGoodTheme.surface)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(FeedGoodTheme.leaf, in: Capsule())
                .accessibilityLabel("Record \(item.task.title) for \(item.plant.name)")
                .accessibilityIdentifier("today.care.done.\(item.plant.name).\(item.task.title)")
        }
    }

    private var myGarden: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                sectionHeading("Growing together", eyebrow: "YOUR LITTLE GREEN WORLD")
                Spacer()
                Button("See all") { selectedTab = .plants }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .disabled(plants.isEmpty)
            }

            if plants.isEmpty {
                Button {
                    showingAddPlant = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 17)
                                .fill(FeedGoodTheme.mist)
                                .frame(width: 68, height: 68)
                            Image(systemName: "plus")
                                .font(.system(size: 21, weight: .light))
                                .foregroundStyle(FeedGoodTheme.leaf)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Make room for a little green")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FeedGoodTheme.soil)
                            Text("Your plant collection starts with one.")
                                .font(.system(size: 12))
                                .foregroundStyle(FeedGoodTheme.muted)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(FeedGoodTheme.leaf)
                    }
                    .padding(13)
                    .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(plants.prefix(8)) { plant in
                            plantCard(plant)
                        }
                        addPlantCard
                    }
                    .padding(.bottom, 2)
                }
                .contentMargins(.trailing, 2)
            }
        }
    }

    private func plantCard(_ plant: Plant) -> some View {
        NavigationLink {
            PlantDetailView(plant: plant)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                PlantPhotoView(photoData: plant.photoData)
                    .frame(width: 142, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(plant.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FeedGoodTheme.soil)
                        .lineLimit(1)
                    Text(plant.species.isEmpty ? "Getting to know you" : plant.species)
                        .font(.system(size: 11))
                        .foregroundStyle(FeedGoodTheme.muted)
                        .lineLimit(1)
                }
                .padding(.horizontal, 2)
            }
            .frame(width: 142, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.plant.\(plant.name)")
    }

    private var addPlantCard: some View {
        Button {
            showingAddPlant = true
        } label: {
            VStack(spacing: 9) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .frame(width: 142, height: 112)
                    .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .strokeBorder(FeedGoodTheme.sage.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    }
                Text("Add a plant")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.leaf)
            }
        }
        .buttonStyle(.plain)
    }

    private var journalPrompt: some View {
        Button {
            selectedTab = .journal
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "book.closed")
                    .font(.system(size: 21, weight: .light))
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .frame(width: 44, height: 44)
                    .background(FeedGoodTheme.mist, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("A little something to remember")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FeedGoodTheme.soil)
                    Text("What have you noticed in your garden lately?")
                        .font(.system(size: 12))
                        .foregroundStyle(FeedGoodTheme.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.leaf)
            }
            .padding(15)
            .background(FeedGoodTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("GROW AT YOUR OWN PACE")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(FeedGoodTheme.muted.opacity(0.8))
            Spacer()
        }
        .padding(.top, 1)
    }

    private func sectionHeading(_ title: String, eyebrow: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(FeedGoodTheme.muted)
            Text(title)
                .font(.system(size: 21, weight: .semibold, design: .serif))
                .tracking(-0.3)
                .foregroundStyle(FeedGoodTheme.soil)
        }
    }
}
