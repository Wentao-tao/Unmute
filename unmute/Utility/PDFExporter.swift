//
//  PDFExporter.swift
//  unmute
//
//  Created by Muhammad Dwiva Arya Erlangga on 14/11/25.
//


import SwiftUI
import UIKit

struct PDFExporter {
    static func exportPDF<Content: View>(@ViewBuilder content: () -> Content) -> URL? {
        let renderer = ImageRenderer(content: content())
        if #available(iOS 26.0, *) {
            renderer.scale = UITraitCollection.current.displayScale
        } else {
            renderer.scale = UIScreen.main.scale
        }

        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("TranscriptSummary.pdf")

        guard let image = renderer.uiImage else {
            print("❌ Renderer failed to create image")
            return nil
        }

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: image.size))

        do {
            try pdfRenderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                renderer.render { proposedSize, render in
                    guard let cg = UIGraphicsGetCurrentContext() else { return }
                    cg.saveGState()
                    render(cg)
                    cg.restoreGState()
                }
            }

            print("✅ Saved to Documents at:", url)
            return url

        } catch {
            print("❌ Failed to write PDF:", error)
            return nil
        }
    }
}
