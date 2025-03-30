//
//  VideoDetailView.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI
import _AVKit_SwiftUI

struct VideoDetailView: View {
    
    @StateObject private var viewModel = VideoDetailViewModel()
    
    let video: Video
    let animation: Namespace.ID
    
    var body: some View {
        Group {
            if viewModel.isFullScreen {
                createFullScreenView()
            } else {
                createRegularView()
            }
        }
        .navigationTransition(.zoom(sourceID: video.id, in: animation))
        .animation(.easeInOut, value: viewModel.isFullScreen)
        .onAppear {
            viewModel.loadVideo(for: video.id, videoUrl: video.videoUrl)
        }
        .onDisappear {
            viewModel.cleanUp()
        }
        .alert(item: $viewModel.errorMessage) { error in
            Alert(title: Text("Error"), message: Text(error))
        }
        .alert("Delete Downloaded Video?", isPresented: $viewModel.isShowingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteDownloadedVideo()
            }
        } message: {
            Text("The video will continue playing via streaming.")
        }
    }
}

private extension VideoDetailView {
    @ViewBuilder
    func createFullScreenView() -> some View {
        if let player = viewModel.player {
            VideoPlayer(player: player)
                .ignoresSafeArea()
        } else {
            Image(systemName: "play.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
        }
    }
    
    func createRegularView() -> some View {
        ScrollView {
            createVideoPlayerSectionView()
            createDetailsSectionView()
        }
    }
    
    func createVideoPlayerSectionView() -> some View {
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(height: 250)
            } else {
                Image(systemName: "play.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            
            if viewModel.isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                    .padding()
            }
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }
    
    func createDetailsSectionView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            createVideoSourceIndicator()
            createHeaderSection()
            Divider()
            createAuthorSection()
            Divider()
            createDescriptionSection()
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    func createHeaderSection() -> some View {
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
    }
    
    func createAuthorSection() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Author")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(video.author)
                    .font(.body)
            }
            
            Spacer()
            
            DownloadButton(
                state: viewModel.downloadState,
                action: viewModel.handleDownload
            )
            .frame(width: 44, height: 44)
        }
    }
    
    @ViewBuilder
    func createDescriptionSection() -> some View {
        Text("Description")
            .font(.headline)
            .padding(.top, 5)
        
        Text(video.description)
            .font(.body)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    func createVideoSourceIndicator() -> some View {
        HStack {
            if viewModel.isPlayingFromLocalFile {
                Label("Local", systemImage: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Streaming", systemImage: "network")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .transition(.opacity)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VideoListView()
}
