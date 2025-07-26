#!/bin/bash

# MX25L1605 驗證環境快速開始腳本
# Quick Start Script for MX25L1605 Verification Environment

echo "🚀 MX25L1605 SPI Flash 驗證環境 - 快速開始"
echo "============================================="
echo ""

# 檢查依賴
echo "📦 檢查依賴項目..."
if ! command -v iverilog &> /dev/null; then
    echo "❌ iverilog 未安裝"
    echo "請執行: sudo apt-get install iverilog"
    exit 1
fi

if ! command -v make &> /dev/null; then
    echo "❌ make 未安裝"
    echo "請執行: sudo apt-get install make"
    exit 1
fi

echo "✅ 所有依賴項目已安裝"
echo ""

# 編譯測試
echo "🔨 編譯簡化測試..."
make clean > /dev/null 2>&1
if make compile_simple > /dev/null 2>&1; then
    echo "✅ 編譯成功"
else
    echo "❌ 編譯失敗，請檢查錯誤訊息"
    make compile_simple
    exit 1
fi

echo ""

# 執行測試
echo "🧪 執行基本功能測試..."
echo "----------------------------------------"
make run_simple

# 檢查結果
if [ -f "simple_basic_test.vcd" ]; then
    echo ""
    echo "🌊 波形檔案已生成: simple_basic_test.vcd"
    
    if command -v gtkwave &> /dev/null; then
        echo "💡 提示: 執行 'make wave_simple' 可開啟波形檢視器"
    else
        echo "💡 提示: 安裝 gtkwave 可查看波形"
        echo "   sudo apt-get install gtkwave"
    fi
fi

echo ""
echo "🎯 快速開始完成！"
echo ""
echo "📚 更多選項:"
echo "   make help           - 顯示所有可用指令"
echo "   make info           - 顯示專案資訊"
echo "   ./run_simulation.sh --help - 顯示執行腳本說明"
echo ""
echo "🔗 相關檔案:"
echo "   README.md           - 完整使用說明"
echo "   CHANGELOG.md        - 版本變更記錄"
echo ""