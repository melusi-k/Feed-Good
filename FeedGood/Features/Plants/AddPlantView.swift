import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var species = ""
    @State private var notes = ""

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
        let plant = Plant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(plant)
        dismiss()
    }
}
