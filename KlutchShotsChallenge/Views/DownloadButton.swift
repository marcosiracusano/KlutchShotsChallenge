//
//  DownloadButton.swift
//  KlutchShotsChallenge
//
//  Created by Marco Siracusano on 28/03/2025.
//

import SwiftUI

struct DownloadButton: View {
    let state: DownloadState
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if state.isDownloading {
                Circle()
                    .stroke(lineWidth: 3)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(state.progress))
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: state.progress)
                
                Text("\(Int(state.progress * 100))%")
                    .font(.caption)
                    .bold()
                
            } else if state.hasCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    VStack {
        DownloadButton(state: .downloading(progress: 0.4)) {
            print("")
        }
        .frame(width: 100, height: 100)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
