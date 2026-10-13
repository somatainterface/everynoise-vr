//
//  ContentView.swift
//  everynoise-vr
//
//  Created by Icaro Lima Magalhaes on 10/13/26.
//

import SwiftUI

/// Control panel: opens the galaxy, mirrors the site's zoom controls, and shows what's playing.
struct ContentView: View {

    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Every Noise")
                    .font(.extraLargeTitle)
                Text("A constellation of genres in your room. Tap an orb to hear it. Pinch with two hands to zoom.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ToggleImmersiveSpaceButton()

            if appModel.immersiveSpaceState == .open {
                zoomControls
                nowPlaying
            }
        }
        .padding(40)
        .frame(width: 520)
        .task {
            // The galaxy is the app; put it in the room right away.
            guard appModel.immersiveSpaceState == .closed else { return }
            appModel.immersiveSpaceState = .inTransition
            if case .opened = await openImmersiveSpace(id: appModel.immersiveSpaceID) { return }
            appModel.immersiveSpaceState = .closed
        }
    }

    private var zoomControls: some View {
        @Bindable var appModel = appModel
        return HStack(spacing: 12) {
            Button("Zoom Out", systemImage: "minus.magnifyingglass") {
                appModel.setZoom(appModel.zoom / 1.4)
            }
            .labelStyle(.iconOnly)
            Slider(value: $appModel.zoom, in: AppModel.zoomRange)
            Button("Zoom In", systemImage: "plus.magnifyingglass") {
                appModel.setZoom(appModel.zoom * 1.4)
            }
            .labelStyle(.iconOnly)
        }
    }

    @ViewBuilder
    private var nowPlaying: some View {
        if let genre = appModel.nowPlaying {
            Label {
                VStack(alignment: .leading) {
                    Text(genre.name).font(.headline)
                    Text("e.g. \(genre.example)").font(.caption).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "speaker.wave.2.fill").foregroundStyle(Color(genre.color))
            }
        } else if let genre = appModel.loading {
            Label("Loading \(genre.name)…", systemImage: "arrow.down.circle")
                .foregroundStyle(.secondary)
        } else {
            Text("Nothing playing")
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
