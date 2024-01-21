#!/bin/sh

file="$1"
vault="$2"
description="$3"
chunkSize=268435456
percentComplete=0;

echo "Chunking $file";

fileCount=$(ls -1 | grep "^chunk" | wc -l)
percentIncrement=`echo 100/$fileCount|bc -l`
echo "Total parts to upload: " $fileCount

echo  "Initializing multipart upload for $file >> $vault with description $description";

i=0;
for file in $(ls | grep "^chunk") 
  do
    currentHash=$(sha256sum "$file" | awk '{print $1}')
    cumulativeHash=$(echo -n "$cumulativeHash$currentHash" | sha256sum | awk '{print $1}')

	byteStart=$((i*chunkSize))
	byteEnd=$((i*chunkSize+chunkSize-1))

	percentComplete=`echo $percentComplete+$percentIncrement|bc -l`
	printf "%3.2f%% complete, now uploading $file\n" "$percentComplete"

	sleep 1
	i=$(($i+1))
	echo "Cumulative hash after $file: $cumulativeHash"

  done
