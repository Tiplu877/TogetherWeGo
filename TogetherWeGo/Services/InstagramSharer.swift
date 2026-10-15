//
//  InstagramSharer.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/13/26.
//


import UIKit

@MainActor
enum InstagramSharer {
    // Returns false if Instagram isn't installed
    static func shareToStory(stickerImage: UIImage, topColor: String, bottomColor: String) -> Bool {
        guard let url = URL(string: "instagram-stories://share?source_application=\(AppConfig.facebookAppID)"),
              UIApplication.shared.canOpenURL(url),
              let png = stickerImage.pngData() else {
            return false
        }

        // Instagram reads the image and colors from the clipboard
        let items: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": png,
            "com.instagram.sharedSticker.backgroundTopColor": topColor,
            "com.instagram.sharedSticker.backgroundBottomColor": bottomColor
        ]
        UIPasteboard.general.setItems([items],
                                      options: [.expirationDate: Date().addingTimeInterval(60 * 5)])

        UIApplication.shared.open(url)
        return true
    }
}