# 變更記錄

本檔案記錄了專案的所有重大變更。

格式基於 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/)，
並且本專案遵循 [語義化版本](https://semver.org/lang/zh-TW/)。

## [1.0.0] - 2024-07-26

### 新增
- 🎉 初始版本發布
- 📁 完整的驗證環境目錄結構
- 🔧 SystemVerilog 驗證組件
  - SPI 介面定義 (`spi_interface.sv`)
  - SPI 交易類別 (`spi_transaction.sv`)
  - SPI 驅動器 (`spi_driver.sv`)
  - SPI 監控器 (`spi_monitor.sv`)
  - 記分板 (`spi_scoreboard.sv`)
  - 測試序列 (`basic_sequence.sv`)
- 📋 多種測試案例
  - 基本 ID 測試 (`test_basic_id.sv`)
  - 寫入讀取測試 (`test_write_read.sv`)
  - 簡化測試 (`simple_basic_test.sv`) - iverilog 相容
- 🛠️ 完整的模擬工具鏈
  - Makefile 編譯控制
  - Shell 腳本執行介面 (`run_simulation.sh`)
  - 記憶體初始化檔案 (`init.dat`)
- 📖 詳細的說明文件
  - 完整的 README.md
  - 使用說明和範例
  - 故障排除指南
- ✅ 支援的 SPI 命令
  - Read ID (9Fh)
  - Read Status (05h)  
  - Write Enable/Disable (06h/04h)
  - Page Program (02h)
  - Sector Erase (20h/D8h)
  - Chip Erase (60h/C7h)
  - Read Data (03h/0Bh)
  - Power Management (B9h/ABh)

### 技術特色
- 🔀 雙重相容性：SystemVerilog 進階功能 + 標準 Verilog (iverilog)
- 📊 自動化測試和結果報告
- 🌊 VCD 波形檔案生成
- 🏗️ 模組化設計，易於擴展
- 📈 詳細的調試輸出和監控

### 測試覆蓋率
- ✅ 基本設備識別功能
- ✅ 狀態暫存器操作
- ✅ 寫入使能控制
- ✅ SPI 通訊時序
- ✅ 錯誤處理機制

## [未來計劃]

### 待新增功能
- [ ] 更多進階測試案例
  - [ ] 邊界條件測試
  - [ ] 電源管理完整測試
  - [ ] 平行模式測試
  - [ ] 4KB 模式測試
- [ ] 覆蓋率分析工具整合
- [ ] 更多模擬器支援
  - [ ] ModelSim
  - [ ] Vivado Simulator
  - [ ] Verilator
- [ ] CI/CD 整合
- [ ] 性能測試框架
- [ ] 自動化報告生成

### 改進項目
- [ ] 最佳化模擬性能
- [ ] 增強錯誤檢測
- [ ] 改進使用者介面
- [ ] 增加更多範例

---

**圖例：**
- 🎉 重大功能
- 📁 檔案結構
- 🔧 核心組件  
- 📋 測試相關
- 🛠️ 工具
- 📖 文件
- ✅ 功能支援
- 🔀 相容性
- 📊 分析工具
- 🌊 除錯功能
- 🏗️ 架構
- 📈 監控