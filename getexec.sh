#!/bin/bash

export VERIFY_CHECKSUM=0
export ALIAS=""
export OWNER=go-acme
export REPO=lego
export BINLOCATION="/usr/local/bin"
export SUCCESS_CMD="$BINLOCATION/$REPO version"
export VERIFY_CHECKSUM=1
export suffix=${REPO}_${version}_linux_amd64.tar.gz

###############################
# Content common across repos #
###############################

export version=$(curl -sI https://github.com/$OWNER/$REPO/releases/latest | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
./get.sh
