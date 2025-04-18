//
//  photowithface.swift
//  Group5_MAPD724_assignment5
//
//  Created by Rickie Au on 17/4/2025.
//
import SwiftUI
import SwiftCamera
import Vision

// Struct to hold each image and its corresponding face rectangles
struct PhotoWithFaces: Identifiable {
    let id = UUID()
    let image: Image
    let faceRects: [NormalizedRect]
}
