//
//  Copyright 2022 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import R2Navigator
import R2Shared
class AutoHighlightModel {
    let publication: Publication
    let currentLocation: Locator?
    let navigator: Navigator
    //let content: Content?
    init(publication: Publication,navigator: Navigator) {
        self.publication = publication
        self.navigator = navigator
        self.currentLocation = self.navigator.currentLocation
        guard let content = publication.content(from: currentLocation) else { return };
        var counter = 0;
        //lambda function
        let wordTokenizer = makeTextContentTokenizer(
            defaultLanguage: publication.metadata.language,
            textTokenizerFactory: { language in
                makeDefaultTextTokenizer(unit: .word, language: language)
            }
        )
        var known_words = ["the": 1, "of":1 ,"at": 1,"and": 1]
        for el in content.sequence() {
            if counter > 50 {
                return
            }
            counter += 1;
            if el is TextContentElement && counter > 40 {
                do {
                    
                    var smth   = try wordTokenizer(el)
                    var words: [TextContentElement.Segment]  = smth.compactMap{$0 as? TextContentElement}
                        .flatMap { $0.segments }
                    words = words.filter { known_words[$0.text] == nil }
                    (navigator as? DecorableNavigator)?.apply(
                                    decorations: words.enumerated().map { (index, word) in
                                        Decoration(
                                            id: "word-\(index)",
                                            locator: word.locator,
                                            style: .highlight(tint: .red, isActive: true)
                                        )
                                    },
                                    in: "words")
                } catch {
                    return
                }
                    /*
                    if let text: String = el.text {
                        print("text?: " + text )
                    }*/
            }
        }
        
      
        //print(content.elements())
        do {
            let words: [TextContentElement.Segment] = try content
                .elements()
                .flatMap { try wordTokenizer($0) }
                .compactMap { $0 as? TextContentElement }
                .flatMap { $0.segments }
            for word in words {
                if word.text == "hello" {
                    print("helllooooo")
                }
            }
        } catch {
            print(error)
        }
    }
   
        /*
        (navigator as? DecorableNavigator)?.apply(
            decorations: words.enumerated().map { (index, word) in
                Decoration(
                    id: "word-\(index)",
                    locator: word.locator,
                    style: .highlight(tint: .red, isActive: true)
                )
            },
            in: "words"
        )*/

}
