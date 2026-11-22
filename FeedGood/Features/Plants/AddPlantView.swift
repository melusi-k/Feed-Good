import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var species = ""
    @State private var notes = ""
    @State private var growingEnvironment: GrowingEnvironment = .unspecified
    @State private var lightCondition: LightCondition = .unspecified

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant details") {
                    TextField("Plant name", text: $name)
                        .accessibilityIdentifier("plants.name")
                    TextField("Species or variety (optional)", text: $species)
                        .accessibilityIdentifier("plants.species")
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("plants.notes")
                }

                Section {
                    Picker("Where does it grow?", selection: $growingEnvironment) {
                        ForEach(GrowingEnvironment.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .accessibilityIdentifier("plants.growingEnvironment")

                    Picker("Observed light", selection: $lightCondition) {
                        ForEach(LightCondition.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .accessibilityIdentifier("plants.lightCondition")
                } header: {
                    Text("Growing context (optional)")
                } footer: {
                    Text("This helps us tailor plant care guidance to your plant’s growing conditions. These are your observations, not measurements. You can leave them unset or change them later. We do not need your location.")
                }
            }
            .feedGoodHeader("New plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePlant() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("plants.save")
                }
            }
        }
    }

    private func savePlant() {
        let plant = Plant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            growingEnvironment: growingEnvironment,
            lightCondition: lightCondition
        )
        modelContext.insert(plant)
        dismiss()
    }
}
