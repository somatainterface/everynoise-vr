//
//  ImmersiveView.swift
//  everynoise-vr
//
//  Created by Icaro Lima Magalhaes on 10/13/26.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @Environment(AppModel.self) private var appModel
    @State private var zoomAtGestureStart: Double?

    private var galaxy: Galaxy { appModel.galaxy }

    var body: some View {
        RealityView { content in
            content.add(galaxy.anchor)
            galaxy.apply(zoom: appModel.zoom)
            #if DEBUG
            // Simulator testing without a pointer: -debugZoom 0.4 -debugPlay jazz
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "debugZoom") != nil {
                appModel.setZoom(defaults.double(forKey: "debugZoom"))
            }
            if let id = defaults.string(forKey: "debugPlay"), let genre = Genre.all.first(where: { $0.id == id }) {
                galaxy.toggle(genre, model: appModel)
            }
            #endif
        } update: { _ in
            galaxy.apply(zoom: appModel.zoom)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    guard let genre = galaxy.genre(for: value.entity) else { return }
                    galaxy.toggle(genre, model: appModel)
                }
        )
        // Pinch with both hands on any orb, or on the core once the galaxy has vanished.
        .gesture(
            MagnifyGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let start = zoomAtGestureStart ?? appModel.zoom
                    zoomAtGestureStart = start
                    appModel.setZoom(start * value.magnification)
                }
                .onEnded { _ in
                    zoomAtGestureStart = nil
                }
        )
        .onDisappear {
            galaxy.stop(model: appModel)
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
