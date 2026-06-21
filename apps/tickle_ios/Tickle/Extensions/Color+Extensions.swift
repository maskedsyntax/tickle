import SwiftUI

extension Color {
    func lighter(by percentage: CGFloat = 20.0) -> Color {
        return self.adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 20.0) -> Color {
        return self.adjust(by: -1 * abs(percentage))
    }

    private func adjust(by percentage: CGFloat) -> Color {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        let nativeColor = NativeColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        #if canImport(UIKit)
        if nativeColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return Color(
                red: Double(min(max(r + percentage / 100, 0), 1)),
                green: Double(min(max(g + percentage / 100, 0), 1)),
                blue: Double(min(max(b + percentage / 100, 0), 1)),
                opacity: Double(a)
            )
        }
        #elseif canImport(AppKit)
        if let rgbColor = nativeColor.usingColorSpace(.deviceRGB) {
            rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            return Color(
                red: Double(min(max(r + percentage / 100, 0), 1)),
                green: Double(min(max(g + percentage / 100, 0), 1)),
                blue: Double(min(max(b + percentage / 100, 0), 1)),
                opacity: Double(a)
            )
        }
        #endif
        
        return self
    }
}
