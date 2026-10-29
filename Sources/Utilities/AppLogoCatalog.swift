import UIKit

/// Small offline fallback catalogue for popular streaming apps.
/// TV-provided artwork and user-imported photos always take precedence.
enum AppLogoCatalog {
    struct Choice: Identifiable {
        let id: String
        let title: String
    }

    static let choices: [Choice] = [
        .init(id: "netflix", title: "Netflix"),
        .init(id: "youtube", title: "YouTube"),
        .init(id: "prime-video", title: "Prime Video"),
        .init(id: "disney-plus", title: "Disney+"),
        .init(id: "plex", title: "Plex"),
        .init(id: "spotify", title: "Spotify"),
        .init(id: "apple-tv", title: "Apple TV"),
        .init(id: "apple-music", title: "Apple Music"),
        .init(id: "max", title: "Max"),
        .init(id: "twitch", title: "Twitch")
    ]

    static func matchingChoice(for appName: String) -> String? {
        let name = appName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if name.contains("netflix") { return "netflix" }
        if name.contains("youtube music") { return "youtube" }
        if name.contains("youtube") { return "youtube" }
        if name.contains("prime video") || name == "prime" { return "prime-video" }
        if name.contains("disney") { return "disney-plus" }
        if name.contains("plex") { return "plex" }
        if name.contains("spotify") { return "spotify" }
        if name.contains("apple music") || name == "music" { return "apple-music" }
        if name.contains("apple tv") || name == "tv" { return "apple-tv" }
        if name == "max" || name.contains("hbo max") { return "max" }
        if name.contains("twitch") { return "twitch" }
        return nil
    }

    static func iconData(forAppName appName: String) -> Data? {
        guard let choice = matchingChoice(for: appName) else { return nil }
        return iconData(for: choice)
    }

    static func iconData(for choiceID: String) -> Data? {
        guard choices.contains(where: { $0.id == choiceID }) else { return nil }
        let size: CGFloat = 256
        let canvas = CGRect(x: 0, y: 0, width: size, height: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: canvas.size, format: format)
        let image = renderer.image { context in
            context.cgContext.addPath(UIBezierPath(roundedRect: canvas, cornerRadius: 56).cgPath)
            context.cgContext.clip()
            let background: UIColor
            switch choiceID {
            case "netflix", "plex", "apple-tv": background = .black
            case "apple-music": background = UIColor(red: 0.96, green: 0.20, blue: 0.39, alpha: 1)
            case "youtube": background = .white
            case "prime-video", "disney-plus", "max": background = UIColor(red: 0.035, green: 0.065, blue: 0.16, alpha: 1)
            case "spotify": background = UIColor(red: 0.12, green: 0.82, blue: 0.42, alpha: 1)
            default: background = UIColor(red: 0.32, green: 0.12, blue: 0.56, alpha: 1)
            }
            background.setFill()
            context.cgContext.fill(canvas)

            switch choiceID {
            case "netflix":
                draw("N", in: canvas.insetBy(dx: 12, dy: -2), color: UIColor(red: 0.91, green: 0.03, blue: 0.08, alpha: 1), size: 212, weight: .black, alignment: .center)
            case "youtube":
                let box = UIBezierPath(roundedRect: CGRect(x: 34, y: 70, width: 188, height: 116), cornerRadius: 32)
                UIColor(red: 1, green: 0.02, blue: 0.02, alpha: 1).setFill()
                box.fill()
                let play = UIBezierPath()
                play.move(to: CGPoint(x: 106, y: 93)); play.addLine(to: CGPoint(x: 106, y: 163)); play.addLine(to: CGPoint(x: 166, y: 128)); play.close()
                UIColor.white.setFill(); play.fill()
            case "prime-video":
                draw("prime", in: CGRect(x: 10, y: 58, width: 236, height: 76), color: .white, size: 66, weight: .bold, alignment: .center)
                draw("video", in: CGRect(x: 10, y: 127, width: 236, height: 64), color: UIColor(red: 0.18, green: 0.72, blue: 0.96, alpha: 1), size: 52, weight: .semibold, alignment: .center)
            case "disney-plus":
                draw("Disney+", in: CGRect(x: 6, y: 77, width: 244, height: 92), color: .white, size: 55, weight: .bold, alignment: .center)
                draw("✦", in: CGRect(x: 175, y: 35, width: 42, height: 45), color: .white, size: 28, weight: .regular, alignment: .center)
            case "plex":
                draw("P", in: CGRect(x: 12, y: 12, width: 232, height: 232), color: UIColor(red: 1, green: 0.75, blue: 0.06, alpha: 1), size: 190, weight: .black, alignment: .center)
            case "spotify":
                let circle = UIBezierPath(ovalIn: CGRect(x: 27, y: 27, width: 202, height: 202))
                UIColor.black.setFill(); circle.fill()
                draw("≋", in: CGRect(x: 34, y: 28, width: 188, height: 192), color: UIColor(red: 0.12, green: 0.82, blue: 0.42, alpha: 1), size: 140, weight: .bold, alignment: .center)
            case "apple-tv":
                draw("tv+", in: CGRect(x: 10, y: 74, width: 236, height: 108), color: .white, size: 88, weight: .bold, alignment: .center)
            case "apple-music":
                // Offline Apple Music-style glyph; generated locally so it is always available.
                draw("♫", in: CGRect(x: 22, y: 12, width: 212, height: 232), color: .white, size: 190, weight: .bold, alignment: .center)
            case "max":
                draw("max", in: CGRect(x: 5, y: 65, width: 246, height: 126), color: .white, size: 100, weight: .black, alignment: .center)
            case "twitch":
                draw("T", in: CGRect(x: 10, y: 8, width: 236, height: 240), color: .white, size: 185, weight: .black, alignment: .center)
            default: break
            }
        }
        return image.pngData()
    }

    private static func draw(_ text: String, in rect: CGRect, color: UIColor, size: CGFloat, weight: UIFont.Weight, alignment: NSTextAlignment) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byClipping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
}
