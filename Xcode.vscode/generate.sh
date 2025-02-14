#!/bin/bash

# 获取当前脚本所在目录
SCRIPT_DIR=$(dirname "$0")

# 查找 Xcode 工程目录
XCODE_PROJECT_DIR=$(find "$SCRIPT_DIR/.." -name "*.xcodeproj" -type d -maxdepth 1)

if [ -z "$XCODE_PROJECT_DIR" ]; then
	echo "错误：找不到 Xcode 工程！"
	exit 1
fi

# 将 XCODE_PROJECT_DIR 转换为绝对路径
if command -v realpath >/dev/null 2>&1; then
	# 如果系统有 realpath 命令，使用它
	XCODE_PROJECT_DIR=$(realpath "$XCODE_PROJECT_DIR")
else
	# 如果系统没有 realpath 命令，使用 cd 和 pwd 来获取绝对路径
	XCODE_PROJECT_DIR=$(cd "$XCODE_PROJECT_DIR" && pwd)
fi

echo "XCODE 工程：$XCODE_PROJECT_DIR"

# 查找 Xcode 工作区目录
XCODE_WORKSPACE_DIR=$(find "$SCRIPT_DIR/.." -name "*.xcworkspace" -type d -maxdepth 1)

if [ -z "$XCODE_WORKSPACE_DIR" ]; then
	echo "错误：找不到 Xcode 工作区！"
	exit 1
fi

# 将 XCODE_WORKSPACE_DIR 转换为绝对路径
if command -v realpath >/dev/null 2>&1; then
	# 如果系统有 realpath 命令，使用它
	XCODE_WORKSPACE_DIR=$(realpath "$XCODE_WORKSPACE_DIR")
else
	# 如果系统没有 realpath 命令，使用 cd 和 pwd 来获取绝对路径
	XCODE_WORKSPACE_DIR=$(cd "$XCODE_WORKSPACE_DIR" && pwd)
fi

echo "XCODE 工作区：$XCODE_WORKSPACE_DIR"

