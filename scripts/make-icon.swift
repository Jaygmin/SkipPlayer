// SkipPlayer 앱 아이콘을 그려서 Resources/AppIcon.icns 와 docs/icon.png 를 만든다.
// 사용법: swift scripts/make-icon.swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
}

func radians(_ degrees: CGFloat) -> CGFloat { degrees * .pi / 180 }

func roundedPolygon(_ points: [CGPoint], radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let first = points[0], last = points[points.count - 1]
    path.move(to: CGPoint(x: (first.x + last.x) / 2, y: (first.y + last.y) / 2))
    for i in points.indices {
        path.addArc(tangent1End: points[i], tangent2End: points[(i + 1) % points.count], radius: radius)
    }
    path.closeSubpath()
    return path
}

/// 1024pt 좌표계(y축 위쪽)에서 그린 뒤 px 크기로 렌더링한다.
func render(_ px: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: CGFloat(px) / 1024, y: CGFloat(px) / 1024)
    let center = CGPoint(x: 512, y: 512)
    let white = color(0xFFFFFF, 0.96)

    // 본체: macOS 아이콘 격자(824pt 둥근 사각형, 여백 100pt) + 그림자
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
    ctx.addPath(bodyPath)
    ctx.setFillColor(color(0x1B1464))
    ctx.fillPath()
    ctx.restoreGState()

    // 배경: 남색 → 보라 대각선, 오른쪽 아래 주황 빛, 위쪽 은은한 광택
    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    ctx.drawLinearGradient(gradient([color(0x1B1464), color(0x6D28D9)]),
                           start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
    let glowCenter = CGPoint(x: 860, y: 160)
    ctx.drawRadialGradient(gradient([color(0xF97316, 0.65), color(0xF97316, 0)]),
                           startCenter: glowCenter, startRadius: 0, endCenter: glowCenter, endRadius: 560, options: [])
    ctx.drawLinearGradient(gradient([color(0xFFFFFF, 0.14), color(0xFFFFFF, 0)]),
                           start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 560), options: [])
    ctx.restoreGState()
    ctx.addPath(CGPath(roundedRect: body.insetBy(dx: 2, dy: 2), cornerWidth: 183, cornerHeight: 183, transform: nil))
    ctx.setStrokeColor(color(0xFFFFFF, 0.10))
    ctx.setLineWidth(4)
    ctx.strokePath()

    // 스킵 화살표: 왼쪽 ↺(뒤로), 오른쪽 ↻(앞으로). 화살촉은 아래쪽에서 마주 본다.
    let ringRadius: CGFloat = 300
    func ringPoint(_ degrees: CGFloat) -> CGPoint {
        CGPoint(x: center.x + ringRadius * cos(radians(degrees)), y: center.y + ringRadius * sin(radians(degrees)))
    }
    func arrowHead(at degrees: CGFloat, clockwise: Bool) {
        let base = ringPoint(degrees)
        let a = radians(degrees)
        let tangent = clockwise ? CGVector(dx: sin(a), dy: -cos(a)) : CGVector(dx: -sin(a), dy: cos(a))
        let normal = CGVector(dx: cos(a), dy: sin(a))
        let length: CGFloat = 80, halfWidth: CGFloat = 50
        let head = roundedPolygon([
            CGPoint(x: base.x + tangent.dx * length, y: base.y + tangent.dy * length),
            CGPoint(x: base.x + normal.dx * halfWidth, y: base.y + normal.dy * halfWidth),
            CGPoint(x: base.x - normal.dx * halfWidth, y: base.y - normal.dy * halfWidth),
        ], radius: 8)
        ctx.addPath(head)
        ctx.fillPath()
    }
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: color(0x000000, 0.25))
    ctx.setStrokeColor(white)
    ctx.setFillColor(white)
    ctx.setLineWidth(40)
    ctx.setLineCap(.round)
    ctx.addArc(center: center, radius: ringRadius, startAngle: radians(100), endAngle: radians(235), clockwise: false)
    ctx.strokePath()
    arrowHead(at: 235, clockwise: false)
    ctx.addArc(center: center, radius: ringRadius, startAngle: radians(80), endAngle: radians(-55), clockwise: true)
    ctx.strokePath()
    arrowHead(at: -55, clockwise: true)

    // 가운데 재생 삼각형 (시각적 중심을 위해 오른쪽으로 살짝 이동)
    ctx.addPath(roundedPolygon([
        CGPoint(x: 650, y: 512), CGPoint(x: 470, y: 407), CGPoint(x: 470, y: 617),
    ], radius: 26))
    ctx.fillPath()

    // 양쪽 "5" (5초 스킵)
    let font = NSFont.systemFont(ofSize: 120, weight: .heavy)
    let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 120) ?? font
    for x: CGFloat in [300, 724] {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: "5", attributes: [
            .font: rounded, .foregroundColor: NSColor(cgColor: white)!,
        ]))
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        ctx.textPosition = CGPoint(x: x - bounds.midX, y: center.y - bounds.midY)
        CTLineDraw(line, ctx)
    }
    ctx.restoreGState()

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "failed to write \(url.path)")
}

let fm = FileManager.default
let iconset = fm.temporaryDirectory.appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try fm.createDirectory(at: iconset, withIntermediateDirectories: false)
for size in [16, 32, 128, 256, 512] {
    writePNG(render(size), to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    writePNG(render(size * 2), to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}

try fm.createDirectory(at: root.appendingPathComponent("Resources"), withIntermediateDirectories: true)
try fm.createDirectory(at: root.appendingPathComponent("docs"), withIntermediateDirectories: true)
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", "-o", root.appendingPathComponent("Resources/AppIcon.icns").path, iconset.path]
try iconutil.run()
iconutil.waitUntilExit()
try fm.removeItem(at: iconset)
precondition(iconutil.terminationStatus == 0, "iconutil failed")

writePNG(render(512), to: root.appendingPathComponent("docs/icon.png"))
print("Wrote Resources/AppIcon.icns and docs/icon.png")
