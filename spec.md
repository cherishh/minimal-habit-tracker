# 技术文档 - iCloud 同步功能

**1. 概述**

本技术文档描述了 habit track 应用中 iCloud 同步功能的实现方案，该方案采用 Apple 的 CloudKit 框架。

**2. 技术选型**

* **CloudKit:** 作为主要的云端数据存储和同步解决方案。

**3. 数据模型在 CloudKit 中的设计**

我们将应用中的核心数据实体映射到 CloudKit 的 Record 类型。

* **Habit (CKRecord Type: `Habit`)**
    * `recordID`: CKRecord.ID (用于唯一标识习惯)
    * `name`: String (习惯名称)
    * `emoji`: String (习惯的 Emoji 图标)
    * `colorTheme`: String (颜色主题名称，对应 `Habit.ColorThemeName` 的 rawValue)
    * `habitType`: String (习惯类型，对应 `Habit.HabitType` 的 rawValue，值为 "Checkbox" 或 "Count")
    * `createdAt`: Date (创建时间)
    * `backgroundColor`: String? (Emoji 的可选背景色，十六进制格式)
    * `maxCheckInCount`: Int64 (用户自定义的打卡次数上限，默认为 5)
    * `updatedAt`: Date (最后更新时间 - *建议：在 `Habit` 结构体中添加此字段，以便追踪更新*)
    * `isArchived`: Bool (是否已归档 - *预留字段暂不实现*)

* **HabitLog (CKRecord Type: `HabitLog`)**
    * `recordID`: CKRecord.ID (用于唯一标识打卡记录)
    * `habit`: CKRecord.Reference (关联的 Habit 记录)
    * `date`: Date (打卡日期，具体到秒)
    * `count`: Int64 (打卡次数)
    * `createdAt`: Date (创建时间 - *建议：在 `HabitLog` 结构体中添加此字段，以便追踪创建时间*)
    * `updatedAt`: Date (最后更新时间 - *建议：在 `HabitLog` 结构体中添加此字段，以便追踪更新时间*)

**4. 同步逻辑**

**4.1 初始化同步 (PRO 用户首次启用或重装后)**

* 当用户购买 PRO 版本后，应用应检查用户是否已登录 iCloud 账户。
* 应用应查询 CloudKit 中是否存在当前用户 ID 相关的 `Habit` 和 `HabitLog` 记录。
* 如果存在记录，则提示用户。如果用户选择恢复数据，则从 CloudKit 拉取所有数据并更新本地数据库。
* 如果恢复失败，允许用户重试，或删除 icloud 中数据。
* 如果用户选择不恢复，则删除 icloud 中数据，并正常启动应用并允许用户创建新的习惯。用户新建习惯后，会自动同步到 icloud。
* 如果不存在记录，则本地数据作为初始数据，并在后续操作中同步到 CloudKit。

**4.2 实时同步 (数据变更)**

* **监听 CloudKit 变化:** 使用 `CKSubscription` 来订阅 `Habit` 和 `HabitLog` 记录的创建、更新和删除事件。
    * 可以创建基于 Record Type 的 Subscription，监听所有该类型的变化。
    * 也可以创建基于用户 ID 的 Subscription，只监听当前用户创建或修改的记录。
* **处理 CloudKit 通知:** 当 CloudKit 有数据变化时，会通过推送通知告知设备。应用收到通知后，应使用 `CKFetchRecordChangesOperation` 来获取具体的变更内容。
* **更新本地数据:** 根据获取到的变更内容（新增、修改、删除的记录），更新本地 Core Data 或其他持久化存储。
* **同步本地变化到 CloudKit:** 当用户在本地创建、修改或删除习惯或进行打卡操作时，应用应将这些变更保存到 CloudKit。
    * 使用 `CKModifyRecordsOperation` 来保存或删除记录。

**5. 处理首次安装与重装恢复**

* **首次安装:** 正常启动流程，不进行额外的 iCloud 查询。
* **卸载后重装:**
    * 在应用启动时，首先触发 in-app purchase 的恢复购买流程。
    * 监听恢复购买流程的结果。
    * **只有当恢复购买成功，并且应用确认用户拥有 PRO 版本后，** 才继续执行以下步骤：
        * 尝试获取用户的 CloudKit User ID。
        * 使用 User ID 查询 Private Database 中是否存在 `Habit` 和 `HabitLog` 记录。
        * 如果存在记录，则显示正在恢复数据的提示，并开始拉取数据。
    * 如果恢复购买成功，但 CloudKit 上没有找到数据，则将本次启动视为 PRO 用户的首次使用。
    * 在恢复购买流程进行期间，可以在 UI 上显示一个加载指示器或提示信息，例如 "正在检查您的 PRO 版本状态..."。

**6. 数据冲突处理**

* 当本地对某个 `Habit` 或 `HabitLog` 记录的修改与从 CloudKit 获取到的该记录的修改发生冲突时（通常是由于两个设备在离线状态下同时修改了同一条记录），`CKModifyRecordsOperation` 会返回一个错误，指示存在冲突。
* **检测冲突:** 在 `CKModifyRecordsOperation` 的 completion block 中检查是否存在 `CKError.serverRecordChanged` 错误。
* **获取冲突版本:** 如果存在冲突，可以从错误信息中获取到服务器端的记录 (`serverRecord`) 和客户端的记录 (`clientRecord`)。
* **提示用户并提供选择:**
    * 弹出一个警告框或显示一个页面，告知用户存在数据冲突。
    * 展示本地版本和云端版本的相关信息（例如最后更新时间，或者关键属性的差异）。
    * 提供两个按钮供用户选择：
        * **保留本地版本:** 将本地版本强制覆盖云端版本。需要重新尝试保存本地记录到 CloudKit，这次可以设置 `force` 选项为 true。
        * **保留云端版本:** 放弃本地修改，使用从云端获取的版本更新本地数据。
* **更新:** 根据用户的选择执行相应的操作。

**7. 错误处理**

* 在进行 CloudKit 操作时，需要处理可能发生的各种错误，例如网络连接问题、iCloud 账户未登录、配额限制等。
* 对于同步失败的情况，应在设置页面显示错误信息，并建议用户检查网络连接或 iCloud 账户状态。
* 可以考虑使用指数退避算法来重试失败的同步操作。

**8. 安全性**

* CloudKit 使用用户的 iCloud 账户进行身份验证和授权，确保用户只能访问自己的数据。
* 数据在传输过程中会进行加密。
* 应用只需要访问用户的 Private Database，其他应用无法访问。

**9. 部署方案**

* 该功能将在 PRO 版本中启用。
* 在发布新版本后，PRO 用户首次启动应用时，会自动开始初始化同步过程（包括恢复购买）。
* 建议在应用更新日志中明确说明新增的 iCloud 同步功能及其使用方法。


**关于 `HabitLog` 的更新说明:**

* `habit` 字段在 CloudKit 中应该存储为 `CKRecord.Reference` 类型，指向对应的 `Habit` 记录。你需要确保在保存 `HabitLog` 时正确创建这个引用。这通常需要在保存 `HabitLog` 之前先保存 `Habit` 记录，并获取其 `CKRecord.ID`。
* `date` 字段建议只存储日期部分，不包含具体的时间，以方便按天查询和统计。
* `count` 字段对应 `HabitLog` 结构体中的 `count` 属性，存储打卡次数。
* `level` 是一个计算属性，不需要存储在 CloudKit 中。你可以在客户端根据 `count` 的值计算得到。
* 我再次建议在 `HabitLog` 结构体中添加 `createdAt` 和 `updatedAt` 字段，以便更好地进行数据追踪和冲突解决。
