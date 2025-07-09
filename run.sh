#!/bin/bash

INPUT_PATH="处理图片路径"

FILE_NAME=$(basename "$INPUT_PATH")
LOCAL_ORIGIN_DIR=$(dirname "$INPUT_PATH")

CONTAINER_ID=容器名
CONTAINER_IMG_DIR=/erase_project/data/dehw_testA_dataset/images
CONTAINER_TEST_CSV=/erase_project/data/dehw_testA_dataset/test.csv
LOCAL_RESULT_DIR=/data/project/test
FILES=("$FILE_NAME")

# 拷贝图片到容器
for file in "${FILES[@]}"; do
  echo "Copy $file to container..."
  docker cp "$LOCAL_ORIGIN_DIR/$file" "$CONTAINER_ID":"$CONTAINER_IMG_DIR/"
done

# 生成并清空 test.csv 内容
> test.csv
for file in "${FILES[@]}"; do
  echo "data/dehw_testA_dataset/images/$file" >> test.csv
done

# 拷贝 test.csv 到容器
docker cp test.csv "$CONTAINER_ID":"$CONTAINER_TEST_CSV"

# 进入容器运行推理
docker exec -it "$CONTAINER_ID" bash -c "cd /erase_project && python work/main.py --train 0 --arch segformer_b2 --modelLog Log/segformer_b2/02131458.pdparams --testDataRoot data/dehw_testA_dataset"

# 拷贝结果图片到本地
mkdir -p "$LOCAL_RESULT_DIR"
for file in "${FILES[@]}"; do
  result_file="${file%.jpg}.png"
  echo "Copy result $result_file from container..."
  docker cp "$CONTAINER_ID":"/erase_project/data/dehw_testA_dataset/result/$result_file" "$LOCAL_RESULT_DIR/"
done

# 清理本地临时文件
rm test.csv
