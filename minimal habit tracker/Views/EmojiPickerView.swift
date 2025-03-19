import SwiftUI

// Emoji选择器视图
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Binding var selectedBackgroundColor: String
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0表示Emoji，1表示Text
    @State private var tempSelectedEmoji: String // 临时存储选中的emoji，仅在确认时才更新绑定值
    @State private var selectedCategoryIndex = 0
    @State private var textInput = ""
    @State private var recentEmojis: [String] = []
    // 添加当前分类的emoji数据
    @State private var currentCategoryEmojis: [String] = []
    
    // 最近使用的emoji的UserDefaults键
    private let recentEmojisKey = "recentEmojis"
    // 最近使用的emoji的最大数量
    private let maxRecentEmojis = 30
    
    // 初始化临时选中的emoji
    init(selectedEmoji: Binding<String>, selectedBackgroundColor: Binding<String>) {
        self._selectedEmoji = selectedEmoji
        self._selectedBackgroundColor = selectedBackgroundColor
        self._tempSelectedEmoji = State(initialValue: selectedEmoji.wrappedValue)
        self._recentEmojis = State(initialValue: Self.loadRecentEmojis())
        // 不再在初始化时加载所有emoji数据
    }
    
    // 从UserDefaults加载最近使用的emoji
    private static func loadRecentEmojis() -> [String] {
        if let savedEmojis = UserDefaults.standard.array(forKey: "recentEmojis") as? [String] {
            return savedEmojis
        } else {
            // 默认emoji列表
            return ["😀", "😊", "👍", "❤️", "🎉", "🔥", "✨", "🙏", "👋", "🤔"]
        }
    }
    
    // 保存emoji到最近使用列表
    private func saveEmojiToRecents(_ emoji: String) {
        // 如果emoji已经在列表中，先移除
        var updatedRecents = recentEmojis.filter { $0 != emoji }
        
        // 将新emoji添加到列表开头
        updatedRecents.insert(emoji, at: 0)
        
        // 如果列表超过最大长度，截断
        if updatedRecents.count > maxRecentEmojis {
            updatedRecents = Array(updatedRecents.prefix(maxRecentEmojis))
        }
        
        // 更新状态和存储
        self.recentEmojis = updatedRecents
        UserDefaults.standard.set(updatedRecents, forKey: recentEmojisKey)
    }
    
    // 顶部图标类别 - 添加SF Symbols图标
    let topIcons = ["clock", "person", "leaf", "gift", "building.2", "number"]
    
    // 表情符号分类定义 - 名称和图标
    let emojiCategoryDefinitions: [(name: String, symbol: String)] = [
        ("最近使用", "clock"),
        ("人物", "person"),
        ("自然", "leaf"),
        ("物品", "gift"),
        ("地点", "building.2"),
        ("符号", "number")
    ]
    
    // 根据分类索引获取对应的emoji数组
    private func getEmojisForCategory(_ index: Int) -> [String] {
        switch index {
        case 0: return recentEmojis // 最近使用
        case 1: return [
            // People 类别的表情符号
            "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "☺️", "😊",
            "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙",
            "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎",
            "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖",
            "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬", "🤯",
            "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗", "🤔",
            "🤭", "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😦",
            "😧", "😮", "😲", "🥱", "😴", "🤤", "😪", "😵", "🤐", "🥴",
            "🤢", "🤮", "🤧", "😷", "🤒", "🤕", "🤑", "🤠", "👋", "🤚",
            "✋", "🖖", "👌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈",
            "👉", "👆", "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛",
            "🤜", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "💪", "🦾", "🦿",
            "🦵", "🦶", "👣", "👂", "🦻", "👃", "🧠", "🦷", "👀", "👁️",
            "👅", "👄", "💋", "❤️", "🧡", "💛", "💚", "💙", "💜", "🤎",
            "🖤", "🤍", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘",
            "💝", "💟", "👶", "👧", "🧒", "👦", "👩", "🧑", "👨", "👩‍🦱",
            "👨‍🦱", "👩‍🦰", "👨‍🦰", "👱‍♀️", "👱", "👱‍♂️", "👩‍🦳", "👨‍🦳", "👩‍🦲", "👨‍🦲",
            "🧔", "👵", "🧓", "👴", "👮‍♀️", "👮", "👮‍♂️", "👷‍♀️", "👷", "👷‍♂️",
            "💂‍♀️", "💂", "💂‍♂️", "🕵️‍♀️", "🕵️", "🕵️‍♂️", "👩‍⚕️", "🧑‍⚕️", "👨‍⚕️", "👩‍🌾",
            "🧑‍🌾", "👨‍🌾", "👩‍🍳", "🧑‍🍳", "👨‍🍳", "👩‍🎓", "🧑‍🎓", "👨‍🎓", "👩‍🎤", "🧑‍🎤",
            "👨‍🎤", "👩‍🏫", "🧑‍🏫", "👨‍🏫", "👩‍🏭", "🧑‍🏭", "👨‍🏭", "👩‍💻", "🧑‍💻", "👨‍💻",
            "👩‍💼", "🧑‍💼", "👨‍💼", "👩‍🔧", "🧑‍🔧", "👨‍🔧", "👩‍🔬", "🧑‍🔬", "👨‍🔬", "👩‍🎨",
            "🧑‍🎨", "👨‍🎨", "👩‍🚒", "🧑‍🚒", "👨‍🚒", "👩‍✈️", "🧑‍✈️", "👨‍✈️", "👩‍🚀", "🧑‍🚀",
            "👨‍🚀", "👩‍⚖️", "🧑‍⚖️", "👨‍⚖️", "👰", "🤵", "🤴", "👸", "🦸‍♀️", "🦸",
            "🦸‍♂️", "🦹‍♀️", "🦹", "🦹‍♂️", "🤶", "🎅", "🧙‍♀️", "🧙", "🧙‍♂️", "🧝‍♀️",
            "🧝", "🧝‍♂️", "🧛‍♀️", "🧛", "🧛‍♂️", "🧟‍♀️", "🧟", "🧟‍♂️", "🧞‍♀️", "🧞",
            "🧞‍♂️", "🧜‍♀️", "🧜", "🧜‍♂️", "🧚‍♀️", "🧚", "🧚‍♂️", "👼", "🤰", "🤱",
            "🙇‍♀️", "🙇", "🙇‍♂️", "💁‍♀️", "💁", "💁‍♂️", "🙅‍♀️", "🙅", "🙅‍♂️", "🙆‍♀️",
            "🙆", "🙆‍♂️", "🙋‍♀️", "🙋", "🙋‍♂️", "🧏‍♀️", "🧏", "🧏‍♂️", "🤦‍♀️", "🤦",
            "🤦‍♂️", "🤷‍♀️", "🤷", "🤷‍♂️", "🙎‍♀️", "🙎", "🙎‍♂️", "🙍‍♀️", "🙍", "🙍‍♂️",
            "💇‍♀️", "💇", "💇‍♂️", "💆‍♀️", "💆", "💆‍♂️", "🧖‍♀️", "🧖", "🧖‍♂️", "💅",
            "🤳", "💃", "🕺", "👯‍♀️", "👯", "👯‍♂️", "🕴️", "👩‍🦽", "🧑‍🦽", "👨‍🦽",
            "👩‍🦼", "🧑‍🦼", "👨‍🦼", "🚶‍♀️", "🚶", "🚶‍♂️", "👩‍🦯", "🧑‍🦯", "👨‍🦯", "🧎‍♀️",
            "🧎", "🧎‍♂️", "🏃‍♀️", "🏃", "🏃‍♂️", "🧍‍♀️", "🧍", "🧍‍♂️", "👭", "🧑‍🤝‍🧑",
            "👬", "👫", "👩‍❤️‍👩", "💑", "👨‍❤️‍👨", "👩‍❤️‍👨", "👩‍❤️‍💋‍👩", "💏", "👨‍❤️‍💋‍👨", "👩‍❤️‍💋‍👨",
            "👪", "👨‍👩‍👦", "👨‍👩‍👧", "👨‍👩‍👧‍👦", "👨‍👩‍👦‍👦", "👨‍👩‍👧‍👧", "👨‍👨‍👦", "👨‍👨‍👧", "👨‍👨‍👧‍👦", "👨‍👨‍👦‍👦",
            "👨‍👨‍👧‍👧", "👩‍👩‍👦", "👩‍👩‍👧", "👩‍👩‍👧‍👦", "👩‍👩‍👦‍👦", "👩‍👩‍👧‍👧", "👨‍👦", "👨‍👦‍👦", "👨‍👧", "👨‍👧‍👦",
            "👨‍👧‍👧", "👩‍👦", "👩‍👦‍👦", "👩‍👧", "👩‍👧‍👦", "👩‍👧‍👧", "🗣️", "👤", "👥", "🫂"
        ]
        case 2: return [
            // Nature 类别的表情符号
            "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐻‍❄️", "🐨",
            "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵", "🙈", "🙉", "🙊",
            "🐒", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅", "🦉",
            "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🪱", "🐛", "🦋", "🐌",
            "🐞", "🐜", "🪰", "🪲", "🪳", "🦟", "🦗", "🕷️", "🕸️", "🦂",
            "🐢", "🐍", "🦎", "🦖", "🦕", "🐙", "🦑", "🦐", "🦞", "🦀",
            "🐡", "🐠", "🐟", "🐬", "🐳", "🐋", "🦈", "🐊", "🐅", "🐆",
            "🦓", "🦍", "🦧", "🦣", "🐘", "🦛", "🦏", "🐪", "🐫", "🦒",
            "🦘", "🦬", "🐃", "🐂", "🐄", "🐎", "🐖", "🐏", "🐑", "🦙",
            "🐐", "🦌", "🐕", "🐩", "🦮", "🐕‍🦺", "🐈", "🐈‍⬛", "🪶", "🐓",
            "🦃", "🦤", "🦚", "🦜", "🦢", "🦩", "🕊️", "🐇", "🦝", "🦨",
            "🦡", "🦫", "🦦", "🦥", "🐁", "🐀", "🐿️", "🦔", "🐾", "🐉",
            "🐲", "🌵", "🎄", "🌲", "🌳", "🌴", "🪵", "🌱", "🌿", "☘️",
            "🍀", "🎍", "🪴", "🎋", "🍃", "🍂", "🍁", "🍄", "🐚", "🪨",
            "🌾", "💐", "🌷", "🌹", "🥀", "🌺", "🌸", "🌼", "🌻", "🌞",
            "🌝", "🌛", "🌜", "🌚", "🌕", "🌖", "🌗", "🌘", "🌑", "🌒",
            "🌓", "🌔", "🌙", "🌎", "🌍", "🌏", "🪐", "💫", "⭐", "🌟",
            "✨", "⚡", "☄️", "💥", "🔥", "🌪️", "🌈", "☀️", "🌤️", "⛅",
            "🌥️", "☁️", "🌦️", "🌧️", "⛈️", "🌩️", "🌨️", "❄️", "☃️", "⛄",
            "🌬️", "💨", "💧", "💦", "☔", "☂️", "🌊", "🌫️"
        ]
        case 3: return [
            // Objects 类别的表情符号
            "🍎", "🍏", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐",
            "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑",
            "🫒", "🥦", "🥬", "🥒", "🌶️", "🫑", "🌽", "🥕", "🧄", "🧅",
            "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳",
            "🧈", "🥞", "🧇", "🥓", "🥩", "🍗", "🍖", "🦴", "🌭", "🍔",
            "🍟", "🍕", "🫓", "🥪", "🥙", "🧆", "🌮", "🌯", "🫔", "🥗",
            "🥘", "🫕", "🥫", "🍝", "🍜", "🍲", "🍛", "🍣", "🍱", "🥟",
            "🦪", "🍤", "🍙", "🍚", "🍘", "🍥", "🥠", "🥮", "🍢", "🍡",
            "🍧", "🍨", "🍦", "🥧", "🧁", "🍰", "🎂", "🍮", "🍭", "🍬",
            "🍫", "🍿", "🍩", "🍪", "🌰", "🥜", "🫘", "🍯", "🥛", "🫗",
            "🍼", "☕", "🫖", "🍵", "🧃", "🥤", "🧋", "🍶", "🍺", "🍻",
            "🥂", "🍷", "🥃", "🍸", "🍹", "🧉", "🍾", "🧊", "🥄", "🍴",
            "🍽️", "🥣", "🥡", "🥢", "🧂", "⚽", "🏀", "🏈", "⚾", "🥎",
            "🎾", "🏐", "🏉", "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑",
            "🥍", "🏏", "🪃", "🥅", "⛳", "🪁", "🏹", "🎣", "🤿", "🥊",
            "🥋", "🎽", "🛹", "🛼", "🛷", "⛸️", "🥌", "🎿", "⛷️", "🏂",
            "🪂", "🏋️", "🏋️‍♂️", "🏋️‍♀️", "🤼", "🤼‍♂️", "🤼‍♀️", "🤸‍♀️", "🤸", "🤸‍♂️",
            "⛹️", "⛹️‍♂️", "⛹️‍♀️", "🤺", "🤾", "🤾‍♂️", "🤾‍♀️", "🏌️", "🏌️‍♂️", "🏌️‍♀️",
            "🏇", "🧘", "🧘‍♂️", "🧘‍♀️", "🏄", "🏄‍♂️", "🏄‍♀️", "🏊", "🏊‍♂️", "🏊‍♀️",
            "🤽", "🤽‍♂️", "🤽‍♀️", "🚣", "🚣‍♂️", "🚣‍♀️", "🧗", "🧗‍♂️", "🧗‍♀️", "🚵",
            "🚵‍♂️", "🚵‍♀️", "🚴", "🚴‍♂️", "🚴‍♀️", "🏆", "🥇", "🥈", "🥉", "🏅",
            "🎖️", "🏵️", "🎗️", "🎫", "🎟️", "🎪", "🤹", "🤹‍♂️", "🤹‍♀️", "🎭",
            "🩰", "🎨", "🎬", "🎤", "🎧", "🎼", "🎹", "🥁", "🎷", "🎺",
            "🎸", "🪕", "🎻", "🎲", "♟️", "🎯", "🎳", "🎮", "🎰", "🧩",
            "🦯", "🦽", "🦼", "🛴", 
        ]
        case 4: return [
            // Places 类别的表情符号
            "🏠", "🏡", "🏘️", "🏚️", "🏗️", "🏭", "🏢", "🏬", "🏣", "🏤",
            "🏥", "🏦", "🏨", "🏪", "🏫", "🏩", "💒", "🏛️", "⛪", "🕌",
            "🕍", "🛕", "🕋", "⛩️", "🛤️", "🛣️", "🗾", "🎑", "🏞️", "🌅",
            "🌄", "🌠", "🎇", "🎆", "🌇", "🌆", "🏙️", "🌃", "🌌", "🌉",
            "🌁", "🛫", "🛬", "🚑", "🚒", "🚓", "🚕", "🚗", "🚙", "🚌",
            "🚎", "🏎️", "🚐", "🛻", "🚚", "🚛", "🚜", "🚲", "🛵", "🏍️",
            "🛺", "🚨", "🚔", "🚍", "🚘", "🚖", "🚠", "🚡", "🚟", "🚃",
            "🚋", "🚞", "🚝", "🚄", "🚅", "🚈", "🚂", "🚆", "🚇", "🚊",
            "🚉", "✈️", "🛩️", "💺", "🛰️", "🚀", "🛸", "🚁", "🛶", "⛵",
            "🚤", "🛥️", "🛳️", "⛴️", "🚢", "⚓", "🚧", "🚦", "🚥", "🚏",
            "🗿", "🗽", "🗼", "🏰", "🏯", "🏟️", "🎡", "🎢", "🎠", "⛲",
            "⛱️", "🏖️", "🏝️", "🏜️", "🌋", "⛰️", "🏔️", "🗻", "🏕️", "⛺",
            "🛖"
        ]
        case 5: return [
            // Symbols 类别的表情符号
            "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔",
            "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️",
            "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐",
            "⛎", "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐",
            "♑", "♒", "♓", "🆔", "⚛️", "🉑", "☢️", "☣️", "📴", "📳",
            "🈶", "🈚", "🈸", "🈺", "🈷️", "✴️", "🆚", "💮", "🉐", "㊙️",
            "㊗️", "🈴", "🈵", "🈹", "🈲", "🅰️", "🅱️", "🆎", "🆑", "🅾️",
            "🆘", "❌", "⭕", "🛑", "⛔", "📛", "🚫", "💯", "💢", "♨️",
            "🚷", "🚯", "🚳", "🚱", "🔞", "📵", "🚭", "❗", "❕", "❓",
            "❔", "‼️", "⁉️", "🔅", "🔆", "〽️", "⚠️", "🚸", "🔱", "⚜️",
            "🔰", "♻️", "✅", "🈯", "💹", "❇️", "✳️", "❎", "🌐", "💠",
            "Ⓜ️", "🌀", "💤", "🏧", "🚾", "♿", "🅿️", "🛗", "🈳", "🈂️",
            "🛂", "🛃", "🛄", "🛅", "🚹", "🚺", "🚼", "⚧", "🚻", "🚮",
            "🎦", "📶", "🈁", "🔣", "ℹ️", "🔤", "🔡", "🔠", "🆖", "🆗",
            "🆙", "🆒", "🆕", "🆓", "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣",
            "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟", "🔢", "#️⃣", "*️⃣", "⏏️", "▶️",
            "⏸️", "⏯️", "⏹️", "⏺️", "⏭️", "⏮️", "⏩", "⏪", "⏫", "⏬",
            "◀️", "🔼", "🔽", "➡️", "⬅️", "⬆️", "⬇️", "↗️", "↘️", "↙️",
            "↖️", "↕️", "↔️", "↪️", "↩️", "⤴️", "⤵️", "🔀", "🔁", "🔂",
            "🔄", "🔃", "🎵", "🎶", "➕", "➖", "➗", "✖️", "♾️", "💲",
            "💱", "™️", "©️", "®️", "〰️", "➰", "➿", "🔚", "🔙", "🔛",
            "🔝", "🔜", "✔️", "☑️", "🔘", "🔴", "🟠", "🟡", "🟢", "🔵",
            "🟣", "⚫", "⚪", "🟤", "🔺", "🔻", "🔸", "🔹", "🔶", "🔷",
            "🔳", "🔲", "▪️", "▫️", "◾", "◽", "◼️", "◻️", "🟥", "🟧",
            "🟨", "🟩", "🟦", "🟪", "⬛", "⬜", "🟫", "🔈", "🔇", "🔉",
            "🔊", "🔔", "🔕", "📣", "📢", "👁️‍🗨️", "💬", "💭", "🗯️", "♠️",
            "♣️", "♥️", "♦️", "🃏", "🎴", "🀄"
        ]
        default: return []
        }
    }
    
    // 从传入的分类和emoji数组中随机选择一个emoji
    private func randomEmoji() -> String {
        // 随机选择一个分类，排除"最近使用"分类
        let randomCategoryIndex = Int.random(in: 1..<emojiCategoryDefinitions.count)
        // 从这个分类中获取emoji
        let emojis = getEmojisForCategory(randomCategoryIndex)
        // 随机选择一个emoji
        return emojis.randomElement() ?? "😀"
    }
    
    // 加载当前分类的emoji
    private func loadCurrentCategoryEmojis() {
        // 使用异步加载避免阻塞UI
        DispatchQueue.global(qos: .userInitiated).async {
            let emojis = self.getEmojisForCategory(self.selectedCategoryIndex)
            DispatchQueue.main.async {
                self.currentCategoryEmojis = emojis
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前选择的emoji预览区域及随机按钮
                ZStack(alignment: .center) {
                    // 当前选择的emoji (居中)
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(hex: selectedBackgroundColor))
                        .frame(width: 80, height: 80)
                    
                    Text(tempSelectedEmoji)
                        .font(.system(size: 40))
                
                        // 随机按钮 (预览右下角)
                    Button(action: {
                        // 随机选择一个新emoji
                        tempSelectedEmoji = randomEmoji()
                        // 不再立即保存到最近使用列表，而是在确认时保存
                    }) {
                            Image("dices")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(width: 36, height: 36)
                                .background(Color(UIColor.systemGray5).opacity(0.6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                        }
                        .offset(x: 75, y: 20)  // 相对于预览的右下角定位
                    }
                }
                .padding(.top)
                .padding(.bottom, 40)
                
                // 选项卡切换
                HStack {
                    Button(action: { selectedTab = 0 }) {
                        Text("Emoji")
                            .fontWeight(selectedTab == 0 ? .bold : .regular)
                            .padding(.bottom, 8)
                            .border(width: selectedTab == 0 ? 2 : 0, edges: [.bottom], color: .primary)
                    }
                    
                    Spacer()
                        .frame(width: 40)
                    
                    Button(action: { selectedTab = 1 }) {
                        Text("Text")
                            .fontWeight(selectedTab == 1 ? .bold : .regular)
                            .padding(.bottom, 8)
                            .border(width: selectedTab == 1 ? 2 : 0, edges: [.bottom], color: .primary)
                    }
                }
                .padding()
                
                if selectedTab == 0 {
                    // Emoji模式
                    
                    // 顶部图标分类
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(0..<emojiCategoryDefinitions.count, id: \.self) { index in
                                Button(action: {
                                    // 切换分类时加载对应的emoji
                                    if selectedCategoryIndex != index {
                                    selectedCategoryIndex = index
                                        loadCurrentCategoryEmojis()
                                    }
                                }) {
                                    Image(systemName: emojiCategoryDefinitions[index].symbol)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedCategoryIndex == index ? .accentColor : .gray)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(selectedCategoryIndex == index ? 
                                                    Color.accentColor.opacity(0.1) : Color.clear)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    
                    // emoji网格
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 12) {
                            ForEach(currentCategoryEmojis, id: \.self) { emoji in
                                Button(action: {
                                    // 选择emoji但不关闭界面
                                    tempSelectedEmoji = emoji
                                    // 不再立即保存到最近使用，而是在确认时保存
                                }) {
                                        Text(emoji)
                                        .font(.system(size: 28))
                                        .frame(width: 44, height: 44)
                                        .background(tempSelectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                } else {
                    // Text模式
                    VStack(spacing: 20) {
                        TextField("输入文字", text: $textInput)
                            .font(.system(size: 28))
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                            .background(Color(hex: selectedBackgroundColor).opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                            .onChange(of: textInput) { newValue in
                                // 如果不为空，则预览第一个字符
                                if !newValue.isEmpty {
                                    let firstChar = String(newValue.prefix(1))
                                    tempSelectedEmoji = firstChar
                                }
                            }
                        
                        Text("将取第一个字作为习惯图标。你也可以输入自定义的 emoji")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
                
                // 移除底部操作按钮
                Spacer() // 用Spacer替代底部按钮区域
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        // 确认选择，更新绑定值
                        selectedEmoji = tempSelectedEmoji
                        // 这里才保存到最近使用列表
                        saveEmojiToRecents(tempSelectedEmoji)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(tempSelectedEmoji.isEmpty)
                }
            }
            .onAppear {
                // 在视图出现时加载当前分类的emoji
                loadCurrentCategoryEmojis()
            }
        }
    }
}

// 边框扩展
struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var line = Path()
            
            switch edge {
            case .top:
                line.move(to: CGPoint(x: rect.minX, y: rect.minY))
                line.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            case .bottom:
                line.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                line.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            case .leading:
                line.move(to: CGPoint(x: rect.minX, y: rect.minY))
                line.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            case .trailing:
                line.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                line.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            
            path.addPath(line)
        }
        
        return path.strokedPath(StrokeStyle(lineWidth: width))
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
} 