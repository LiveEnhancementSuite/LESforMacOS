#!/bin/bash
# lint-changed.sh — 変更されたファイルに対して軽量な静的チェックを実行
# Biome 的にソースコード変更の都度実行することを想定
set -euo pipefail

ERRORS=0
WARNINGS=0

# 引数があればそのファイルだけ、なければ git diff で変更ファイルを取得
if [ $# -gt 0 ]; then
    FILES=("$@")
else
    mapfile -t FILES < <(git diff --name-only HEAD 2>/dev/null; git diff --cached --name-only 2>/dev/null)
    # 重複除去
    mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | sort -u)
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "✓ チェック対象のファイルがありません"
    exit 0
fi

echo "=== LES Lint Check ==="
echo "対象: ${#FILES[@]} ファイル"
echo ""

# ── Lua チェック ──────────────────────────────────────────────
for f in "${FILES[@]}"; do
    [[ "$f" == *.lua ]] || continue
    [ -f "$f" ] || continue

    # 1. string ライブラリの上書き検出
    if grep -nP '^\s*local\s+string\s*=' "$f" 2>/dev/null; then
        echo "ERROR: $f — 変数名 'string' は標準ライブラリを上書きします"
        ((ERRORS++))
    fi

    # 2. 0-indexed ループの検出 (Lua は 1-indexed)
    if grep -nP 'for\s+\w+\s*=\s*0\s*,' "$f" 2>/dev/null; then
        echo "WARNING: $f — Lua は 1-indexed です。0 始まりのループを確認してください"
        ((WARNINGS++))
    fi

    # 3. 150文字超の行
    if awk -v file="$f" 'length > 150 { printf "WARNING: %s:%d — 行が %d 文字（上限150）\n", file, NR, length; found=1 } END { exit !found }' "$f" 2>/dev/null; then
        ((WARNINGS++))
    fi
done

# ── Objective-C / C チェック ──────────────────────────────────
for f in "${FILES[@]}"; do
    [[ "$f" == *.h || "$f" == *.m ]] || continue
    [ -f "$f" ] || continue

    # 1. sa_family_t を使用しているが sys/socket.h をインクルードしていない
    if grep -q 'sa_family_t' "$f" && ! grep -qE '#include\s+<sys/socket\.h>|#import\s+<sys/socket\.h>' "$f"; then
        echo "ERROR: $f — sa_family_t を使用していますが <sys/socket.h> のインクルードがありません"
        ((ERRORS++))
    fi

    # 2. kIOMainPortDefault を使用しているが availability guard がない
    if grep -q 'kIOMainPortDefault' "$f" && ! grep -qE '@available|API_AVAILABLE|__builtin_available' "$f"; then
        echo "WARNING: $f — kIOMainPortDefault は macOS 12.0+ です。availability guard を確認してください"
        ((WARNINGS++))
    fi

    # 3. @import の後に必要なシステムヘッダーが欠けていないか
    if grep -q '@import Foundation' "$f"; then
        # mach_port_t, kern_return_t, IOReturn 等のカーネル型
        if grep -qE '\b(mach_port_t|kern_return_t|IOReturn)\b' "$f" && ! grep -qE '#include\s+<mach/mach\.h>|#import\s+<IOKit/' "$f"; then
            echo "WARNING: $f — カーネル型を使用していますがシステムヘッダーのインクルードを確認してください"
            ((WARNINGS++))
        fi
    fi
done

# ── GitHub Actions ワークフローチェック ───────────────────────
for f in "${FILES[@]}"; do
    [[ "$f" == .github/workflows/*.yml ]] || continue
    [ -f "$f" ] || continue

    # 1. 非推奨アクションバージョンの検出
    if grep -nE 'actions/(checkout|upload-artifact|download-artifact)@v[12]\b' "$f" 2>/dev/null; then
        echo "WARNING: $f — GitHub Actions の非推奨バージョンが使用されています（v3+ を推奨）"
        ((WARNINGS++))
    fi

    # 2. ハードコードされた SDK パスの検出
    if grep -nE 'MacOSX[0-9]+\.[0-9]+\.sdk' "$f" 2>/dev/null; then
        echo "WARNING: $f — SDK パスがバージョン固有です。MacOSX.sdk シンボリックリンクの使用を検討してください"
        ((WARNINGS++))
    fi
done

# ── 結果 ─────────────────────────────────────────────────────
echo ""
if [ $ERRORS -gt 0 ]; then
    echo "✗ ${ERRORS} エラー, ${WARNINGS} 警告"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo "△ ${WARNINGS} 警告（エラーなし）"
    exit 0
else
    echo "✓ すべてのチェックをパスしました"
    exit 0
fi
