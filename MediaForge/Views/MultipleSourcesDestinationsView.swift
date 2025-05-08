import SwiftUI

struct MultipleSourcesDestinationsView: View {
    @EnvironmentObject private var viewModel: MediaForgeViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Basic placeholder content
            VStack(spacing: 20) {
                Text("MediaForge Pro")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                
                Text("Professional UI will be available soon")
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text("This feature is under development")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    MultipleSourcesDestinationsView()
        .environmentObject(MediaForgeViewModel())
} 