# 使用xcodebuild命令获取所有的scheme, 先使用 -project获取，如果获取不到再使用 -workspace
echo "从 '$XCODE_PROJECT_DIR' 中获取scheme列表"
XCODE_SCHEMES=$(xcodebuild -list -project "$XCODE_PROJECT_DIR" 2>/dev/null | awk '/Schemes:/,/^$/ {if (NF && $1 != "Schemes:") print $0}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [ -z "$XCODE_SCHEMES" ]; then
	echo "无法从 '$XCODE_PROJECT_DIR' 中获取到scheme列表"
	echo "从 '$XCODE_WORKSPACE_DIR' 中获取scheme列表"
	XCODE_SCHEMES=$(xcodebuild -list -workspace "$XCODE_WORKSPACE_DIR" 2>/dev/null | awk '/Schemes:/,/^$/ {if (NF && $1 != "Schemes:") print $0}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
	if [ -z "$XCODE_SCHEMES" ]; then
		echo "无法从 '$XCODE_WORKSPACE_DIR' 中获取到scheme列表"
		echo "请检查Xcode工程，确保有正确的scheme配置"
		exit 1
	fi
fi

# 将schemes转换为数组
IFS=$'\n' read -d '' -r -a XCODE_SCHEME_ARRAY <<<"$XCODE_SCHEMES"

# 显示所有可用的schemes
echo "可用的scheme："
for i in "${!XCODE_SCHEME_ARRAY[@]}"; do
	echo "[$((i + 1))] ${XCODE_SCHEME_ARRAY[$i]}"
done

# 提示用户选择scheme
echo "请选择scheme编号（直接回车将默认使用第一项）："
read -r XCODE_SCHEME_INDEX

# 如果用户没有输入，使用默认scheme（第一个）
if [ -z "$XCODE_SCHEME_INDEX" ]; then
	XCODE_SELECTED_SCHEME="${XCODE_SCHEME_ARRAY[0]}"
else
	# 检查输入是否有效
	if ! [[ "$XCODE_SCHEME_INDEX" =~ ^[0-9]+$ ]] || [ "$XCODE_SCHEME_INDEX" -lt 1 ] || [ "$XCODE_SCHEME_INDEX" -gt "${#XCODE_SCHEME_ARRAY[@]}" ]; then
		echo "错误：无效的选择。使用默认scheme。"
		XCODE_SELECTED_SCHEME="${XCODE_SCHEME_ARRAY[0]}"
	else
		XCODE_SELECTED_SCHEME="${XCODE_SCHEME_ARRAY[$((XCODE_SCHEME_INDEX - 1))]}"
	fi
fi

echo "------ 用户使用的scheme: $XCODE_SELECTED_SCHEME ------"

# --- 禁用手动选择 target，xcworkspace 下不支持指定 target --- #
# # 使用xcodebuild命令获取所有的target
# # 使用 -project 而不是 -workspace
# XCODE_TARGETS=$(xcodebuild -list -project "$XCODE_PROJECT_DIR" 2>/dev/null | awk '/Targets:/,/^$/ {if (NF && $1 != "Targets:") print $0}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
# # XCODE_TARGETS=$(xcodebuild -list -workspace "$XCODE_WORKSPACE_DIR" 2>/dev/null | awk '/Targets:/,/^$/ {if (NF && $1 != "Targets:") print $0}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
#
# if [ -z "$XCODE_TARGETS" ]; then
# 	echo "错误：无法获取target列表。请确保Xcode命令行工具已正确安装。"
# 	exit 1
# fi
#
# # 将targets转换为数组
# IFS=$'\n' read -d '' -r -a XCODE_TARGET_ARRAY <<<"$XCODE_TARGETS"
#
# # 显示所有可用的targets
# echo "可用的targets："
# for i in "${!XCODE_TARGET_ARRAY[@]}"; do
# 	echo "[$((i + 1))] ${XCODE_TARGET_ARRAY[$i]}"
# done
#
# # 提示用户选择target
# echo "请选择target编号（直接回车将默认使用第一项）："
# read -r XCODE_TARGET_INDEX
#
# # 如果用户没有输入，使用默认target（第一个）
# if [ -z "$XCODE_TARGET_INDEX" ]; then
# 	XCODE_SELECTED_TARGET="${XCODE_TARGET_ARRAY[0]}"
# else
# 	# 检查输入是否有效
# 	if ! [[ "$XCODE_TARGET_INDEX" =~ ^[0-9]+$ ]] || [ "$XCODE_TARGET_INDEX" -lt 1 ] || [ "$XCODE_TARGET_INDEX" -gt "${#XCODE_TARGET_ARRAY[@]}" ]; then
# 		echo "错误：无效的选择。使用默认target。"
# 		XCODE_SELECTED_TARGET="${XCODE_TARGET_ARRAY[0]}"
# 	else
# 		XCODE_SELECTED_TARGET="${XCODE_TARGET_ARRAY[$((XCODE_TARGET_INDEX - 1))]}"
# 	fi
# fi
#
# echo "------ 用户使用的target: $XCODE_SELECTED_TARGET ------"

# 执行 xcode-build-server 命令
# 检查 xcode-build-server 命令是否存在
if ! command -v xcode-build-server &>/dev/null; then
	echo "错误：xcode-build-server 命令未找到。"
	echo "请使用以下命令通过 Homebrew 安装 xcode-build-server："
	echo "brew install xcode-build-server"
	echo "安装完成后，请重新运行此脚本。"
	exit 1
fi
echo "执行 xcode-build-server 命令，生成 buildServer.json 文件"
xcode-build-server config -workspace "$XCODE_WORKSPACE_DIR" -scheme "$XCODE_SELECTED_SCHEME"

# 检查 buildServer.json 文件是否生成
BUILD_SERVER_JSON="$SCRIPT_DIR/buildServer.json"
if [ -f "$BUILD_SERVER_JSON" ]; then
	echo "buildServer.json 文件已生成。"

	# 复制文件到上一级目录
	cp "$BUILD_SERVER_JSON" "$SCRIPT_DIR/.." || {
		echo "错误：无法复制 buildServer.json 文件" >&2
		exit 1
	}
	echo "已将 buildServer.json 复制到上一级目录。"

	# 删除原文件
	rm "$BUILD_SERVER_JSON" || {
		echo "错误：无法删除原 buildServer.json 文件" >&2
		exit 1
	}
	echo "已删除原 buildServer.json 文件。"
else
	echo "未成功生成 buildServer.json 文件。"
	exit 1
fi

# 定义目标文件路径
LAUNCH_JSON="$SCRIPT_DIR/launch.json"
TASKS_JSON="$SCRIPT_DIR/tasks.json"

# 重新定义 buildServer.json 文件路径
BUILD_SERVER_JSON="$SCRIPT_DIR/../buildServer.json"

# 检查 buildServer.json 是否存在
if [ ! -f "$BUILD_SERVER_JSON" ]; then
	echo "错误：找不到 buildServer.json 文件！"
	exit 1
fi

# 复制 .launch.json 和 .tasks.json 到当前目录并覆盖已有文件
cp "$SCRIPT_DIR/.launch.json" "$LAUNCH_JSON"
cp "$SCRIPT_DIR/.tasks.json" "$TASKS_JSON"

# 从 buildServer.json 提取 build_root, workspace 和 scheme
XCODE_BUILD_ROOT=$(jq -r '.build_root' "$BUILD_SERVER_JSON")
XCODE_WORKSPACE=$(jq -r '.workspace' "$BUILD_SERVER_JSON")
XCODE_SCHEME=$(jq -r '.scheme' "$BUILD_SERVER_JSON")
# --- 在使用 xcworkspace 编译 Xcode 项目时，不能手动指定 target，而需要通过 scheme 间接指定，一般来说 target 和 scheme 必须会对应相同 --- #
XCODE_TARGET=$XCODE_SCHEME
XCODE_BUNDLEID=$(xcodebuild -showBuildSettings -workspace "$XCODE_WORKSPACE" -scheme "$XCODE_SCHEME" | grep '^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER' | sed 's/.*= //')

# 检查提取的变量是否为空
if [ -z "$XCODE_BUILD_ROOT" ]; then
	echo "错误：无法提取 buildServer.json 中 build_root 信息！"
fi
echo "提取到XCODE_BUILD_ROOT: $XCODE_BUILD_ROOT"

if [ -z "$XCODE_WORKSPACE" ]; then
	echo "错误：无法提取 buildServer.json 中 workspace 信息！"
fi
echo "提取到XCODE_WORKSPACE: $XCODE_WORKSPACE"

if [ -z "$XCODE_SCHEME" ]; then
	echo "错误：无法提取 buildServer.json 中 scheme 信息！"
fi
echo "提取到XCODE_SCHEME: $XCODE_SCHEME"

if [ -z "$XCODE_BUNDLEID" ]; then
	echo "错误：无法提取 PRODUCT_BUNDLE_IDENTIFIER 信息！"
fi
echo "提取到XCODE_BUNDLEID: $XCODE_BUNDLEID"

echo "替换 launch.json 中的占位符"
sed -i "" "s|\${#xcodeBuildRoot}|$XCODE_BUILD_ROOT|g" "$LAUNCH_JSON"
sed -i "" "s|\${#xcodeWorkSpace}|$XCODE_WORKSPACE|g" "$LAUNCH_JSON"
sed -i "" "s|\${#xcodeScheme}|$XCODE_SCHEME|g" "$LAUNCH_JSON"
sed -i "" "s|\${#xcodeTarget}|$XCODE_TARGET|g" "$LAUNCH_JSON"
sed -i "" "s|\${#xcodeBundleId}|$XCODE_BUNDLEID|g" "$LAUNCH_JSON"

echo "替换 tasks.json 中的占位符"
sed -i "" "s|\${#xcodeBuildRoot}|$XCODE_BUILD_ROOT|g" "$TASKS_JSON"
sed -i "" "s|\${#xcodeWorkSpace}|$XCODE_WORKSPACE|g" "$TASKS_JSON"
sed -i "" "s|\${#xcodeScheme}|$XCODE_SCHEME|g" "$TASKS_JSON"
sed -i "" "s|\${#xcodeTarget}|$XCODE_TARGET|g" "$TASKS_JSON"
sed -i "" "s|\${#xcodeBundleId}|$XCODE_BUNDLEID|g" "$TASKS_JSON"

echo "操作完成！"
