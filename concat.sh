#!/bin/bash

# 結合された Markdown ファイルの出力先
output_file="combined.md"

# 出力ファイルを空にする
> "$output_file"

# ch2 から ch15 までのディレクトリをループ処理
for dir in ch2 ch3 ch4 ch5 ch6 ch7 ch8 ch9 ch10 ch11 ch12 ch13 ch14 ch15; do
  # ディレクトリ内のすべての Markdown ファイルを検索して結合
  find "$dir" -name "*.md" -print0 | while IFS= read -r -d $'\0' file; do
    echo "結合中: $file"
    cat "$file" >> "$output_file"
    echo "" >> "$output_file"  # ファイル間に空行を追加
  done
done

echo "Markdown ファイルの結合が完了しました: $output_file"
