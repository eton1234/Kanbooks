//
//  Copyright 2022 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import UIKit
import R2Shared
import R2Navigator

class EPUBViewController: ReaderViewController {
    var popoverUserconfigurationAnchor: UIBarButtonItem?
    var userSettingNavigationController: UserSettingsNavigationController
    
    init(publication: Publication, locator: Locator?, bookId: Book.Id, books: BookRepository, bookmarks: BookmarkRepository, highlights: HighlightRepository, resourcesServer: ResourcesServer) {
        var navigatorEditingActions = EditingAction.defaultActions
        navigatorEditingActions.append(EditingAction(title: "Highlight", action: #selector(highlightSelection)))
        //TODO: add your custom editing action for a diff type of hilight 
        var navigatorConfig = EPUBNavigatorViewController.Configuration()
        navigatorConfig.editingActions = navigatorEditingActions
        
        let navigator = EPUBNavigatorViewController(publication: publication, initialLocation: locator, resourcesServer: resourcesServer, config: navigatorConfig)
        let settingsStoryboard = UIStoryboard(name: "UserSettings", bundle: nil)
        userSettingNavigationController = settingsStoryboard.instantiateViewController(withIdentifier: "UserSettingsNavigationController") as! UserSettingsNavigationController
        userSettingNavigationController.fontSelectionViewController =
            (settingsStoryboard.instantiateViewController(withIdentifier: "FontSelectionViewController") as! FontSelectionViewController)
        userSettingNavigationController.advancedSettingsViewController =
            (settingsStoryboard.instantiateViewController(withIdentifier: "AdvancedSettingsViewController") as! AdvancedSettingsViewController)
        
        super.init(navigator: navigator, publication: publication, bookId: bookId, books: books, bookmarks: bookmarks, highlights: highlights)
        print("start is: ", navigator)
        
        //TODO: add highlight for auto
        navigator.delegate = self
    }
    func autoHigh(publication: Publication, currentLocation: Locator?) {
        
        //var currentLocation = navigator.currentLocation
        guard let content = publication.content(from: currentLocation) else { return };
        //guard let content = content else { return};
        var counter = 0;
        //lambda wordTokenizer function
        let wordTokenizer = makeTextContentTokenizer(
            defaultLanguage: publication.metadata.language,
            textTokenizerFactory: { language in
                makeDefaultTextTokenizer(unit: .word, language: language)
            }
        )
        //https://www.gutenberg.org/ebooks/24060.epub.noimages
        var fee: [TextContentElement.Segment]  = []
        var known_words = ["the": 1, "of":1 ,"at": 1,"and": 1]
        var word_count = 0
        for el in content.sequence() {
            if el is TextContentElement{
                do {
                    let smth = try wordTokenizer(el)
                    var words: [TextContentElement.Segment]  = smth.compactMap{$0 as? TextContentElement}
                        .flatMap { $0.segments }
                    //words = words.filter { known_words[$0.text] == nil }
                    for word in words {
                        word_count+=1
                        if word_count > 400 {
                            return
                        }
                        print(word.text, word_count)
                        //print(bookId, word.locator.text, word.locator.locations)
                        if known_words[word.text] != nil {
                            let highlight = Highlight(bookId: bookId, locator: word.locator, color: .clear, progression: 0)
                            saveHighlight(highlight)
                        } else {
                            let highlight = Highlight(bookId: bookId, locator: word.locator, color: .red, progression: 0)
                            saveHighlight(highlight)
                        }
                    }
                } catch {
                    continue
                }
            }
        }
    }
    var epubNavigator: EPUBNavigatorViewController {
        return navigator as! EPUBNavigatorViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
       /*  */
        //navigator.currentLocation
        /// Set initial UI appearance.
        if let appearance = publication.userProperties.getProperty(reference: ReadiumCSSReference.appearance.rawValue) {
            setUIColor(for: appearance)
        }
        
        let userSettings = epubNavigator.userSettings
        userSettingNavigationController.userSettings = userSettings
        userSettingNavigationController.modalPresentationStyle = .popover
        userSettingNavigationController.usdelegate = self
        userSettingNavigationController.userSettingsTableViewController.publication = publication
        

        publication.userSettingsUIPresetUpdated = { [weak self] preset in
            guard let `self` = self, let presetScrollValue:Bool = preset?[.scroll] else {
                return
            }
            
            if let scroll = self.userSettingNavigationController.userSettings.userProperties.getProperty(reference: ReadiumCSSReference.scroll.rawValue) as? Switchable {
                if scroll.on != presetScrollValue {
                    self.userSettingNavigationController.scrollModeDidChange()
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        epubNavigator.userSettings.save()
    }

    override func makeNavigationBarButtons() -> [UIBarButtonItem] {
        var buttons = super.makeNavigationBarButtons()

        // User configuration button
        let userSettingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "settingsIcon"), style: .plain, target: self, action: #selector(presentUserSettings))
        buttons.insert(userSettingsButton, at: 1)
        popoverUserconfigurationAnchor = userSettingsButton

        return buttons
    }
    
    override var currentBookmark: Bookmark? {
        guard let locator = navigator.currentLocation else {
            return nil
        }
        
        return Bookmark(bookId: bookId, locator: locator)
    }
    
    @objc func presentUserSettings() {
        let popoverPresentationController = userSettingNavigationController.popoverPresentationController!
        
        popoverPresentationController.delegate = self
        popoverPresentationController.barButtonItem = popoverUserconfigurationAnchor

        userSettingNavigationController.publication = publication
        present(userSettingNavigationController, animated: true) {
            // Makes sure that the popover is dismissed also when tapping on one of the other UIBarButtonItems.
            // ie. http://karmeye.com/2014/11/20/ios8-popovers-and-passthroughviews/
            popoverPresentationController.passthroughViews = nil
        }
    }

    @objc func highlightSelection() {
        if let navigator = navigator as? SelectableNavigator, let selection = navigator.currentSelection {
            let highlight = Highlight(bookId: bookId, locator: selection.locator, color: .yellow)
            saveHighlight(highlight)
            navigator.clearSelection()
        }
    }
}
//used to be in the ReaderViewController but i removed it
extension EPUBViewController: EPUBNavigatorDelegate {
    
}

extension EPUBViewController: VisualNavigatorDelegate {
    
    func navigator(_ navigator: VisualNavigator, didTapAt point: CGPoint) {
        // clear a current search highlight
        if let decorator = self.navigator as? DecorableNavigator {
            decorator.apply(decorations: [], in: "search")
        }
        
        let viewport = navigator.view.bounds
        // Skips to previous/next pages if the tap is on the content edges.
        let thresholdRange = 0...(0.2 * viewport.width)
        var moved = false
        if thresholdRange ~= point.x {
            moved = navigator.goLeft(animated: false)
           
        } else if thresholdRange ~= (viewport.maxX - point.x) {
            moved = navigator.goRight(animated: false)
        }
        
        if !moved {
            toggleNavigationBar()
            
            if let navigator = navigator as? VisualNavigator {
             navigator.firstVisibleElementLocator { locator in
                 //print("helloo",locator)
                 //let content = publication.content(from: locator)
                 if let self = self as? EPUBViewController {
                     self.autoHigh(publication: self.publication, currentLocation: locator)
                 }
             } } else {return}
        }
    }
    
}


extension EPUBViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension EPUBViewController: UserSettingsNavigationControllerDelegate {

    internal func getUserSettings() -> UserSettings {
        return epubNavigator.userSettings
    }
    
    internal func updateUserSettingsStyle() {
        DispatchQueue.main.async {
            self.epubNavigator.updateUserSettingStyle()
        }
    }
    //TODO: I can use this to change the highlight color to the proper
    /// Synchronyze the UI appearance to the UserSettings.Appearance.
    ///
    /// - Parameter appearance: The appearance.
    internal func setUIColor(for appearance: UserProperty) {
        self.appearanceChanged(appearance)
        let colors = AssociatedColors.getColors(for: appearance)
        
        navigator.view.backgroundColor = colors.mainColor
        view.backgroundColor = colors.mainColor
        //
        navigationController?.navigationBar.barTintColor = colors.mainColor
        navigationController?.navigationBar.tintColor = colors.textColor
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: colors.textColor]
    }
    
}
