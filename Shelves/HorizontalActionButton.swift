import SwiftUI

struct HorizontalActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(ShelvesDesign.Typography.labelMedium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, ShelvesDesign.Spacing.lg)
            .padding(.vertical, ShelvesDesign.Spacing.md)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        HorizontalActionButton(
            title: "Mark Read",
            icon: "checkmark.circle.fill",
            color: .green
        ) {
            print("Mark Read tapped")
        }
        
        HorizontalActionButton(
            title: "View Details",
            icon: "info.circle.fill",
            color: .blue
        ) {
            print("View Details tapped")
        }
    }
    .padding()
}