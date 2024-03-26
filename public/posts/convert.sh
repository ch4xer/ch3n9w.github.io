#!/bin/bash

# 遍历当前目录下的所有 Markdown 文件
for file in *.md; do
    # 提取文件名（去掉文件扩展名）
    folder_name="${file%.*}"

    # 创建文件夹
    if [ ! -d "$folder_name" ]; then
        mkdir "$folder_name"
        echo "Folder '$folder_name' created successfully."
    else
        echo "Folder '$folder_name' already exists."
    fi
    mv "$file" "$folder_name/index.md"
    echo "'$file' moved to '$folder_name/index.md'."
done
