#!/bin/bash
# =============================================
# Claude Code 自動応答 + 監視スクリプト
# tmuxセッションの出力を監視し、自動応答する
# =============================================

# PATHを通す
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

SESSION_NAME="claude-dev"
LOG_FILE="$HOME/claude-automation/claude-monitor.log"
CHECK_INTERVAL=3  # 秒ごとにチェック

# LINE通知設定（後で設定）
LINE_NOTIFY_TOKEN=""
LINE_NOTIFY_URL="https://notify-api.line.me/api/notify"

# ログ関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# LINE通知関数
send_line_notify() {
    local message="$1"
    if [ -n "$LINE_NOTIFY_TOKEN" ]; then
        curl -s -X POST "$LINE_NOTIFY_URL" \
            -H "Authorization: Bearer $LINE_NOTIFY_TOKEN" \
            -F "message=$message" > /dev/null 2>&1
        log "📱 LINE通知送信: $message"
    else
        log "⚠️  LINE通知未設定: $message"
    fi
}

# tmuxセッションの最新出力を取得
get_latest_output() {
    tmux capture-pane -t "$SESSION_NAME" -p 2>/dev/null | tail -20
}

log "🚀 Claude Code 自動応答スクリプト開始"
log "監視セッション: $SESSION_NAME"

# メインループ
while true; do
    # セッションが存在するか確認
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        log "❌ セッション '$SESSION_NAME' が見つかりません。待機中..."
        sleep 10
        continue
    fi

    # 最新の出力を取得
    OUTPUT=$(get_latest_output)

    # === 自動応答パターン ===

    # パターン1: ファイル書き込み確認 (Y/n)
    if echo "$OUTPUT" | grep -qE "(Allow|Approve|Permission|Do you want to|Y/n|y/N)" 2>/dev/null; then
        if echo "$OUTPUT" | grep -qE "(delete|remove|drop|destroy|既存データ|本番)" 2>/dev/null; then
            # 危険な操作 → LINE通知して手動対応
            log "🔴 危険な操作を検知！手動対応が必要です"
            send_line_notify "⚠️ Claude Codeで危険な操作の確認が出ています。手動対応してください。"
        else
            # 安全な操作 → 自動でY
            log "🟢 確認プロンプト検知 → 自動でY"
            tmux send-keys -t "$SESSION_NAME" "y" Enter
            sleep 2
        fi

    # パターン2: リミット到達後の再開待ち
    elif echo "$OUTPUT" | grep -qiE "(rate limit|usage limit|limit reached|リミット|制限)" 2>/dev/null; then
        log "⏳ リミット到達検知。復帰を待機中..."
        send_line_notify "⏳ Claude Codeがリミットに到達しました。自動復帰を待っています。"
        sleep 60  # リミット中は1分間隔でチェック
        continue

    # パターン3: リミット解除後 → 「続けて」を自動入力
    elif echo "$OUTPUT" | grep -qE "(❯|>|\\\$)" 2>/dev/null; then
        # プロンプトが表示されている（入力待ち状態）
        LAST_LINE=$(echo "$OUTPUT" | tail -1)
        if echo "$LAST_LINE" | grep -qE "^(❯|>|\\\$)" 2>/dev/null; then
            # 何もないプロンプト → 「続けて」を入力
            log "🔄 入力待ち検知 → 「続けて」を自動入力"
            tmux send-keys -t "$SESSION_NAME" "続けて" Enter
            sleep 5
        fi

    # パターン4: エラー検知
    elif echo "$OUTPUT" | grep -qiE "(error|エラー|failed|失敗)" 2>/dev/null; then
        log "⚠️ エラー検知"
        send_line_notify "⚠️ Claude Codeでエラーが発生しています。確認してください。"
        sleep 30
        continue
    fi

    sleep "$CHECK_INTERVAL"
done
