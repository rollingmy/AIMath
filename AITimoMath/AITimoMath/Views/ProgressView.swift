import SwiftUI

struct ProgressBar: View {
    let value: Double
    let maxValue: Double
    var foregroundColor: Color = .blue
    var backgroundColor: Color = Color(.systemGray5)
    var height: CGFloat = 10.0
    
    private var progress: Double {
        min(max(value / maxValue, 0.0), 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: height)
                    .foregroundColor(backgroundColor)
                    .cornerRadius(height / 2)
                
                Rectangle()
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
                    .foregroundColor(foregroundColor)
                    .cornerRadius(height / 2)
            }
        }
    }
} 