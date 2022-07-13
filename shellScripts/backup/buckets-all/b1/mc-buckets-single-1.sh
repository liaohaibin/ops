#!/bin/bash

cnt = 0
for i in `tac 1`
do
echo $i
./mc mb inner2/${i}
./mc mirror huawei/${i} inner2/${i}
cnt=$[$cnt+1]
echo "cnt="$cnt
done
