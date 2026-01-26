struct UploadView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image("TutorMateLogoTransparent")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            if viewModel.imageDataArray.isEmpty {
                Text("Upload a worksheet to get started.")
                    .foregroundColor(.secondary)
            }
            
            // Image Preview
            if !viewModel.imageDataArray.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(viewModel.imageDataArray.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: viewModel.imageDataArray[index].thumbnailImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button(action: { viewModel.removeImage(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Circle().fill(Color.white))
                            }
                            .offset(x: 8, y: -8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Upload Button
            PhotosPicker(selection: $selectedItems, matching: .images) {
                HStack {
                    Image(systemName: "camera")
                    Text(viewModel.imageDataArray.isEmpty ? "Add Images/Files" : "Add More Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.31, green: 0.36, blue: 0.63))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .onChange(of: selectedItems) { newItems in
                viewModel.handleImageSelection(newItems)
            }
            
            if !viewModel.imageDataArray.isEmpty {
                Button(action: { viewModel.checkAssignment() }) {
                    Text("Check Assignment")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Quiz Generation
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create a quiz from a topic:")
                        .font(.system(size: 14, weight: .medium))
                    
                    TextField("e.g., 'US State Capitals'", text: $viewModel.customPrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                }
                
                HStack {
                    Text("Number of Questions:")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Picker("", selection: $viewModel.questionCount) {
                        ForEach([5, 10, 15, 20, 25, 30], id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Button(action: { viewModel.generateQuiz() }) {
                    Text("Generate Quiz")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.31, green: 0.36, blue: 0.63))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
