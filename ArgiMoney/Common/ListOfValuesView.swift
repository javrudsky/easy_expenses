import SwiftUI

/// A reusable list-of-values picker with built-in search.
public struct ListOfValuesView<Value: Identifiable & Hashable>: View {
    private let values: [Value]
    private let nameKeyPath: KeyPath<Value, String>
    private let onSelect: (Value) -> Void

    @State private var query: String = ""

    public init(values: [Value], name: KeyPath<Value, String>, onSelect: @escaping (Value) -> Void) {
        self.values = values
        self.nameKeyPath = name
        self.onSelect = onSelect
    }

    private var filtered: [Value] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return values }
        return values.filter { $0[keyPath: nameKeyPath].localizedCaseInsensitiveContains(trimmed) }
    }

    public var body: some View {
            
        VStack(spacing: 0) {
            Spacer()
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search", text: $query)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .safeAreaPadding(.horizontal)
                .padding(.vertical)
                .background(.thinMaterial)
            }
            .padding(.horizontal)
            
            Divider()
            
            // List of values
            List(filtered, id: \.self) { value in
                Button {
                    onSelect(value)
                } label: {
                    HStack {
                        Text(value[keyPath: nameKeyPath])
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .listStyle(.insetGrouped)
        }
        .backgroundStyle(Color(.white).opacity(30))
        .padding()
    }
}

#Preview("ListOfValuesView: LovType") {
    struct LovType: Identifiable, Hashable {
        let id = UUID()
        let name: String
    }
    let sample: [LovType] = [
        LovType(name: "Food"),
        LovType(name: "Transport"),
        LovType(name: "Utilities"),
        LovType(name: "Entertainment")
    ]
    return NavigationStack {
        ListOfValuesView(values: sample, name: \.name) { selected in
            print("Selected: \(selected.name)")
        }
    }
}
