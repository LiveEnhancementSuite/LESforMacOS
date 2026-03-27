# Live Enhancement Suite Custom — ユーザマニュアル

> LESforMacOS Custom のユーザ向け操作マニュアルです。
> インストールから全機能の使い方までを解説します。

## 目次

- [全体の流れ](#全体の流れ)
- [インストール](#インストール)
- [基本操作](#基本操作)
- [キーボードショートカット一覧](#キーボードショートカット一覧)
- [プラグインメニュー](#プラグインメニュー)
- [ピアノロールマクロ](#ピアノロールマクロ)
- [VST ショートカット](#vst-ショートカット)
- [プロジェクト時間トラッキング](#プロジェクト時間トラッキング)
- [メニューバー](#メニューバー)
- [設定リファレンス](#設定リファレンス)
- [設定ファイルの場所](#設定ファイルの場所)
- [トラブルシューティング](#トラブルシューティング)
- [イースターエッグ](#イースターエッグ)

---

## 全体の流れ

LES が Ableton Live と連携する仕組みの全体像です。

```mermaid
graph TD
    A[LES を起動] --> B{Ableton Live が<br/>フォーカスされた？}
    B -->|はい| C[ショートカット・マクロが有効化]
    B -->|いいえ| D[ショートカット・マクロが無効化]
    C --> E[キーボード入力を監視]
    E --> F{登録済みの<br/>ショートカット？}
    F -->|はい| G[マクロを実行]
    F -->|いいえ| H[Ableton にそのまま渡す]
    G --> E
    H --> E
    D --> B
```

---

## インストール

```mermaid
graph LR
    A[DMG をダウンロード] --> B[DMG を開く]
    B --> C[.app を /Applications にドラッグ]
    C --> D[LES を起動]
    D --> E{初回起動}
    E --> F[アクセシビリティ権限を許可]
    F --> G[Ableton Live を起動]
    G --> H[使用開始]
```

### 動作要件

| 項目 | 要件 |
|------|------|
| macOS | 12 (Monterey) 〜 15 (Sequoia) |
| Ableton Live | 9 〜 12 |

### 手順

1. [最新リリース](https://github.com/bassmicrobe/LESforMacOSCustom/releases/latest)から `LiveEnhancementSuite.dmg` をダウンロード
2. DMG を開き、`Live Enhancement Suite Custom.app` を `/Applications` にドラッグ
3. アプリを起動
4. **システム設定 → プライバシーとセキュリティ → アクセシビリティ** で LES を許可
5. Ableton Live を起動すると、LES が自動的にショートカットを有効化

---

## 基本操作

LES は Ableton Live がフォーカスされている間だけ動作します。他のアプリに切り替えると自動でショートカットが無効化されます。

```mermaid
stateDiagram-v2
    [*] --> 無効
    無効 --> 有効 : Ableton Live にフォーカス
    有効 --> 無効 : 他のアプリにフォーカス
    有効 --> 一時停止 : Cmd+Shift+1
    一時停止 --> 有効 : Cmd+Shift+1
    有効 --> [*] : Ableton Live を終了
```

| 操作 | 説明 |
|------|------|
| Ableton にフォーカス | 全ショートカットが自動で有効化 |
| 他のアプリにフォーカス | 全ショートカットが自動で無効化 |
| `Cmd+Shift+1` | LES のショートカットを一時停止/再開 |

---

## キーボードショートカット一覧

### メインショートカット

| ショートカット | 機能 | 説明 |
|---------------|------|------|
| `Cmd+Shift+H` | プラグインメニュー | カスタムプラグインメニューを表示 |
| `Cmd+B` | Buplicate | クリップを複数回複製（初回7回、以降8回） |
| `Cmd+Shift+M` | MIDIクリップ作成 | 新規MIDIクリップを作成 |
| `Cmd+Alt+S` | バージョン保存 | プロジェクトを新バージョンとして保存 |
| `Alt+L` | マーカー作成 | 現在位置にロケーターマーカーを追加 |
| `Cmd+W` | ウィンドウを閉じる | フォーカス中のウィンドウを閉じる |
| `Cmd+Alt+W` | 全ウィンドウを閉じる | メインウィンドウ以外を全て閉じる |
| `Cmd+Shift+1` | 一時停止 | LES の全ショートカットを一時停止/再開 |

### 編集ショートカット

| ショートカット | 機能 | 設定依存 |
|---------------|------|---------|
| `Cmd+Alt+D` | 絶対複製 | `ctrlabsoluteduplicate=0` の場合 |
| `Cmd+Ctrl+D` | 絶対複製 | `ctrlabsoluteduplicate=1` の場合 |
| `Cmd+Alt+V` | 絶対置換 | `absolutereplace=1` の場合 |
| `0` `0`（素早く2回） | 削除キー | `double0todelete=1` の場合 |

### トラック操作

| ショートカット | 機能 |
|---------------|------|
| `Alt+G` | 中クリックエミュレーション |
| `Alt+E` | エンベロープモード |
| `Alt+X` | トラッククリア |
| `Alt+C` | トラック色変更 |

---

## プラグインメニュー

お気に入りのプラグインをカテゴリ分けして素早くアクセスできます。

```mermaid
graph TD
    A[ダブル右クリック] --> B{Shift を<br/>押している？}
    B -->|いいえ| C[プラグインメニュー表示]
    B -->|はい| D[ピアノロールメニュー表示]
    C --> E[プラグインを選択]
    E --> F[Live の検索窓が開く]
    F --> G[プラグイン名を自動入力]
    G --> H{autoadd が有効？}
    H -->|はい| I[自動でプラグインを追加]
    H -->|いいえ| J[手動で追加を選択]
```

### 使い方

1. Ableton Live 上で**ダブル右クリック**
2. カテゴリを辿ってプラグインを選択
3. Live の検索窓が開き、プラグイン名が自動入力される
4. `autoadd=1` の場合、自動的にトラックに追加される

### Cmd キーの反転動作

プラグイン選択時に `Cmd` を押しながらクリックすると、`autoadd` 設定が一時的に反転します：
- `autoadd=1` の場合 → Cmd で自動追加を**スキップ**
- `autoadd=0` の場合 → Cmd で自動追加を**実行**

### メニューのカスタマイズ

`~/.les/menuconfig.ini` を編集してプラグインメニューの内容を変更できます。

```ini
; コメント行（表示されない）
/カテゴリ名
プラグイン名1
プラグイン名2
—                    ; 区切り線
//サブカテゴリ名
プラグイン名3
..                   ; 1つ上の階層に戻る
/nocategory          ; ルート階層に戻る
```

例：

```ini
/EQ
Pro-Q 3
Channel EQ
—
//ダイナミックEQ
Soothe 2
..
/Compressor
Pro-C 2
Glue Compressor
/nocategory
OTT
```

変更後、メニューバーの **Reload** で反映されます（または `dynamicreload=1` で自動反映）。

### プラグイン検索 UI（Chooser）

メニューバーの **Search Plugins...** から Spotlight 風の検索 UI を開きます。

#### カテゴリフィルタ

1. 検索 UI を開く
2. 先頭の **📂 カテゴリ絞込** を選択
3. カテゴリ一覧から選択すると、そのカテゴリのプラグインのみ表示
4. **すべて表示** でフィルタを解除

カテゴリは `menuconfig.ini` の `/カテゴリ名` 構文に基づきます。

#### ソート

1. 検索 UI を開く
2. 先頭の **⚙ ソート変更** を選択
3. ソート方法を選択：

| ソート | 説明 |
|--------|------|
| 名前順 (A→Z) | アルファベット順（デフォルト） |
| 使用頻度順 | よく使うプラグインが上位 |
| 最終使用日時順 | 最近使ったプラグインが上位 |
| 追加日時順 | 新しく追加されたプラグインが上位 |

#### 使用統計

プラグインを使用するたびに以下が自動記録されます：

- **使用回数** — プラグインの累計使用回数
- **最終使用日時** — 最後に使った日時
- **追加日時** — 初めて使用した日時

統計データは `~/.les/resources/plugin_stats.json` に保存されます。検索 UI のサブテキストにも表示されます。

---

## ピアノロールマクロ

ピアノロール内でのノート操作を効率化します。

```mermaid
graph TD
    A[バッククォートキーを押し続ける] --> B[ピアノロールマクロモード開始]
    B --> C{マウス操作}
    C -->|左クリック| D[ダブルクリックをエミュレート<br/>ノートを即座に配置]
    C -->|左クリック + Shift| E[シフト選択モード<br/>複数ノートを選択]
    C -->|右クリック| F[通常の右クリック]
    A --> G[キーを離す]
    G --> H[マクロモード終了]
```

### 使い方

1. ピアノロールビューを開く
2. バッククォートキー（`` ` ``）を**押し続ける**
3. 左クリックするとダブルクリックが自動実行され、素早くノートを配置できる
4. `Shift` を併用すると選択モードになる
5. キーを離すとマクロモード終了

### スケール・コードメニュー

ダブル右クリック + `Shift` でスケール/コードメニューが表示されます。

**スケール（一部）：**

| カテゴリ | スケール |
|---------|---------|
| 基本 | Major, Minor, Harmonic Minor, Melodic Minor |
| モード | Dorian, Phrygian, Lydian, Mixolydian, Locrian |
| ペンタトニック | Major Pentatonic, Minor Pentatonic, Blues |
| ワールド | Arabic, Gypsy, Hirajoshi, In-Sen, Pelog |

**コード：**

Major, Minor, Maj7, Min7, Maj9, Min9, 7th, Augmented, Diminished, Power Chord, Octaves

---

## VST ショートカット

特定の VST プラグインウィンドウがフォーカスされている場合に有効になります。

```mermaid
graph TD
    A[VST ウィンドウにフォーカス] --> B{プラグイン名を検出}
    B -->|FabFilter Pro-Q 3| C[Cmd+Z / Cmd+Shift+Z が<br/>ウィンドウサイズに応じた<br/>Undo/Redo ボタンをクリック]
    B -->|Kick 2| D[Cmd+Z / Cmd+Shift+Z が<br/>Undo/Redo ボタンをクリック]
    B -->|その他| E[通常の Cmd+Z 動作]
```

### 対応プラグイン

| プラグイン | Cmd+Z | Cmd+Shift+Z | 補足 |
|-----------|-------|-------------|------|
| **FabFilter Pro-Q 3** | Undo | Redo | ウィンドウサイズに応じてクリック位置を自動計算 |
| **Kick 2** | Undo | Redo | ウィンドウ幅の比率でボタン位置を計算 |

`vstshortcuts=0` で無効化できます。

---

## プロジェクト時間トラッキング

各プロジェクトの作業時間を自動で記録します。

```mermaid
sequenceDiagram
    participant U as ユーザ
    participant L as LES
    participant A as Ableton Live

    U->>A: プロジェクトを開く
    A->>L: ウィンドウタイトルからプロジェクト名を取得
    L->>L: 前回の保存時間を読み込み
    loop 毎秒
        L->>L: カウンターを+1
    end
    U->>A: 別のプロジェクトを開く
    L->>L: 現在の時間をファイルに保存
    L->>L: 新しいプロジェクトの時間を読み込み
    U->>L: メニューバー → Project Time
    L->>U: "X時間 Y分 Z秒" を表示
```

### 機能

- **自動記録**: Ableton Live がフォーカスされている間、毎秒カウント
- **プロジェクト別**: ウィンドウタイトルからプロジェクト名を自動検出して個別に記録
- **永続保存**: `~/.les/resources/time/` にプロジェクトごとのファイルで保存
- **確認方法**: メニューバーアイコン → **Project Time** をクリック
- **リセット**: Project Time ダイアログで「Reset」を選択

### Strict Time モード

メニューバーの **Strict Time** にチェックを入れると：
- Ableton Live からフォーカスが外れた時にタイマーを**停止**
- フォーカスが戻った時にタイマーを**再開**

チェックを外すと、フォーカスに関係なくタイマーが動き続けます。

---

## メニューバー

macOS メニューバー右上の LES アイコン（または "LES" テキスト）からアクセスします。

```mermaid
graph TD
    M[メニューバーアイコン] --> A[Configure Menu<br/>プラグインメニューを編集]
    M --> B[Configure Settings<br/>設定ファイルを編集]
    M --> C[Donate<br/>寄付ページを開く]
    M --> D[Project Time<br/>作業時間を確認]
    M --> E[Strict Time ☑<br/>厳密な時間計測の切替]
    M --> F[Reload<br/>設定を再読み込み]
    M --> G[Install InsertWhere<br/>M4Lデバイスをインストール]
    M --> H["Manual 📖<br/>オンラインマニュアルを開く"]
    M --> I[Exit<br/>LES を終了]
```

### デバッグモード（`enabledebug=1`）

追加メニュー項目：
- **Console** — Hammerspoon コンソールを開く
- **Restart** — LES を再起動
- **Open Hammerspoon Folder** — 設定フォルダを Finder で開く

---

## 設定リファレンス

`~/.les/settings.ini` で設定を変更できます。変更後は **Reload** で反映してください。

### スイッチ設定（0 = オフ / 1 = オン）

| 設定名 | デフォルト | 説明 |
|--------|-----------|------|
| `autoadd` | `1` | プラグイン選択時に自動追加 |
| `disableloop` | `1` | MIDIクリップ作成時にループを無効化 |
| `saveasnewver` | `1` | Cmd+Alt+S のバージョン保存を有効化 |
| `altgrmarker` | `1` | マーカーショートカットを Shift+L → Alt+L に変更 |
| `double0todelete` | `1` | 0キー2回押しで Delete キーを送信 |
| `absolutereplace` | `1` | 絶対複製・絶対置換を有効化 |
| `ctrlabsoluteduplicate` | `0` | 絶対複製を Cmd+Ctrl+D にマップ（動画編集ソフトとの競合回避） |
| `enableclosewindow` | `1` | Cmd+W によるウィンドウ閉じを有効化 |
| `vstshortcuts` | `1` | VST 固有ショートカットを有効化 |
| `dynamicreload` | `0` | プラグインメニューを開くたびに自動リロード |
| `texticon` | `0` | メニューバーアイコンの代わりに "LES" テキストを表示 |
| `addtostartup` | `0` | macOS ログイン時に LES を自動起動 |
| `launchwithlive` | `0` | Ableton Live の起動を検知して LES を自動起動（Launch Agent） |
| `enabledebug` | `0` | デバッグモードを有効化 |
| `checksanity` | `1` | macOS / Ableton Live のバージョン互換性チェック |
| `resettobrowserbookmark` | `0` | プラグイン追加後にブックマーク位置をクリック |

### 値設定

| 設定名 | デフォルト | 型 | 説明 |
|--------|-----------|---|------|
| `pianorollmacro` | `` ` `` | キー名 | ピアノロールマクロのトリガーキー |
| `loadspeed` | `0.3` | 秒 | プラグイン自動追加までの待機時間 |
| `bookmarkx` | `500` | ピクセル | ブックマーク復帰クリックの X 座標 |
| `bookmarky` | `500` | ピクセル | ブックマーク復帰クリックの Y 座標 |

---

## 設定ファイルの場所

```mermaid
graph LR
    H["~/.les/"] --> A["settings.ini<br/>全般設定"]
    H --> B["menuconfig.ini<br/>プラグインメニュー定義"]
    H --> C["init.lua<br/>ジャンプスタートスクリプト"]
    H --> D["resources/"]
    D --> E["time/<br/>プロジェクト別タイマーデータ"]
    D --> F["strict.txt<br/>Strict Time 状態"]
```

| ファイル | 用途 |
|---------|------|
| `~/.les/settings.ini` | 全般設定（ショートカットの有効/無効、動作パラメータ） |
| `~/.les/menuconfig.ini` | プラグインメニューの内容とカテゴリ構成 |
| `~/.les/resources/time/` | プロジェクト別の作業時間データ |

---

## トラブルシューティング

### LES が動作しない

```mermaid
graph TD
    A[LES が動作しない] --> B{メニューバーに<br/>LES アイコンがある？}
    B -->|いいえ| C[LES を起動]
    B -->|はい| D{Cmd+Shift+1 で<br/>一時停止していない？}
    D -->|一時停止中| E[Cmd+Shift+1 で再開]
    D -->|動作中| F{アクセシビリティ権限は<br/>許可されている？}
    F -->|いいえ| G["システム設定 →<br/>プライバシーとセキュリティ →<br/>アクセシビリティ で許可"]
    F -->|はい| H[メニューバー → Reload]
    H --> I{まだ動かない？}
    I -->|はい| J["メニューバー → Exit →<br/>LES を再起動"]
```

### プラグインメニューが表示されない

- ダブル右クリックの間隔が短すぎる/長すぎる場合があります
- `~/.les/menuconfig.ini` が存在するか確認
- メニューバーの **Reload** を実行

### プラグインが自動追加されない

- `settings.ini` で `autoadd=1` になっているか確認
- `loadspeed` の値を大きくする（HDD の場合は `0.5` 〜 `1.0`）
- Ableton Live のブラウザが表示されているか確認

### バージョン保存が動作しない

- `saveasnewver=1` になっているか確認
- プロジェクトが一度は保存されているか確認（未保存プロジェクトでは動作しません）

---

## イースターエッグ

`enabledebug=1` の状態で、**Shift キーを素早く2回タップ** するとチートメニューが表示されます。

以下のコマンドを入力できます：

| コマンド | 動作 |
|---------|------|
| `les` / `sweet` | LES ボイスサンプルを再生 |
| `303` / `sylenth` | デモ版メッセージを再生 |
| `fl studio` | FL Studio のサウンドを再生 |
| `collab bro` / `als` | レッスンプロジェクトを開く |
| `owo` / `uwu` | ??? |

---

## バージョン情報

| 項目 | 値 |
|------|-----|
| プログラム名 | Live Enhancement Suite Custom |
| バンドルID | org.les.Live-Enhancement-Suite-Custom |
| ベース | [LESforMacOS](https://github.com/LiveEnhancementSuite/LESforMacOS) のフォーク |
| ライセンス | MIT |
| バグ報告 | [GitHub Issues](https://github.com/bassmicrobe/LESforMacOSCustom/issues) |
