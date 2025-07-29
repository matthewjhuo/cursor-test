# 📤 上傳到您的 GitHub 帳戶

本指南將協助您將 MX25L1605 SPI Flash 驗證環境上傳到您自己的 GitHub 帳戶。

## 🚀 自動化設定（推薦）

我們提供了一個自動化腳本來簡化整個過程：

```bash
./setup_github.sh
```

這個腳本會引導您完成所有步驟，包括：
- 檢查 Git 配置
- 輸入 GitHub 資訊
- 配置遠端倉庫
- 推送代碼

## 🛠️ 手動設定步驟

如果您偏好手動操作，請依照以下步驟：

### 步驟 1: 檢查 Git 配置

確保您已設定 Git 用戶資訊：

```bash
# 檢查現有配置
git config --global user.name
git config --global user.email

# 如果沒有設定，請執行
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 步驟 2: 在 GitHub 建立新倉庫

1. 前往 [GitHub](https://github.com) 並登入
2. 點擊右上角的 "+" 選擇 "New repository"
3. 填寫倉庫資訊：
   - **Repository name**: `mx25l1605-spi-flash-verification` (或您喜歡的名稱)
   - **Description**: `MX25L1605 SPI Flash SystemVerilog Verification Environment`
   - **Visibility**: Public (推薦) 或 Private
   - **⚠️ 重要**: 不要勾選 "Initialize this repository with README"
4. 點擊 "Create repository"

### 步驟 3: 配置本地倉庫

```bash
# 移除現有的遠端設定
git remote remove origin

# 添加您的 GitHub 倉庫 (替換 YOUR_USERNAME 和 REPO_NAME)
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# 確保在 main 分支
git checkout -b main

# 添加所有檔案
git add .

# 提交變更
git commit -m "feat: 初始化 MX25L1605 SPI Flash SystemVerilog 驗證環境

🎉 完整的驗證環境包含:
- SystemVerilog 測試組件 (介面、驅動器、監控器、記分板)  
- 多種測試案例 (ID測試、讀寫測試、iverilog相容測試)
- 完整的模擬工具鏈 (Makefile、腳本)
- 詳細的中文文檔和使用指南
- 支援所有主要 SPI Flash 命令
- iverilog 和進階 SystemVerilog 雙重相容

快速開始: cd verification/sim && ./quick_start.sh"
```

### 步驟 4: 推送到 GitHub

```bash
# 推送到您的 GitHub 倉庫
git push -u origin main
```

**注意**: 如果推送時要求認證，您可能需要：
- 輸入 GitHub 用戶名和密碼
- 或使用個人訪問令牌 (Personal Access Token)
- 或設定 SSH 金鑰

## 🔐 GitHub 認證設定

### 使用個人訪問令牌 (推薦)

1. 前往 GitHub Settings > Developer settings > Personal access tokens
2. 點擊 "Generate new token"
3. 選擇適當的權限 (至少需要 `repo` 權限)
4. 複製生成的令牌
5. 在推送時使用令牌作為密碼

### 使用 SSH 金鑰

```bash
# 生成 SSH 金鑰
ssh-keygen -t ed25519 -C "your.email@example.com"

# 添加到 ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 複製公鑰並添加到 GitHub
cat ~/.ssh/id_ed25519.pub

# 更改遠端 URL 為 SSH
git remote set-url origin git@github.com:YOUR_USERNAME/REPO_NAME.git
```

## ✅ 驗證上傳成功

上傳完成後，您可以：

1. 前往您的 GitHub 倉庫頁面
2. 確認所有檔案都已正確上傳
3. 檢查 README.md 是否正確顯示
4. 測試克隆功能：

```bash
# 在新的目錄測試克隆
git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
cd REPO_NAME
cd verification/sim
./quick_start.sh
```

## 🎨 優化您的 GitHub 倉庫

### 添加 Topics 標籤

在您的 GitHub 倉庫頁面：
1. 點擊右側的設定圖示 (齒輪)
2. 在 "Topics" 區域添加標籤：
   - `systemverilog`
   - `verification`
   - `spi`
   - `flash-memory`
   - `testbench`
   - `iverilog`

### 設定倉庫描述

在倉庫主頁，點擊 "Edit" 並添加描述：
```
🔧 Complete SystemVerilog verification environment for MX25L1605 SPI Flash memory, with iverilog compatibility and comprehensive test cases
```

### 釘選倉庫（可選）

如果這是您的重要專案，可以在 GitHub 個人頁面釘選此倉庫。

## 🆘 常見問題

### Q: 推送時出現 "Permission denied" 錯誤
**A**: 檢查您的 GitHub 認證設定，確保使用正確的用戶名和密碼/令牌。

### Q: 倉庫已存在錯誤
**A**: 確保您在 GitHub 上建立的是空倉庫，沒有初始化任何檔案。

### Q: 檔案沒有完全上傳
**A**: 檢查 `.gitignore` 檔案，確保重要檔案沒有被忽略。

### Q: 想要改變倉庫名稱
**A**: 在 GitHub 倉庫的 Settings 頁面可以重新命名倉庫。

---

## 📞 需要協助？

如果遇到任何問題，請：
1. 檢查 GitHub 的官方文檔
2. 確認網路連線正常
3. 驗證 Git 和 GitHub 設定

祝您順利上傳！🎉