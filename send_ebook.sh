#!/bin/bash

# Ebook sending to Kindle script / 电子书发送到Kindle脚本
# Usage / 使用方法: ./send_ebook.sh [file1] [file2] ...
# Or / 或者: ./send_ebook.sh (send latest ebook in current directory / 发送当前目录最新的电子书)

set -e

# Configuration file path / 配置文件路径
CONFIG_FILE="$HOME/.ebook_config"

# Supported file formats / 支持的文件格式
SUPPORTED_FORMATS="epub|pdf|mobi|txt"

# Maximum file size (35MB, Gmail limit) / 最大文件大小 (35MB, Gmail限制)
MAX_SIZE=36700160

# Color output / 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions / 日志函数
log_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check configuration file / 检查配置文件
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Config file doesn't exist / 配置文件不存在: $CONFIG_FILE"
        echo "Please create configuration file with following content / 请创建配置文件，内容如下："
        echo "FROM_EMAIL=\"your@gmail.com\""
        echo "APP_PASSWORD=\"your app password\""
        echo "TO_EMAIL=\"your_kindle@kindle.com\""
        exit 1
    fi
    
    # Load configuration / 加载配置
    source "$CONFIG_FILE"

    # Health check - show configuration content / 健康检查 - 显示配置内容
    echo "🔍 Configuration check / 配置检查:"
    echo "Configuration file / 配置文件: $CONFIG_FILE"
    echo "FROM_EMAIL: '$FROM_EMAIL'"
    echo "TO_EMAIL: '$TO_EMAIL'"
    echo "APP_PASSWORD: '${APP_PASSWORD:0:4}****${APP_PASSWORD: -4}' (length / 长度: ${#APP_PASSWORD} should be 16 / 应为16)"
    
    # Check required configuration / 检查必要配置
    if [ -z "$FROM_EMAIL" ] || [ -z "$APP_PASSWORD" ] || [ -z "$TO_EMAIL" ]; then
        log_error "Configuration file missing required parameters / 配置文件缺少必要参数"
        echo "Please ensure configuration file contains / 请确保配置文件包含: FROM_EMAIL, APP_PASSWORD, TO_EMAIL"
        exit 1
    fi
}

# Check file / 检查文件
check_file() {
    local file="$1"
    
    # Check if file exists / 检查文件是否存在
    if [ ! -f "$file" ]; then
        log_error "File doesn't exist / 文件不存在: $file"
        return 1
    fi
    
    # Check file format / 检查文件格式
    local extension="${file##*.}"
    if ! echo "$extension" | grep -qiE "^($SUPPORTED_FORMATS)$"; then
        log_warn "Unsupported format / 不支持的格式: $file (supported / 支持: $SUPPORTED_FORMATS)"
        return 1
    fi
    
    # Check file size / 检查文件大小
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    if [ "$size" -gt "$MAX_SIZE" ]; then
        log_warn "File too large / 文件过大: $file ($(($size/1024/1024))MB > 35MB)"
        return 1
    fi
    
    return 0
}

# Create email content / 创建邮件内容
create_email() {
    local file="$1"
    local filename=$(basename "$file")
    local boundary="----=_NextPart_$(date +%s)"
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    local size_mb=$(echo "scale=2; $size/1024/1024" | bc 2>/dev/null || echo "unknown")
    
    cat << EOF
From: $FROM_EMAIL
To: $TO_EMAIL
Subject: Ebook from Pigeon
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="$boundary"

--$boundary
Content-Type: text/plain; charset=utf-8

Ebook attachment: $filename
File size: ${size_mb}MB
Sent: $(date '+%Y-%m-%d %H:%M:%S')

--$boundary
Content-Type: application/octet-stream; name="$filename"
Content-Disposition: attachment; filename="$filename"
Content-Transfer-Encoding: base64

$(base64 -i "$file")
--$boundary--
EOF
}

