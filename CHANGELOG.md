# 変更履歴 (CHANGELOG)

このフォークで行われた全ての変更をまとめています。

## [Unreleased] — 2026-03-27

### プラグインメニュー高速化（1200件対応）

- **`menus/plugin.lua`**: `buildPluginMenu()` のホットループを最適化
  - `string.find` / `string.sub` / `string.gsub` 等をローカル変数にキャッシュ（関数ルックアップコスト削減）
  - `table.insert` による逐次追加を直接インデックス代入に置換（テーブルリサイズ削減）
  - 行の先頭1-2文字を事前取得しループ内の `string.sub` 呼び出しを半減
  - `hs.inspect(arr)` / `hs.inspect(pluginArray)` のデバッグ出力を除去（1200件の配列シリアライズを回避）
  - メニュー構築ループ内の `print()` 12箇所を除去（毎回の文字列連結コストを排除）

### ピアノロール eventtap 再利用

- **`shortcuts/piano.lua`**: `keyhandlerevent` を事前生成して `start()`/`stop()` で再利用
  - 変更前: キー押下のたびに `hs.eventtap.new()` で生成し、離すたびに破棄 → GC 圧力
  - 変更後: 起動時に1回だけ生成し、必要に応じて start/stop を切り替え
  - イベントタイプ定数もローカルにキャッシュ

### appwatch キャッシュ無効化の最適化

- **`lifecycle/appwatch.lua`**: `hs.window.focusedWindow()` の呼び出しを1回に削減（旧: 最大3回）
  - 結果をローカル変数 `focusedWin` にキャッシュして再利用

### Docker テスト環境

- **`Dockerfile.test`** を追加 — Debian bookworm ベースで Lua 5.4 + busted + pnpm を含むテスト実行環境
- macOS ローカル環境を汚さずに `docker build -f Dockerfile.test -t les-test . && docker run --rm les-test` でテスト実行可能
- pnpm を統合し、Node.js ベースのツールチェーン（lint、フォーマッタ等）にも対応

### モジュール分割（LESmain.lua リファクタリング）

旧 `LESmain.lua`（1908行）を機能別に分割し、保守性を大幅に向上。

| 新モジュール | 行数 | 内容 |
|-------------|------|------|
| `menus/plugin.lua` | ~330 | メニュー構築・プラグインメニュー |
| `lifecycle/reload.lua` | ~195 | チートメニュー・リロード処理 |
| `shortcuts/macros.lua` | ~430 | キーボードマクロ（ディスパッチテーブル化） |
| `shortcuts/rightclick.lua` | ~145 | 右クリックメニュー・プラグイン読込 |
| `shortcuts/piano.lua` | ~100 | ピアノロールマクロ |
| `vst/shortcuts.lua` | ~50 | VST ショートカット |
| `tracking/timer.lua` | ~120 | タイマー・使用時間追跡 |
| `lifecycle/appwatch.lua` | ~60 | アプリケーション監視 |

`LESmain.lua` は ~132行のオーケストレーターに縮小。

### パフォーマンス最適化

#### ディスパッチテーブル (`shortcuts/macros.lua`)

- **変更前**: 25+ の if-else チェーンによる O(n) キーコード検索
- **変更後**: `keyDispatch` テーブルによる O(1) ルックアップ
- `hs.eventtap.checkKeyboardModifiers()` の呼び出しをイベントあたり1回に削減（旧: 28+回）
- FabFilter undo/redo の重複コード（~90行）を `handleFabFilterUndoRedo()` に統合
- **推定改善**: キーストローク処理の CPU 負荷を 40-60% 削減

#### メモ化キャッシュ (`proccom.lua`)

- `getLiveHsAppObj()` に 2 秒 TTL キャッシュを追加
- `hs.application.find()`（重い API コール）の呼び出し頻度を大幅に削減
- アプリフォーカス変更時に `invalidateLiveAppCache()` でキャッシュを無効化

#### タイマー最適化 (`tracking/timer.lua`)

- `getTimerKey()` で文字列連結結果をキャッシュ（毎秒の `"timer_" .. name` を回避）
- VST ウィンドウ検出でタイトル変更を検知し、不要な再チェックをスキップ
- `requesttime()` の時間フォーマットを簡素化（複雑な string.format+regex → 算術演算）

