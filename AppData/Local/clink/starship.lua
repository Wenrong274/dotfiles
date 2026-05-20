-- Starship prompt for CMD (via Clink)
-- Clink 啟動時自動載入此目錄下的 .lua 檔
load(io.popen('starship init cmd'):read("*a"))()
