import SwiftUI

// 习惯排序视图
struct HabitSortView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @State private var habits: [Habit] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    HStack {
                        Text(habit.emoji)
                            .font(.title2)
                            .padding(.trailing, 8)
                        
                        Text(habit.name)
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                }
                .onMove { from, to in
                    habits.move(fromOffsets: from, toOffset: to)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("排序习惯".localized(in: .contentView))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消".localized(in: .common)) {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存".localized(in: .common)) {
                        saveHabitOrder()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                habits = habitStore.habits
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func saveHabitOrder() {
        // 保存新的习惯顺序到HabitStore
        habitStore.updateHabitOrder(habits)
    }
} 