# Send email / 发送邮件
send_email() {
    local file="$1"
    local filename=$(basename "$file")

    # Show file information / 显示文件信息
    local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    log_info "Original file size / 原始文件大小: $(echo "scale=2; $file_size/1024" | bc)KB"
    
    log_info "Sending / 正在发送: $filename"
    
    # Create temporary email file / 创建临时邮件文件
    local temp_email=$(mktemp)
    create_email "$file" > "$temp_email"

    # Show email file information / 显示邮件文件信息
    local email_size=$(stat -f%z "$temp_email" 2>/dev/null || stat -c%s "$temp_email" 2>/dev/null)
    log_info "MIME email size / MIME邮件大小: $(echo "scale=2; $email_size/1024" | bc)KB"
    log_info "Base64 expansion rate / base64膨胀率: $(echo "scale=1; $email_size*100/$file_size" | bc)%"
    
    # Send email / 发送邮件
    local result
    local curl_output=$(mktemp)
    local curl_code
    
    if curl -v --url 'smtps://smtp.gmail.com:465' \
        --ssl-reqd \
        --user "$FROM_EMAIL:$APP_PASSWORD" \
        --mail-from "$FROM_EMAIL" \
        --mail-rcpt "$TO_EMAIL" \
        --upload-file "$temp_email" \
        --connect-timeout 30 \
        --max-time 300 \
        --progress-bar \
        --show-error \
        --write-out "%{http_code}" \
        --stderr "$curl_output"; then
        log_info "Successfully sent / 成功发送: $filename"
        result=0
    else
        curl_code=$?
        log_error "Failed to send / 发送失败: $filename (curl exit code / curl退出码: $curl_code)"
        if [ -s "$curl_output" ]; then
            echo "Error details / 错误详情:"
            cat "$curl_output"
        fi
        result=1
    fi
    
    # Clean up temporary files / 清理临时文件
    rm -f "$temp_email" "$curl_output"
    return $result
}

# Get latest ebook file / 获取最新的电子书文件
get_latest_ebook() {
    find . -maxdepth 1 -type f \( -iname "*.epub" -o -iname "*.pdf" -o -iname "*.mobi" -o -iname "*.txt" \) -exec ls -t {} + | head -1
}

# Main function / 主函数
main() {
    echo "🕊️ Pigeon: Ebook sending tool / 信鸽：电子书发送工具 📚"
    
    # Check configuration / 检查配置
    check_config
    
    # Check dependencies / 检查依赖
    command -v curl >/dev/null 2>&1 || { log_error "Need to install curl / 需要安装 curl"; exit 1; }
    command -v base64 >/dev/null 2>&1 || { log_error "Need to install base64 / 需要安装 base64"; exit 1; }
    
    local files=()
    
    # Process arguments / 处理参数
    if [ $# -eq 0 ]; then
        # No arguments, send latest ebook / 没有参数，发送最新的电子书
        local latest_file=$(get_latest_ebook)
        if [ -n "$latest_file" ]; then
            files=("$latest_file")
            log_info "Found latest ebook / 找到最新电子书: $(basename "$latest_file")"
        else
            log_error "No ebook files found in current directory / 当前目录没有找到电子书文件"
            exit 1
        fi
    else
        # Has arguments, process specified files / 有参数，处理指定文件
        files=("$@")
    fi
    
    # Send files / 发送文件
    local success_count=0
    local total_count=${#files[@]}
    
    for file in "${files[@]}"; do
        if check_file "$file"; then
            if send_email "$file"; then
                ((success_count++))
            fi
        fi
    done
    
    # Summary / 总结
    echo ""
    if [ $success_count -eq $total_count ]; then
        log_info "All files sent successfully / 全部发送完成: $success_count/$total_count"
    elif [ $success_count -gt 0 ]; then
        log_warn "Partially sent successfully / 部分发送成功: $success_count/$total_count"
    else
        log_error "Failed to send / 发送失败: $success_count/$total_count"
        exit 1
    fi
}

# Run main function / 运行主函数
main "$@"