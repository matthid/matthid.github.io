#!/bin/bash


scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ `uname -s` == MINGW* ]]; then
  # C:/PROJ/Yaaf-Backend
  PROJDIR=`pwd -W`
  export MSYS_NO_PATHCONV=1
else
  PROJDIR=`pwd`
fi
# alias clustermanagement="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v `pwd -W`\clustercgf:/clustercfg -v \"`pwd`:/workdir\" -ti matthid/clustermanagement"

#$scriptDir/build.sh

RUN="$scriptDir/run.sh"
alias run="$RUN"

JEKYLL="$scriptDir/run.sh jekyll"
alias jekyll="$JEKYLL"
