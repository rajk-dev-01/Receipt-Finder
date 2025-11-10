//
//  CameraView.swift
//  Receipt Finder
//
//  Created by Rajahiresh Kalva on 8/6/25.
//

import SwiftUI
import VisionKit
import Vision

struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    // Pass scanned images + OCR text back to parent
    var onScanComplete: (_ images: [UIImage], _ recognizedText: String) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            print("❌ Scanning failed: \(error.localizedDescription)")
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            
            parent.presentationMode.wrappedValue.dismiss()
            
            // ✅ Run OCR on first page (or loop if multi-page)
            DispatchQueue.global(qos: .userInitiated).async {
                var recognizedText = ""
                if let firstImage = images.first {
                    recognizedText = self.performOCR(on: firstImage)
                }
                
                // Send results back to parent
                DispatchQueue.main.async {
                    self.parent.onScanComplete(images, recognizedText)
                }
            }
        }
        
        // MARK: - OCR (Background Thread)
        private func performOCR(on image: UIImage) -> String {
            guard let cgImage = image.cgImage else {
                return "❌ Failed to convert UIImage to CGImage"
            }
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("❌ OCR failed: \(error.localizedDescription)")
                return ""
            }
            
            let textResults = request.results as? [VNRecognizedTextObservation] ?? []
            return textResults.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        }
    }
}

