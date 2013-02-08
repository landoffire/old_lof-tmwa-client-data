#!/bin/bash
export WORLD_DATA_REPOSITORY=../.git
export CLIENT_UPDATES_DIR=../../tmwa-lof-updates
./createupdates.lua
cp ../news.txt $CLIENT_UPDATES_DIR/
