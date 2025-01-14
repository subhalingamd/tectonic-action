#!/usr/bin/env bash

set -e
echo "Compiling $1"
tectonic $1

PUSH_OUTPUT=$(echo "$2" | tr '[:upper:]' '[:lower:]')

if [[ $PUSH_OUTPUT != "yes" ]]; then # Don't push PDF
  exit 0;
fi

OUTPUT_PDF="${1%.*}.pdf"

if [[ ${OUTPUT_PDF:0:1} == "/" ]]; then
  OUTPUT_PDF=${OUTPUT_PDF:1}
fi

FILE_NAME=$(basename $OUTPUT_PDF)
DIR=$(dirname $OUTPUT_PDF)
OUTPUT_PATH=$OUTPUT_PDF

PUSH_PATH=$3
if [[ ! -z $PUSH_PATH ]]; then
  if [[ ${PUSH_PATH:0:1} == "/" ]]; then
    PUSH_PATH=${PUSH_PATH:1}
  fi
  DIR=$PUSH_PATH
  OUTPUT_PATH="$DIR/$FILE_NAME"
fi

PUSH_BRANCH=$4
if [[ -z $PUSH_BRANCH ]]; then
  PUSH_BRANCH=${GITHUB_REF##*/}
fi

LOGGING=$(echo "$5" | tr '[:upper:]' '[:lower:]')
STATUSCODE=$(curl --silent --output resp.json --write-out "%{http_code}" -X GET -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/${DIR}?ref=${PUSH_BRANCH})

if [ $((STATUSCODE/100)) -ne 2 ]; then
  echo "Github's API returned $STATUSCODE"
  if [[ $LOGGING == "yes" ]]; then
    cat resp.json
  fi
  exit 22;
fi

SHA=""
for i in $(jq -c '.[]' resp.json);
do
    NAME=$(echo $i | jq -r .name)
    if [ "$NAME" = "$FILE_NAME" ]; then
        SHA=$(echo $i | jq -r .sha)
        break
    fi
done

echo '{
  "message": "'"update $OUTPUT_PATH"'",
  "committer": {
    "name": "github-actions[bot]",
    "email": "github-actions[bot]@users.noreply.github.com"
  },
  "content": "'"$(base64 -w 0 $OUTPUT_PDF)"'",
  "branch": "'$PUSH_BRANCH'",
  "sha": "'$SHA'"
}' > payload.json

STATUSCODE=$(curl --silent --output resp1.json --write-out "%{http_code}" \
            -i -X PUT -H "Authorization: token $GITHUB_TOKEN" -d @payload.json \
            https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/${OUTPUT_PATH})

if [ $((STATUSCODE/100)) -ne 2 ]; then
  echo "Github's API returned $STATUSCODE"
  if [[ $LOGGING == "yes" ]]; then
    cat resp1.json
  fi
  exit 22;
fi
