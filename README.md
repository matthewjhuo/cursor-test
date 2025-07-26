# MX25L1605 SPI Flash 驗證環境

這是一個為 **MX25L1605** 16Mbit SPI Flash 記憶體模型建立的完整 SystemVerilog 驗證環境。該環境支援使用 iverilog 進行模擬，並提供多種測試案例來驗證 Flash 記憶體的各項功能。

## 專案結構

```
/workspace/
├── mx25L1605.v                    # DUT - MX25L1605 Flash 記憶體模型
├── README.md                      # 專案說明文件
└── verification/                  # 驗證環境
    ├── interfaces/                # 介面定義
    │   └── spi_interface.sv       # SPI 匯流排介面
    ├── utils/                     # 工具類別
    │   └── spi_transaction.sv     # SPI 交易類別
    ├── agents/                    # 驗證代理
    │   ├── spi_driver.sv         # SPI 驅動器
    │   └── spi_monitor.sv        # SPI 監控器
    ├── scoreboard/               # 記分板
    │   └── spi_scoreboard.sv     # 結果比較與統計
    ├── sequences/                # 測試序列
    │   └── basic_sequence.sv     # 基本測試序列
    ├── testbench/               # 測試平台
    │   └── spi_flash_tb.sv      # 主要測試平台
    ├── test_cases/              # 測試案例
    │   ├── test_basic_id.sv     # 基本 ID 測試
    │   └── test_write_read.sv   # 寫入讀取測試
    └── sim/                     # 模擬相關
        ├── Makefile             # 編譯與模擬控制
        └── run_simulation.sh    # 模擬執行腳本
```

## 功能特色

### 🔧 驗證環境特色
- **SystemVerilog 驗證環境**：採用現代化的驗證方法學
- **交易層建模**：抽象化的 SPI 交易處理
- **多層次測試**：從單元測試到整合測試
- **自動化記分板**：自動比較預期與實際結果
- **波形生成**：支援 VCD 格式波形輸出
- **模組化設計**：易於擴展和維護

### 📋 支援的 SPI 命令
- **Read ID (9Fh)**：讀取設備識別資訊
- **Read Status (05h)**：讀取狀態暫存器
- **Write Enable/Disable (06h/04h)**：寫入使能控制
- **Page Program (02h)**：頁面程式設計
- **Sector Erase (20h/D8h)**：扇區擦除 (4KB/64KB)
- **Chip Erase (60h/C7h)**：全晶片擦除
- **Read Data (03h/0Bh)**：一般讀取/快速讀取
- **Power Management (B9h/ABh)**：電源管理模式
- **4KB Mode (A5h/B5h)**：進入/退出 4KB 扇區模式

## 快速開始

### 1. 環境需求

確保系統已安裝以下工具：

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install iverilog gtkwave make

# CentOS/RHEL/Fedora
sudo yum install iverilog gtkwave make
# 或
sudo dnf install iverilog gtkwave make

# macOS (使用 Homebrew)
brew install icarus-verilog gtkwave make
```

### 2. 驗證安裝

```bash
# 檢查工具版本
iverilog -V
vvp -V
gtkwave --version
make --version
```

### 3. 執行測試

#### 使用模擬腳本（推薦）

```bash
# 進入模擬目錄
cd verification/sim

# 顯示說明
./run_simulation.sh --help

# 執行基本 ID 測試
./run_simulation.sh basic_id

# 執行寫入讀取測試
./run_simulation.sh write_read

# 執行所有測試
./run_simulation.sh all

# 執行測試並開啟波形
./run_simulation.sh -w basic_id

# 清理後執行測試
./run_simulation.sh -c -v all
```

#### 使用 Makefile

```bash
# 進入模擬目錄
cd verification/sim

# 顯示可用目標
make help

# 編譯所有測試
make compile

# 執行特定測試
make run_basic_id
make run_write_read
make run_main

# 執行所有測試
make run_all

# 開啟波形
make wave_basic_id

