import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\\.dismiss) private var dismiss
    @Environment(\\.modelContext) private var modelContext
    @State private var name = ""
    @State private var species = ""
    @State private var notes = ""
    @State private var growingEnvironment = ""
    @State private var lightCondition = ""
    @State private var growingLocation = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant details") {
                    TextField("Plant name", text: $name)
                        .accessibilityIdentifier("plants.name")
                    TextField("Species or variety (optional)", text: $species)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Picker("Environment", selection: $growingEnvironment) {
                        Text("Not set").tag("")
                        ForEach(GrowingEnvironment.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    Picker("Light conditions", selection: $lightCondition) {
                        Text("Not set").tag("")
                        ForEach(LightCondition.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    TextField("Where it grows (optional)", text: $growingLocation)
                } header: {
                    Text("Growing context (optional)")
                } footer: {
                    Text("Add what you know, or skip this section. These are your observations, not sensor readings. No precise location is collected.")
                }
            }
            .navigationTitle("New plant")
            .navigationBarTitleDisplayMode(.inline)
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
        let location = growingLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let plant = Plant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            growingEnvironment: growingEnvironment.isEmpty ? nil : growingEnvironment,
            lightCondition: lightCondition.isEmpty ? nil : lightCondition,
            growingLocation: location.isEmpty ? nil : location
        )
        modelContext.insert(plant)
        dismiss()
    }
}
