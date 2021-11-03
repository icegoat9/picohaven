#!/bin/sh
if [ "$#" -ne 2 ];
then
    echo "Usage: $0 source rules" >&2
    exit -1
fi

cat $1 | sed -E -n -f $2

