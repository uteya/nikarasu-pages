#!/bin/bash
# ============================================================
# ペりん Claude Code オンボーディングスクリプト
# ============================================================
# Usage:
#   curl -sL https://uteya.github.io/nikarasu-pages/perin-onboarding.sh | bash
#
# 前提:
#   1. Claude Code Max契約済み
#   2. Claude Code CLIインストール済み
#   3. GitHub uteya orgに招待済み & SSH or HTTPS設定済み
# ============================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ペりん Claude Code オンボーディング             ║"
echo "║  株式会社にからす — CTO セットアップ             ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# --- Step 1: 前提確認 ---
echo "━━━ Step 1/7: 前提確認 ━━━"

# claude CLI
if ! command -v claude &> /dev/null; then
  echo "❌ Claude Code がインストールされていません"
  echo ""
  echo "  Mac:     brew install claude-code"
  echo "  または:  npm install -g @anthropic-ai/claude-code"
  echo ""
  exit 1
fi
echo "  ✅ Claude Code: インストール確認"

# git
if ! command -v git &> /dev/null; then
  echo "❌ Git がインストールされていません"
  exit 1
fi
echo "  ✅ Git: $(git --version | head -1)"

# git config
if [ -z "$(git config user.name)" ]; then
  read -p "  Git ユーザー名を入力: " git_name
  git config --global user.name "$git_name"
fi
if [ -z "$(git config user.email)" ]; then
  read -p "  Git メールアドレスを入力: " git_email
  git config --global user.email "$git_email"
fi
echo "  ✅ Git config: $(git config user.name) <$(git config user.email)>"

# SSH or HTTPS
CLONE_PREFIX=""
echo "  GitHub接続確認中..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  CLONE_PREFIX="git@github.com:"
  echo "  ✅ SSH: 接続OK"
else
  echo "  ⚠️  SSH接続が確認できません。HTTPSを使用します"
  CLONE_PREFIX="https://github.com/"
fi

# --- Step 2: プロジェクトディレクトリ ---
echo ""
echo "━━━ Step 2/7: プロジェクトディレクトリ準備 ━━━"
PROJECTS_DIR="$HOME/projects"
mkdir -p "$PROJECTS_DIR"
echo "  ✅ $PROJECTS_DIR"

# --- Step 3: 3リポジトリクローン ---
echo ""
echo "━━━ Step 3/7: リポジトリクローン ━━━"

clone_repo() {
  local repo=$1
  local dir_name=$2
  local target="$PROJECTS_DIR/$dir_name"

  if [ -d "$target/.git" ]; then
    echo "  ⏭️  $dir_name: 既にクローン済み（pullします）"
    cd "$target" && git pull --ff-only 2>/dev/null || true
    cd "$PROJECTS_DIR"
  else
    echo "  📥 $dir_name をクローン中..."
    git clone "${CLONE_PREFIX}${repo}.git" "$target"
    echo "  ✅ $dir_name: クローン完了"
  fi
}

clone_repo "uteya/nikarasu-strategy" "nikarasu-strategy"
clone_repo "uteya/lisse-lecheck" "lisse-lecheck"
clone_repo "uteya/crosstech-awabar" "crosstech-awabar"

# --- Step 4: CLAUDE.local.md 配置 ---
echo ""
echo "━━━ Step 4/7: CLAUDE.local.md 配置 ━━━"

setup_local_md() {
  local pj_dir="$PROJECTS_DIR/$1"
  local local_md="$pj_dir/CLAUDE.local.md"
  local template="$pj_dir/CLAUDE.local.md.perin"

  if [ -f "$local_md" ]; then
    echo "  ⏭️  $1: CLAUDE.local.md 既存（上書きしない）"
  elif [ -f "$template" ]; then
    cp "$template" "$local_md"
    echo "  ✅ $1: CLAUDE.local.md 配置完了"
  else
    echo "  ⚠️  $1: テンプレートが見つかりません（手動で作成してください）"
  fi
}

setup_local_md "nikarasu-strategy"
setup_local_md "lisse-lecheck"
setup_local_md "crosstech-awabar"

# --- Step 5: グローバル CLAUDE.md ---
echo ""
echo "━━━ Step 5/7: グローバル設定 ━━━"

CLAUDE_DIR="$HOME/.claude"
GLOBAL_CLAUDE="$CLAUDE_DIR/CLAUDE.md"
mkdir -p "$CLAUDE_DIR"

