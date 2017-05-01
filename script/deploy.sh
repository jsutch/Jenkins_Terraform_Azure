#!/bin/sh

ssh -i ~/.ssh/id_rsa deployroot@13.91.44.67 <<EOF
uname -a
EOF
