#!/bin/bash

# MX25L1605 驗證環境 GitHub 設定腳本
# 幫助您將專案上傳到自己的 GitHub 帳戶

echo "🚀 MX25L1605 驗證環境 - GitHub 設定助手"
echo "=========================================="
echo ""

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}📋 步驟 $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 步驟 1: 檢查 Git 配置
print_step "1" "檢查 Git 配置"
if ! git config --global user.name > /dev/null 2>&1; then
    print_warning "請先設定您的 Git 用戶名："
    echo "git config --global user.name \"Your Name\""
    exit 1
fi

if ! git config --global user.email > /dev/null 2>&1; then
    print_warning "請先設定您的 Git 電子郵件："
    echo "git config --global user.email \"your.email@example.com\""
    exit 1
fi

USER_NAME=$(git config --global user.name)
USER_EMAIL=$(git config --global user.email)
print_success "Git 配置正確: $USER_NAME <$USER_EMAIL>"

echo ""

# 步驟 2: 獲取 GitHub 資訊
print_step "2" "輸入您的 GitHub 資訊"

echo "請輸入您的 GitHub 用戶名："
read -p "> " GITHUB_USERNAME

echo "請輸入您想要的倉庫名稱 (建議: mx25l1605-spi-flash-verification)："
read -p "> " REPO_NAME

if [ -z "$GITHUB_USERNAME" ] || [ -z "$REPO_NAME" ]; then
    print_error "用戶名和倉庫名稱不能為空"
    exit 1
fi

GITHUB_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo ""
print_success "GitHub 倉庫地址: $GITHUB_URL"

# 步驟 3: 建立 GitHub 倉庫指引
print_step "3" "建立 GitHub 倉庫"
echo "請在 GitHub 網站上建立新倉庫："
echo ""
echo -e "${YELLOW}1. 前往 https://github.com/new${NC}"
echo -e "${YELLOW}2. 倉庫名稱: ${REPO_NAME}${NC}"
echo -e "${YELLOW}3. 描述: MX25L1605 SPI Flash SystemVerilog Verification Environment${NC}"
echo -e "${YELLOW}4. 設為 Public (推薦) 或 Private${NC}"
echo -e "${YELLOW}5. 不要初始化 README, .gitignore 或 LICENSE (我們已經有了)${NC}"
echo -e "${YELLOW}6. 點擊 'Create repository'${NC}"
echo ""

read -p "完成後請按 Enter 繼續..."

# 步驟 4: 配置遠端倉庫
print_step "4" "配置遠端倉庫"

# 移除現有的 origin
if git remote get-url origin > /dev/null 2>&1; then
    git remote remove origin
    print_success "移除舊的 origin 設定"
fi

# 添加新的 origin
git remote add origin "$GITHUB_URL"
print_success "添加新的 origin: $GITHUB_URL"

# 步驟 5: 準備推送
print_step "5" "準備推送代碼"

# 確保在 main 分支
git checkout -b main 2>/dev/null || git checkout main

# 添加所有檔案
git add .

# 檢查是否有變更需要提交
if git diff --cached --quiet; then
    print_warning "沒有需要提交的變更"
else
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

    print_success "代碼已提交"
fi

# 步驟 6: 推送到 GitHub
print_step "6" "推送到 GitHub"

echo "現在將推送代碼到您的 GitHub 倉庫..."
echo "您可能需要輸入 GitHub 密碼或個人訪問令牌"
echo ""

if git push -u origin main; then
    print_success "代碼推送成功！"
else
    print_error "推送失敗，請檢查："
    echo "1. GitHub 倉庫是否已正確建立"
    echo "2. 您的 GitHub 認證是否正確"
    echo "3. 網路連線是否正常"
    echo ""
    echo "您也可以手動推送："
    echo "git push -u origin main"
    exit 1
fi

# 成功完成
echo ""
echo "🎉 成功！您的 MX25L1605 驗證環境已上傳到 GitHub"
echo "=================================================="
echo ""
echo -e "${GREEN}📍 您的專案地址:${NC}"
echo "   https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo ""
echo -e "${GREEN}🚀 快速開始指令:${NC}"
echo "   git clone https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
echo "   cd ${REPO_NAME}"
echo "   cd verification/sim"
echo "   ./quick_start.sh"
echo ""
echo -e "${GREEN}📚 下一步建議:${NC}"
echo "1. 在 GitHub 上添加詳細的專案描述"
echo "2. 設定 Topics 標籤: systemverilog, verification, spi, flash-memory"
echo "3. 考慮添加 GitHub Actions 自動化測試"
echo "4. 邀請協作者或設為開源專案"
echo ""
echo "感謝使用 MX25L1605 驗證環境！🎊"