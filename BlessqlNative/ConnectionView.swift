import SwiftUI

struct ConnectionView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header branding
            HStack {
                Image(systemName: "cylinder.split.1x2")
                    .font(.system(size: 20))
                    .foregroundColor(.blessqlPrimary)
                Text("Blessql")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Connection list
            ConnectionListView()
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    ConnectionView()
}
