//
//  ContentView.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI

struct VideoListView: View {
    @Environment(\.dependencies) private var dependencies
    @StateObject private var viewModel: VideoListViewModel
    @Namespace private var animation
    
    init(viewModel: VideoListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.videos) { video in
                        NavigationLink(value: video) {
                            VideoRowView(video: video)
                                .matchedTransitionSource(id: video.id, in: animation) {
                                    $0
                                        .background(.clear)
                                        .clipShape(.rect(cornerRadius: 15))
                                }
                        }
                    }
                }
                .navigationTitle("Videos")
                .navigationDestination(for: Video.self) { video in
                    VideoDetailView(
                        viewModel: .init(downloadManager: dependencies.downloadManager),
                        video: video,
                        animation: animation
                    )
                        .toolbarVisibility(.hidden, for: .navigationBar)
                }
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
                viewModel.fetchVideos()
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
    VideoListView(viewModel: .init(networking: NetworkingService()))
}
