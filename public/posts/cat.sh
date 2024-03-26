#!/bin/bash

# 在当前目录及所有子目录中查找名为index.md的文件
# 并将文件中的"category"替换为"categories"
find . -type f -name "index.md" | while read file; do
    # 使用sed命令直接在文件中执行替换操作
    # -i 选项表示直接修改文件，'s/category/categories/g' 定义了替换操作
    sed -i 's/categories: 做题/categories: CTF/g' "$file"
    echo "Updated $file"
done
