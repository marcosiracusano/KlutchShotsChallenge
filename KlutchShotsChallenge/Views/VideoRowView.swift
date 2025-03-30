//
//  VideoRowView.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 27/03/2025.
//

import SwiftUI

struct VideoRowView: View {
    let video: Video
    
    var body: some View {
        HStack {
            CachedAsyncImage(url: URL(string: video.thumbnailUrl))
                .clipShape(.rect(cornerRadius: 5))
                .frame(width: 100, height: 100)
            
            VStack(alignment: .leading) {
                Text(video.title).font(.headline).multilineTextAlignment(.leading)
                Text(video.duration).font(.subheadline)
                Text(video.author).font(.caption)
            }
            .foregroundStyle(Color(.primary))
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VideoListView(viewModel: .init(networking: NetworkingService()))
}
