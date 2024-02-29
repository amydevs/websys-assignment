#!/bin/sh
cd _site
mkdir -p ../tmp
tar -czf ../tmp/workspace.tar *
cd -