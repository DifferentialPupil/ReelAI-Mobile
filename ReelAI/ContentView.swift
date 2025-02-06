//
//  ContentView.swift
//  ReelAI
//
//  Created by Azaldin Freidoon on 2/3/25.
//

import SwiftUI
import AVKit
import FirebaseStorage

// Content View
struct ContentView: View {
    @StateObject private var storageService = StorageService()
    @State private var dragOffset: CGFloat = 0
    @State private var currentVideoIndex: Int = 0
    @State private var showingProfile = false
    @State private var showingVideoGeneration = false
    
    var body: some View {
        ZStack {
            Group {
                if !storageService.videos.isEmpty {
                    VideoPlayerView(url: storageService.videos[currentVideoIndex].url)
                        .ignoresSafeArea()
                } else {
                    // Show loading or empty state
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            
            // Side tap detection overlays
            HStack(spacing: 0) {
                // Left side tap detector
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Left side tapped")
                        if !storageService.videos.isEmpty {
                            currentVideoIndex = (currentVideoIndex - 1 + storageService.videos.count) % storageService.videos.count
                            print("Switching to video index: \(currentVideoIndex)")
                        }
                    }
                
                // Right side tap detector
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Right side tapped")
                        if !storageService.videos.isEmpty {
                            currentVideoIndex = (currentVideoIndex + 1) % storageService.videos.count
                            print("Switching to video index: \(currentVideoIndex)")
                        }
                    }
            }
            
            // Profile Button Overlay
            Icons(
                onProfileTap: { showingProfile = true },
                onVideoTap: { showingVideoGeneration = true },
                onHeartTap: { print("Heart button tapped") }
            )
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let verticalMovement = value.translation.height
                    let horizontalMovement = value.translation.width
                    
                    // Vertical swipes
                    if verticalMovement > 50 {
                        print("Swiped down with offset: \(verticalMovement)")
                    } else if verticalMovement < -50 {
                        print("Swiped up with offset: \(verticalMovement)")
                    }
                    
                    // Horizontal swipes
                    if horizontalMovement > 50 {
                        print("Swiped right with offset: \(horizontalMovement)")
                        
                    } else if horizontalMovement < -50 {
                        print("Swiped left with offset: \(horizontalMovement)")
                        showingProfile = true
                    }
                }
        )
        .task {
            print("Fetching videos...")
            await storageService.fetchVideos()
            print("Done fetching videos.")
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showingVideoGeneration) {
            VideoGenerationView()
        }
    }
}

class LoopingPlayerViewModel: ObservableObject {
    let player: AVPlayer
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var isLoading: Bool = false
    private var playerObserver: Any?
    
    init(url: URL) {
        print(url)
        let playerItem = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: playerItem)
        setupObserver(for: playerItem)
    }
    
    private func setupObserver(for playerItem: AVPlayerItem) {
        // Remove existing observer if any
        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Setup new observer
        playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            playerItem.seek(to: .zero, completionHandler: nil)
            self?.player.play()
            self?.isPlaying = true
        }
    }
    
    deinit {
        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func toggleMute() {
        player.isMuted.toggle()
        isMuted.toggle()
    }
    
    func seek(to time: CMTime) {
        player.seek(to: time)
    }
    
    func replay() {
        player.seek(to: .zero)
        player.play()
        isPlaying = true
    }

    func changeVideo(url: URL) {
        isLoading = true
        let playerItem = AVPlayerItem(url: url)
        
        // Setup observer before changing item to ensure we don't miss any notifications
        setupObserver(for: playerItem)
        
        player.replaceCurrentItem(with: playerItem)
        player.play()
        isPlaying = true
        isLoading = false
    }
}

struct VideoPlayerView: View {
    let url: URL
    @StateObject private var viewModel: LoopingPlayerViewModel
    
    init(url: URL) {
        self.url = url
        _viewModel = StateObject(wrappedValue: LoopingPlayerViewModel(url: url))
        print("Video player initialized")
    }
    
    var body: some View {
        ZStack {
            CustomVideoPlayer(player: viewModel.player)
                .onAppear {
                    viewModel.player.play()
                    viewModel.isPlaying = true
                }
                .onChange(of: url) { newURL in
                    viewModel.changeVideo(url: newURL)
                }
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
            
            // // Overlay controls
            // VStack {
            //     Spacer()
            //     HStack(spacing: 30) {
            //         Button(action: viewModel.replay) {
            //             Image(systemName: "arrow.counterclockwise")
            //                 .foregroundColor(.white)
            //                 .font(.system(size: 24))
            //         }
                    
            //         Button(action: viewModel.togglePlayPause) {
            //             Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
            //                 .foregroundColor(.white)
            //                 .font(.system(size: 24))
            //         }
                    
            //         Button(action: viewModel.toggleMute) {
            //             Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            //                 .foregroundColor(.white)
            //                 .font(.system(size: 24))
            //         }
            //     }
            //     .padding(.bottom, 20)
            // }
        }
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

struct Icons: View {
    let onProfileTap: () -> Void
    let onVideoTap: () -> Void
    let onHeartTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Icon(action: onProfileTap, imageName: "person.circle.fill")
            Icon(action: onVideoTap, imageName: "play.rectangle.fill")
            Icon(action: onHeartTap, imageName: "heart.fill")
            Spacer()
        }
        .padding(.top, 60)
    }
}

struct Icon: View {
    let action: () -> Void
    let imageName: String
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
        }
    }
}

#Preview {
    ContentView()
}
