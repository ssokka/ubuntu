#!/usr/bin/env sh

# 인코딩
# utf-8 lf

# 설명 및 사용 방법
# https://github.com/ssokka/Ubuntu/tree/master/gsa-gen


path=/app/data/command/gsa-gen.bash
curl -o ${path} https://raw.githubusercontent.com/ssokka/ubuntu/master/gsa-gen/gsa-gen.bash

if [[ -f "${path}" ]]; then
    apk add --no-cache bash
    which bash &>/dev/null
    if [[ $? == 0 ]]; then
        bash /app/data/command/gsa-gen.bash
    fi
fi
