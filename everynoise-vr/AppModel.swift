//
//  AppModel.swift
//  everynoise-vr
//
//  Created by Icaro Lima Magalhaes on 10/13/26.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    static let zoomRange: ClosedRange<Double> = 0.15...2.5

    /// Scale of the constellation. Below ~0.6 genres start fading out, least prominent first;
    /// below ~0.3 the whole galaxy is gone and only its core remains.
    var zoom: Double = 1

    /// The genre whose preview is playing, if any.
    var nowPlaying: Genre?
    /// The genre whose preview is downloading, if any.
    var loading: Genre?

    @ObservationIgnored lazy var galaxy = Galaxy()

    func setZoom(_ value: Double) {
        zoom = min(max(value, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
    }
}
