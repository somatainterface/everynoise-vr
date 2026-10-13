//
//  Genre.swift
//  everynoise-vr
//

import Foundation
import UIKit

/// A genre as it appears on the first layer of everynoise.com.
///
/// `top`/`left` are the pixel coordinates from the site's scatter plot
/// (up = more mechanical and electric, down = more organic;
/// left = denser and more atmospheric, right = spikier and bouncier).
/// `fontSize` is the site's font-size percentage, which tracks how prominent the genre is.
struct Genre: Identifiable, Hashable {
    let id: String
    let name: String
    let colorHex: String
    let top: Double
    let left: Double
    let fontSize: Double
    let previewURL: URL
    let example: String

    var color: UIColor { UIColor(hex: colorHex) }

    /// 0 for the least prominent genre in the set, 1 for the most prominent.
    var prominence: Double {
        let sizes = Genre.all.map(\.fontSize)
        let lo = sizes.min()!, hi = sizes.max()!
        return (fontSize - lo) / (hi - lo)
    }

    /// Position in the constellation, in meters, relative to its center.
    var position: SIMD3<Float> {
        // The site's plot is ~1400px wide and ~22000px tall; squash it into a ~1.4m x 1.2m volume.
        let x = Float(left / 1400 - 0.5) * 1.4
        let y = Float(0.5 - top / 22000) * 1.2
        // The page is flat, so spread genres in depth by hue to make the galaxy volumetric.
        var hue: CGFloat = 0
        color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        let z = Float(hue - 0.5) * 0.9
        return [x, y, z]
    }
}

extension Genre {
    static let all: [Genre] = [
        Genre(id: "pop", name: "pop", colorHex: "#ad8907", top: 4997, left: 783, fontSize: 160,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/17fa164b977074dd1b1869bfb10b08cfd513e53b")!,
              example: "Demi Lovato \"Heart Attack\""),
        Genre(id: "rock", name: "rock", colorHex: "#ac7119", top: 11552, left: 563, fontSize: 141,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/c5efbed38649f0676181dc6bb6e3c8644925726e")!,
              example: "Black Sabbath \"Paranoid\""),
        Genre(id: "hiphop", name: "hip hop", colorHex: "#ac7f08", top: 6854, left: 1086, fontSize: 135,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/f27225424bca80900ee9a32f4a494c900a012200")!,
              example: "Nas \"N.Y. State of Mind\""),
        Genre(id: "kpop", name: "k-pop", colorHex: "#ba8414", top: 5326, left: 777, fontSize: 123,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/33e5ec94a2f425d6b83a045a760be6bc90bba335")!,
              example: "EXID \"Up & Down\""),
        Genre(id: "metal", name: "metal", colorHex: "#dc4e3c", top: 8923, left: 214, fontSize: 112,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/2121bedf135b44a9f49cce6f4c8b003959c16826")!,
              example: "King Diamond \"Abigail\""),
        Genre(id: "jazz", name: "jazz", colorHex: "#50905d", top: 19462, left: 901, fontSize: 106,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/6b1c4ca1799a20dbf9cdc226e22899c5664701dd")!,
              example: "Wayne Shorter \"Footprints\""),
        Genre(id: "bossanova", name: "bossa nova", colorHex: "#649637", top: 16844, left: 828, fontSize: 106,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/0c3b657c6358bcaf5db19bafaaa0672a3840f6ef")!,
              example: "Nara Leão \"João E Maria\""),
        Genre(id: "reggae", name: "reggae", colorHex: "#8a8f1f", top: 7322, left: 1212, fontSize: 106,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/54be3e2b272ef71a520789998792328a5b306aea")!,
              example: "Bunny Wailer \"Dream Land\""),
        Genre(id: "ambient", name: "ambient", colorHex: "#4f94c4", top: 15167, left: 234, fontSize: 103,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/fa4c9f32b8a404941292e7a05f7156b04c6223b7")!,
              example: "Loscil \"Angle of List\""),
        Genre(id: "techno", name: "techno", colorHex: "#ba89c8", top: 1048, left: 1180, fontSize: 101,
              previewURL: URL(string: "https://p.scdn.co/mp3-preview/48059bf908579426b4cc9ccc03ccd6c66782dc06")!,
              example: "Robert Hood \"Onslaught (FJAAK Remix)\""),
    ]
}

extension UIColor {
    convenience init(hex: String) {
        let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0xffffff
        self.init(red: CGFloat((value >> 16) & 0xff) / 255,
                  green: CGFloat((value >> 8) & 0xff) / 255,
                  blue: CGFloat(value & 0xff) / 255,
                  alpha: 1)
    }
}
