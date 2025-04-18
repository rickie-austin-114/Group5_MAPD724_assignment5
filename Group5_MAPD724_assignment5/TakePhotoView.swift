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
        // dismiss the view if user touch anywhere
        .onTapGesture {
            isPresented = false
        }
    }

    // Face Detection Method
    func detectFaces(imageData: Data) async throws -> [NormalizedRect] {
        let request = DetectFaceRectanglesRequest()
        let observation = try await request.perform(on: imageData, orientation: .up)
        return observation.map(\.boundingBox)
    }
}



