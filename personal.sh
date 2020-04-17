#!/bin/bash

#set line number for vi

vicfg=/root/.vimrc

if [ -f $vicfg ]; then
cat >>${vicfg} << EOF
:set nu
EOF
else
touch ${vicf}g;
cat >> ${vicfg} << EOF
:set nu
EOF
fi

#set alias

label="# User specific aliases and functions"

sed -i "/${label}/a\ \nalias clr='clear'" /root/.bashrc
#sed -e '/# User/a\' -e "\nalias clr='clear'" /root/.bashrc
#第一个-e后的参数是单引号
