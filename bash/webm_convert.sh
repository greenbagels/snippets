#!/bin/bash
# $1=input file, $2=filesize, $3=version, $4=start time, $5=duration, $6=output file

case $# in
5)
    ofile="output.webm"
    ;; #we don't want to assume there's any default file extension (or one to begin with)
6)
    ofile=$6
    ;;
*)
    echo "Usage: ./script input_file file_size vpx_version start_time duration [output_file]"
    echo "Example: ./script input.mkv 500M vp9 00:00:02 00:02:00 output.mkv"
    exit 1
    ;;
esac


if [[ "$2" =~ [^0-9]+ ]]; then        
    case "${BASH_REMATCH}" in
    "E"|"e")
        fact=1000000000000000000
        ;;
    "P"|"p")
        fact=1000000000000000
        ;;
    "T"|"t")
        fact=1000000000000
        ;;
    "G"|"g")
        fact=1000000000
        ;;
    "M"|"m")
        fact=1000000
        ;;
    "K"|"k")
        fact=1000
        ;;
    *) #Error: Something Happened
        echo "Nonmetric prefix detected."
        exit 1
    esac
fi

if [[ "$2" =~ [0-9]+ ]]; then #convert to bytes
    filesz=$((${BASH_REMATCH} * fact * 8))
else #we don't have a file size?
    echo "No numerical file size provided!"
    exit 1
fi

duration=$((10#${5:6:2} + 10#${5:3:2} * 60 + 10#${5:0:2} * 3600))
bitrate=$((${filesz} / ${duration}))
case "$3" in
"vp8")
    ARGLIST="-c:v libvpx -quality good -cpu-used 0"
    ;;
"vp9")
    ARGLIST="-c:v libvpx-vp9 -auto-alt-ref 1 -lag-in-frames 25 -tile-columns 6 -frame-parallel 1 -speed 1"
    ;;
*)
    echo "vpx_version must be either vp8 or vp9"
    exit 1
esac

#WARNING: ffmpeg will *forcibly overwrite* existing files!
ffmpeg -ss ${4} -y -i ${1} -t ${5} ${ARGLIST} -crf 10 -b:v ${bitrate} -threads $(nproc) -pass 1 -an -f webm /dev/null
ffmpeg -ss ${4} -y -i ${1} -t ${5} ${ARGLIST} -crf 10 -b:v ${bitrate} -threads $(nproc) -pass 2 -c:a libopus -b:a 192k -vbr constrained -compression_level 10 -application audio -f webm ${ofile}
