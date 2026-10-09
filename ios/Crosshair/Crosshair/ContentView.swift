import SwiftUI

private enum Theme {
    static let bg = Color(red: 0.03, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let line = Color(red: 0.16, green: 0.20, blue: 0.27)
    static let text = Color.white
    static let muted = Color.white.opacity(0.55)
    static let cyan = Color(red: 0.24, green: 0.88, blue: 1.0)
    static let green = Color(red: 0.24, green: 1.0, blue: 0.60)
}

struct ContentView: View {
    @ObservedObject private var overlay = OverlayController.shared
    @State private var style = CrosshairStyle.default
    @State private var query = ""
    @State private var colorFilter = "all"

    private var filtered: [CrosshairStyle] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return PresetLibrary.all.filter { item in
            if colorFilter != "all", item.colorID != colorFilter { return false }
            if text.isEmpty { return true }
            if "\(item.id)".contains(text) { return true }
            if item.shape.title.lowercased().contains(text) { return true }
            if item.colorID.contains(text) { return true }
            return false
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                preview
                controls
                presetBar
                presetGrid
                overlayButtons
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            overlay.status = "\(PresetLibrary.count) presets ready. Customize, then start overlay."
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("by sonic")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.cyan)
            Text("AIM POINT")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(Theme.text)
            Rectangle().fill(Theme.cyan).frame(height: 2).padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var preview: some View {
        ZStack {
            Checkerboard().opacity(0.35)
            CrosshairCanvas(style: style)
            VStack {
                Spacer()
                Text("Center preview")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 8)
            }
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CUSTOM")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ReticleShape.allCases) { shape in
                        Button(shape.title) {
                            style.shape = shape
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(style.shape == shape ? Theme.cyan : Theme.card, in: Capsule())
                        .foregroundStyle(style.shape == shape ? .black : Theme.text)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CrosshairPalette.colors) { item in
                        Button {
                            style.colorID = item.id
                        } label: {
                            Circle()
                                .fill(item.color)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle().stroke(style.colorID == item.id ? Theme.cyan : Theme.line, lineWidth: 2)
                                )
                        }
                    }
                }
            }

            labeledSlider("Size", value: $style.length, range: 8...28)
            labeledSlider("Thickness", value: $style.thickness, range: 1...5)
            labeledSlider("Gap", value: $style.gap, range: 0...14)
            Toggle("Outline", isOn: $style.outline)
                .tint(Theme.cyan)
                .foregroundStyle(Theme.text)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var presetBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRESETS  \(PresetLibrary.count)+")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text("#\(style.id == 0 ? "custom" : "\(style.id)")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.cyan)
            }
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                TextField("Search shape, color, or number", text: $query)
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(Theme.text)
            }
            .padding(8)
            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    filterChip("All", selected: colorFilter == "all") { colorFilter = "all" }
                    ForEach(CrosshairPalette.colors) { item in
                        filterChip(item.name, selected: colorFilter == item.id) { colorFilter = item.id }
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var presetGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(filtered.prefix(400)) { item in
                    Button {
                        style = item
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.card)
                            CrosshairCanvas(style: item)
                            VStack {
                                Spacer()
                                Text("#\(item.id)")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Theme.muted)
                                    .padding(.bottom, 4)
                            }
                        }
                        .frame(height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(style.id == item.id ? Theme.cyan : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
            if filtered.count > 400 {
                Text("Showing 400 of \(filtered.count). Search or filter to see more.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 8)
            }
        }
    }

    private var overlayButtons: some View {
        VStack(spacing: 8) {
            Text(overlay.status)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button {
                overlay.start(style: style)
            } label: {
                Text(overlay.isActive ? "Restart Overlay" : "Start Overlay")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Button {
                overlay.stop()
            } label: {
                Text("Stop Overlay")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .padding(.top, 4)
    }

    private func labeledSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.muted)
            Slider(value: value, in: range)
                .tint(Theme.cyan)
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? Theme.cyan : Theme.card, in: Capsule())
            .foregroundStyle(selected ? .black : Theme.text)
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 16
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    if (row + col) % 2 == 0 {
                        context.fill(Path(CGRect(x: x, y: y, width: step, height: step)), with: .color(Color.white.opacity(0.06)))
                    }
                    x += step
                    col += 1
                }
                y += step
                row += 1
            }
        }
        .background(Color.black)
    }
}

#Preview {
    ContentView()
}
