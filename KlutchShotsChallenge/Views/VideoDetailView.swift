//
//  VideoDetailView.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI
import _AVKit_SwiftUI

struct VideoDetailView: View {
    let video: Video
    @StateObject private var viewModel = VideoDetailViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isFullScreen {
                createFullScreenView()
            } else {
                createRegularView()
            }
        }
        .onAppear {
            guard let url = URL(string: video.videoUrl) else { return }
            viewModel.loadVideo(from: url)
        }
        .onDisappear {
            viewModel.cleanUp()
        }
    }
}

private extension VideoDetailView {
    func createFullScreenView() -> some View {
        ZStack(alignment: .topLeading) {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
            
            // Exit full screen button
            // TODO: Replace with drap gesture to remove
            Button(action: viewModel.toggleFullScreen) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding()
        }
        .statusBarHidden(true)
    }
    
    func createRegularView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                createVideoPlayerSectionView()
                createDetailsSectionView()
            }
        }
    }
    
    func createVideoPlayerSectionView() -> some View {
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(height: 250)
            }
            
            if viewModel.isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                    .padding()
            }
            
            // Full screen button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.toggleFullScreen()
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            }
        }
        .frame(height: 250)
    }
    
    func createDetailsSectionView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(video.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            HStack {
                Text(video.uploadTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(video.views) views")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Author")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(video.author)
                        .font(.body)
                }
                
                Spacer()
                
                // Download button
                DownloadButton(state: viewModel.downloadState) {
                    guard let url = URL(string: video.videoUrl) else { return }
                    viewModel.downloadVideo(from: url)
                }
                .frame(width: 44, height: 44)
            }
            
            Divider()
            
            // Video description
            Text("Description")
                .font(.headline)
                .padding(.top, 5)
            
            Text(video.description)
                .font(.body)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    VideoDetailView(video: Video.example)
}
