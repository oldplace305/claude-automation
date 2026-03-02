#!/bin/bash
# =============================================
# ワンクリック起動スクリプト
# Claude Code + 自動応答を一発で起動
# =============================================

SCRIPT_DIR="$HOME/claude-automation"

# PATHを通す
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

echo "========================================"
echo "  Claude Code 自動開発環境 起動"
echo "========================================"
echo ""

# プロジェクトディレクトリを選択
if [ -n "$1" ]; then
    PROJECT_DIR="$1"
else
    PROJECT_DIR="$HOME"
    echo "💡 プロジェクトを指定する場合:"
    echo "   ./claude-start.sh /path/to/project"
    echo ""
    echo "デフォルト ($PROJECT_DIR) で起動します..."
    echo ""
fi

# Step 1: tmuxセッション起動 + Claude Code開始
echo "🚀 Step 1: Claude Codeセッション起動..."
bash "$SCRIPT_DIR/start-claude-session.sh" "$PROJECT_DIR"

sleep 3

# Step 2: 自動応答スクリプトをバックグラウンド起動
echo "🤖 Step 2: 自動応答スクリプト起動..."
nohup bash "$SCRIPT_DIR/auto-responder.sh" > /dev/null 2>&1 &
RESPONDER_PID=$!
echo "$RESPONDER_PID" > "$SCRIPT_DIR/responder.pid"
echo "   PID: $RESPONDER_PID"

echo ""
echo "========================================"
echo "  ✅ 起動完了！"
echo "========================================"
echo ""
echo "📺 Claude Codeの画面を見る:"
echo "   tmux attach -t claude-dev"
echo ""
echo "📋 自動応答ログを見る:"
echo "   tail -f $SCRIPT_DIR/claude-monitor.log"
echo ""
echo "🛑 全部停止する:"
echo "   bash $SCRIPT_DIR/claude-stop.sh"
echo ""
