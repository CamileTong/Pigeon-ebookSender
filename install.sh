#!/bin/bash

# macOS ebook sending tool installer script / macOS 电子书发送工具安装脚本
# Install script to system and create right-click menu / 安装脚本到系统，并创建右键菜单

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "📚 Ebook sending tool - macOS installer / 电子书发送工具 - macOS 安装程序"
echo ""

# 1. Create directories / 创建目录
BIN_DIR="$HOME/bin"
SERVICES_DIR="$HOME/Library/Services"

mkdir -p "$BIN_DIR"
mkdir -p "$SERVICES_DIR"

# 2. Copy script file / 复制脚本文件
SCRIPT_FILE=""
if [ -f "send_ebook.sh" ]; then
    SCRIPT_FILE="send_ebook.sh"
elif [ -f "$(dirname "$0")/send_ebook.sh" ]; then
    SCRIPT_FILE="$(dirname "$0")/send_ebook.sh"
else
    log_error "Cannot find send_ebook.sh file / 找不到 send_ebook.sh 文件"
    echo "Please ensure send_ebook.sh is in the same directory as installer script, or in current directory / 请确保 send_ebook.sh 与安装脚本在同一目录，或在当前目录中"
    exit 1
fi

cp "$SCRIPT_FILE" "$BIN_DIR/"
chmod +x "$BIN_DIR/send_ebook.sh"
log_info "Script installed to / 已安装脚本到: $BIN_DIR/send_ebook.sh"

# 3. Create configuration file template / 创建配置文件模板
CONFIG_FILE="$HOME/.ebook_config"
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# Ebook sending configuration file / 电子书发送配置文件
FROM_EMAIL="your@gmail.com"
APP_PASSWORD="your app password"
TO_EMAIL="your_kindle@kindle.com"
EOF
    log_info "Configuration file template created / 已创建配置文件模板: $CONFIG_FILE"
    log_warn "Please edit configuration file with correct information / 请编辑配置文件填入正确信息"
else
    log_info "Configuration file already exists / 配置文件已存在: $CONFIG_FILE"
fi

# 4. Add to PATH (if needed) / 添加到PATH (如果需要)
SHELL_RC=""
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    SHELL_RC="$HOME/.bash_profile"
fi

if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    if ! grep -q "export PATH.*$BIN_DIR" "$SHELL_RC"; then
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
        log_info "Added to PATH / 已添加到PATH: $SHELL_RC"
    fi
fi

# 5. Create Automator Quick Action / 创建Automator快速操作
WORKFLOW_PATH="$SERVICES_DIR/Send to Kindle.workflow"

if [ ! -d "$WORKFLOW_PATH" ]; then
    mkdir -p "$WORKFLOW_PATH/Contents"
    
    # Create Info.plist / 创建Info.plist
    cat > "$WORKFLOW_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.Automator.SendToKindle</string>
    <key>CFBundleName</key>
    <string>Send to Kindle</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

    # Create document.wflow / 创建document.wflow
    cat > "$WORKFLOW_PATH/Contents/document.wflow" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>444.42</string>
    <key>AMApplicationVersion</key>
    <string>2.9</string>
    <key>AMDocumentVersion</key>
    <string>2</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <true/>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.path</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>2.0.3</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMParameterProperties</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <dict>
                        <key>tokenizedValue</key>
                        <array>
                            <string>$HOME/bin/send_ebook.sh "\$@"</string>
                        </array>
                    </dict>
                </dict>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.attributed-string</string>
                    </array>
                </dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>$HOME/bin/send_ebook.sh "\$@"</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>1</integer>
                    <key>shell</key>
                    <string>/bin/bash</string>
                    <key>source</key>
                    <string></string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.RunShellScript</string>
                <key>CFBundleVersion</key>
                <string>2.0.3</string>
                <key>CanShowSelectedItemsWhenRun</key>
                <false/>
                <key>CanShowWhenRun</key>
                <true/>
                <key>Category</key>
                <array>
                    <string>AMCategoryUtilities</string>
                </array>
                <key>Class Name</key>
                <string>RunShellScriptAction</string>
                <key>InputUUID</key>
                <string>A1F0C8C1-B8A5-4C8D-9B5E-123456789ABC</string>
                <key>Keywords</key>
                <array>
                    <string>Shell</string>
                    <string>Script</string>
                    <string>Command</string>
                    <string>Run</string>
                    <string>Unix</string>
                </array>
                <key>OutputUUID</key>
                <string>B2F1D9D2-C9B6-5D9E-AC6F-234567890BCD</string>
                <key>UUID</key>
                <string>C3F2EAEA-DACA-6EAF-BD7G-345678901CDE</string>
                <key>UnlocalizedApplications</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>arguments</key>
                <dict>
                    <key>0</key>
                    <dict>
                        <key>default value</key>
                        <string>$HOME/bin/send_ebook.sh "\$@"</string>
                        <key>name</key>
                        <string>COMMAND_STRING</string>
                        <key>required</key>
                        <string>0</string>
                        <key>type</key>
                        <string>0</string>
                        <key>uuid</key>
                        <string>0</string>
                    </dict>
                </dict>
                <key>isViewVisible</key>
                <true/>
                <key>location</key>
                <string>309.000000:253.000000</string>
                <key>nibPath</key>
                <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/English.lproj/main.nib</string>
            </dict>
            <key>isViewVisible</key>
            <true/>
        </dict>
    </array>
    <key>connectors</key>
    <dict/>
    <key>workflowMetaData</key>
    <dict>
        <key>serviceInputTypeIdentifier</key>
        <string>com.apple.Automator.fileSystemObject</string>
        <key>serviceOutputTypeIdentifier</key>
        <string>com.apple.Automator.nothing</string>
        <key>serviceApplicationBundleIdentifier</key>
        <string>com.apple.finder</string>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
EOF

    log_info "Right-click menu created / 已创建右键菜单: Send to Kindle"
else
    log_info "Right-click menu already exists / 右键菜单已存在"
fi

echo ""
log_info "Installation completed! / 安装完成！"
echo ""
echo "Next steps / 下一步操作："
echo "1. Edit configuration file / 编辑配置文件: nano ~/.ebook_config"
echo "2. Get Gmail App Password and fill in configuration / 获取Gmail App Password并填入配置"
echo "3. Usage / 使用方法:"
echo "   - Command line / 命令行: send_ebook.sh book.pdf"
echo "   - Right-click menu / 右键菜单: Select file -> Quick Actions -> Send to Kindle / 选择文件 -> 快速操作 -> Send to Kindle"
echo ""
echo "App Password setup method / App Password获取方法:"
echo "1. Enable two-factor authentication / 开启两步验证: https://myaccount.google.com/security"
echo "2. Generate app-specific password / 生成应用专用密码: Security -> App passwords / 安全性 -> 应用专用密码"
echo ""

# Check if terminal restart is needed / 检查是否需要重启终端
if [ -n "$SHELL_RC" ]; then
    log_warn "Please restart terminal or run / 请重启终端或运行: source $SHELL_RC"
fi