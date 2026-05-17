# DeepSeek Menubar

macOS 菜单栏应用，实时监控 DeepSeek API 账户余额与用量数据。

## 功能

- **余额监控** — 在菜单栏直接显示 DeepSeek API 账户余额，余额低于阈值时显示黄色警告
- **本月消费** — 查看当月 API 调用总消费金额
- **用量明细** — 按模型展示 Token 用量与 API 请求次数，支持展开查看各模型今日消费
- **自动刷新** — 按可配置的时间间隔自动刷新数据（默认 60 秒）
- **低余额提醒** — 余额低于设定阈值时菜单栏图标高亮警告
- **开机自启** — 可选开机自动启动
- **凭据安全** — API Key 和平台 Token 通过 macOS Keychain 加密存储
- **菜单栏便捷操作** — 一键刷新、跳转 Web 控制台、偏好设置

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本

## 安装

### 直接下载

从 Releases 页面下载 `DeepSeekMenubar.app`，拖入 Applications 文件夹即可。

首次打开可能需要右键 → 打开以绕过未签名应用的 Gatekeeper 限制。

### 自行编译

```bash
git clone https://github.com/<你的用户名>/DeepSeekMenubar.git
cd DeepSeekMenubar
chmod +x build-app.sh
./build-app.sh
```

编译产物为 `DeepSeekMenubar.app`，可直接运行。

## 初次使用

1. 启动应用后，在菜单栏点击钥匙图标
2. 输入你的 DeepSeek API Key（可在 [platform.deepseek.com](https://platform.deepseek.com) 获取）
3. 点击确认，菜单栏将显示当前余额

### 可选：配置消费数据

如需查看月度消费统计和模型用量详情：

1. 打开 [platform.deepseek.com](https://platform.deepseek.com) 并登录
2. 打开浏览器开发者工具（F12）
3. 进入 **Application** → **Local Storage** → 找到 `userToken` 的值
4. 在应用的偏好设置中粘贴该 Token

> **注意**：平台 Token 会过期，过期后需要重新获取。

## 使用说明

### 菜单栏

- 正常状态：显示当前余额数字
- 低余额状态：显示黄色三角警告图标 + 余额
- 加载中：显示 `···`
- 未配置：显示钥匙图标

### 主界面

- **账户余额**：当前可用余额
- **本月消费**：当月总消费金额
- **用量明细**：点击展开各模型的 Token 用量和请求次数
- **刷新**：手动立即刷新所有数据
- **View on Web**：在浏览器中打开 DeepSeek 控制台

### 偏好设置

- **API Key**：DeepSeek API 密钥
- **平台 Token**（可选）：用于获取消费数据
- **刷新间隔**：15–300 秒可调
- **低余额阈值**：0–50 元可调
- **开机自启**：开关

## 技术栈

- Swift 5.9 + SwiftUI
- macOS 14+ (MenuBarExtra API)
- Observation 框架（iOS 17+ / macOS 14+ 响应式编程）
- Keychain Services（凭据加密存储）
- SMAppService（开机自启管理）
- URLSession（网络请求）

## 项目结构

```
DeepSeekMenubar/
├── Package.swift              # Swift 包配置
├── build-app.sh               # 一键编译脚本
├── DeepSeekMenubar.app/       # 预编译应用包
└── Sources/DeepSeekMenubar/
    ├── DeepSeekMenubarApp.swift    # 应用入口与菜单栏布局
    ├── AppViewModel.swift          # 核心状态管理与数据刷新
    ├── Models/
    │   ├── BalanceInfo.swift       # 余额响应模型
    │   └── MonthlyCost.swift       # 消费与用量模型
    ├── Services/
    │   ├── DeepSeekAPIService.swift # DeepSeek API 网络层
    │   ├── KeychainManager.swift    # Keychain 凭据管理
    │   └── PreferencesManager.swift # 用户偏好设置管理
    └── Views/
        ├── MainContentView.swift    # 主界面
        ├── SetupView.swift          # 首次配置界面
        ├── SettingsView.swift       # 偏好设置界面
        └── BalanceCard.swift        # 余额与消费卡片组件
```

## API 说明

应用调用两个 DeepSeek 接口：

| 接口 | 用途 | 认证方式 |
|------|------|---------|
| `api.deepseek.com/user/balance` | 查询账户余额 | API Key (Bearer Token) |
| `platform.deepseek.com/api/v0/usage/cost` | 查询月度消费 | 平台 Token (Bearer Token) |
| `platform.deepseek.com/api/v0/usage/amount` | 查询用量明细 | 平台 Token (Bearer Token) |

## License

MIT
