#!/usr/bin/env bash
mkdir prod 2>/dev/null

for i in `seq 1 40`;
do
  echo "./bloc-$i.sh  2> prod/$i.err 1> prod/$i.txt"
  ./bloc-$i.sh  2> prod/$i.err 1> prod/$i.txt
done