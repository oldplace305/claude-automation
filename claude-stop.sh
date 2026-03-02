#!/bin/bash
# =============================================
# 全停止スクリプト
# =============================================

SCRIPT_DIR="$HOME/claude-automation"

echo "🛑 Claude Code自動環境を停止します..."

# 自動応答スクリプトを停止
if [ -f "$SCRIPT_DIR/responder.pid" ]; then
    PID=$(cat "$SCRIPT_DIR/responder.pid")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "   ✅ 自動応答スクリプト停止 (PID: $PID)"
    else
        echo "   ⚠️  自動応答スクリプトは既に停止済み"
    fi
    rm -f "$SCRIPT_DIR/responder.pid"
fi

# tmuxセッションを終了
if tmux has-session -t claude-dev 2>/dev/null; then
    tmux kill-session -t claude-dev
    echo "   ✅ tmuxセッション停止"
else
    echo "   ⚠️  tmuxセッションは既に停止済み"
fi

echo ""
echo "✅ 全て停止しました"
