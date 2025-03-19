import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    @State private var showingImporter = false
    @State private var showingShareSheet = false
    @State private var csvTempFileURL: URL?
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var duplicateIds: [String] = []
    @Environment(\.colorScheme) var colorScheme
    @State private var isGeneratingCSV = false
    @State private var cleanupTimer: Timer?
    @State private var exportCompleted = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("选择要执行的操作")
                    .font(.headline)
                    .padding(.top, 20)
                
                Spacer()
                
                VStack(spacing: 20) {
                    // 导出按钮
                    actionButton(
                        icon: "file-up",
                        title: "导出数据",
                        description: "将您的所有习惯和打卡记录导出为标准CSV文件，可用于备份",
                        action: exportData,
                        disabled: isGeneratingCSV || csvTempFileURL == nil
                    )
                    
                    // 导入按钮
                    actionButton(
                        icon: "file-down",
                        title: "导入数据",
                        description: "从CSV文件导入习惯和打卡记录，用于恢复备份或迁移数据",
                        action: { showingImporter = true },
                        disabled: false
                    )
                }
                .padding(.horizontal)
                
                if isGeneratingCSV {
                    ProgressView("准备导出数据中...")
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("导入 & 导出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet, onDismiss: {
                // 用户关闭分享表单时处理临时文件
                handleShareSheetDismiss()
            }) {
                if let url = csvTempFileURL {
                    ShareSheet(activityItems: [url], completionWithItemsHandler: { (activityType, completed, _, _) in
                        exportCompleted = completed
                    })
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        loadCSVFile(from: url)
                    }
                case .failure:
                    alertMessage = "导入失败，请重试。"
                    showingAlert = true
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            }
            .onAppear {
                // 视图出现时预先生成CSV文件
                generateCSVFile()
            }
            .onDisappear {
                // 视图消失时清理临时文件和取消定时器
                invalidateTimer()
                cleanupTempFile()
            }
        }
    }
    
    // 创建大按钮
    private func actionButton(icon: String, title: String, description: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(disabled ? .gray : .blue)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(disabled ? .gray : .primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(disabled ? .gray : .secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(disabled ? .gray : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(disabled ? 0.05 : 0.1))
            )
            .opacity(disabled ? 0.7 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
    }
    
    // 处理分享表单关闭
    private func handleShareSheetDismiss() {
        invalidateTimer() // 取消之前的定时器
        
        if exportCompleted {
            // 如果已完成导出，立即删除临时文件
            cleanupTempFile()
        } else {
            // 如果用户只是关闭分享表单但未完成导出，1分钟后删除临时文件
            cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
                cleanupTempFile()
            }
        }
        
        // 重置导出状态
        exportCompleted = false
    }
    
    // 取消定时器
    private func invalidateTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    // 在视图显示时预先生成CSV文件
    private func generateCSVFile() {
        isGeneratingCSV = true
        
        // 在后台线程处理文件生成
        DispatchQueue.global(qos: .userInitiated).async {
            // 创建CSV内容
            var csvString = "habit_id,habit_name,emoji,date,check_in_count,max_count,habit_type,color_theme\n"
            
            // 收集所有习惯的ID，用于创建打卡记录
            let habitsDict = habitStore.habits.reduce(into: [UUID: Habit]()) { dict, habit in
                dict[habit.id] = habit
            }
            
            // 为每一条打卡记录生成一行CSV
            for log in habitStore.habitLogs {
                if let habit = habitsDict[log.habitId] {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: log.date)
                    
                    // 格式化为CSV行，确保包含引号以处理特殊字符
                    let line = "\"\(habit.id.uuidString)\",\"\(habit.name)\",\"\(habit.emoji)\",\"\(dateString)\",\"\(log.count)\",\"\(habit.maxCheckInCount)\",\"\(habit.habitType.rawValue)\",\"\(habit.colorTheme.rawValue)\"\n"
                    csvString.append(line)
                }
            }
            
            // 如果没有习惯数据，添加一行示例数据
            if csvString.split(separator: "\n").count <= 1 {
                csvString += "\"00000000-0000-0000-0000-000000000000\",\"示例习惯\",\"📝\",\"2023-01-01\",\"1\",\"1\",\"Checkbox\",\"GitHub\"\n"
            }
            
            // 将CSV内容写入临时文件
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "习惯数据_\(formattedDate()).csv"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                
                // 在主线程更新UI状态
                DispatchQueue.main.async {
                    csvTempFileURL = fileURL
                    isGeneratingCSV = false
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "创建导出文件失败：\(error.localizedDescription)"
                    showingAlert = true
                    isGeneratingCSV = false
                }
            }
        }
    }
    
    // 清理临时文件
    private func cleanupTempFile() {
        if let url = csvTempFileURL {
            try? FileManager.default.removeItem(at: url)
            csvTempFileURL = nil
        }
    }
    
    private func exportData() {
        // 直接显示分享表单，因为CSV文件已经在视图出现时生成好了
        if csvTempFileURL != nil {
            showingShareSheet = true
        } else {
            // 如果文件不存在，重新生成
            generateCSVFile()
            alertMessage = "正在准备数据，请稍后重试"
            showingAlert = true
        }
    }
    
    private func loadCSVFile(from url: URL) {
        do {
            // 安全访问文件
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // 读取CSV文件内容
            let csvData = try String(contentsOf: url, encoding: .utf8)
            let rows = csvData.components(separatedBy: "\n")
            
            // 验证CSV文件格式
            guard rows.count > 1 else {
                alertMessage = "导入文件为空或格式不正确"
                showingAlert = true
                return
            }
            
            // 验证标题行
            let headers = parseCSVLine(rows[0])
            let expectedHeaders = ["habit_id", "habit_name", "emoji", "date", "check_in_count", "max_count", "habit_type", "color_theme"]
            
            guard headers.count == expectedHeaders.count,
                  headers.enumerated().allSatisfy({ expectedHeaders[$0.offset] == $0.element }) else {
                alertMessage = "CSV文件格式不正确，请确保包含正确的列标题"
                showingAlert = true
                return
            }
            
            // 收集现有习惯ID
            let existingHabitIds = Set(habitStore.habits.map { $0.id.uuidString })
            var importedHabits: [Habit] = []
            var importedLogs: [HabitLog] = []
            duplicateIds = []
            
            // 解析每一行数据
            for i in 1..<rows.count {
                let row = rows[i]
                guard !row.isEmpty else { continue }
                
                let columns = parseCSVLine(row)
                guard columns.count == expectedHeaders.count else {
                    alertMessage = "CSV文件格式不正确，第\(i+1)行数据不完整"
                    showingAlert = true
                    return
                }
                
                // 解析数据
                let habitIdString = columns[0]
                guard let habitId = UUID(uuidString: habitIdString) else {
                    alertMessage = "无效的习惯ID格式：\(habitIdString)"
                    showingAlert = true
                    return
                }
                
                let habitName = columns[1]
                let emoji = columns[2]
                
                // 解析日期
                let dateString = columns[3]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let date = dateFormatter.date(from: dateString) else {
                    alertMessage = "无效的日期格式：\(dateString)"
                    showingAlert = true
                    return
                }
                
                // 解析打卡次数
                guard let checkInCount = Int(columns[4]) else {
                    alertMessage = "无效的打卡次数：\(columns[4])"
                    showingAlert = true
                    return
                }
                
                // 解析最大打卡次数
                guard let maxCount = Int(columns[5]) else {
                    alertMessage = "无效的最大打卡次数：\(columns[5])"
                    showingAlert = true
                    return
                }
                
                // 解析习惯类型
                let habitTypeString = columns[6]
                guard let habitType = Habit.HabitType(rawValue: habitTypeString) else {
                    alertMessage = "无效的习惯类型：\(habitTypeString)"
                    showingAlert = true
                    return
                }
                
                // 解析颜色主题
                let colorThemeString = columns[7]
                guard let colorTheme = Habit.ColorThemeName(rawValue: colorThemeString) else {
                    alertMessage = "无效的颜色主题：\(colorThemeString)"
                    showingAlert = true
                    return
                }
                
                // 检查ID是否重复
                if existingHabitIds.contains(habitIdString) {
                    // 记录重复的ID
                    if !duplicateIds.contains(habitIdString) {
                        duplicateIds.append(habitIdString)
                    }
                    continue // 跳过重复的ID
                }
                
                // 创建或更新习惯
                if !importedHabits.contains(where: { $0.id == habitId }) {
                    let habit = Habit(
                        id: habitId,
                        name: habitName,
                        emoji: emoji,
                        colorTheme: colorTheme,
                        habitType: habitType,
                        maxCheckInCount: maxCount
                    )
                    importedHabits.append(habit)
                }
                
                // 创建打卡记录
                let log = HabitLog(habitId: habitId, date: date, count: checkInCount)
                importedLogs.append(log)
            }
            
            // 检查是否有重复ID
            if !duplicateIds.isEmpty {
                alertMessage = "导入数据中有\(duplicateIds.count)个习惯ID与现有习惯重复：\(duplicateIds.joined(separator: ", "))"
                showingAlert = true
                return
            }
            
            // 将导入的习惯和打卡记录添加到存储中
            importedHabits.forEach { habitStore.addHabit($0) }
            
            for log in importedLogs {
                let calendar = Calendar.current
                let existingLogs = habitStore.habitLogs.filter { existingLog in
                    existingLog.habitId == log.habitId && calendar.isDate(existingLog.date, inSameDayAs: log.date)
                }
                
                if existingLogs.isEmpty {
                    habitStore.habitLogs.append(log)
                }
            }
            
            // 保存数据
            habitStore.saveDataForExport()
            
            alertMessage = "成功导入\(importedHabits.count)个习惯和\(importedLogs.count)条打卡记录！"
            showingAlert = true
            
        } catch {
            alertMessage = "读取CSV文件失败：\(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // 解析CSV行，处理引号内的逗号
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        result.append(currentField)
        return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    // 格式化当前日期为文件名
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}

// 用于实现分享功能的UIViewControllerRepresentable
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.completionWithItemsHandler = completionWithItemsHandler
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 不需要更新
    }
}

// 用于文件导出的文档类型
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var data: String
    
    init(data: String) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(data.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

extension UTType {
    static let commaSeparatedText = UTType(importedAs: "public.comma-separated-values-text")
} 
