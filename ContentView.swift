//
//  ContentView.swift
//  BoardCap AI
//
//  Created by Abdul Moiz on 25/6/25.
//
import SwiftUI
import AVFoundation

// MARK: - Main App Entry Point
struct ContentView: View {
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            if showMainApp {
                MainTabView()
                    .transition(.move(edge: .trailing))
            } else {
                WelcomeScreen(onGetStarted: {
                    print("Get Started button tapped!") // Debug line
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showMainApp = true
                    }
                })
                .transition(.move(edge: .leading))
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 1 // Start with Capture tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            CaptureScreen()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Capture")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    let onGetStarted: () -> Void
    @State private var showGetStarted = false
    
    let features = [
        Feature(
            icon: "camera.viewfinder",
            title: "Smart Capture",
            description: "Automatically detect and capture whiteboards and blackboards with perfect clarity"
        ),
        Feature(
            icon: "doc.text.image",
            title: "Instant Notes",
            description: "Transform your photos into organized, searchable note documents in seconds"
        ),
        Feature(
            icon: "textformat.abc",
            title: "Text Recognition",
            description: "Extract and edit text from handwritten or printed board content"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBlue).opacity(0.3),
                        Color(.systemPurple).opacity(0.08),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header section
                        VStack(spacing: 20) {
                            Spacer(minLength: 60)
                            
                            // App icon placeholder
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "camera.aperture")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("BoardCap AI")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Transform boards into notes")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Features section
                        VStack(spacing: 32) {
                            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                                FeatureCard(
                                    feature: feature,
                                    isVisible: true
                                )
                                .scaleEffect(showGetStarted ? 1.0 : 0.8)
                                .opacity(showGetStarted ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.2),
                                    value: showGetStarted
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        
                        // CTA section
                        VStack(spacing: 20) {
                            Button(action: onGetStarted) {
                                HStack {
                                    Text("Get Started")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 8)
                            }
                            .scaleEffect(showGetStarted ? 1.0 : 0.9)
                            .opacity(showGetStarted ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(0.8),
                                value: showGetStarted
                            )
                            
                            Text("No account required • Free to start")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .opacity(showGetStarted ? 1.0 : 0.0)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .delay(1.0),
                                    value: showGetStarted
                                )
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 40)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                showGetStarted = true
            }
        }
    }
}