### シェル依存の排除 (`helpers.lua`)

以下の関数を `/bin/zsh` 呼び出しから純 Lua I/O + `hs.fs` API に置換：

| 関数 | 旧実装 | 新実装 |
|------|--------|--------|
| `ShellCopy()` | `cp` コマンド | `io.open("rb")` / `io.open("wb")` |
| `ShellCreateDirectory()` | `mkdir -p` | 再帰的 `hs.fs.mkdir()` |
| `ShellOverwriteFile()` | `echo >` | `io.open("w")` |
| `ShellConcatenateFile()` | `echo >>` | `io.open("a")` |
| `ShellCreateEmptyFile()` | `touch` | `io.open("w")` + close |
| `ShellDeleteFile()` | `rm` | `os.remove()` / `hs.fs.rmdir()` |

`ShellExec()` と `ShellRecursiveCopy()` は Lua 等価物がないため維持。

### グローバル変数汚染の修正

- **`string` ライブラリ上書きバグ**: `buildPluginMenu()` 内の `string = subfolderval .. ...` を `local entry = ...` に修正（Lua 標準ライブラリの破壊を防止）
- **パラメータ名シャドウイング**: `GetDataPath(string)` → `GetDataPath(path)`、`strQuote(string)` → `strQuote(str)`
- **関数スコープ修正**: `module.lua` 内の `getMacOSVersion()` 等を `local function` に変更
- **テーブルインデックス修正**: `for i = 0, delcount` → `for i = 1, delcount`（Lua は 1-indexed）
- **未クローズファイルハンドル**: `coolfunc()` の `io.open` に `f:close()` を追加
- **nil チェック追加**: `io.open("menuconfig.ini", "r")` の戻り値チェック

### ビルド速度改善

| 設定 | 変更前 | 変更後 | 効果 |
|------|--------|--------|------|
| C 言語標準 | `gnu99` | `gnu17` | 最新の最適化を活用 |
| C++ 標準 | `gnu++0x` | `gnu++17` | 同上 |
| デバッグシンボル (Debug) | `dwarf-with-dsym` | `dwarf` | dSYM 生成を省略しビルド高速化 |
| デバッグシンボル (Release) | （未設定） | `dwarf-with-dsym` | クラッシュレポート用に明示設定 |

### 型チェック・静的解析

- **`.luacheckrc`**: LES 固有のグローバル変数を包括的に定義、テスト用 busted グローバルも追加
- **`extensions/les/.luarc.json`**: LuaLS（Lua Language Server）設定を追加（Lua 5.4、`hs` グローバル）
- **LuaLS 型アノテーション**: `helpers.lua`、`proccom.lua` に `---@param` / `---@return` を追加

### テストスイート

- **`extensions/les/tests/helpers_spec.lua`**: busted（BDD スタイル）テスト 23 件を新規作成
  - 文字列ユーティリティ: `strQuote`, `strJoinPaths`, `strJoinArgs`, `strSanitize`, `strMultiLineTrim`
  - IO ユーティリティ: `ioIsFilePresent`, `fileToTable`, `tableToFile`
  - ファイル操作ヘルパー: `ShellCreateEmptyFile`, `ShellOverwriteFile`, `ShellConcatenateFile`, `ShellCopy`, `ShellDeleteFile`, `ShellCreateDirectory`
- Hammerspoon (`hs`) API のモック実装を含み、スタンドアロンで実行可能

### Python 依存関係更新 (`requirements.txt`)

| パッケージ | 変更前 | 変更後 |
|-----------|--------|--------|
| jinja2 | 3.0.3 | 3.1.3 |
| mistune | 2.0.0 | 3.0.2 |
| pygments | 2.11.2 | 2.17.2 |

### ドキュメント

- **`README.md`**: 日本語に完全翻訳、フォーク情報・著作権表示・プロジェクト構成・Claude Code ワークフローを追加
- **`CLAUDE.md`**: Claude Code 用プロジェクトコンテキストファイルを新規作成
- **`CHANGELOG.md`**: 本ファイル（全変更の日本語ドキュメント）

### Claude Code 統合

- `CLAUDE.md` にプロジェクト固有のコンテキスト（アーキテクチャ、規約、ビルド手順、設計判断）を記述
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) のベストプラクティスに基づく構成
