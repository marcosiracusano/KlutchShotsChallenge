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
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
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
        .onAppear {
            guard let url = URL(string: video.videoUrl) else { return }
            viewModel.loadVideo(from: url)
        }
        .onDisappear {
            viewModel.cleanUp()
        }
    }
}

#Preview {
    VideoDetailView(video: Video.example)
}
