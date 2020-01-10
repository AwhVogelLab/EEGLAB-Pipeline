#!/bin/bash
cd "$(dirname "$0")"
fileid="1nz8pfjYjRFbK487LJRVAkCxZfL3SCPxv"
filename="test_data.zip"
curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${filename}

unzip test_data

rm cookie
rm test_data.zip
rm -r __MACOSX/