# 清理產生的檔案
make clean
```

## 測試案例說明

### 1. 基本 ID 測試 (test_basic_id.sv)

測試 Flash 記憶體的識別功能：

- **Read ID (9Fh)**：驗證製造商 ID、記憶體類型和密度
- **Read Manufacturer ID (90h)**：驗證製造商和設備 ID
- **Read Electronic ID (ABh)**：驗證電子識別碼

**預期結果**：
- 製造商 ID：0xC2 (MXIC)
- 記憶體類型：0x20
- 記憶體密度：0x15 (16Mbit)

### 2. 寫入讀取測試 (test_write_read.sv)

測試完整的寫入和讀取週期：

1. **Write Enable**：啟用寫入功能
2. **Page Program**：程式設計一整頁 (256 bytes) 資料
3. **Read Status**：檢查程式設計完成狀態
4. **Read Data**：讀取並驗證資料
5. **Fast Read**：使用快速讀取模式驗證

**測試模式**：使用 XOR 模式 (i ^ 0xA5) 產生測試資料

### 3. 主要測試平台 (spi_flash_tb.sv)

整合性測試平台，包含：

- **ID 和狀態檢查**
- **讀取操作測試**
- **寫入操作測試**
- **擦除操作測試**
- **電源管理測試**
- **混合操作測試**
- **壓力測試**

## 驗證方法學

### 驗證架構

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Sequence  │───▶│    Driver    │───▶│     DUT     │
│  Generator  │    │              │    │ (mx25L1605) │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
┌─────────────┐    ┌──────────────┐          │
│ Scoreboard  │◀───│   Monitor    │◀─────────┘
│             │    │              │
└─────────────┘    └──────────────┘
```

### 關鍵組件

1. **SPI Interface**：定義 SPI 匯流排信號和時序
2. **Transaction Class**：封裝 SPI 命令和資料
3. **Driver**：將交易轉換為實際的 SPI 時序
4. **Monitor**：監控並擷取 SPI 匯流排活動
5. **Scoreboard**：比較預期與實際結果

### 驗證覆蓋率

- **命令覆蓋率**：所有 SPI 命令
- **位址覆蓋率**：不同記憶體區域
- **資料模式覆蓋率**：各種資料模式
- **時序覆蓋率**：不同時序條件
- **錯誤情境覆蓋率**：異常操作測試

## 波形分析

### 查看波形

執行測試後會產生 VCD 檔案，可使用 GTKWave 查看：

```bash
# 自動開啟波形
./run_simulation.sh -w basic_id

# 手動開啟波形
gtkwave test_basic_id.vcd &
```

### 重要信號

- **spi_if.sclk**：SPI 時脈
- **spi_if.cs_n**：片選信號 (低電位有效)
- **spi_if.si**：串列資料輸入 (MOSI)
- **spi_if.so**：串列資料輸出 (MISO)
- **spi_if.wp_n**：寫入保護
- **spi_if.hold_n**：暫停信號

## 故障排除

### 常見問題

1. **編譯錯誤**
   ```bash
   # 檢查語法
   make lint
   
   # 檢查檔案路徑
   make debug
   ```

2. **模擬停止**
   ```bash
   # 檢查相依性
   ./run_simulation.sh --debug
   
   # 增加詳細輸出
   ./run_simulation.sh -v basic_id
   ```

3. **波形檔案未產生**
   ```bash
   # 檢查 VCD 檔案
   ls -la *.vcd
   
   # 確認測試完成
   make run_basic_id
   ```

### 調試技巧

1. **增加調試輸出**：在測試檔案中增加 `$display` 語句
2. **縮小測試範圍**：先執行簡單的測試案例
3. **檢查時序**：在波形中確認時脈和控制信號
4. **驗證資料**：比較預期與實際的資料值

## 擴展指南

### 添加新測試案例

1. **建立測試檔案**：
   ```bash
   cp verification/test_cases/test_basic_id.sv verification/test_cases/test_new.sv
   ```

2. **修改 Makefile**：
   ```makefile
   # 添加新的測試目標
   compile_new: test_new.vvp
   run_new: compile_new
       $(VVP) test_new.vvp
   ```

3. **更新模擬腳本**：
   ```bash
   # 在 run_simulation.sh 中添加新案例
   "new")
       run_make run_new
       ;;
   ```

### 添加新命令支援

1. **更新交易類別**：在 `spi_transaction.sv` 中添加新命令
2. **更新驅動器**：在 `spi_driver.sv` 中實作新命令
3. **更新監控器**：在 `spi_monitor.sv` 中添加監控邏輯
4. **更新記分板**：在 `spi_scoreboard.sv` 中添加檢查邏輯

## 授權

本專案採用 MIT 授權。詳細資訊請參閱 LICENSE 檔案。

## 貢獻

歡迎提交 Issue 和 Pull Request 來改善這個驗證環境。

---

**注意**：這個驗證環境是為教育和開發目的而建立，實際的產品驗證可能需要更多的測試案例和覆蓋率分析。