// MARK: - Image Detail View
struct ImageDetailView: View {
    let savedImage: SavedImage
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image display
                    if let image = StorageManager.shared.loadImage(from: savedImage) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 16) {
                        // Basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            InfoRow(label: "Name", value: savedImage.displayName)
                            InfoRow(label: "Type", value: savedImage.metadata.boardType.displayName)
                            InfoRow(label: "Created", value: savedImage.createdAt, style: .medium)
                            InfoRow(label: "Size", value: "\(savedImage.metadata.imageSize.width) × \(savedImage.metadata.imageSize.height)")
                        }
                        
                        Divider()
                        
                        // Description
                        if !savedImage.metadata.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(savedImage.metadata.description)
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Tags
                        if !savedImage.metadata.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80))
                                ], spacing: 8) {
                                    ForEach(savedImage.metadata.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Note Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack(spacing: 16) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            )
            .alert("Delete Note", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    StorageManager.shared.deleteImage(savedImage)
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("This will permanently delete this note. This action cannot be undone.")
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Date, style: DateFormatter.Style) {
        self.label = label
        let formatter = DateFormatter()
        formatter.dateStyle = style
        self.value = formatter.string(from: value)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Capture Screen
struct CaptureScreen: View {
    @State private var showCamera = false
    @State private var capturedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var cameraPermissionGranted = false
    @State private var showPermissionAlert = false
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 20) {
                Text("Capture Your Board")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 40)
                
                Text("Position your device to capture whiteboards or blackboards clearly")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Main content area
            VStack(spacing: 24) {
                // Recent captures or camera preview placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .frame(height: 300)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    if storageManager.savedImages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue.opacity(0.6))
                            
                            Text("No captures yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("Tap the camera button below to start")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // Show recent captures in a grid
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(storageManager.savedImages.prefix(5), id: \.id) { savedImage in
                                    if let image = storageManager.loadImage(from: savedImage) {
                                        VStack(spacing: 8) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 160)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            Text(savedImage.displayName)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary camera button
                    Button(action: {
                        checkCameraPermission()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .medium))
                            
                            Text("Capture Board")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 8)
                    }
                    
                    // Secondary actions
                    HStack(spacing: 16) {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("From Photos")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        if !storageManager.savedImages.isEmpty {
                            Button(action: {
                                // Show gallery of saved images
                                print("Showing gallery with \(storageManager.savedImages.count) images")
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("Gallery")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Tips section
                VStack(spacing: 12) {
                    Text("💡 Tips for better captures")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TipRow(icon: "lightbulb.fill", text: "Ensure good lighting on the board")
                        TipRow(icon: "viewfinder", text: "Keep the board fully in frame")
                        TipRow(icon: "hand.raised.fill", text: "Hold steady for clearer text")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .fullScreenCover(isPresented: $showCamera) {
            EnhancedCameraView()
        }
        .alert("Camera Access Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow camera access in Settings to capture boards.")
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }
}

// MARK: - Supporting Views
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct FeatureCard: View {
    let feature: Feature
    let isVisible: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon container
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(feature.title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 20,
                    x: 0,
                    y: 8
                )
        )
    }
}

struct Feature {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Camera View (Placeholder)
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImages.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Simple Test Version (Use this if above doesn't work)
struct SimpleContentView: View {
    @State private var currentScreen = 0 // 0 = welcome, 1 = capture
    
    var body: some View {
        Group {
            if currentScreen == 0 {
                WelcomeScreen(onGetStarted: {
                    print("Button tapped - switching to screen 1")
                    currentScreen = 1
                })
            } else {
                CaptureScreen()
            }
        }
        .animation(.easeInOut, value: currentScreen)
    }
}

// MARK: - Home View
struct HomeView: View {
    @StateObject private var storageManager = StorageManager.shared
    @State private var searchText = ""
    @State private var selectedFilter: BoardType? = nil
    @State private var showingImageDetail = false
    @State private var selectedImage: SavedImage?
    
    var filteredImages: [SavedImage] {
        var images = storageManager.savedImages
        
        // Apply search filter
        if !searchText.isEmpty {
            images = images.filter { savedImage in
                savedImage.displayName.localizedCaseInsensitiveContains(searchText) ||
                savedImage.metadata.description.localizedCaseInsensitiveContains(searchText) ||
                savedImage.metadata.tags.contains { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply board type filter
        if let filter = selectedFilter {
            images = images.filter { $0.metadata.boardType == filter }
        }
        
        return images.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter bar
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search your notes...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedFilter == nil,
                                action: { selectedFilter = nil }
                            )
                            
                            ForEach(BoardType.allCases, id: \.self) { boardType in
                                FilterChip(
                                    title: boardType.displayName,
                                    isSelected: selectedFilter == boardType,
                                    action: { selectedFilter = boardType }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Content
                if filteredImages.isEmpty {
                    EmptyStateView(searchText: searchText, selectedFilter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredImages, id: \.id) { savedImage in
                                BoardCard(savedImage: savedImage) {
                                    selectedImage = savedImage
                                    showingImageDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("My Notes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImageDetail) {
                if let selectedImage = selectedImage {
                    ImageDetailView(savedImage: selectedImage)
                }
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
    }
}

// MARK: - Board Card
struct BoardCard: View {
    let savedImage: SavedImage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                if let image = StorageManager.shared.loadImage(from: savedImage) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                
                // Title
                Text(savedImage.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Metadata
                HStack {
                    Image(systemName: savedImage.metadata.boardType.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Text(savedImage.metadata.boardType.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(savedImage.createdAt, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let searchText: String
    let selectedFilter: BoardType?
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? "doc.text.image" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text(searchText.isEmpty ? "No notes yet" : "No matching notes")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(searchText.isEmpty ? "Capture your first board to get started" : "Try adjusting your search or filters")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
        
        ContentView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var storageManager = StorageManager.shared
    @State private var showingDeleteAlert = false
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack(spacing: 16) {
                        // Profile Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BoardCap User")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("\(storageManager.savedImages.count) notes captured")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // App Features Section
                Section("Features") {
                    NavigationLink(destination: Text("Camera Settings")) {
                        SettingsRow(
                            icon: "camera.fill",
                            title: "Camera Settings",
                            subtitle: "Configure capture preferences"
                        )
                    }
                    
                    NavigationLink(destination: Text("Text Recognition")) {
                        SettingsRow(
                            icon: "textformat.abc",
                            title: "Text Recognition",
                            subtitle: "Manage OCR settings"
                        )
                    }
                    
                    NavigationLink(destination: Text("Storage Management")) {
                        SettingsRow(
                            icon: "externaldrive.fill",
                            title: "Storage",
                            subtitle: "Manage saved images and data"
                        )
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Notes",
                            subtitle: "Share your captured notes"
                        )
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        SettingsRow(
                            icon: "trash.fill",
                            title: "Clear All Data",
                            subtitle: "Delete all saved notes",
                            iconColor: .red
                        )
                    }
                }
                
                // App Info Section
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        Text("Terms of Service")
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button(action: {
                        // Open feedback form
                    }) {
                        SettingsRow(
                            icon: "envelope.fill",
                            title: "Send Feedback",
                            subtitle: "Help us improve BoardCap AI"
                        )
                    }
                    
                    NavigationLink(destination: Text("Help & FAQ")) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & FAQ",
                            subtitle: "Get help with the app"
                        )
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    storageManager.clearAllData()
                }
            } message: {
                Text("This will permanently delete all your captured notes. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView()
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = .blue
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Export View
struct ExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var storageManager = StorageManager.shared
    @State private var selectedImages: Set<String> = []
    @State private var exportFormat = ExportFormat.pdf
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case images = "Images"
        case text = "Text Only"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Export options
                VStack(spacing: 20) {
                    // Format selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Format")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: {
                                exportFormat = format
                            }) {
                                HStack {
                                    Image(systemName: exportFormat == format ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(exportFormat == format ? .blue : .secondary)
                                    
                                    Text(format.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                    
                    // Image selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Select Notes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Select All") {
                                selectedImages = Set(storageManager.savedImages.map { $0.id })
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(storageManager.savedImages, id: \.id) { savedImage in
                                    ExportImageCard(
                                        savedImage: savedImage,
                                        isSelected: selectedImages.contains(savedImage.id),
                                        onToggle: {
                                            if selectedImages.contains(savedImage.id) {
                                                selectedImages.remove(savedImage.id)
                                            } else {
                                                selectedImages.insert(savedImage.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer()
                
                // Export button
                Button(action: {
                    // Handle export
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Export \(selectedImages.count) Notes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            selectedImages.isEmpty ? Color.gray : Color.blue
                        )
                        .cornerRadius(16)
                }
                .disabled(selectedImages.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Export Notes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Export Image Card
struct ExportImageCard: View {
    let savedImage: SavedImage
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            ZStack {
                if let image = StorageManager.shared.loadImage(from: savedImage) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                
                // Selection overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.3))
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
