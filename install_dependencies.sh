#!/bin/bash
# Quick and easy install of tools through `apt`

sudo apt update && \
    sudo apt install -y sublist3r

if [ ! -e "sd-goo.sh" ] 
then 
    echo "download sd-goo.sh" >&2 # TODO: add download functionality
    exit 1
fi