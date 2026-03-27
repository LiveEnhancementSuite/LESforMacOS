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
│       ├── LESmain.lua       # エントリーポイント
│       ├── module.lua        # モジュール管理
│       ├── helpers.lua       # ファイル操作ヘルパー
│       ├── proccom.lua       # プロセス検出・メニュー操作
│       ├── settings.lua      # 設定システム
│       ├── shortcuts/        # キーボードショートカット
│       ├── menus/            # メニューバー UI
│       ├── lifecycle/        # リロード・アプリ監視
│       ├── tracking/         # タイマー・使用時間追跡
│       ├── vst/              # VST プラグイン操作
│       └── tests/            # busted テストスイート
├── Pods/                     # CocoaPods 依存関係
├── Hammerspoon.xcworkspace/  # Xcode ワークスペース
├── Dockerfile.test           # テスト実行環境 (Docker)
├── CLAUDE.md                 # Claude Code プロジェクトコンテキスト
├── CHANGELOG.md              # 変更履歴
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

### 3. ビルドと配布

開発からリリースまでの全体の流れ：

```
ソースコード
  │
  ├─ [開発用] デバッグビルド → .app → そのまま起動して動作確認
  │
  └─ [配布用] リリースビルド → .app → DMG に梱包 → .dmg をユーザーに配布
                                  │                      │
                                  └─ (任意) Apple 公証    └─ ユーザーが開いて
                                     Gatekeeper 対応        /Applications にドラッグ
```

#### デバッグビルド（開発用）

コンパイルして `.app` を生成し、動作確認に使います：

```bash
XCODE_ARGS="GCC_TREAT_WARNINGS_AS_ERRORS=NO MACOSX_DEPLOYMENT_TARGET=11.0"
xcodebuild -workspace Hammerspoon.xcworkspace -scheme Hammerspoon \
  -configuration Debug ${XCODE_ARGS} clean build | xcbeautify
```

既存プロセスを終了してすぐ起動するショートカット：

```bash
./rebuild.sh
```

#### リリースビルド → DMG 作成（配布用）

**方法 A: ワンコマンド**

```bash
# ビルド→検証→公証→アーカイブを一括実行
./scripts/release.sh
```

**方法 B: 手動ステップ**

```bash
# ① ビルド（Release 構成で .app を生成）
./scripts/build.sh clean
./scripts/build.sh docs
./scripts/build.sh build -s Release -c Release
./scripts/build.sh validate

# ② DMG に梱包（.app をインストーラーに変換）
npm install -g create-dmg    # 初回のみ

mkdir -p release
cp -R ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release/*.app/ \
  "./Live Enhancement Suite.app/"

create-dmg --dmg-title="Live Enhancement Suite" \
  "Live Enhancement Suite.app" release/

mv release/*.dmg release/LiveEnhancementSuite.dmg
shasum -a 256 release/LiveEnhancementSuite.dmg > release/LiveEnhancementSuite.dmg.sha256sum
```

`release/LiveEnhancementSuite.dmg` が配布用インストーラーです。

#### Apple 公証（任意）

App Store 外で配布する場合、macOS Gatekeeper に「安全なアプリ」と認識させるため公証を行います：

```bash
# 公証用プロファイルの設定（初回のみ）
xcrun notarytool store-credentials -v \
  --apple-id YOUR_APPLE_ID \
  --team-id YOUR_TEAM_ID \
  --password APP_SPECIFIC_PASSWORD

# 公証の実行（DMG 作成前に行う）
./scripts/build.sh notarize
```

#### GitHub Actions による自動リリース

`v*` 形式のタグをプッシュすると、上記の全工程を GitHub Actions が自動実行します：

```bash
git tag v1.0.0
git push origin v1.0.0
# → 自動で: リリースビルド → DMG 作成 → GitHub Releases にアップロード
```

ワークフローの詳細: [`.github/workflows/les_release.yml`](.github/workflows/les_release.yml)

## テスト

Docker を使ってローカル環境を汚さずにテストを実行できます。

```bash
# イメージをビルドして全テスト実行（luacheck + busted）
docker build -f Dockerfile.test -t les-test .
docker run --rm les-test

# busted テストのみ
docker run --rm les-test busted extensions/les/tests/

# luacheck 静的解析のみ
docker run --rm les-test luacheck extensions/les/

# コンテナ内でシェルを開く
docker run --rm -it les-test /bin/sh
```

Docker イメージには以下が含まれます：
- **Lua 5.4** + **busted**（テストフレームワーク）+ **luacheck**（静的解析）
- **Node.js 22** + **pnpm**（JS ツールチェーン用）

テストファイルは `extensions/les/tests/` に `*_spec.lua` の命名規則で配置します。

## 変更履歴

このフォークでの変更点は [CHANGELOG.md](CHANGELOG.md) を参照してください。

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
