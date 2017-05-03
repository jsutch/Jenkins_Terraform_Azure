#!/bin/bash
echo "Hello, World - v.10" > index.html
nohup busybox httpd -f -p 2112&
