#!/bin/bash
echo "Hello, World" > index.html
#busybox httpd -f -p 8080
nohup busybox httpd -f -p 2112&
