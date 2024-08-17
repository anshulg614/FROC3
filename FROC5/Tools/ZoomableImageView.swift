//
//  ZoomableImageView.swift
//  FROC5
//
//  Created by Anshul Ganumpally on 8/17/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct ZoomableImageView: UIViewRepresentable {
    let url: URL?
    let frameHeight: CGFloat
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2
        
        imageView.addGestureRecognizer(pinchGesture)
        imageView.addGestureRecognizer(panGesture)
        
        context.coordinator.imageView = imageView
        
        // Load image asynchronously
        if let url = url {
            context.coordinator.loadImage(from: url, into: imageView)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var imageView: UIImageView?
        var currentScale: CGFloat = 1.0
        var initialCenter = CGPoint()
        
        @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
            guard let imageView = imageView else { return }
            
            if sender.state == .began || sender.state == .changed {
                imageView.transform = imageView.transform.scaledBy(x: sender.scale, y: sender.scale)
                sender.scale = 1.0
            } else if sender.state == .ended {
                UIView.animate(withDuration: 0.3) {
                    imageView.transform = CGAffineTransform.identity
                }
            }
        }
        
        @objc func handlePan(_ sender: UIPanGestureRecognizer) {
            guard let imageView = imageView else { return }
            
            if sender.state == .began {
                initialCenter = imageView.center
            } else if sender.state == .changed {
                let translation = sender.translation(in: imageView.superview)
                imageView.center = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            } else if sender.state == .ended {
                UIView.animate(withDuration: 0.3) {
                    imageView.transform = CGAffineTransform.identity
                    imageView.center = self.initialCenter
                }
            }
        }
        
        func loadImage(from url: URL, into imageView: UIImageView) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            }
        }
    }
}
