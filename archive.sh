#!/bin/bash

TAG=$1

if [ -z $TAG ]; then echo "FATAL ERROR: please pass the tag which needs to be archived"; exit 1; fi

echo "==> Archiving tag: $TAG"

git archive --format=tar.gz $TAG >$TAG.tar.gz

