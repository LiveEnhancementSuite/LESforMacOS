# LESforMacOS Custom — アーキテクチャドキュメント

> 開発者向けの内部設計ドキュメントです。
> GUI の仕組み、モジュール構成、データフローを解説します。

## 目次

- [GUI アーキテクチャ](#gui-アーキテクチャ)
- [3層 UI 構造](#3層-ui-構造)
- [ネイティブ UI 層（Objective-C + XIB）](#ネイティブ-ui-層objective-c--xib)
- [Hammerspoon Lua API 層](#hammerspoon-lua-api-層)
- [イベント駆動層（hs.eventtap）](#イベント駆動層hseventtap)
- [モジュール構成とデータフロー](#モジュール構成とデータフロー)
- [起動シーケンス](#起動シーケンス)
- [プラグインメニュー構築フロー](#プラグインメニュー構築フロー)
- [キーストローク処理パイプライン](#キーストローク処理パイプライン)
- [アプリケーション監視](#アプリケーション監視)
- [パフォーマンス設計](#パフォーマンス設計)

---

## GUI アーキテクチャ

LES の GUI は独自のウィンドウを描画せず、macOS 標準の UI コンポーネントを Lua スクリプトから呼び出す構成です。

```mermaid
graph TB
    subgraph "ネイティブ UI 層（Objective-C + XIB）"
        A1[MainMenu.xib<br/>アプリメニュー]
        A2[ConsoleWindow.xib<br/>デバッグコンソール]
        A3[PreferencesWindow.xib<br/>設定ウィンドウ]
        A4[MJMenuIcon.m<br/>NSStatusItem]
    end

    subgraph "Hammerspoon Lua API 層"
        B1["hs.menubar<br/>LES メニューバー"]
        B2["hs.menubar (不可視)<br/>プラグインメニュー"]
        B3["hs.menubar (不可視)<br/>ピアノロールメニュー"]
        B4["hs.dialog<br/>ダイアログ・アラート"]
        B5["hs.alert<br/>画面上通知"]
    end

    subgraph "イベント駆動層"
        C1["hs.eventtap<br/>キーボード監視"]
        C2["hs.eventtap<br/>マウス監視"]
        C3["hs.application.watcher<br/>アプリ監視"]
        C4["hs.timer<br/>1秒タイマー"]
    end

    C1 --> B1
    C2 -->|ダブル右クリック| B2
    C2 -->|Shift+ダブル右クリック| B3
    C1 -->|Cmd+Shift+1| B5
    C3 --> B1
    A4 --> B1
```

---

## 3層 UI 構造

### 各層の役割

```mermaid
graph LR
    subgraph "Layer 1: ネイティブ"
        direction TB
        N1[XIB レイアウト]
        N2[Objective-C コントローラー]
        N3[AppKit フレームワーク]
        N1 --> N2 --> N3
    end

    subgraph "Layer 2: Lua API"
        direction TB
        L1[Lua テーブル定義]
        L2[Hammerspoon API 呼び出し]
        L3[macOS メニュー/ダイアログ]
        L1 --> L2 --> L3
    end

    subgraph "Layer 3: イベント"
        direction TB
        E1[システムイベント取得]
        E2[ディスパッチテーブル]
        E3[UI トリガー / マクロ実行]
        E1 --> E2 --> E3
    end

    N3 -.->|LuaSkin ブリッジ| L2
    E3 -.->|メニュー表示| L2
```

| 層 | 技術 | 用途 | 変更頻度 |
|----|------|------|---------|
| ネイティブ UI | Objective-C + XIB | コンソール、設定、アプリメニュー | ほぼ変更なし |
| Lua API | Hammerspoon Lua API | LES メニュー、ダイアログ、通知 | 機能追加時 |
| イベント駆動 | hs.eventtap / hs.timer | キー監視、マウス監視、タイマー | ショートカット追加時 |

---

## ネイティブ UI 層（Objective-C + XIB）

Hammerspoon コアが提供する GUI で、LES からは直接変更しません。

### ファイル構成

```mermaid
graph TD
    subgraph "Hammerspoon/"
        X1["MainMenu.xib"] -->|NSMenu| D1["MJAppDelegate.m<br/>アプリライフサイクル"]
        X2["ConsoleWindow.xib"] -->|NSPanel + NSTextView| D2["MJConsoleWindowController.m<br/>Lua REPL"]
        X3["PreferencesWindow.xib"] -->|NSPanel + チェックボックス| D3["MJPreferencesWindowController.m<br/>設定 UI"]
        D4["MJMenuIcon.m"] -->|NSStatusItem| D1
    end
```

### 主要コンポーネント

| ファイル | クラス | UI 要素 |
|---------|--------|---------|
| `MainMenu.xib` | — | アプリケーションメニュー（About, Preferences, Edit, Help） |
| `ConsoleWindow.xib` | `MJConsoleWindowController` | Lua 実行コンソール（入力欄 + 出力ビュー） |
| `PreferencesWindow.xib` | `MJPreferencesWindowController` | 設定パネル（起動時起動、Dock アイコン、コンソール常前面） |
| `MJMenuIcon.m` | `MJMenuIcon` | ステータスバーのアイコン（NSStatusItem） |
| `MJAppDelegate.m` | `MJAppDelegate` | アプリ起動・終了、URL スキーム、Dock クリック処理 |

### コンソールウィンドウの詳細

```mermaid
sequenceDiagram
    participant U as ユーザ
    participant TF as NSTextField (入力)
    participant TV as NSTextView (出力)
    participant LS as LuaSkin (Lua実行)

    U->>TF: Lua コードを入力
    TF->>LS: 文字列を評価
    LS->>TV: 結果を色分け表示
    Note over TV: コマンド → 黒<br/>戻り値 → 青<br/>stdout → オレンジ
    TV->>TV: 0.2秒バッファリングで描画
```

- 最大 100,000 行の履歴を保持
- 出力は 0.2 秒のバッファリングで描画パフォーマンスを確保
- ダーク/ライトモード対応（NSAppearance）

---

## Hammerspoon Lua API 層

LES のユーザ向け GUI の中心。全て Lua テーブルで定義し、Hammerspoon API でレンダリングします。

### メニューバーの構造

```mermaid
graph TD
    MB["LESmenubar<br/>hs.menubar.new()"] -->|setMenu| GT["getMenuBar()"]
    GT --> DBG{enabledebug?}
    DBG -->|Yes| D1["Console"]
    DBG -->|Yes| D2["Restart"]
    DBG -->|Yes| D3["Open Hammerspoon Folder"]
    DBG -->|Yes| D4["---"]
    DBG -->|No/Yes| U1["Configure Menu"]
    GT --> U2["Configure Settings"]
    GT --> U3["Donate"]
    GT --> U4["Project Time"]
    GT --> U5["Strict Time ☑"]
    GT --> U6["Reload"]
    GT --> U7["Install InsertWhere"]
    GT --> U8["Manual"]
    GT --> U9["Exit"]

    MB -->|setIcon| ICON["osxTrayIcon.png"]
    MB -->|setTitle| TEXT["'LES'<br/>texticon=1の場合"]
```

### 不可視メニューバーによるコンテキストメニュー

LES の最も特徴的な GUI パターンです。

```mermaid
graph LR
    subgraph "作成時"
        A["hs.menubar.new()"] --> B["setMenu(menu)"]
        B --> C["removeFromMenuBar()"]
    end

    subgraph "表示時（ダブル右クリック）"
        D["hs.eventtap が検出"] --> E["popupMenu(mousePos)"]
        E --> F["macOS ネイティブメニューが表示"]
    end

    C -.->|メニューバーから消えるが<br/>メモリには残る| E
```

```lua
-- 作成（起動時に1回）
pluginMenu = hs.menubar.new()
pluginMenu:setMenu(menu)            -- Lua テーブルからメニュー生成
pluginMenu:removeFromMenuBar()      -- メニューバーから非表示

-- 表示（ダブル右クリック時）
pluginMenu:popupMenu(hs.mouse.absolutePosition())
```

**なぜこの方式か？**
- Hammerspoon にはネイティブのコンテキストメニュー API がない
- `hs.menubar` の `popupMenu()` を使えば任意の座標にメニューを表示できる
- macOS 標準のメニュー描画を利用するため、見た目が自然

### ダイアログとアラート

```mermaid
graph TD
    subgraph "LES ヘルパー関数"
        H1["HSMakeAlert(title, msg)"] -->|内部| D1["hs.dialog.blockAlert()"]
        H2["HSMakeQuery(title, msg)"] -->|内部| D2["hs.dialog.blockAlert()<br/>→ boolean 返却"]
        H3["astBlockingQuery()"] -->|内部| D3["hs.osascript.applescript()<br/>AppleScript ダイアログ"]
    end

    subgraph "直接使用"
        D4["hs.dialog.textPrompt()<br/>テキスト入力"]
        D5["hs.dialog.chooseFileOrFolder()<br/>ファイル選択"]
        D6["hs.alert.show()<br/>画面上フローティング通知"]
    end
```

| 関数 | 用途 | ブロッキング |
|------|------|------------|
| `HSMakeAlert()` | 情報表示 | Yes |
| `HSMakeQuery()` | Yes/No 確認 → boolean | Yes |
| `astBlockingQuery()` | Live フォーカス中の確認 | Yes（AppleScript 経由） |
| `hs.dialog.textPrompt()` | テキスト入力（チートメニュー） | Yes |
| `hs.dialog.chooseFileOrFolder()` | フォルダ選択（InsertWhere） | Yes |
| `hs.alert.show()` | 画面上通知（一時停止通知など） | No（自動消去） |

---

## イベント駆動層（hs.eventtap）

全てのユーザ入力はイベントタップで捕捉し、ディスパッチテーブルで振り分けます。

### eventtap の全体像

```mermaid
graph TD
    subgraph "アクティブな eventtap"
        ET1["quickmacro<br/>keyDown, keyUp,<br/>leftMouseDown, leftMouseUp"]
        ET2["firstRightClick<br/>rightMouseDown,<br/>rightMouseUp"]
        ET3["modifierHandler<br/>keyDown, keyUp,<br/>flagsChanged"]
        ET4["pausebutton<br/>Cmd+Shift+1"]
        ET5["dingodango<br/>flagsChanged<br/>(debug のみ)"]
    end

    subgraph "条件付き eventtap"
        ET6["keyhandlerevent<br/>leftMouseDown/Up,<br/>rightMouseDown<br/>(ピアノマクロ中のみ)"]
    end

    ET1 -->|キーコード| DP["keyDispatch テーブル<br/>O(1) ルックアップ"]
    ET2 -->|ダブル検出| PM["プラグインメニュー表示"]
    ET3 -->|マクロキー検出| ET6
    ET4 -->|トグル| DIS["disablemacros() /<br/>enablemacros()"]
    ET5 -->|Shift×2| CM["チートメニュー"]
```

### eventtap のライフサイクル

```mermaid
stateDiagram-v2
    [*] --> 全停止 : LES 起動時
    全停止 --> 全有効 : Ableton Live にフォーカス<br/>(enablemacros)
    全有効 --> 全停止 : 他のアプリにフォーカス<br/>(disablemacros)
    全有効 --> 一時停止 : Cmd+Shift+1
    一時停止 --> 全有効 : Cmd+Shift+1

    state 全有効 {
        [*] --> quickmacro
        [*] --> firstRightClick
        [*] --> modifierHandler
        [*] --> pausebutton
        quickmacro --> keyhandlerevent : ピアノマクロキー押下
        keyhandlerevent --> quickmacro : キー離す
    }
```

---

## モジュール構成とデータフロー

### モジュール依存関係

```mermaid
graph TD
    MAIN["LESmain.lua<br/>オーケストレーター"] --> MOD["module.lua<br/>バージョン検証"]
    MAIN --> HELP["helpers.lua<br/>ファイル操作"]
    MAIN --> PROC["proccom.lua<br/>Live 検出"]
    MAIN --> SET["settings.lua<br/>設定管理"]

    MAIN --> MB["menus/bar.lua<br/>メニューバー定義"]
    MAIN --> MK["menus/keys/menu.lua<br/>スケール/コード"]
    MAIN --> MP["menus/plugin.lua<br/>プラグインメニュー構築"]

    MAIN --> LR["lifecycle/reload.lua<br/>リロード処理"]
    MAIN --> LA["lifecycle/appwatch.lua<br/>アプリ監視"]

    MAIN --> SM["shortcuts/macros.lua<br/>キーマクロ"]
    MAIN --> SR["shortcuts/rightclick.lua<br/>右クリックメニュー"]
    MAIN --> SP["shortcuts/piano.lua<br/>ピアノマクロ"]
    MAIN --> VS["vst/shortcuts.lua<br/>VST ショートカット"]

    MAIN --> TT["tracking/timer.lua<br/>時間追跡"]

    MAIN --> GC["globals/constants.lua"]
    MAIN --> GF["globals/filepaths.lua"]
    MAIN --> US["util/string.lua"]
    MAIN --> UI["util/io.lua"]

    LR -->|reloadLES()| MP
    LR -->|reloadLES()| MB
    LA -->|enablemacros()| SM
    LA -->|enablemacros()| SR
    LA -->|enablemacros()| SP
    TT -->|VST検出| VS

    style MAIN fill:#e1f5fe
    style SM fill:#fff3e0
    style MP fill:#fff3e0
    style LA fill:#fff3e0
```

---

## 起動シーケンス

```mermaid
sequenceDiagram
    participant HS as Hammerspoon
    participant LM as LESmain.lua
    participant MOD as module.lua
    participant SET as settings.lua
    participant PM as plugin.lua
    participant AW as appwatch.lua

    HS->>LM: require("LESmain")
    LM->>LM: ジャンプスタートスクリプト検証
    LM->>MOD: module:init()
    MOD->>MOD: macOS / Live バージョン検証
    MOD->>MOD: アクセシビリティ権限確認
    LM->>SET: settingsManager:init()
    LM->>PM: reloadLES()
    PM->>PM: menuconfig.ini パース
    PM->>PM: buildPluginMenu()
    PM->>PM: buildMenuBar()
    PM->>PM: rebuildRcMenu()
    LM->>AW: appwatcher:start()
    AW->>AW: disablemacros()（初期状態）
    Note over AW: Live がフォーカスされるまで<br/>全ショートカット無効
```

---

## プラグインメニュー構築フロー

1200件のプラグインを menuconfig.ini からパースしてメニューに変換する処理です。

```mermaid
graph TD
    A["menuconfig.ini を読み込み"] --> B["全行を配列に格納"]
    B --> C["配列を逆順に"]
    C --> D["前処理ループ"]

    D --> D1["em-dash → -- に変換"]
    D --> D2["空行・コメント行を除去"]
    D --> D3["Readme 行をフラグ化"]

    D --> E["カテゴリ解析ループ"]
    E --> E1["/名前 → レベル1フォルダ"]
    E --> E2["//名前 → レベル2+フォルダ"]
    E --> E3[".. → 1つ上の階層へ"]
    E --> E4["/nocategory → ルートへ"]
    E --> E5["その他 → プラグインエントリ"]

    E --> F["pluginArray 生成<br/>'レベル, カテゴリ名, プラグイン名'"]

    F --> G["メニューテーブル構築ループ"]
    G --> G1["レベル比較で<br/>スコープ上昇/下降/維持を判定"]
    G --> G2["_G[カテゴリ名] にテーブル作成"]
    G --> G3["loadPlugin() を fn に設定"]

    G --> H["menu テーブル完成"]
    H --> I["hs.menubar:setMenu(menu)"]

    style A fill:#e8f5e9
    style H fill:#e8f5e9
    style I fill:#e1f5fe
```

---

## キーストローク処理パイプライン

```mermaid
graph LR
    A["macOS キーイベント"] --> B["hs.eventtap<br/>(quickmacro)"]
    B --> C["キーコード取得"]
    C --> D{"keyDispatch[code]<br/>にハンドラある？"}
    D -->|いいえ| E["イベントを通過"]
    D -->|はい| F["修飾キーを1回取得<br/>checkKeyboardModifiers()"]
    F --> G["ハンドラを順次実行"]
    G --> H{"イベントを消費？"}
    H -->|はい| I["return true<br/>Ableton に渡さない"]
    H -->|いいえ| E
```

---

## アプリケーション監視

```mermaid
graph TD
    AW["hs.application.watcher"] -->|activated / deactivated| CHECK{"isHsAppObjLive(app)?"}
    CHECK -->|No| IGNORE["無視（非 Live アプリ）"]
    CHECK -->|Yes| FOCUS{"focusedWindow の<br/>アプリ == Live?"}

    FOCUS -->|Yes かつ macros 無効| ENABLE["enablemacros()<br/>clock:start()<br/>キャッシュ無効化"]
    FOCUS -->|No かつ macros 有効| DISABLE["disablemacros()<br/>clock:stop() (Strict時)"]

    AW -->|terminated| QUIT["clock:stop()<br/>coolfunc() で時間保存"]
```

---

## パフォーマンス設計

### ホットパスと最適化

```mermaid
graph TD
    subgraph "🔴 最高頻度（毎キーストローク）"
        HP1["quickmacro eventtap<br/>→ ディスパッチテーブル O(1)"]
        HP2["modifierHandler eventtap<br/>→ イベント型定数キャッシュ"]
    end

    subgraph "🟠 高頻度（毎右クリック）"
        HP3["firstRightClick eventtap<br/>→ タイムスタンプ比較のみ"]
    end

    subgraph "🟡 中頻度（毎秒）"
        HP4["timerfunc<br/>→ タイマーキーキャッシュ<br/>→ VST タイトル変更検出"]
    end

    subgraph "🟢 低頻度（アプリ切替時）"
        HP5["appwatch<br/>→ focusedWindow() 1回呼び出し<br/>→ Live アプリのみキャッシュ無効化"]
    end

    subgraph "🔵 最低頻度（リロード時）"
        HP6["buildPluginMenu<br/>→ ローカル関数キャッシュ<br/>→ 直接インデックス代入<br/>→ デバッグ出力除去"]
    end
```

### キャッシュ戦略

| キャッシュ | TTL | 無効化タイミング | 対象 |
|-----------|-----|----------------|------|
| `getLiveHsAppObj()` | 2秒 | アプリフォーカス変更時 | `hs.application.find()` の結果 |
| `getTimerKey()` | 永続 | なし | `"timer_" .. name` の文字列連結 |
| `vstWindowState` | 永続 | タイトル変更時 | VST ウィンドウのタイトル |
| `keyhandlerevent` | 永続 | なし | ピアノマクロ用 eventtap インスタンス |
| `gValidTitleTable` | セッション | `enablemacros()` 時に再構築 | Live メニュー項目テーブル |
