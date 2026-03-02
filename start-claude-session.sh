#!/bin/bash
# =============================================
# Claude Code tmuxセッション起動スクリプト
# 使い方: ./start-claude-session.sh [プロジェクトパス]
# =============================================

# PATHを通す
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

SESSION_NAME="claude-dev"
PROJECT_DIR="${1:-$HOME}"

# 既存セッションがあれば確認
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  既にセッション '$SESSION_NAME' が存在します"
    echo "   接続する場合: tmux attach -t $SESSION_NAME"
    echo "   終了してから再起動する場合: tmux kill-session -t $SESSION_NAME"
    exit 0
fi

# 新しいtmuxセッションを作成
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"

# セッション内でClaude Codeを起動
tmux send-keys -t "$SESSION_NAME" "cd $PROJECT_DIR && claude" Enter

echo "✅ tmuxセッション '$SESSION_NAME' を起動しました"
echo "📂 プロジェクト: $PROJECT_DIR"
echo ""
echo "--- 操作方法 ---"
echo "画面を見る:   tmux attach -t $SESSION_NAME"
echo "画面から離れる: Ctrl+B → D（セッションは裏で継続）"
echo "セッション終了: tmux kill-session -t $SESSION_NAME"