if [ -f "$GLOBAL_CLAUDE" ]; then
  echo "  ⏭️  ~/.claude/CLAUDE.md 既存（上書きしない）"
else
  cat > "$GLOBAL_CLAUDE" << 'GLOBALEOF'
# Global Rules — ペりん / にからす

## 基本
- 日本語で応答する（コードコメント・変数名は英語可）
- 重要な意思決定はdocs/decisions.mdに根拠チェーンとともに記録する

## セッション開始ルーチン
1. 現在のプロジェクトの `.context/STATUS.md` を読む
2. 自分の担当タスクを確認する
3. 期日が近いタスクがあれば最初に報告する

## セッション終了ルーチン
1. `.context/CHANGES.md` に作業内容を追記する
2. コミット

## 作業スタイル
- 仕様を先に固めてから実装する（Spec-Driven Development）
- 不明点は推測せず確認する
- 大きなタスクは段階的に分割する

## コミュニケーション
- 簡潔に。冗長な前置きや社交辞令は不要
- 判断に迷ったら選択肢を提示して聞く
- 「〜かもしれません」より「〜です。ただし〜のリスクがあります」

## チーム規約
- 共有リポジトリでは CLAUDE.md（PJルート）のルールに従う
- CLAUDE.local.md に個人設定を記載（.gitignore対象）
- 共有リポジトリへの直接pushは禁止。feature/perin/xxx → PR → 小竹マージ
GLOBALEOF
  echo "  ✅ ~/.claude/CLAUDE.md 配置完了"
fi

# --- Step 6: 追加プロジェクト ---
echo ""
echo "━━━ Step 6/7: 追加プロジェクト（任意） ━━━"
echo ""
echo "  他にクローンしたいプロジェクトがあれば入力してください"
echo "  （空Enterで完了）"
echo ""
echo "  例: uteya/nikarasu-pages"
echo ""

while true; do
  read -p "  リポジトリ (org/name): " extra_repo
  if [ -z "$extra_repo" ]; then
    break
  fi

  extra_name=$(basename "$extra_repo")
  extra_target="$PROJECTS_DIR/$extra_name"

  if [ -d "$extra_target/.git" ]; then
    echo "  ⏭️  $extra_name: 既にクローン済み"
  else
    echo "  📥 $extra_name をクローン中..."
    git clone "${CLONE_PREFIX}${extra_repo}.git" "$extra_target" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "  ✅ $extra_name: クローン完了"

      # CLAUDE.local.md テンプレートがあればコピー
      if [ -f "$extra_target/CLAUDE.local.md.perin" ]; then
        cp "$extra_target/CLAUDE.local.md.perin" "$extra_target/CLAUDE.local.md"
        echo "  ✅ CLAUDE.local.md 自動配置"
      fi
    else
      echo "  ❌ クローン失敗（リポジトリ名を確認してください）"
    fi
  fi
  echo ""
done

# --- Step 7: 完了 ---
echo ""
echo "━━━ Step 7/7: 完了！ ━━━"
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ セットアップ完了！                                   ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  📁 セットアップ済みプロジェクト:                        ║"
echo "║    ~/projects/nikarasu-strategy/   （戦略・WazaAI）       ║"
echo "║    ~/projects/lisse-lecheck/       （LeCHECK）            ║"
echo "║    ~/projects/crosstech-awabar/    （awabar）              ║"
echo "║                                                          ║"
echo "║  📄 グローバル設定:                                      ║"
echo "║    ~/.claude/CLAUDE.md                                   ║"
echo "║                                                          ║"
echo "║  🚀 最初にやること:                                      ║"
echo "║    cd ~/projects/nikarasu-strategy && claude              ║"
echo "║    → 「セットアップを開始してください」                    ║"
echo "║    → 3PJ横断タスク一覧が表示されます                      ║"
echo "║                                                          ║"
echo "║  📖 クイックリファレンス:                                ║"
echo "║    docs/perin-quickref.md                                ║"
echo "║                                                          ║"
echo "║  🔀 ブランチの切り方:                                    ║"
echo "║    git checkout -b feature/perin/タスク名                 ║"
echo "║    （作業後）git push origin feature/perin/タスク名       ║"
echo "║    → GitHubでPR作成 → 小竹がマージ                      ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
