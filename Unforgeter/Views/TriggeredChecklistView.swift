import SwiftUI

struct TriggeredChecklistView: View {
    let isSimulation: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var checked: Set<String> = []
    private let items = ["Laptop", "Charger", "Keys"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(isSimulation ? "This is a simulated departure." : "You left the test zone.")
                        .font(.headline)
                    Text("Before you go, double-check your essentials.")
                }
                Section("Sample checklist") {
                    ForEach(items, id: \.self) { item in
                        Button {
                            if checked.contains(item) { checked.remove(item) }
                            else { checked.insert(item) }
                        } label: {
                            Label(item, systemImage: checked.contains(item) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(checked.contains(item) ? .teal : .primary)
                        }
                        .accessibilityValue(checked.contains(item) ? "Checked" : "Unchecked")
                    }
                }
                Section {
                    Button("I've got everything") { dismiss() }
                        .font(.headline)
                } footer: {
                    Text("This sample resets each time you open it. Custom Rule checklists will follow the geofence proof.")
                }
            }
            .navigationTitle("Before you go")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .tint(.teal)
        }
    }
}
