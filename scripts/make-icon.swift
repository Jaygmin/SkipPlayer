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

func radians(_ degrees: CGFloat) -> CGFloat { degrees * .pi / 180 }

/// Apple 아이콘처럼 모서리가 연속적으로 휘는 superellipse.
func squircle(_ rect: CGRect, exponent n: CGFloat = 5) -> CGPath {
    let path = CGMutablePath()
    let steps = 720
    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let x = rect.midX + rect.width / 2 * copysign(pow(abs(cos(t)), 2 / n), cos(t))
        let y = rect.midY + rect.height / 2 * copysign(pow(abs(sin(t)), 2 / n), sin(t))
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

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
/// 흰 배경 + 검은 재생 삼각형 + 파란 스킵 링(↻), 모두 정중앙 정렬.
func render(_ px: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: CGFloat(px) / 1024, y: CGFloat(px) / 1024)
    let center = CGPoint(x: 512, y: 512)

    // 본체: macOS 아이콘 격자(824pt, 여백 100pt) + 옅은 그림자, 흰색 → 옅은 회색 세로 그라데이션
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = squircle(body)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 24, color: color(0x000000, 0.22))
    ctx.addPath(bodyPath)
    ctx.setFillColor(color(0xE9E9EE))
    ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let background = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                colors: [color(0xFFFFFF), color(0xE9E9EE)] as CFArray, locations: nil)!
    ctx.drawLinearGradient(background, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    ctx.restoreGState()
    ctx.addPath(squircle(body.insetBy(dx: 1.5, dy: 1.5)))
    ctx.setStrokeColor(color(0x000000, 0.06))
    ctx.setLineWidth(3)
    ctx.strokePath()

    // 스킵 링: 위쪽 가운데가 열린 ↻ 하나
    let ringRadius: CGFloat = 272
    let blue = color(0x0A84FF)
    ctx.setStrokeColor(blue)
    ctx.setFillColor(blue)
    ctx.setLineWidth(36)
    ctx.setLineCap(.round)
    let end: CGFloat = 118 - 360  // 62°에서 시계 방향으로 304° 회전
    ctx.addArc(center: center, radius: ringRadius, startAngle: radians(62), endAngle: radians(end), clockwise: true)
    ctx.strokePath()
    let a = radians(end)
    let base = CGPoint(x: center.x + ringRadius * cos(a), y: center.y + ringRadius * sin(a))
    let tangent = CGVector(dx: sin(a), dy: -cos(a)), normal = CGVector(dx: cos(a), dy: sin(a))
    let length: CGFloat = 74, halfWidth: CGFloat = 48
    ctx.addPath(roundedPolygon([
        CGPoint(x: base.x + tangent.dx * length, y: base.y + tangent.dy * length),
        CGPoint(x: base.x + normal.dx * halfWidth, y: base.y + normal.dy * halfWidth),
        CGPoint(x: base.x - normal.dx * halfWidth, y: base.y - normal.dy * halfWidth),
    ], radius: 6))
    ctx.fillPath()

    // 재생 삼각형: 무게중심을 정중앙에 (광학적 중앙 정렬)
    let triangle = [0, 120, 240].map { degrees in
        CGPoint(x: center.x + 150 * cos(radians(CGFloat(degrees))), y: center.y + 150 * sin(radians(CGFloat(degrees))))
    }
    ctx.addPath(roundedPolygon(triangle, radius: 30))
    ctx.setFillColor(color(0x1C1C1E))
    ctx.fillPath()

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
