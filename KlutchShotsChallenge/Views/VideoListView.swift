//
//  ContentView.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI

struct VideoListView: View {
    @StateObject private var viewModel: VideoListViewModel
    
    init(viewModel: VideoListViewModel = VideoListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.videos) { video in
                    NavigationLink(value: video) {
                        VideoRowView(video: video)
                    }
                }
            }
            .navigationTitle("Videos")
            .navigationDestination(for: Video.self) { video in
                VideoDetailView(video: video)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .alert(item: $viewModel.errorMessage) { error in
            Alert(title: Text("Error"), message: Text(error))
        }
        .onAppear {
            viewModel.fetchVideos()
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

#Preview {
    VideoListView()
}
