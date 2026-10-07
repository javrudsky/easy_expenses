import SwiftUI

struct SomethingHappenView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)

            Text("Sorry, something happened")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("Please try again in a moment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

#Preview {
    SomethingHappenView()
}
