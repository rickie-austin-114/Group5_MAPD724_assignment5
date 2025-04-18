//
//  TakePhotoView.swift
//  Group5_MAPD724_assignment5
//
//  Created by Rickie Au on 17/4/2025.
//

//
//  ContentView.swift
//  Group5_MAPD724_assignment5
//
//  Created by Rickie Au on 17/4/2025.
//
//
//  ContentView.swift
//  CameraSample9
//
//  Created by Rickie Au on 17/4/2025.
//

//
//  ContentView.swift
//  CameraSampleApp
//
//  Created by student on 2025-04-04.
//

import SwiftUI
import SwiftCamera
import Vision

// Struct to h  aold each image and its corresponding face rectangles
struct PhotoWithFaces: Identifiable {
    let id = UUID()
    let image: Image
    let faceRects: [NormalizedRect]
}

struct TakePhotoView: View {
    @StateObject var camera = CameraModel()
    @Binding var capturedPhotos: [PhotoWithFaces]
    @Binding var isPresented: Bool

    
    var body: some View {
        ZStack {
            CameraLiveView(model: camera)
                .task {
                    do {
                        try camera.setInputDevice(position: .front, type: .wide)
                        try camera.addOutputDevice(type: .photo)
                        camera.start()
                    } catch {
                        print("Camera setup error: \(error.localizedDescription)")
                    }
                }
                .overlay(alignment: .topLeading) {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(capturedPhotos) { photo in
                                ZStack {
                                    photo.image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 200)
                                        .overlay {
                                            GeometryReader { geo in
                                                ForEach(photo.faceRects.indices, id: \.self) { i in
                                                    FaceCircle(normalizedRect: photo.faceRects[i], imageSize: geo.size)
                                                }
                                            }
                                        }
                                        .clipped()
                                    
                                    ShareLink(item: photo.image, preview: SharePreview("photo", icon: photo.image)) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .padding(6)
                                            .background(Color.white.opacity(0.5))
                                            .foregroundColor(.black)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(radius: 2)
                                    }
                                    
                                    .padding()
                                }
                            }
                        }
                        .padding()
                    }
                    .background(.thinMaterial)
                }
                .overlay(alignment: .bottom) {
                    Button("Take Photo") {
                        Task {
                            do {
                                let photoData = try await camera.capturePhoto(type: .jpeg)
                                
#if os(macOS)
                                if let nsImage = NSImage(data: photoData) {
                                    let image = Image(nsImage: nsImage)
                                    let boxes = try await detectFaces(imageData: photoData)
                                    let photo = PhotoWithFaces(image: image, faceRects: boxes)
                                    capturedPhotos.append(photo)
                                }
#elseif os(iOS)
                                if let uiImage = UIImage(data: photoData) {
                                    let image = Image(uiImage: uiImage)
                                    let boxes = try await detectFaces(imageData: photoData)
                                    let photo = PhotoWithFaces(image: image, faceRects: boxes)
                                    capturedPhotos.append(photo)
                                }
                                
                                isPresented = false
#endif
                                
                            } catch {
                                print("Capture error: \(error)")
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom)
                }
        }
        .onTapGesture {
            isPresented = false // Update the binding to dismiss the view
        }
    }

    // MARK: - Face Detection Method
    func detectFaces(imageData: Data) async throws -> [NormalizedRect] {
        let request = DetectFaceRectanglesRequest()
        let observation = try await request.perform(on: imageData, orientation: .up)
        return observation.map(\.boundingBox)
    }
}

// MARK: - Face Circle View
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

