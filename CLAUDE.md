# CLAUDE.md — LESforMacOS Custom プロジェクトコンテキスト

> このファイルは [Claude Code](https://claude.ai/code) がプロジェクトを理解するためのコンテキストです。
> [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) のプラクティスに基づいています。

## プロジェクト概要

LESforMacOS Custom は [Live Enhancement Suite](https://github.com/LiveEnhancementSuite/LESforMacOS) のフォークです。App名は **Live Enhancement Suite Custom** です。Hammerspoon（macOS 自動化フレームワーク）上で動作する Lua スクリプトにより、Ableton Live の操作を拡張します。

## アーキテクチャ

```
extensions/les/           # LES コアロジック（Lua 5.4）
├── LESmain.lua           # エントリーポイント（オーケストレーター）
├── module.lua            # バージョン検証・初期化
├── helpers.lua           # ファイル操作ヘルパー（純Lua I/O）
├── proccom.lua           # Live プロセス検出・メニュー操作
├── settings.lua          # 設定管理システム
├── globals/              # 定数・パス定義
├── menus/                # メニューバー UI
├── shortcuts/            # キーボードショートカット・マクロ
│   └── macros.lua        # ディスパッチテーブル方式のイベント処理
├── lifecycle/            # アプリ起動・リロード管理
├── tracking/             # タイマー・使用時間追跡
├── vst/                  # VST プラグイン操作
├── util/                 # 文字列・IO ユーティリティ
└── tests/                # busted テストスイート
Hammerspoon/              # コアアプリケーション（Objective-C）
LuaSkin/                  # Lua ランタイムラッパー
├── lua-5.4.7/            # 組み込み Lua
```

## 言語・技術スタック

| 技術 | バージョン | 用途 |
|------|-----------|------|
| Lua | 5.4.7 | LES スクリプトロジック |
| Objective-C | C17 | Hammerspoon コア |
| C++ | C++17 | LuaSkin・ネイティブ拡張 |
| Python | 3.x | ドキュメント生成 (Jinja2) |
| Xcode | 14.1+ | ビルドシステム |

## ビルドコマンド

```bash
# macOS ビルド
pod install
xcodebuild -workspace Hammerspoon.xcworkspace -scheme Hammerspoon \
  -configuration Debug GCC_TREAT_WARNINGS_AS_ERRORS=NO clean build

# Lua テスト（Docker）
docker build -f Dockerfile.test -t les-test . && docker run --rm les-test

# Lua 静的解析
luacheck extensions/les/
```

## コーディング規約

### Lua

- **グローバル変数**: Hammerspoon のアーキテクチャ上、モジュール間通信にグローバルを使用。`.luacheckrc` で明示的に定義すること
- **型アノテーション**: LuaLS 形式の `---@param` / `---@return` を使用
- **関数スコープ**: モジュール内でのみ使用する関数は `local function` にする
- **文字列ライブラリ**: 変数名に `string` を使わない（標準ライブラリを上書きする）
- **テーブルインデックス**: Lua は 1-indexed。`for i = 1, #t` を使用
- **ファイル操作**: シェルコマンドより純 Lua I/O（`io.open`）や `hs.fs` を優先
- **最大行長**: 150 文字

### Objective-C / C++

- コンパイル標準: C17 (`gnu17`) / C++17 (`gnu++17`)
- デバッグビルド: `dwarf` 形式（ビルド速度優先）
- リリースビルド: `dwarf-with-dsym` 形式（クラッシュレポート用）

## テスト

- フレームワーク: [busted](https://github.com/lunarmodules/busted)（BDD スタイル）
- テストファイル命名: `*_spec.lua`
- `hs` API は `rawset(_G, "hs", mock)` でモック化
- Docker で実行可能（macOS ローカル環境を汚さない）

## 重要な設計判断

1. **ディスパッチテーブル**: `shortcuts/macros.lua` のキー処理は O(1) ルックアップテーブルを使用
2. **メモ化キャッシュ**: `proccom.lua` の `getLiveHsAppObj()` は 2 秒 TTL、`getValidTitles()` は 60 秒 TTL でキャッシュ
3. **シェル依存排除**: `helpers.lua` のファイル操作は全て純 Lua + `hs.fs` で実装（`ShellExec` のみ残存）
4. **モジュール分割**: 旧 `LESmain.lua`（1908行）を機能別に 8 モジュールへ分割
5. **非同期 UI**: `astSleep()`（AppleScript `delay`）の代わりに `hs.timer.doAfter()` を使用。メインスレッドをブロックしない
6. **カテゴリ名前空間**: プラグインカテゴリは `_G._pluginCategories` に格納（`_G` 直接汚染を回避）
7. **設定の統合テーブル**: `_G.LES_CONFIG` で全設定値を一括参照可能（`_G.key` との後方互換性を維持）

## よくある落とし穴

- `hs.*` API は Hammerspoon ランタイム内でのみ利用可能（テスト時はモック必須）
- `io.popen` / `ShellExec` は `/bin/sh` 経由で実行される（`popen(3)` は常に `sh` を使う。macOS デフォルトの zsh ではない）。`ShellExec` 呼び出しは POSIX 互換に保つこと（zsh 固有構文を使わない）
- `hs.eventtap` のコールバックは高頻度で呼ばれるため、パフォーマンスに注意
- `hs.application.find()` は重い処理。キャッシュを活用すること
- `astSleep()` は既存コード（`reload.lua` のチートメニュー等）で残存するが、新規コードでは使用禁止。`hs.timer.doAfter()` を使うこと

