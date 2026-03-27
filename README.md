<div align="center">
  <img src="https://raw.githubusercontent.com/LiveEnhancementSuite/LESforMacOS/develop/Hammerspoon/Images.xcassets/AppIcon.appiconset/icon_256x256.png" alt="Live Enhancement Suite"/>
  <br/>
  <a href="https://github.com/LiveEnhancementSuite/LESforMacOS/tree/develop">
    <img src="https://github.com/LiveEnhancementSuite/LESforMacOS/actions/workflows/les_build.yml/badge.svg" alt="ビルドステータス">
  </a>
  <br/>
</div>

# LESforMacOS Custom

> **これは [LESforMacOS](https://github.com/LiveEnhancementSuite/LESforMacOS) のフォーク（派生版）です。**
> オリジナルの Live Enhancement Suite をベースに、カスタマイズや改良を加えています。

LESforMacOS は Live Enhancement Suite の macOS 版です。[Hammerspoon](https://github.com/Hammerspoon/hammerspoon) のフォークであり、Hammerspoon を活用した [Lua スクリプト](https://github.com/LiveEnhancementSuite/LESforMacOS/tree/develop/extensions/les)を内蔵しています。Ableton Live の操作を便利にするショートカットやマクロを提供し、音楽制作のワークフローを向上させます。

## クイックスタート

1. [最新リリース](https://github.com/LiveEnhancementSuite/LESforMacOS/releases/latest)をダウンロード
2. `Live Enhancement Suite.dmg` を開き、指示に従ってインストール
3. [ドキュメント](https://docs.enhancementsuite.me/)で使い方を確認

### 動作要件

| 項目 | 最低要件 |
|------|---------|
| macOS | 12 (Monterey) 以上 |
| Ableton Live | 10 以上 |

## 主な機能

| 機能 | 説明 | デフォルトキー |
|------|------|---------------|
| ピアノロールマクロ | ピアノロール操作の自動化 | `` ` ``（バッククォート） |
| MIDIクリップ作成 | 新規MIDIクリップを素早く作成 | `Cmd+Shift+M` |
| プロジェクトバージョニング | 新バージョンとして保存 | `Cmd+Alt+S` |
| マーカー作成 | ロケーターマーカーを作成 | `Shift+L` |
| ウィンドウ管理 | ウィンドウの閉じる・切替操作 | `Ctrl+W` |
| カスタムメニュー | メニューバーからの操作 | メニューバーアイコン |

### 設定

設定ファイルは `~/.les/settings.ini` に保存されます。主な設定項目：

- `autoadd` — プラグイン検索後に自動追加
- `disableloop` — ループボタンの自動有効化を無効化
- `saveasnewver` — Cmd+Alt+S でバージョン保存
- `enabledebug` — デバッグコンソールを有効化
- `texticon` — メニューバーにテキスト "LES" を表示

## プロジェクト構成

```
LESforMacOSCustom/
├── Hammerspoon/              # コアアプリケーション (Objective-C)
├── LuaSkin/                  # Lua ランタイムラッパー
│   └── lua-5.4.7/            # 組み込み Lua インタープリター
├── extensions/               # Hammerspoon 拡張モジュール (94+)
│   └── les/                  # ★ Live Enhancement Suite 本体
│       ├── LESmain.lua       # メインロジック
│       ├── module.lua        # モジュール管理
│       ├── settings.lua      # 設定システム
│       ├── helpers.lua       # ヘルパー関数
│       └── proccom.lua       # プロセス間通信
├── Pods/                     # CocoaPods 依存関係
├── Hammerspoon.xcworkspace/  # Xcode ワークスペース
├── LICENSE                   # MIT ライセンス
└── README.md                 # このファイル
```

## ビルド方法

### 前提条件

- **Xcode** 14.1 以上（Apple Developer アカウントが必要）
- **Homebrew**
- **CocoaPods**
- **Ruby** 3.x

### 1. 依存パッケージのインストール

```bash
# Homebrew パッケージ
brew install coreutils jq xcbeautify gawk gh gpg

# Ruby gems
gem install --user t
gem install trainer
```

### 2. リポジトリのクローンとセットアップ

```bash
git clone https://github.com/bassmicrobe/LESforMacOSCustom
cd LESforMacOSCustom

# CocoaPods 依存関係のインストール
pod install

# Python 依存関係のインストール
pip3 install --user -r requirements.txt
```

### 3. ビルド

```bash
XCODE_ARGS="GCC_TREAT_WARNINGS_AS_ERRORS=NO MACOSX_DEPLOYMENT_TARGET=11.0"
xcodebuild -workspace Hammerspoon.xcworkspace -scheme Hammerspoon \
  -configuration Debug ${XCODE_ARGS} clean build | xcbeautify
```

## 開発ワークフロー（Claude Code）

このプロジェクトは [Claude Code](https://claude.ai/code) を活用して開発・メンテナンスを行っています。

### Claude Code でできること

- **コード解析** — プロジェクト構造やLuaスクリプトの調査
- **バグ修正** — 問題の特定と修正
- **機能追加** — 新しいショートカットやマクロの実装
- **リファクタリング** — コード品質の改善

### CLAUDE.md について

プロジェクトルートに `CLAUDE.md` を配置することで、Claude Code にプロジェクト固有のコンテキスト（ビルド手順、コーディング規約、アーキテクチャ情報など）を提供できます。詳しくは [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) を参照してください。

## コントリビューション

LESforMacOS へのコントリビューションは、Hammerspoon フォーク部分と LES スクリプト部分の両方で受け付けています。

既存の Hammerspoon ユーザーにとっては、`~/.hammerspoon` がアプリケーションバンドル内に組み込まれていると考えるとわかりやすいです。

LESforMacOS は設定ファイルとジャンプスタートスクリプト（Hammerspoon コアをアプリケーションバンドル内のロジックにリダイレクトする `init.lua`）を `~/.les` に保存しますが、コアロジックは `Contents/Resources/extensions/hs/les` にあります。

ソースツリーでは `extensions/les` に対応します。

## ライセンスと著作権

このプロジェクトは **MIT ライセンス** のもとで公開されています。

```
Copyright (c) 1994 - 2017 Lua.org, PUC-Rio
Copyright (c) 2014 - 2023 The Hammerspoon Contributors[1]
Copyright (c) 2019 - 2023 LESforMacOS authors[2]
Copyright (c) 2026 bassmicrobe (本フォークのカスタマイズ部分)

Released under the MIT License.

[1] - https://github.com/Hammerspoon/hammerspoon/graphs/contributors
[2] - https://github.com/LiveEnhancementSuite/LESforMacOS/blob/develop/extensions/les/AUTHORS.txt
```

詳細は [LICENSE](LICENSE) ファイルを参照してください。
