import SwiftUI
import UIKit

struct SpeechBubble: View {
    let text: String
    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: 0x1E2233))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .frame(maxWidth: 200)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
            Triangle().fill(Color.white).frame(width: 16, height: 9)
        }
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct BobStage: View {
    @ObservedObject private var bob = Bob.shared
    @State private var sim = Sim()
    @State private var bubble: String? = nil
    @State private var bubbleId = 0

    private func say(_ t: String) {
        bubble = t
        bubbleId += 1
        let id = bubbleId
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            if bubbleId == id { bubble = nil }
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                TimelineView(.animation) { tl in
                    Canvas { ctx, size in
                        sim.tick(tl.date)
                        drawBob(&ctx, size: size, skin: bob.skin, accs: bob.accs, mood: bob.mood, sim: sim)
                    }
                }
                if let b = bubble {
                    SpeechBubble(text: b)
                        .padding(.top, 6)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: bubble)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                sim.hop(); say(Dialogue.hop())
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .onTapGesture {
                sim.pat(); say(Dialogue.pat())
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .gesture(
                DragGesture(minimumDistance: 8).onChanged { v in
                    sim.lookAt((v.location.x / geo.size.width - 0.5) * 2, (v.location.y / geo.size.height - 0.5) * 2)
                }
            )
        }
        .task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            say(Dialogue.greet())
            while !Task.isCancelled {
                let s = UInt64.random(in: 12...24)
                try? await Task.sleep(nanoseconds: s * 1_000_000_000)
                say(Dialogue.idle(bob.mood))
            }
        }
    }
}
