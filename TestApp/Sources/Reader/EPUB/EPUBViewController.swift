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
        navigatorEditingActions.append(EditingAction(title: "parsePage", action: #selector(parsePage)))
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
        
        //TODO: add highlight for auto
        navigator.delegate = self
    }
    //automatically highlights from starting location
    private func autoHigh(currentLocation: Locator?) {
        
        
        print("autoHigh's \(currentLocation)")
        //var currentLocation = navigator.currentLocation
        guard let content = self.publication.content(from: currentLocation) else { return };
        //guard let content = content else { return};
        //lambda wordTokenizer function
        let wordTokenizer = makeTextContentTokenizer(
            defaultLanguage: publication.metadata.language,
            textTokenizerFactory: { language in
                makeDefaultTextTokenizer(unit: .word, language: language)
            }
        )
        //https://www.gutenberg.org/ebooks/24060.epub.noimages
        var known_words = ["的": 1, "一": 1, "是": 1, "了": 1, "我": 1, "不": 1, "人": 1, "在": 1, "他": 1, "有": 1, "这": 1, "个": 1, "上": 1, "们": 1, "来": 1, "到": 1, "时": 1, "大": 1, "地": 1, "为": 1, "子": 1, "中": 1, "你": 1, "说": 1, "生": 1, "国": 1, "年": 1, "着": 1, "就": 1, "那": 1,  "和": 1, "要": 1, "她": 1, "出": 1, "也": 1, "得": 1, "里": 1, "后": 1, "自": 1, "以": 1,  "会": 1, "家": 1, "可": 1, "下": 1, "而": 1, "过": 1, "天": 1, "去": 1, "能": 1, "对": 1,  "小": 1, "多": 1, "然": 1, "于": 1, "心": 1, "学": 1, "么": 1, "之": 1, "都": 1, "好": 1,  "看": 1, "起": 1, "发": 1, "当": 1, "没": 1, "成": 1, "只": 1, "如": 1, "事": 1, "把": 1,  "还": 1, "用": 1, "第": 1, "样": 1, "道": 1, "想": 1, "作": 1, "种": 1, "开": 1, "美": 1,  "总": 1, "从": 1, "无": 1, "情": 1, "己": 1, "面": 1, "最": 1, "女": 1, "但": 1, "现": 1,  "前": 1, "些": 1, "所": 1, "同": 1, "日": 1, "手": 1, "又": 1, "行": 1, "意": 1, "动": 1,  "方": 1, "期": 1, "它": 1, "头": 1, "经": 1, "长": 1, "儿": 1, "回": 1, "位": 1, "分": 1,  "爱": 1, "老": 1, "因": 1, "很": 1, "给": 1, "名": 1, "法": 1, "间": 1, "斯": 1, "知": 1,  "世": 1, "什": 1, "两": 1, "次": 1, "使": 1, "身": 1, "者": 1, "被": 1, "高": 1, "已": 1,  "亲": 1, "其": 1, "进": 1, "此": 1, "话": 1, "常": 1, "与": 1, "活": 1, "正": 1, "感": 1,  "见": 1, "明": 1, "问": 1, "力": 1, "理": 1, "尔": 1, "点": 1, "文": 1, "几": 1, "定": 1,  "本": 1, "公": 1, "特": 1, "做": 1, "外": 1, "孩": 1, "相": 1, "西": 1, "果": 1, "走": 1,  "将": 1, "月": 1, "十": 1, "实": 1, "向": 1, "声": 1, "车": 1, "全": 1, "信": 1, "重": 1,  "三": 1, "机": 1, "工": 1, "物": 1, "气": 1, "每": 1, "并": 1, "别": 1, "真": 1, "打": 1,  "太": 1, "新": 1, "比": 1, "才": 1, "便": 1, "夫": 1, "再": 1, "书": 1, "部": 1, "水": 1,  "像": 1, "眼": 1, "等": 1, "体": 1, "却": 1, "加": 1, "电": 1, "主": 1, "界": 1, "门": 1,  "利": 1, "海": 1, "受": 1, "听": 1, "表": 1, "德": 1, "少": 1, "克": 1, "代": 1, "员": 1,  "许": 1, "先": 1, "口": 1, "由": 1, "死": 1, "安": 1, "写": 1, "性": 1, "马": 1, "光": 1,  "白": 1, "或": 1, "住": 1, "难": 1, "望": 1, "教": 1, "命": 1, "花": 1, "结": 1, "乐": 1,  "色": 1, "更": 1, "拉": 1, "东": 1, "神": 1, "记": 1, "处": 1, "让": 1, "母": 1, "父": 1,  "应": 1, "直": 1, "字": 1, "场": 1, "平": 1, "报": 1, "友": 1, "关": 1, "放": 1, "至": 1,  "张": 1, "认": 1, "接": 1, "告": 1, "入": 1, "笑": 1, "内": 1, "英": 1, "军": 1, "候": 1,  "民": 1, "岁": 1, "往": 1, "何": 1, "度": 1, "山": 1, "觉": 1, "路": 1, "带": 1, "万": 1,  "男": 1, "边": 1, "风": 1, "解": 1, "叫": 1, "任": 1, "金": 1, "快": 1, "原": 1, "吃": 1,  "妈": 1, "变": 1, "通": 1, "师": 1, "立": 1, "象": 1, "数": 1, "四": 1, "失": 1, "满": 1,  "战": 1, "远": 1, "格": 1, "士": 1, "音": 1, "轻": 1, "目": 1, "条": 1, "呢": 1, "病": 1,  "始": 1, "达": 1, "深": 1, "完": 1, "今": 1, "提": 1, "求": 1, "清": 1, "王": 1, "化": 1,  "空": 1, "业": 1, "思": 1, "切": 1, "怎": 1, "非": 1, "找": 1, "片": 1, "罗": 1, "钱": 1,  "吗": 1, "语": 1, "元": 1, "喜": 1, "曾": 1, "离": 1, "飞": 1, "科": 1, "言": 1, "干": 1,  "流": 1, "欢": 1, "约": 1, "各": 1, "即": 1, "指": 1, "合": 1, "反": 1, "题": 1, "必": 1,  "该": 1, "论": 1, "交": 1, "终": 1, "林": 1, "请": 1, "医": 1, "晚": 1, "制": 1, "球": 1,  "决": 1, "传": 1, "画": 1, "保": 1, "读": 1, "运": 1, "及": 1, "则": 1, "房": 1, "早": 1]
        var word_count = 0
        var count = 0
        var fee: [Decoration]  = []
        for el in content.sequence() {
            if el is TextContentElement{
                do {
                    let smth = try wordTokenizer(el)
                    var words: [TextContentElement.Segment]  = smth.compactMap{$0 as? TextContentElement}
                        .flatMap { $0.segments }
                    
                    //words = words.filter { known_words[$0.text] == nil }
                   for word in words {
                        word_count+=1
                        if word_count > 190 {
                            /*
                                (navigator as? DecorableNavigator)?.apply(
                                                decorations: fee,
                                                in: "fee") */
                            return
                            }
                            
                
                    //let start = Date()
                    //DispatchQueue.concurrentPerform(iterations: i) { i in
                       fee.append(Decoration(
                        id: "word-\(word_count)",
                        locator: word.locator,
                        style: .underline()
                    ))
                       /*
                       if known_words[word.text] == nil  {
    
                       (navigator as? DecorableNavigator)?.apply(
                                       decorations: [Decoration(
                                        id: "word-\(word_count)",
                                        locator: word.locator,
                                        style: .underline()
                                    )],
                                       in: "word-\(word_count)")
                       }*/
                       
                        if known_words[word.text] != nil {
                            //known_words[word.text] = 2
                            let highlight = Highlight(bookId: bookId, locator: word.locator, color: .clear, progression: 0)
                            saveHighlight(highlight)
                        } else {
                            
                            let highlight = Highlight(bookId: bookId, locator: word.locator, color: .red, progression: 0)
                            saveHighlight(highlight)

                        }
                    }
                   
                    //let end = Date()
                    //print("time: \(end.timeIntervalSince(start))")
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
            print(selection.locator)
            let highlight = Highlight(bookId: bookId, locator: selection.locator, color: .yellow)
            saveHighlight(highlight)
            navigator.clearSelection()
        }
    }
    @objc func parsePage() {
        if let navigator = navigator as? SelectableNavigator, let selection = navigator.currentSelection {
            
            autoHigh(currentLocation: selection.locator)
            //print(selection.locator)
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
            

        }
        if let navigator = navigator as? VisualNavigator {
         navigator.firstVisibleElementLocator { locator in
             //print("helloo",locator)
             //let content = publication.content(from: locator)
             if let self = self as? EPUBViewController {
                 self.autoHigh(currentLocation: locator)
             }
         } } else {return}
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
