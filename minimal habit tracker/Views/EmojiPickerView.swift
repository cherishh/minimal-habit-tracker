import SwiftUI

// Emoji选择器视图
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0表示Emoji，1表示Text
    @State private var tempSelectedEmoji: String // 临时存储选中的emoji，仅在确认时才更新绑定值
    @State private var selectedCategoryIndex = 0
    @State private var textInput = ""
    @State private var recentEmojis: [String] = []
    var backgroundColor: String
    
    // 最近使用的emoji的UserDefaults键
    private let recentEmojisKey = "recentEmojis"
    // 最近使用的emoji的最大数量
    private let maxRecentEmojis = 30
    
    // 初始化临时选中的emoji
    init(selectedEmoji: Binding<String>, backgroundColor: String) {
        self._selectedEmoji = selectedEmoji
        self._tempSelectedEmoji = State(initialValue: selectedEmoji.wrappedValue)
        self._recentEmojis = State(initialValue: Self.loadRecentEmojis())
        self.backgroundColor = backgroundColor
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
    let topIcons = ["clock", "face.smiling", "person", "hand.raised", "leaf", "cup.and.saucer", "bicycle", "airplane", "gift", "flag"]
    
    // 表情符号分类
    var emojiCategories: [(name: String, symbol: String, emojis: [String])] {
        var categories: [(name: String, symbol: String, emojis: [String])] = [
            ("最近使用", "clock", recentEmojis),
            ("笑脸表情", "face.smiling", ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "🫠", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "☺️", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🫢", "🫣", "🤫", "🤔", "🫡", "🤐", "🤨", "😐", "😑", "😶", "🫥", "😶‍🌫️", "😏", "😒", "🙄", "😬", "😮‍💨", "🤥", "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢", "🤮", "🤧", "🥵", "🥶", "🥴", "😵", "😵‍💫", "🤯", "🤠", "🥳", "🥸", "😎", "🤓", "🧐"]),
            ("人物形象", "person", ["👶", "👧", "🧒", "👦", "👩", "🧑", "👨", "👩‍🦱", "🧑‍🦱", "👨‍🦱", "👩‍🦰", "🧑‍🦰", "👨‍🦰", "👱‍♀️", "👱", "👱‍♂️", "👩‍🦳", "🧑‍🦳", "👨‍🦳", "👩‍🦲", "🧑‍🦲", "👨‍🦲", "🧔‍♀️", "🧔", "🧔‍♂️", "👵", "🧓", "👴", "👲", "👳‍♀️", "👳", "👳‍♂️", "🧕", "👮‍♀️", "👮", "👮‍♂️", "👷‍♀️", "👷", "👷‍♂️", "💂‍♀️", "💂", "💂‍♂️", "🕵️‍♀️", "🕵️", "🕵️‍♂️", "👩‍⚕️", "🧑‍⚕️", "👨‍⚕️", "👩‍🌾", "🧑‍🌾", "👨‍🌾", "👩‍🍳", "🧑‍🍳", "👨‍🍳", "👩‍🎓", "🧑‍🎓", "👨‍🎓", "👩‍🎤", "🧑‍🎤", "👨‍🎤"]),
            ("手势动作", "hand.raised", ["👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆", "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛", "🤜", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "✍️", "💅", "🤳", "💪", "🦾", "🦵", "🦶", "👣", "👂", "🦻", "👃", "🧠", "🫀", "🫁", "🦷", "🦴", "👀", "👁️", "👅", "👄", "🫦"]),
            ("动物与自然", "leaf", ["🐵", "🐒", "🦍", "🦧", "🐶", "🐕", "🦮", "🐕‍🦺", "🐩", "🐺", "🦊", "🦝", "🐱", "🐈", "🐈‍⬛", "🦁", "🐯", "🐅", "🐆", "🐴", "🐎", "🦄", "🦓", "🦌", "🦬", "🐮", "🐂", "🐃", "🐄", "🐷", "🐖", "🐗", "🐽", "🐏", "🐑", "🐐", "🐪", "🐫", "🦙", "🦒", "🐘", "🦣", "🦏", "🦛", "🐭", "🐁", "🐀", "🐹", "🐰", "🐇", "🐿️", "🦫", "🦔", "🦇", "🐻", "🐻‍❄️", "🐨", "🐼", "🦥", "🦦", "🦨", "🦘", "🦡", "🐾", "🦃", "🐔", "🐓", "🐣", "🐤", "🐥", "🐦", "🐧", "🕊️", "🦅", "🦆", "🦢", "🦉", "🦤", "🪶", "🦩", "🦚", "🦜", "🐸", "🐊", "🐢", "🦎", "🐍", "🐲", "🐉", "🦕", "🦖", "🐳", "🐋", "🐬", "🦭", "🐟", "🐠", "🐡", "🦈", "🐙", "🐚", "🐌", "🦋", "🐛", "🐜", "🐝", "🪲", "🐞", "🦗", "🪳", "🕷️", "🕸️", "🦂", "🦟", "🪰", "🪱", "🦠", "💐", "🌸", "💮", "🏵️", "🌹", "🥀", "🌺", "🌻", "🌼", "🌷", "🌱", "🪴", "🌲", "🌳", "🌴", "🌵", "🌾", "🌿", "☘️", "🍀", "🍁", "🍂", "🍃", "🍄", "🌰", "🦀", "🦞", "🦐", "🦑"]),
            ("食物与饮料", "cup.and.saucer", ["🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🥭", "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🫐", "🥝", "🍅", "🫒", "🥥", "🥑", "🍆", "🥔", "🥕", "🌽", "🌶️", "🫑", "🥒", "🥬", "🥦", "🧄", "🧅", "🍄", "🥜", "🫘", "🌰", "🍞", "🥐", "🥖", "🫓", "🥨", "🥯", "🥞", "🧇", "🧀", "🍖", "🍗", "🥩", "🥓", "🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🌯", "🫔", "🥙", "🧆", "🥚", "🍳", "🥘", "🍲", "🫕", "🥣", "🥗", "🍿", "🧈", "🧂", "🥫", "🍱", "🍘", "🍙", "🍚", "🍛", "🍜", "🍝", "🍠", "🍢", "🍣", "🍤", "🍥", "🥮", "🍡", "🥟", "🥠", "🥡", "🦀", "🦞", "🦐", "🦑", "🦪", "🍦", "🍧", "🍨", "🍩", "🍪", "🎂", "🍰", "🧁", "🥧", "🍫", "🍬", "🍭", "🍮", "🍯", "🍼", "🥛", "☕", "🫖", "🍵", "🍶", "🍾", "🍷", "🍸", "🍹", "🍺", "🍻", "🥂", "🥃", "🫗", "🥤", "🧋", "🧃", "🧉", "🧊", "🥢", "🍽️", "🍴", "🥄"]),
            ("旅行与地点", "airplane", ["🚂", "🚃", "🚄", "🚅", "🚆", "🚇", "🚈", "🚉", "🚊", "🚝", "🚞", "🚋", "🚌", "🚍", "🚎", "🚐", "🚑", "🚒", "🚓", "🚔", "🚕", "🚖", "🚗", "🚘", "🚙", "🚚", "🚛", "🚜", "🏎️", "🏍️", "🛵", "🦽", "🦼", "🛺", "🚲", "🛴", "🛹", "🛼", "🚏", "🛣️", "🛤️", "🛢️", "⛽", "🚨", "🚥", "🚦", "🛑", "🚧", "⚓", "⛵", "🛶", "🚤", "🛳️", "⛴️", "🛥️", "🚢", "✈️", "🛩️", "🛫", "🛬", "🪂", "💺", "🚁", "🚟", "🚠", "🚡", "🛰️", "🚀", "🛸", "🛎️", "🧳", "⌛", "⏱️", "⏲️", "⏰", "🕰️", "⌚", "🧭", "🎪", "🎭", "🖼️", "🎨", "🧵", "🪡", "🧶", "🪢", "👓", "🕶️", "🥽", "🥼", "🦺", "👔", "👕", "👖", "🧣", "🧤", "🧥", "🧦", "👗", "👘", "🥻", "🩱", "🩲", "🩳", "👙", "👚", "👛", "👜", "👝", "🎒", "🩴", "👞", "👟", "🥾", "🥿", "👠", "👡", "🩰", "👢", "👑", "👒", "🎩", "🎓", "🧢", "🪖", "⛑️", "📿", "💄", "💍", "💎"]),
            ("活动与运动", "bicycle", ["🎯", "🎮", "🎲", "♟️", "🎭", "🎨", "🧩", "🎪", "🎤", "🎧", "🎼", "🎹", "🥁", "🎷", "🎺", "🎸", "🪕", "🎻", "🎬", "🏹", "🥊", "🥋", "⚽", "⚾", "🥎", "🏀", "🏐", "🏈", "🏉", "🎾", "🥏", "🎳", "🏏", "🏑", "🏒", "🥍", "🏓", "🏸", "🥊", "🥋", "🥅", "⛳", "⛸️", "🎣", "🤿", "🎽", "🎿", "🛷", "🥌", "🎯", "🪀", "🪁", "🎱", "🎖️", "🏆", "🏅", "🥇", "🥈", "🥉", "🏔️", "⛰️", "🌋", "🗻", "🏕️", "🏖️", "🏜️", "🏝️", "🏞️", "🏟️", "🏛️", "🏗️", "🧱", "🪨", "🪵", "🛖", "🏘️", "🏚️", "🏠", "🏡", "🏢", "🏣", "🏤", "🏥", "🏦", "🏨", "🏩", "🏪", "🏫", "🏬", "🏭", "🏯", "🏰", "💒", "🗼", "🗽", "⛪", "🕌", "🛕", "🕍", "⛩️", "🕋", "⛲", "⛺", "🌁", "🌃", "🏙️", "🌄", "🌅", "🌆", "🌇", "🌉", "♨️", "🎠", "🎡", "🎢", "💈", "🎪"]),
            ("物品与对象", "gift", ["📱", "📲", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "🖲️", "🕹️", "🗜️", "💽", "💾", "💿", "📀", "🧮", "🎥", "🎞️", "📽️", "🎬", "📺", "📷", "📸", "📹", "📼", "🔍", "🔎", "🕯️", "💡", "🔦", "🏮", "🪔", "📔", "📕", "📖", "📗", "📘", "📙", "📚", "📓", "📒", "📃", "📜", "📄", "📰", "🗞️", "📑", "🔖", "🏷️", "💰", "🪙", "💴", "💵", "💶", "💷", "💸", "💳", "🧾", "💹", "✉️", "📧", "📨", "📩", "📤", "📥", "📦", "📫", "📪", "📬", "📭", "📮", "🗳️", "✏️", "✒️", "🖋️", "🖊️", "🖌️", "🖍️", "📝", "💼", "📁", "📂", "🗂️", "📅", "📆", "🗒️", "🗓️", "📇", "📈", "📉", "📊", "📋", "📌", "📍", "📎", "🖇️", "📏", "📐", "✂️", "🗃️", "🗄️", "🗑️", "🔒", "🔓", "🔏", "🔐", "🔑", "🗝️", "🔨", "🪓", "⛏️", "⚒️", "🛠️", "🗡️", "⚔️", "🔫", "🪃", "🏹", "🛡️", "🪚", "🔧", "🪛", "🔩", "⚙️", "🗜️", "⚖️", "🦯", "🔗", "⛓️", "🪝", "🧰", "🧲", "🪜", "⚗️", "🧪", "🧫", "🧬", "🔬", "🔭", "📡", "💉", "🩸", "💊", "🩹", "🩺", "🚪", "🛗", "🪞", "🪟", "🛏️", "🛋️", "🪑", "🚽", "🪠", "🚿", "🛁", "🪤", "🪒", "🧴", "🧷", "🧹", "🧺", "🧻", "🪣", "🧼", "🪥", "🧽", "🧯", "🛒", "🚬", "⚰️", "🪦", "⚱️", "🗿", "🪧", "🏧", "🚮", "🚰", "♿", "🚹", "🚺", "🚻", "🚼", "🚾", "🛂", "🛃", "🛄", "🛅"]),
            ("符号与标志", "flag", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🤎", "🖤", "🤍", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "☮️", "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐", "⛎", "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓", "🆔", "⚛️", "🉑", "☢️", "☣️", "📴", "📳", "🈶", "🈚", "🈸", "🈺", "🈷️", "✴️", "🆚", "💮", "🉐", "㊙️", "㊗️", "🈴", "🈵", "🈹", "🈲", "🅰️", "🅱️", "🆎", "🆑", "🅾️", "🆘", "❌", "⭕️", "🛑", "⛔️", "📛", "🚫", "💯", "💢", "♨️", "🚷", "🚯", "🚳", "🚱", "🔞", "📵", "🚭", "❗️", "❕", "❓", "❔", "‼️", "⁉️", "🔅", "🔆", "〽️", "⚠️", "🚸", "🔱", "⚜️", "🔰", "♻️", "✅", "🈯️", "💹", "❇️", "✳️", "❎", "🌐", "💠", "Ⓜ️", "🌀", "💤", "🚾", "🚼", "🏧", "🚻", "🔤", "🔡", "🔠", "🆖", "🆗", "🆙", "🆒", "🆕", "🆓", "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟", "🔢", "#️⃣", "*️⃣", "⏏️", "▶️", "⏸️", "⏯️", "⏹️", "⏺️", "⏭️", "⏮️", "⏩", "⏪", "⏫", "⏬", "◀️", "🔼", "🔽", "➡️", "⬅️", "⬆️", "⬇️", "↗️", "↘️", "↙️", "↖️", "↕️", "↔️", "↪️", "↩️", "⤴️", "⤵️", "🔀", "🔁", "🔂", "🔄", "🔃", "🎵", "🎶", "➕", "➖", "➗", "✖️", "♾️", "💲", "💱", "™️", "©️", "®️", "👁️‍🗨️", "🔚", "🔙", "🔛", "🔝", "🔜"])
        ]
        return categories
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前选择的emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(hex: backgroundColor))
                        .frame(width: 80, height: 80)
                    
                    Text(tempSelectedEmoji)
                        .font(.system(size: 40))
                }
                .padding(.top)
                
                // 选项卡切换
                HStack {
                    Button(action: { selectedTab = 0 }) {
                        Text("Emoji")
                            .fontWeight(selectedTab == 0 ? .bold : .regular)
                            .padding(.bottom, 8)
                            .border(width: selectedTab == 0 ? 2 : 0, edges: [.bottom], color: .primary)
                    }
                    
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
                            ForEach(0..<topIcons.count, id: \.self) { index in
                                Button(action: {
                                    selectedCategoryIndex = index
                                }) {
                                    Image(systemName: emojiCategories[index].symbol)
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
                            ForEach(emojiCategories[selectedCategoryIndex].emojis, id: \.self) { emoji in
                                Button(action: {
                                    // 选择emoji但不关闭界面
                                    tempSelectedEmoji = emoji
                                    // 保存到最近使用列表
                                    saveEmojiToRecents(emoji)
                                }) {
                                    ZStack {
                                        Circle()
                                            .stroke(tempSelectedEmoji == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                                            .background(
                                                Circle()
                                                    .fill(tempSelectedEmoji == emoji ? 
                                                        Color(hex: backgroundColor).opacity(0.5) : Color.clear)
                                            )
                                            .frame(width: 52, height: 52)
                                        
                                        Text(emoji)
                                            .font(.system(size: 30))
                                    }
                                    .frame(width: 52, height: 52)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                    }
                } else {
                    // Text模式
                    VStack(spacing: 20) {
                        Text("输入文字")
                            .font(.headline)
                            .padding(.top, 20)
                        
                        TextField("输入文字", text: $textInput)
                            .font(.system(size: 28))
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                            .background(Color(hex: backgroundColor).opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                            .onChange(of: textInput) { newValue in
                                // 如果不为空，则预览第一个字符
                                if !newValue.isEmpty {
                                    let firstChar = String(newValue.prefix(1))
                                    tempSelectedEmoji = firstChar
                                }
                            }
                        
                        Text("将取第一个字符作为习惯图标")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitle("添加图标", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("确定") {
                    // 确认时才更新绑定值
                    if selectedTab == 1 && !textInput.isEmpty {
                        // 在Text模式下，只取第一个字符
                        selectedEmoji = String(textInput.prefix(1))
                    } else {
                        selectedEmoji = tempSelectedEmoji
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
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