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
            AsyncImage(url: URL(string: video.thumbnailUrl)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 100, height: 100)
            
            VStack(alignment: .leading) {
                Text(video.title).font(.headline)
                Text(video.duration).font(.subheadline)
                Text(video.author).font(.caption)
            }
        }
    }
}

#Preview {
    VideoListView()
}
