#!/bin/bash

set -e 
set -o pipefail

if [ ! -z $ECHO ]; then
  set -x #echo on
fi

myPwd=`pwd`
winptyFlag=""
if [[ `uname -s` == MINGW* ]]; then
  # C:/PROJ/Yaaf-Backend
  myPwd=`pwd -W`
  with_withpty=`which winpty`
fi
if [ -z $INTERACTIVE ]; then
  interactiveFlags=""
else
  interactiveFlags="-ti "
  if [ ! -z $with_withpty ]; then
    winptyFlag="winpty"
  fi
fi
#case "$-" in
#*i*) interactiveFlags="-ti " ;;
#esac
#echo $-



MSYS_NO_PATHCONV=1 docker run ${interactiveFlags}--rm -p 4000:4000 -v $myPwd:/srv/jekyll jekyll-yaaf $@


