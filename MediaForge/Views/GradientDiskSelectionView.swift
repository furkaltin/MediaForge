import SwiftUI

struct GradientDiskSelectionView: View {
    @EnvironmentObject private var viewModel: MediaForgeViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.8),
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.8),
                    Color.green.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Basic placeholder content
            VStack {
                Text("Coming Soon")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                Text("Gradient UI is temporarily disabled")
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    GradientDiskSelectionView()
        .environmentObject(MediaForgeViewModel())
} 