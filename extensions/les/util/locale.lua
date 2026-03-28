--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-- Localization table for English and Japanese.
-- Access strings via the global L("key") function.

local strings = {
  en = {
    -- Shared buttons
    btn_ok          = "Ok",
    btn_yes         = "Yes",
    btn_no          = "No",
    btn_cancel      = "Cancel",
    btn_reset_time  = "Reset Time",

    -- Menu bar items
    menu_console              = "Console",
    menu_restart              = "Restart",
    menu_open_hs_folder       = "Open Hammerspoon Folder",
    menu_search_plugins       = "Search Plugins...",
    menu_project_notes        = "Project Notes...",
    menu_settings             = "Settings...",
    menu_scan_plugins         = "Scan Plugins...",
    menu_force_rescan         = "Force Full Rescan...",
    menu_configure_menu       = "Configure Menu",
    menu_configure_settings   = "Configure Settings (Raw)",
    menu_donate               = "Donate",
    menu_project_time         = "Project Time",
    menu_strict_time          = "Strict Time",
    menu_reload               = "Reload",
    menu_install_insertwhere  = "Install InsertWhere",
    menu_manual               = "Manual 📖",
    menu_exit                 = "Exit",
    menu_ai_assistant         = "AI Assistant...",
    menu_ai_recommend         = "AI Plugin Suggestions...",
    menu_ai_namegen           = "AI Project Name Suggestions...",
    menu_language             = "言語: 日本語",  -- shows option to switch TO Japanese

    -- Plugin chooser
    chooser_not_loaded   = "Plugin menu is not loaded yet",
    chooser_no_plugins   = "No plugins found in menuconfig.ini",

    -- Plugin menu
    plugin_readme        = "read me",
    menuconfig_missing   = "Your menuconfig.ini is missing or corrupt.\n\nDo you want to restore the default menuconfig?",

    -- Welcome / readme
    readme_body = "@InvertedSilence, @DirectOfficial による Live Enhancement Suite macOS rewrite. Installer by @actuallyjamez 🐦.\n\nDouble right click to open up the custom plug-in menu.\n\nClick on the LES logo in the menu bar to add your own plug-ins, change settings, and read our manual.\n\nHappy producing : )",

    -- Accessibility permission
    accessibility_system_settings     = "System Settings > Privacy & Security > Accessibility",
    accessibility_system_preferences  = "System Preferences > Security & Privacy > Privacy > Accessibility",
    -- %1=programName, %2=asyNavPath, %3=programName (unused)
    accessibility_alert = "Please grant accessibility permissions by navigating to %s and enabling it for \"%s\".\n\nIf it isn't already present, please drag and drop the application to the allowlist.",

    -- Version check
    -- %1=programName, %2=minVer, %3=maxVer, %4=curVer, %5=progName, %6=programBugTracker
    version_fail = "%s is only validated to run between %s and %s and is currently being run on %s.\n\nThe program may behave in an undefined manner and may cause disruption but will continue running until prompted to exit.\n\nIf you believe this is in error or that the program must be updated to support a newer release of %s, please file an issue at %s.",
    version_disable_query = "Would you like to disable startup version verification on future launches?\n\nYou can choose to configure this in the future by editing settings.ini and changing the value of \"checksanity\"",

    -- Settings
    settings_startup_query  = "You're all set! Would you like to set LES to launch on login? (this can be changed later)",
    settings_pianoroll_error = "Hey! The settings entry for \"pianorollmacro\" is not a character corresponding to a key on your keyboard.\n\nClosing this dialog box will open the settings file for you; please change the character under \"pianorollmacro\" to a key that exists on your keyboard and then restart the program.\n\nYou won't be able to properly use many features without it.\n\nLES will continue to run without a proper pianoroll macro mapped.",

    -- VST scaling
    macros_scaling_error = "If you're seeing this, it means that Midas didn't properly think about the way VST plugins deal with scaling at your current display resolution.\n\nPerhaps you have the plugin (or your OS) set to a custom scaling amount?\n\nIt is recommended to disable the VST specific shortcuts in the settings.ini if you want to continue to use custom scaling.\n\nThese shortcuts will be disabled until LES is reloaded.",

    -- Project time
    timer_no_project_title  = "There was no open project detected.",
    timer_no_project_detail = "Please open or focus Live for a second and try again.",
    timer_zero              = "0 hours, 0 minutes, and 0 seconds",
    timer_format            = "%d hours, %d minutes, and %02d seconds",
    timer_unsaved_project   = "Time spent in unsaved projects:",
    timer_project           = "Time spent inside the [%s] project:",
    timer_reset_title       = "Are you sure?",
    timer_reset_detail      = "This action cannot be undone",

    -- InsertWhere
    insertwhere_query = "InsertWhere is a Max For Live companion device developed by Mat Zo.\n\nInsertWhere allows you to change the position where plugins are autoinserted after using the LES plugin menu.\n\nOnce loaded, it will allow you to switch between these settings:\n\n- Autoadd plugins before the one you have selected\n- Autoadd plugins after the the one you have selected\n- Always autoadd plugins at the end of the chain like normal\n\nTo activate InsertWhere, place a single instance of the device on the master channel in your project and choose your desired setting.\n\nDo you want to install the InsertWhere M4L plugin?",
    insertwhere_location_alert  = "Please select the location where you want LES to extract the InsertWhere companion plugin.\n\nRecommended: Ableton User Library",
    insertwhere_folder_dialog   = "Please select the location to extract InsertWhere:",
    insertwhere_success = "Success!!\n\nFor extra ease of use, include InsertWhere in your default template.\n\nFor more information on InsertWhere, visit the documentation website linked under the \"Manual 📖\" button in the tray.\n\nThank you Mat Zo for making this amazing device!",

    -- Cheat menu
    cheat_title  = "A mysterious aura surrounds you...",
    cheat_prompt = "Enter cheat",

    -- AppleScript
    rightclick_sleep_error = "applescript sleep failed to execute properly",

    -- Jumpstart (LESmain)
    jumpstart_mismatch          = "LES has detected a mismatched jumpstart script.\n\nThis may be because you're upgrading from an older version of LES, if so, this is normal. Would you like to repair your jumpstart script?",
    jumpstart_success           = "LES has successfully repaired the jumpstart script. Please restart LES for these changes to apply.",
    jumpstart_failure           = "LES was unable to repair the jumpstart script. Please check permissions for ~/.les or clear the directory and try again.",
    jumpstart_continue_warning  = "LES cannot guarantee that it will behave as tested. Would you like to exit LES?",
  },

  ja = {
    -- Shared buttons
    btn_ok          = "OK",
    btn_yes         = "はい",
    btn_no          = "いいえ",
    btn_cancel      = "キャンセル",
    btn_reset_time  = "時間をリセット",

    -- Menu bar items
    menu_console              = "コンソール",
    menu_restart              = "再起動",
    menu_open_hs_folder       = "Hammerspoon フォルダを開く",
    menu_search_plugins       = "プラグインを検索...",
    menu_project_notes        = "プロジェクトノート...",
    menu_settings             = "設定...",
    menu_scan_plugins         = "プラグインをスキャン...",
    menu_force_rescan         = "強制フルスキャン...",
    menu_configure_menu       = "メニュー設定を編集",
    menu_configure_settings   = "設定を直接編集 (Raw)",
    menu_donate               = "寄付する",
    menu_project_time         = "プロジェクト作業時間",
    menu_strict_time          = "厳密な時間計測",
    menu_reload               = "再読み込み",
    menu_install_insertwhere  = "InsertWhere をインストール",
    menu_manual               = "マニュアル 📖",
    menu_exit                 = "終了",
    menu_ai_assistant         = "AI アシスタント...",
    menu_ai_recommend         = "AI プラグイン提案...",
    menu_ai_namegen           = "AI プロジェクト名提案...",
    menu_language             = "Language: English",  -- shows option to switch TO English

    -- Plugin chooser
    chooser_not_loaded   = "プラグインメニューがまだ読み込まれていません",
    chooser_no_plugins   = "menuconfig.ini にプラグインが見つかりません",

    -- Plugin menu
    plugin_readme       = "はじめに",
    menuconfig_missing  = "menuconfig.ini が見つからないか破損しています。\n\nデフォルトの menuconfig を復元しますか？",

    -- Welcome / readme
    readme_body = "@InvertedSilence、@DirectOfficial による Live Enhancement Suite macOS リライト版へようこそ。インストーラーは @actuallyjamez 制作です 🐦。\n\nダブル右クリックでカスタムプラグインメニューを開けます。\n\nメニューバーの LES ロゴをクリックして、プラグインの追加、設定の変更、マニュアルの閲覧ができます。\n\nHappy producing : )",

    -- Accessibility permission
    accessibility_system_settings     = "システム設定 > プライバシーとセキュリティ > アクセシビリティ",
    accessibility_system_preferences  = "システム環境設定 > セキュリティとプライバシー > プライバシー > アクセシビリティ",
    -- %1=programName, %2=asyNavPath, %3=programName (unused)
    accessibility_alert = "「%s」にアクセシビリティの権限を付与してください。%s に移動して有効にしてください。\n\nリストにない場合は、アプリをドラッグ＆ドロップで許可リストに追加してください。",

    -- Version check
    -- %1=programName, %2=minVer, %3=maxVer, %4=curVer, %5=progName, %6=programBugTracker
    version_fail = "%s は macOS %s から macOS %s の間でのみ動作が検証されていますが、現在 macOS %s で実行されています。\n\nこのプログラムは予期しない動作をしたり、問題を引き起こす可能性がありますが、終了を求められるまで動作を継続します。\n\nこれが誤りであると思われる場合、またはより新しい macOS バージョンへの対応が必要な場合は、%s の issue トラッカーに報告してください: %s",
    version_disable_query = "今後の起動時にバージョン確認を無効にしますか？\n\nこの設定は、settings.ini を編集して \"checksanity\" の値を変更することで、後から変更できます。",

    -- Settings
    settings_startup_query  = "設定が完了しました！ログイン時に LES を自動起動しますか？（後から変更できます）",
    settings_pianoroll_error = "設定ファイルの \"pianorollmacro\" にキーボード上に存在しない文字が設定されています。\n\nこのダイアログを閉じると設定ファイルが開きます。\"pianorollmacro\" の値をキーボード上に存在するキーに変更して、プログラムを再起動してください。\n\nこの設定がないと多くの機能が正常に使用できません。\n\nLES はピアノロールマクロなしで動作を継続します。",

    -- VST scaling
    macros_scaling_error = "現在のディスプレイ解像度では、VST プラグインのスケーリングが正しく認識できませんでした。\n\nプラグインまたは OS にカスタムスケーリングが設定されている可能性があります。\n\nカスタムスケーリングを使用し続ける場合は、settings.ini で VST 専用ショートカットを無効にすることをお勧めします。\n\nこれらのショートカットは LES を再読み込みするまで無効になります。",

    -- Project time
    timer_no_project_title  = "開いているプロジェクトが見つかりませんでした。",
    timer_no_project_detail = "Live を開くか、フォーカスしてからもう一度試してください。",
    timer_zero              = "0時間 0分 0秒",
    timer_format            = "%d時間 %d分 %02d秒",
    timer_unsaved_project   = "未保存プロジェクトの作業時間:",
    timer_project           = "[%s] プロジェクトの作業時間:",
    timer_reset_title       = "本当にリセットしますか？",
    timer_reset_detail      = "この操作は元に戻せません",

    -- InsertWhere
    insertwhere_query = "InsertWhere は Mat Zo が開発した Max For Live コンパニオンデバイスです。\n\nInsertWhere を使うと、LES プラグインメニューからプラグインを自動挿入する際の位置を変更できます。\n\nロード後、以下の設定を切り替えられます:\n\n- 選択中のプラグインの前に自動挿入\n- 選択中のプラグインの後に自動挿入\n- 通常通り常にチェーンの末尾に自動挿入\n\nInsertWhere を有効にするには、プロジェクトのマスターチャンネルにデバイスを1つ配置し、希望する設定を選んでください。\n\nInsertWhere M4L プラグインをインストールしますか？",
    insertwhere_location_alert  = "InsertWhere コンパニオンプラグインの展開先を選択してください。\n\n推奨: Ableton ユーザーライブラリ",
    insertwhere_folder_dialog   = "InsertWhere の展開先を選択してください:",
    insertwhere_success = "インストール完了！\n\nより使いやすくするために、デフォルトテンプレートに InsertWhere を含めることをお勧めします。\n\nInsertWhere の詳細については、トレイの「マニュアル 📖」ボタンからドキュメントサイトをご覧ください。\n\n素晴らしいデバイスを作ってくれた Mat Zo に感謝！",

    -- Cheat menu
    cheat_title  = "不思議なオーラに包まれた...",
    cheat_prompt = "チートコードを入力",

    -- AppleScript
    rightclick_sleep_error = "AppleScript のスリープ処理に失敗しました",

    -- Jumpstart (LESmain)
    jumpstart_mismatch          = "LES が起動スクリプトの不一致を検出しました。\n\n旧バージョンからアップグレード中の場合は正常です。起動スクリプトを修復しますか？",
    jumpstart_success           = "起動スクリプトの修復が完了しました。変更を反映するには LES を再起動してください。",
    jumpstart_failure           = "起動スクリプトの修復に失敗しました。~/.les のアクセス権限を確認するか、ディレクトリを削除してから再試行してください。",
    jumpstart_continue_warning  = "LES の動作を保証できません。LES を終了しますか？",
  },
}

--- Global localization function.
--- Returns the UI string for `key` in the current language (_G.uiLanguage).
--- Falls back to Japanese, then to the key itself if not found.
function L(key)
  local lang = _G.uiLanguage or "ja"
  local t = strings[lang] or strings["ja"]
  local s = t[key]
  if s == nil then
    s = strings["ja"][key]
  end
  return s or key
end
