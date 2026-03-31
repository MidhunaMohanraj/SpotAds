import SwiftUI

// MARK: - Ad Label

struct AdBadge: View {
    var body: some View {
        Text("Ad")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(Color(.systemBackground))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - CTA Button

struct CTAButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.green)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Bar

struct AdProgressBar: View {
    let progress: Double  // 0.0 – 1.0
    var tint: Color = .green
    var trackColor: Color = Color.white.opacity(0.2)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(progress))
                    .animation(.linear(duration: 0.5), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Skip Button

struct SkipButton: View {
    let canSkip: Bool
    let remaining: Int
    let action: () -> Void

    var body: some View {
        Button(action: { if canSkip { action() } }) {
            HStack(spacing: 4) {
                if canSkip {
                    Text("Skip Ad")
                    Image(systemName: "chevron.right.2")
                } else {
                    Text("Skip in \(remaining)s")
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(canSkip ? .white : .white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(canSkip ? Color.white.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(canSkip ? 0.5 : 0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .disabled(!canSkip)
        .animation(.easeInOut(duration: 0.3), value: canSkip)
    }
}

// MARK: - Async Image (with placeholder)

struct AdAsyncImage: View {
    let url: URL?
    var aspectRatio: CGFloat = 16/9
    var cornerRadius: CGFloat = 0

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        shimmerPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(aspectRatio, contentMode: .fill)
                    case .failure:
                        Color(.systemGray5)
                            .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                shimmerPlaceholder
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var shimmerPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay(ShimmerView())
    }
}

// MARK: - Shimmer

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.3),
                Color.white.opacity(0.0)
            ]),
            startPoint: UnitPoint(x: phase, y: 0.5),
            endPoint: UnitPoint(x: phase + 1, y: 0.5)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Previews

#Preview("CTA Button") {
    CTAButton(label: "Shop Now") {}
        .padding()
        .background(.black)
}

#Preview("Skip Button — Locked") {
    SkipButton(canSkip: false, remaining: 5) {}
        .padding()
        .background(.black)
}

#Preview("Skip Button — Unlocked") {
    SkipButton(canSkip: true, remaining: 0) {}
        .padding()
        .background(.black)
}
