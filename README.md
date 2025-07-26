# cursor-test

# 驗證環境資料夾結構

- tb/         # 測試平台 (testbench) 及測試案例 (testcase)
- sv_utils/   # SystemVerilog 驗證輔助元件 (如 interface, driver, monitor, scoreboard)
- build/      # 編譯與模擬產生的中間檔

# 使用 iverilog 進行模擬

```sh
iverilog -g2012 -o build/tb_mx25L1605 tb/tb_mx25L1605.sv mx25L1605.v sv_utils/*.sv
evince build/tb_mx25L1605
```