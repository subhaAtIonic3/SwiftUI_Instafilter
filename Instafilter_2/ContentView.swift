//
//  ContentView.swift
//  Instafilter_2
//
//  Created by Subhrajyoti Chakraborty on 24/08/20.
//  Copyright © 2020 Subhrajyoti Chakraborty. All rights reserved.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var showingFilterSheet = false
    @State private var showNoImageSelectedAlert = false
    
    let context = CIContext()
    
    func getFilterName(_ filter: CIFilter) -> String {
        switch filter.name {
            case "CICrystallize":
                return "Crystallize"
            case "CIEdges":
                return "Edges"
            case "CIGaussianBlur":
                return "Gaussian Blur"
            case "CIPixellate":
                return "Pixellate"
            case "CISepiaTone":
                return "Sepia Tone"
            case "CIUnsharpMask":
                return "Unsharp Mask"
            case "CIVignette":
                return "Vignette"
            default:
                return filter.name
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let beginImage = CIImage(image: inputImage)
        print(currentFilter.name)
        var filterName = currentFilter.name
        filterName = String(filterName.split(separator: "I")[1])
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius * 300, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }

        
        guard let outputImage = currentFilter.outputImage else { return }
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
    
    var body: some View {
        
        let intensity = Binding<Double>(get: {
            self.filterIntensity
        }, set: {
            self.filterIntensity = $0
            self.applyProcessing()
        })
        
        let radius = Binding(get: {
            self.filterRadius
        }, set: {
            self.filterRadius = $0
            self.applyProcessing()
        })
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker.toggle()
                }
                HStack {
                    Text("Intensity")
                    Slider(value: intensity)
                }
                HStack {
                    Text("Radius")
                    Slider(value: radius)
                }
                .padding(.vertical)
                HStack {
                    Button("Filter: \(self.getFilterName(currentFilter))") {
                        self.showingFilterSheet.toggle()
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        let imageSaver = ImageSaver()
                        if self.processedImage != nil {
                            imageSaver.writeToPhotoAlbum(image: self.processedImage!)
                        } else {
                            self.showNoImageSelectedAlert.toggle()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Edges")) { self.setFilter(CIFilter.edges()) },
                    .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur()) },
                    .default(Text("Pixellate")) { self.setFilter(CIFilter.pixellate()) },
                    .default(Text("Sepia Tone")) { self.setFilter(CIFilter.sepiaTone()) },
                    .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask()) },
                    .default(Text("Vignette")) { self.setFilter(CIFilter.vignette()) },
                    .cancel()
                ])
            }
            .alert(isPresented: $showNoImageSelectedAlert) {
                Alert(title: Text("Error!"), message: Text("Please select an Image first"), dismissButton: .default(Text("OK")))
            }
            .padding([.horizontal, .vertical])
            .navigationBarTitle("Instafilter")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveImage), nil)
    }
    
    @objc func saveImage(_ image: UIImage?, didFinishSavingWithError error: Error?, context: UnsafeRawPointer ) {
        if error != nil {
            print("Some error occurred!")
        } else {
            print("Successfully saved the image")
        }
    }
}
