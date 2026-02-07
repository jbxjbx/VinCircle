// MARK: - Theme.swift
// VinCircle - iOS Social Wine App
// Centralized theme definitions for wine-red color palette and animations

import SwiftUI

// MARK: - Wine Color Palette

extension Color {
    
    // Primary Wine Colors
    static let wineRed = Color(hex: "#8B2942")
    static let deepBurgundy = Color(hex: "#5C1A30")
    static let darkWine = Color(hex: "#3D0F1A")
    
    // Accent Colors
    static let champagneGold = Color(hex: "#D4A574")
    static let roseGold = Color(hex: "#B76E79")
    static let softRose = Color(hex: "#F5E6E8")
    static let cream = Color(hex: "#FFF8F0")
    
    // Utility - Create color from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Wine Gradients

struct WineGradients: Sendable {
    
    // Primary gradient for avatars, headers
    static let primary = LinearGradient(
        colors: [.wineRed, .deepBurgundy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Accent gradient with gold
    static let accent = LinearGradient(
        colors: [.wineRed, .roseGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Rich burgundy for dark elements
    static let dark = LinearGradient(
        colors: [.deepBurgundy, .darkWine],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Champagne highlight gradient
    static let champagne = LinearGradient(
        colors: [.champagneGold, .roseGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Score ring gradient
    static let scoreRing = AngularGradient(
        colors: [.wineRed, .champagneGold, .roseGold, .wineRed],
        center: .center
    )
    
    // Progress bar gradient
    static let progress = LinearGradient(
        colors: [.deepBurgundy, .wineRed, .roseGold],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Animation Constants

struct WineAnimations: Sendable {
    
    // Card appearance
    static let cardAppear = Animation.easeOut(duration: 0.4)
    
    // Heart pulse on like
    static let heartPulse = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    // Ring fill animation
    static let ringFill = Animation.easeInOut(duration: 1.0)
    
    // Annotation bounce on map
    static let annotationBounce = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    // Step transitions in posting flow
    static let stepTransition = Animation.easeInOut(duration: 0.35)
    
    // Stagger delay for list items
    static func staggerDelay(index: Int) -> Double {
        Double(index) * 0.08
    }
}

// MARK: - View Modifiers

extension View {
    
    /// Adds a wine-themed card style
    func wineCard() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// Adds entrance animation with stagger effect
    func staggeredAppear(index: Int, isVisible: Bool) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                WineAnimations.cardAppear.delay(WineAnimations.staggerDelay(index: index)),
                value: isVisible
            )
    }
    
    /// Wine-themed glow effect
    func wineGlow(isActive: Bool = true) -> some View {
        self.shadow(color: isActive ? Color.wineRed.opacity(0.4) : .clear, radius: 8)
    }
}

// MARK: - Animated Heart Button

struct AnimatedHeartButton: View {
    @Binding var isLiked: Bool
    let likeCount: Int
    
    @State private var animateScale = false
    
    var body: some View {
        Button {
            withAnimation(WineAnimations.heartPulse) {
                isLiked.toggle()
                animateScale = true
            }
            
            // Reset scale animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateScale = false
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? Color.wineRed : .secondary)
                    .scaleEffect(animateScale ? 1.3 : 1.0)
                
                Text("\(likeCount + (isLiked ? 1 : 0))")
                    .foregroundStyle(isLiked ? Color.wineRed : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Animated Progress Ring

struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    WineGradients.primary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(WineAnimations.ringFill) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.champagneGold.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
