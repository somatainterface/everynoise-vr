//
//  Galaxy.swift
//  everynoise-vr
//

import RealityKit
import SwiftUI

/// Builds and drives the constellation of genre orbs.
@MainActor
final class Galaxy {
    /// Fixed in the room; holds the core so it stays put and visible at any zoom.
    let anchor = Entity()
    /// Scaled by zoom; holds the orbs and dust.
    let root = Entity()
    let core: ModelEntity

    private var orbs: [String: ModelEntity] = [:]
    private let dust = Entity()
    private var playback: AudioPlaybackController?
    private var playbackTask: Task<Void, Never>?

    init() {
        // Roughly eye level, a step and a half in front of where the space opened.
        anchor.position = [0, 1.35, -1.8]
        anchor.addChild(root)

        core = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [UnlitMaterial(color: .white)]
        )
        core.name = "core"
        core.components.set(InputTargetComponent())
        core.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.06)]))
        core.components.set(HoverEffectComponent())
        anchor.addChild(core)

        for genre in Genre.all {
            let orb = Self.makeOrb(for: genre)
            orbs[genre.id] = orb
            root.addChild(orb)
        }

        root.addChild(dust)
        Self.scatterDust(into: dust)
    }

    func genre(for entity: Entity) -> Genre? {
        var current: Entity? = entity
        while let e = current {
            if let genre = Genre.all.first(where: { $0.id == e.name }) { return genre }
            current = e.parent
        }
        return nil
    }

    // MARK: Zoom

    /// Scales the galaxy and fades genres out as it shrinks, least prominent first,
    /// the way a map drops minor labels when you zoom out.
    func apply(zoom: Double) {
        root.scale = .init(repeating: Float(zoom))
        for genre in Genre.all {
            guard let orb = orbs[genre.id] else { continue }
            // Prominent genres hold on until 0.3, minor ones disappear at 0.55.
            let vanishAt = 0.55 - 0.25 * genre.prominence
            let opacity = Float(min(max((zoom - vanishAt) / 0.15, 0), 1))
            orb.components.set(OpacityComponent(opacity: opacity))
            orb.components[InputTargetComponent.self]?.isEnabled = opacity > 0.2
        }
        dust.components.set(OpacityComponent(opacity: Float(min(max((zoom - 0.3) / 0.3, 0), 1))))
    }

    // MARK: Playback

    /// Plays a genre's preview from its orb, so the sound comes from where the orb is.
    /// Tapping the playing genre again stops it, like on the site.
    func toggle(_ genre: Genre, model: AppModel) {
        let wasPlaying = model.nowPlaying == genre
        stop(model: model)
        guard !wasPlaying, let orb = orbs[genre.id] else { return }

        model.loading = genre
        playbackTask = Task {
            do {
                let resource = try await Self.audio(for: genre)
                try Task.checkCancellation()
                let controller = orb.playAudio(resource)
                controller.completionHandler = { [weak self] in
                    guard model.nowPlaying == genre else { return }
                    self?.stop(model: model)
                }
                playback = controller
                model.loading = nil
                model.nowPlaying = genre
                setPulsing(true, orb: orb)
            } catch {
                if model.loading == genre { model.loading = nil }
            }
        }
    }

    func stop(model: AppModel) {
        playbackTask?.cancel()
        playback?.stop()
        playback = nil
        if let playing = model.nowPlaying, let orb = orbs[playing.id] {
            setPulsing(false, orb: orb)
        }
        model.nowPlaying = nil
        model.loading = nil
    }

    private func setPulsing(_ on: Bool, orb: ModelEntity) {
        guard let body = orb.findEntity(named: "body") else { return }
        body.stopAllAnimations()
        if on {
            let pulse = FromToByAnimation<Transform>(
                from: Transform(scale: .init(repeating: 1.15)),
                to: Transform(scale: .init(repeating: 1.45)),
                duration: 0.45,
                timing: .easeInOut,
                bindTarget: .transform,
                repeatMode: .autoReverse
            )
            if let resource = try? AnimationResource.generate(with: pulse) {
                body.playAnimation(resource)
            }
        } else {
            body.move(to: Transform(), relativeTo: body.parent, duration: 0.25)
        }
    }

    /// Previews are short MP3s; download once into Caches so RealityKit can spatialize them.
    private static func audio(for genre: Genre) async throws -> AudioFileResource {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let file = caches.appending(path: "preview-\(genre.id).mp3")
        if !FileManager.default.fileExists(atPath: file.path()) {
            let (temp, _) = try await URLSession.shared.download(from: genre.previewURL)
            try? FileManager.default.removeItem(at: file)
            try FileManager.default.moveItem(at: temp, to: file)
        }
        return try await AudioFileResource(contentsOf: file, configuration: .init(shouldLoop: false))
    }

    // MARK: Building

    private static func makeOrb(for genre: Genre) -> ModelEntity {
        let color = displayColor(genre.color)
        let radius = Float(0.025 + 0.035 * genre.prominence)

        let orb = ModelEntity()
        orb.name = genre.id
        orb.position = genre.position
        orb.components.set(InputTargetComponent())
        orb.components.set(CollisionComponent(shapes: [.generateSphere(radius: max(radius * 1.6, 0.05))]))
        orb.components.set(HoverEffectComponent(.spotlight(.init(color: color, strength: 2))))
        orb.components.set(SpatialAudioComponent(gain: -6, directivity: .beam(focus: 0)))

        let body = ModelEntity()
        body.name = "body"
        orb.addChild(body)

        var surface = PhysicallyBasedMaterial()
        surface.baseColor = .init(tint: color)
        surface.emissiveColor = .init(color: color)
        surface.emissiveIntensity = 1.6
        surface.roughness = 0.3
        body.addChild(ModelEntity(mesh: .generateSphere(radius: radius), materials: [surface]))

        var halo = UnlitMaterial(color: color.withAlphaComponent(0.18))
        halo.blending = .transparent(opacity: 0.18)
        halo.faceCulling = .front
        body.addChild(ModelEntity(mesh: .generateSphere(radius: radius * 1.7), materials: [halo]))

        let label = Self.makeLabel(genre.name, color: color, height: Float(0.022 + 0.014 * genre.prominence))
        label.position = [0, -(radius * 1.7 + 0.035), 0]
        orb.addChild(label)

        return orb
    }

    /// A text mesh centered on its parent that always turns to face the viewer.
    private static func makeLabel(_ text: String, color: UIColor, height: Float) -> Entity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: CGFloat(height), weight: .semibold),
            alignment: .center
        )
        let glyphs = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: color)])
        glyphs.position = -mesh.bounds.center

        let label = Entity()
        label.components.set(BillboardComponent())
        label.addChild(glyphs)
        return label
    }

    private static func scatterDust(into parent: Entity) {
        let mesh = MeshResource.generateSphere(radius: 0.0025)
        let material = UnlitMaterial(color: .white.withAlphaComponent(0.6))
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<220 {
            let star = ModelEntity(mesh: mesh, materials: [material])
            // Flattened ellipsoid, denser toward the middle, like a galaxy disc.
            let r = Float.random(in: 0...1, using: &rng) * Float.random(in: 0.3...1, using: &rng)
            let theta = Float.random(in: 0..<(2 * .pi), using: &rng)
            let phi = Float.random(in: 0..<(.pi), using: &rng)
            star.position = [
                0.95 * r * sin(phi) * cos(theta),
                0.75 * r * cos(phi),
                0.5 * r * sin(phi) * sin(theta),
            ]
            star.scale = .init(repeating: .random(in: 0.5...1.6, using: &rng))
            parent.addChild(star)
        }
    }

    /// The site's colors are tuned for a white page; lift them so they read as light in a room.
    private static func displayColor(_ color: UIColor) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(s * 1.1, 1), brightness: 1, alpha: 1)
    }
}
