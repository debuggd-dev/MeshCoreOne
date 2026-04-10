import SwiftUI

/// Settings section for selecting the app's accent color (Customization)
struct ThemeSettingsSection: View {
    @AppStorage("appThemeColor") private var appTheme: AppTheme = .system
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Accent Color")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(AppTheme.allCases) { theme in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    appTheme = theme
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(theme.color ?? Color.accentColor)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                                    
                                    if appTheme == theme {
                                        Circle()
                                            .stroke(Color.primary.opacity(0.8), lineWidth: 3)
                                            .frame(width: 52, height: 52)
                                    }
                                    
                                    if theme == .system {
                                        Image(systemName: "paintpalette.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white)
                                            .shadow(radius: 1)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(theme.rawValue)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Customization")
        } footer: {
            Text("Personalize the app by choosing your favorite accent color.")
        }
    }
}

#Preview {
    Form {
        ThemeSettingsSection()
    }
}
