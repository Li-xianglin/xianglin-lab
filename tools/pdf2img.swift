import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// pdf2img <input.pdf> <output_dir> <prefix> [width=2560] [chunkH=2560] [quality=0.9]
let args = CommandLine.arguments
guard args.count >= 4 else {
    print("Usage: swift pdf2img.swift <input.pdf> <output_dir> <prefix> [width=2560] [chunkH=2560] [quality=0.9]")
    exit(1)
}

let inputPath = args[1]
let outputDir = args[2]
let prefix = args[3]
let targetWidth: CGFloat = args.count >= 5 ? CGFloat(Double(args[4]) ?? 2560) : 2560
let chunkH: Int = args.count >= 6 ? (Int(args[5]) ?? 2560) : 2560
let quality: CGFloat = args.count >= 7 ? CGFloat(Double(args[6]) ?? 0.9) : 0.9

let url = URL(fileURLWithPath: inputPath) as CFURL
guard let pdf = CGPDFDocument(url) else {
    print("Failed to open PDF: \(inputPath)")
    exit(1)
}

let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let totalPages = pdf.numberOfPages
print("PDF has \(totalPages) page(s). Rendering at width \(Int(targetWidth)) q=\(quality), slicing every \(chunkH)px")

let startTime = Date()
var globalIndex = 0

for pageIdx in 1...totalPages {
    guard let page = pdf.page(at: pageIdx) else { continue }
    let box = page.getBoxRect(.mediaBox)
    let rotation = page.rotationAngle
    let pageW = (rotation == 90 || rotation == 270) ? box.height : box.width
    let pageH = (rotation == 90 || rotation == 270) ? box.width : box.height

    let scale = targetWidth / pageW
    let w = Int((pageW * scale).rounded())
    let h = Int((pageH * scale).rounded())

    print("page \(pageIdx): native \(Int(pageW))x\(Int(pageH)) → render \(w)x\(h)")

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: UInt32 = CGImageAlphaInfo.noneSkipLast.rawValue
    guard let ctx = CGContext(
        data: nil,
        width: w,
        height: h,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        print("  ! failed to create context")
        continue
    }

    ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let drawRect = CGRect(x: 0, y: 0, width: w, height: h)
    let xform = page.getDrawingTransform(.mediaBox, rect: drawRect, rotate: 0, preserveAspectRatio: true)
    ctx.concatenate(xform)
    ctx.drawPDFPage(page)

    guard let fullImg = ctx.makeImage() else {
        print("  ! failed to make image")
        continue
    }

    print(String(format: "  rendered in %.1fs", Date().timeIntervalSince(startTime)))

    // Slice top-to-bottom
    let bmpH = fullImg.height
    let bmpW = fullImg.width
    let chunks = (bmpH + chunkH - 1) / chunkH

    for c in 0..<chunks {
        let yTop = c * chunkH
        let thisH = min(chunkH, bmpH - yTop)
        let rect = CGRect(x: 0, y: yTop, width: bmpW, height: thisH)
        guard let sub = fullImg.cropping(to: rect) else {
            print("  ! crop failed at chunk \(c)")
            continue
        }
        globalIndex += 1
        let idxStr = String(format: "%03d", globalIndex)
        let outPath = "\(outputDir)/\(prefix)-\(idxStr).jpg"
        let outURL = URL(fileURLWithPath: outPath) as CFURL
        let utType = UTType.jpeg.identifier as CFString
        guard let dest = CGImageDestinationCreateWithURL(outURL, utType, 1, nil) else { continue }
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, sub, props as CFDictionary)
        CGImageDestinationFinalize(dest)
    }
    print("  → \(chunks) chunks written")
}

let elapsed = Date().timeIntervalSince(startTime)
print(String(format: "Done in %.1fs. Total %d chunks.", elapsed, globalIndex))
