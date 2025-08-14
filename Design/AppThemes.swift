//
//  AppTheme.swift
//  SimpleMiles
//
//  Central theme: colors + typography + a map-based preview.
//  Define the corresponding Color Assets named exactly as documented below.
//
import SwiftUI
import MapKit

// MARK: - Theme Root
enum AppTheme {

    // MARK: - Shades
    enum Shade: String, CaseIterable {
        case dark   = "CP-Dark"
        case medium = "CP-Medium"
        case light  = "CP-Light"
    }

    // MARK: - Colors
    enum Colors {

        // Convenience aliases (optional)
        static var primaryDark: Color   { Color("CP-Dark") }
        static var primaryMedium: Color { Color("CP-Medium") }
        static var primaryLight: Color  { Color("CP-Light") }
        
        static var secondaryDark: Color   { Color("CS-Dark") }
        static var secondaryMedium: Color { Color("CS-Medium") }
        static var secondaryLight: Color  { Color("CS-Light") }

        static var accentDark: Color   { Color("CA-Dark") }
        static var accentMedium: Color { Color("CA-Medium") }
        static var accentLight: Color  { Color("CA-Light") }
        
        static var customWhite: Color { Color("CWhite") }
    }

    // MARK: - Typography
    enum Typography {
        // Adjust sizes/weights once; reuse everywhere.
        static let title    = Font.system(size: 28, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body     = Font.system(size: 16, weight: .regular, design: .default)
        static let caption  = Font.system(size: 13, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        static let note     = Font.system(size: 10, weight: .medium, design: .default)
    }
}

private struct TextThemeSwatch: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(color)
        }
        .frame(width: 100, height: 40)
        .glassEffect(.clear)
    }
}
// MARK: - Preview Helpers (Reusable, local to this file)
private struct ThemeSwatch: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .shadow(radius: 2)
                .overlay(
                    Circle().stroke(.white.opacity(0.6), lineWidth: 0.5)
                )

            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(color)
        }
        .frame(width: 100, height: 40)
        .glassEffect(.clear)
    }
}

private struct ThemeSwatchSystem: View {
    let title: String
    let color: Color
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(color.opacity(0.1))
                .frame(width: 100, height: 40)
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(color)
        }
        .frame(width: 100, height: 40)
        .glassEffect(.clear)
        
    }
}

private struct ThemePanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .center, spacing: 0) {
                    Text("Primary").font(AppTheme.Typography.caption).opacity(0.7)
                    ThemeSwatch(title: "Dark",   color:AppTheme.Colors.primaryDark)
                    ThemeSwatch(title: "Medium", color: AppTheme.Colors.primaryMedium)
                    ThemeSwatch(title: "Light",  color: AppTheme.Colors.primaryLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                VStack(alignment: .center, spacing: 0) {
                    Text("Secondary").font(AppTheme.Typography.caption).opacity(0.7)
                    ThemeSwatch(title: "Dark",   color: AppTheme.Colors.secondaryDark)
                    ThemeSwatch(title: "Medium", color: AppTheme.Colors.secondaryMedium)
                    ThemeSwatch(title: "Light",  color: AppTheme.Colors.secondaryLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                VStack(alignment: .center, spacing: 0) {
                    Text("Accent").font(AppTheme.Typography.caption).opacity(0.7)
                    ThemeSwatch(title: "Dark",   color: AppTheme.Colors.accentDark)
                    ThemeSwatch(title: "Medium", color: AppTheme.Colors.accentMedium)
                    ThemeSwatch(title: "Light",  color: AppTheme.Colors.accentLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        .padding(16)
        }
    }
}

private struct BackgroundThemePanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .center, spacing: 0) {
                    Text("Primary").font(AppTheme.Typography.caption).opacity(0.7)
                    ThemeSwatchSystem(title: "Dark",   color:AppTheme.Colors.primaryDark)
                    ThemeSwatchSystem(title: "Medium", color: AppTheme.Colors.primaryMedium)
                    ThemeSwatchSystem(title: "Light",  color: AppTheme.Colors.primaryLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                VStack(alignment: .center, spacing: 0) {
                    Text("Secondary").font(AppTheme.Typography.caption).opacity(0.7)
                    ThemeSwatchSystem(title: "Dark",   color: AppTheme.Colors.secondaryDark)
                    ThemeSwatchSystem(title: "Medium", color: AppTheme.Colors.secondaryMedium)
                    ThemeSwatchSystem(title: "Light",  color: AppTheme.Colors.secondaryLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                VStack(alignment: .center, spacing: 0) {
                    Text("Accent").font(AppTheme.Typography.caption).opacity(0.7)
                    ThemeSwatchSystem(title: "Dark",   color: AppTheme.Colors.accentDark)
                    ThemeSwatchSystem(title: "Medium", color: AppTheme.Colors.accentMedium)
                    ThemeSwatchSystem(title: "Light",  color: AppTheme.Colors.accentLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        .padding(16)
        }
    }
}

private struct TextThemePanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
           HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .center, spacing: 0) {
                    Text("Primary").font(AppTheme.Typography.caption).opacity(0.7)
                    TextThemeSwatch(title: "Dark", color: AppTheme.Colors.primaryDark)
                    TextThemeSwatch(title: "Medium", color: AppTheme.Colors.primaryMedium)
                    TextThemeSwatch(title: "Light", color: AppTheme.Colors.primaryLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                VStack(alignment: .center, spacing: 0) {
                    Text("Secondary").font(AppTheme.Typography.caption).opacity(0.7)
                    TextThemeSwatch(title: "Dark", color: AppTheme.Colors.secondaryDark)
                    TextThemeSwatch(title: "Medium", color: AppTheme.Colors.secondaryMedium)
                    TextThemeSwatch(title: "Light", color: AppTheme.Colors.secondaryLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                VStack(alignment: .center, spacing: 0) {
                    Text("Accent").font(AppTheme.Typography.caption).opacity(0.7)
                    TextThemeSwatch(title: "Dark", color: AppTheme.Colors.accentDark)
                    TextThemeSwatch(title: "Medium", color: AppTheme.Colors.accentMedium)
                    TextThemeSwatch(title: "Light", color: AppTheme.Colors.accentLight)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        .padding(16)
        }
    }
}

private struct SplitThemePreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var plainBackground: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack {
                    plainBackground
                        .ignoresSafeArea()
                    VStack(spacing: 18) {
                        ThemePanel()
                        BackgroundThemePanel()
                        TextThemePanel()
                    }
                    .frame(maxWidth: 700)
                    .padding()
                }
                .frame(height: geo.size.height / 2)

                ZStack {
                    Map(position: .constant(.region(.init(
                        center: .init(latitude: 37.3349, longitude: -122.0090),
                        span: .init(latitudeDelta: 0.028, longitudeDelta: 0.028)
                    ))))
                    .ignoresSafeArea()
                    VStack(spacing: 18) {
                        ThemePanel()
                        BackgroundThemePanel()
                        TextThemePanel()
                    }
                    .frame(maxWidth: 700)
                    .padding()
                }
                .frame(height: geo.size.height / 2)
            }
        }
    }
}

// MARK: - Live Map-based Preview
#Preview("AppTheme – Split (Plain & Map)") {
    SplitThemePreview()
}
