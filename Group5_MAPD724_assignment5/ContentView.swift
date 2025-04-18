//
//  ContentView.swift
//  Group5_MAPD724_assignment5
//
//  Created by Rickie Au on 17/4/2025.
//
//

import SwiftUI
import SwiftCamera
import Vision
import Photos
import PhotosUI


struct ContentView: View {
    @State private var navigateToTakePhotoView = false
    
    @State var showPhotoSelector = false
    @State var selectedPhoto: [PhotosPickerItem] = []
    @State var selectedImages: [PhotoWithFaces] = []


    var body: some View {
        ZStack {
            
            ZStack {
                // Fullscreen LinearGradient background
                LinearGradient(gradient: Gradient(colors: [Color.orange, Color.blue, Color.red]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                
                VStack {
                    
                    
                    Button("Add Photo") {
                        showPhotoSelector = true
                    }
                    .padding(.top, 20) // Add some top padding, ensure the button located at the top of the screen
                    .background(Color.white)
                    .cornerRadius(10)

                    Spacer() // use spacer to push the button to the top of the screen


                    // Horizontal ScrollView for selected images
                    ScrollView(.horizontal) {

                        
                        HStack(spacing: 12) {
                        
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                ZStack {
                                    selectedImages[index].image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 200)
                                        .overlay {
                                            GeometryReader { geo in
                                                ForEach(selectedImages[index].faceRects.indices, id: \.self) { i in
                                                    FaceCircle(normalizedRect: selectedImages[index].faceRects[i], imageSize: geo.size)
                                                }
                                            }
                                        }
                                        .clipped()
                                    
                                    ShareLink(item: selectedImages[index].image, preview: SharePreview("photo", icon: selectedImages[index].image)) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .padding(6)
                                            .background(Color.white.opacity(0.5))
                                            .foregroundColor(.black)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                                
                            .padding()
                        }
                        
                        .padding(.horizontal)
                    }
                    .containerRelativeFrame(.vertical) { height, _ in
                        height * 0.20 // 20% of container height
                    }
                    
                    Spacer()// use spacer to push the scrollview to the center of the screen

                }
                .frame(maxHeight: .infinity) // Ensures VStack takes full height of the screen
            }
            .photosPicker(isPresented: $showPhotoSelector,
                         selection: $selectedPhoto,
                         matching: .images,
                         preferredItemEncoding: .compatible)
            .onChange(of: selectedPhoto) { oldValue, newValue in
                handlePhotoSelection(newValue)
            }



        }
        .gesture(
            DragGesture().onEnded { gesture in
                if gesture.translation.height < -20 { // negative means swipe up, 20% of screen height
                    navigateToTakePhotoView = true
                }
            }
        )
        .fullScreenCover(isPresented: $navigateToTakePhotoView) {
            TakePhotoView(capturedPhotos: $selectedImages, isPresented: $navigateToTakePhotoView)
        }
    }
    
    private func handlePhotoSelection(_ newValue: [PhotosPickerItem]) {
        Task {
            // Limit to 5 photos, else print error message
            if newValue.count <= 5 {
                selectedImages.removeAll()
                for photo in newValue {
                    do {
                        if let image = try await loadImage(from: photo) {
                            if let photoData = try await loadImageData(from: photo) {
                                
                                
                                
#if os(macOS)
                                if let nsImage = NSImage(data: photoData) {
                                    let image = Image(nsImage: nsImage)
                                    let boxes = try await detectFaces(imageData: photoData)
                                    let photo = PhotoWithFaces(image: image, faceRects: boxes)
                                    selectedImages.append(photo)
                                }
#elseif os(iOS)
                                if let uiImage = UIImage(data: photoData) {
                                    let image = Image(uiImage: uiImage)
                                    let boxes = try await detectFaces(imageData: photoData)
                                    let photo = PhotoWithFaces(image: image, faceRects: boxes)
                                    selectedImages.append(photo)
                                }
                                
#endif

                            }

                        }
                    } catch {
                        print("Error loading image: \(error)")
                    }
                }
            } else {
                print("Error: Cannot select more than 5 images")
            }
        }
    }
    

    func loadImageData(from item: PhotosPickerItem) async throws -> Data? {
        // Try loading the item as Data
        try await item.loadTransferable(type: Data.self)
        /*
        if let data = try await item.loadTransferable(type: Data.self) {
            return data
        } else {
            throw NSError(domain: "ImageDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"])
        }*/
    }
    
    // MARK: - Face Detection Method
    func detectFaces(imageData: Data) async throws -> [NormalizedRect] {
        let request = DetectFaceRectanglesRequest()
        let observation = try await request.perform(on: imageData, orientation: .up)
        return observation.map(\.boundingBox)
    }
    
    
    
    private func loadImage(from item: PhotosPickerItem) async throws -> Image? {
        try await item.loadTransferable(type: Image.self)
    }
}


