local M = {}
local function ShowLexusVIPMenu()
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end

        local function Step_ScamAlert()
            local Msg = require("client.slua.logic.common.logic_common_msg_box")
            if Msg and Msg.Show then
                -- Deteksi bahasa
                local lang = _G.LexusLang or "ID"

                -- Title
                local title = lang == "EN"
                    and "MOD USAGE PERIOD HAS ENDED"
                    or "MASA PENGGUNAAN MOD TELAH BERAKHIR"

                -- Content
                local content = lang == "EN"
                    and
                    "YOUR MOD VERSION HAS EXPIRED!\n\nPlease contact admin for extension.\n\n Telegram: @ZENKOADMIN\n WhatsApp: 085147804573\n\n If someone sold this to you besides me, you have been scammed!"
                    or
                    "VERSI MOD ANDA TELAH KADALUARSA!\n\nSilakan inbox admin untuk diperpanjang.\n\n Inbox Tele: @ZENKOADMIN\n WA: 085147804573\n\n Jika Ada Seseorang Yang Telah Menjual Barang Ini Kepada Anda Selain Saya, Maka Selamat Anda Telah Tertipu!"

                -- Button
                local btn1 = lang == "EN" and "CONTACT" or "INBOX"
                local btn2 = lang == "EN" and "CLOSE" or "TUTUP"

                Msg.Show(1, title, content,
                    function()
                        local Web = require("client.slua.logic.url.logic_webview_sdk")
                        if Web and Web.OpenURL then
                            Web:OpenURL("https://t.me/ZENKOADMIN")
                        end
                    end,
                    function() end,
                    btn1, btn2
                )
            end
        end


        local function Step_SelectLanguage()
            Msg.Show(2, "SELECT LANGUAGE / PILIH BAHASA",
                "Please select your preferred language.\nSilakan pilih bahasa yang ingin Anda gunakan.",
                function()
                    _G.LexusLang = "ID"
                    Step_ScamAlert()
                end,
                function()
                    _G.LexusLang = "EN"
                    Step_ScamAlert()
                end, "BAHASA INDONESIA", "ENGLISH")
        end

        Step_SelectLanguage()
    end)
end


function M.Run(beginPlaySelf)
    ShowLexusVIPMenu()
end

return M
