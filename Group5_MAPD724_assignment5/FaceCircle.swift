//
//  FaceCircle.swift
//  Group5_MAPD724_assignment5
//
//  Created by Rickie Au on 17/4/2025.
//

import SwiftUI
import SwiftCamera
import Vision

// Face Circle View
struct FaceCircle: View {
    let normalizedRect: NormalizedRect
    let imageSize: CGSize

    var body: some View {
        let rect = normalizedRect.toImageCoordinates(imageSize, origin: .upperLeft)
        return Circle()
            .stroke(Color.red, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}
