-- Starship prompt for CMD (via Clink)
-- Clink 啟動時自動載入此目錄下的 .lua 檔
-- Guard：starship 不在 PATH 時略過，避免 CMD/Clink 啟動報錯
-- io.popen 與 load() 的回傳值都會驗證，避免異常輸出導致啟動失敗
local where_h = io.popen('where starship 2>nul')
local found   = where_h and where_h:read('*a') or ''
if where_h then where_h:close() end

if found ~= '' then
    local init_h = io.popen('starship init cmd')
    if init_h then
        local chunk = init_h:read('*a')
        init_h:close()
        if chunk and chunk ~= '' then
            local fn, _err = load(chunk)
            if fn then fn() end
        end
    end
end
