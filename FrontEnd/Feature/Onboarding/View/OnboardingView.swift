import SwiftUI
import CoreLocation

/// Explains the necessity of background location access and provides a user-triggered permission request.
struct OnboardingView: View {
    
    // MARK: - Environment
    @Environment(\.layout) private var layout
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Immersive background
            LinearGradient(
                colors: [AppTheme.Colors.primaryPath.opacity(0.1), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon / Branding
                Image(systemName: "location.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(AppTheme.Colors.primaryPath)
                    .shadow(color: AppTheme.Colors.primaryPath.opacity(0.5), radius: 20)
                
                // Welcome Text
                VStack(spacing: 12) {
                    Text("Welcome to Simple Miles")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("Automatic, privacy-first mileage tracking for your daily drives.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Feature Highlights
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "bolt.shield.fill",
                        title: "Background Tracking",
                        desc: "Simple Miles detects when you start driving and records your trip automatically."
                    )
                    
                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "Privacy First",
                        desc: "All your location data stays on your device. We never see where you go."
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Call to Action
                VStack(spacing: 16) {
                    Text("To enable automatic tracking, please allow 'Always' location access on the next screen.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        LocationManager.shared.requestAuthorizationAndStart()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, layout.bottomSafeInset + 20)
            }
        }
    }
    
    // MARK: - Subview: FeatureRow
    private struct FeatureRow: View {
        let icon: String
        let title: String
        let desc: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.primaryPath)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}
