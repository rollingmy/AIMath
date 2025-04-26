import SwiftUI

/// A view that displays a user's avatar, with a fallback placeholder
struct AvatarImageView: View {
    let avatarName: String
    let size: CGFloat
    
    init(avatarName: String, size: CGFloat = 60) {
        self.avatarName = avatarName
        self.size = size
    }
    
    var body: some View {
        // First try to load the image from assets
        if let uiImage = UIImage(named: avatarName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
        } else {
            // Fallback to a placeholder with initials or icon
            ZStack {
                Circle()
                    .fill(avatarBackgroundColor)
                    .frame(width: size, height: size)
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                
                // Show a default icon
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            }
        }
    }
    
    // Generate a consistent color based on the avatar name
    private var avatarBackgroundColor: Color {
        // Use the hash value of the name to generate a consistent color
        let hash = abs(avatarName.hashValue)
        let hue = Double(hash % 10) / 10.0 // Get a value between 0 and 1
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }
}

// Extension to make Image work with our custom view
extension Image {
    /// Create an avatar image with a consistent style
    static func avatar(_ name: String, size: CGFloat = 60) -> some View {
        AvatarImageView(avatarName: name, size: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        AvatarImageView(avatarName: "avatar-1", size: 60)
        AvatarImageView(avatarName: "avatar-2", size: 60)
        AvatarImageView(avatarName: "nonexistent", size: 60)
    }
    .padding()
} 