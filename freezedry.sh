#!/bin/sh

file="$1"
vault="$2"
description="$3"
chunkSize=268435456
percentComplete=0;
cumulativeHash
echo "Chunking $file";

fileCount=$(ls -1 | grep "^chunk" | wc -l)
percentIncrement=`echo 100/$fileCount|bc -l`
echo "Total parts to upload: " $fileCount

echo  "Initializing multipart upload for $file >> $vault with description $description";

touch cumulativehash

init=$(aws glacier initiate-multipart-upload --account-id - --part-size $chunkSize --vault-name $vault --archive-description $description)

uploadId=$(echo $init | jq '.uploadId' | xargs)

i=0;
for file in $(ls | grep "^chunk")
do
    rangeStart=$((i*chunkSize))
    rangeEnd=$((i*chunkSize+chunkSize-1))
    
	aws glacier upload-multipart-part --upload-id $uploadId --body $filef --range "'"'bytes '"$rangeStart"'-'"$rangeEnd"'/*'"'" --account-id - --vault-name $vault
    
	currentHash=$(openssl dgst -sha256 -binary "$file" | awk '{print $1}')
    cumulativeHash=$(echo -n "$cumulativeHash$currentHash" | openssl dgst -sha256 -binary | awk '{print $1}')
    
    percentComplete=`echo $percentComplete+$percentIncrement|bc -l`
    printf "%3.2f%% complete, now uploading $file\n" "$percentComplete"
    
    # sleep 1
    i=$(($i+1))
    echo "Cumulative hash after $file: $cumulativeHash"
    echo $cumulativeHash > cumulativehash
    
done

aws glacier complete-multipart-upload --checksum $cumulativeHash --archive-size 3145728 --upload-id $uploadId --account-id - --vault-name $vault