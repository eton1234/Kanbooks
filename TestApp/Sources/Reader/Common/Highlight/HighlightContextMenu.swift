//
//  Copyright 2022 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import SwiftUI
import Combine

struct HighlightContextMenu: View {
    @ObservedObject var trans: Translation
    let colors: [HighlightColor]
    let systemFontSize: CGFloat
    let colorScheme: ColorScheme
    let highlight: Highlight
    let translation: String
    

    private let colorSubject = PassthroughSubject<HighlightColor, Never>()
    var selectedColorPublisher: AnyPublisher<HighlightColor, Never> {
        return colorSubject.eraseToAnyPublisher()
    }
    
    private let deleteSubject = PassthroughSubject<Void, Never>()
    var selectedDeletePublisher: AnyPublisher<Void, Never> {
        return deleteSubject.eraseToAnyPublisher()
    }
    /*
    var translation : String {
        SwiftGoogleTranslate.shared.start(with: "AIzaSyDRdCPU29xPWrz4PWkkvMRmvZMvxe0rLkI");
        SwiftGoogleTranslate.shared.translate(String(highlight.locator.text.highlight ?? "none"), "en", "zh") { (text, error) in
          if let t = text {
            translation =  t
          } else { return "no translation"}
    }
    } */
    var body: some View {
        VStack {
            HStack {
                ForEach(colors, id: \.self) { color in
                    Button {
                        colorSubject.send(color)
                    } label: {
                        Text(emoji(for: color))
                            .font(.system(size: systemFontSize))
                    }
                    Divider()
                }
                    
                Button {
                    deleteSubject.send()
                } label: {
                    Image(systemName: "xmark.bin")
                        .font(.system(size: systemFontSize))
                }
            }
           // .frame(width: preferredSize.width, height: preferredSize.height)
            .colorStyle(colorScheme)
            
            
            Text(String(highlight.locator.text.highlight ?? "none") )
            Text(trans.text)
        }
    }
    
    var preferredSize: CGSize {
        let itemSide = itemSideSize
        let itemsCount = colors.count + 1 // 1 is for "delete"
        return CGSize(width: itemSide*CGFloat(itemsCount*2), height: itemSide*3)
    }
    
// MARK: - Private
    private func emoji(for color: HighlightColor) -> String {
        switch color {
        case .red:
            return "🔴"
        case .green:
            return "🟢"
        case .blue:
            return "🔵"
        case .yellow:
            return "🟡"
        case .clear:
            return "⚪️"
        }
    }
    
    private var itemSideSize: CGFloat {
        let font = UIFont.systemFont(ofSize: systemFontSize)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = ("🔴" as NSString).size(withAttributes: fontAttributes)
        return max(size.width, size.height) * 1.6
    }
}
