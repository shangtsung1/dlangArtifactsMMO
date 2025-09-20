#!/usr/bin/env bash

BASE_URL="https://api.artifactsmmo.com/items"
PAGE=1
PAGE_SIZE=50

while : ; do
  RESPONSE=$(curl -s -G "$BASE_URL" \
    --data-urlencode "page=$PAGE" \
    --data-urlencode "page_size=$PAGE_SIZE" \
    -H "Accept: application/json")

  echo "$RESPONSE" | jq -c '.data[]
  | select(.type == "weapon" and .subtype == "tool")
  | {
      code: .code,
      level: .level,
      type: .type,
      skill: (if (.craft and (.craft | type == "array") and (.craft | length > 0)) then .craft[0].skill else null end)
    }'

  TOTAL=$(echo "$RESPONSE" | jq '.total // 0')
  CURRENT_PAGE=$(echo "$RESPONSE" | jq '.page // 0')
  PAGE_SIZE_RESPONSE=$(echo "$RESPONSE" | jq '.page_size // '"$PAGE_SIZE"'')

  if [[ -z "$PAGE_SIZE_RESPONSE" || "$PAGE_SIZE_RESPONSE" -eq 0 ]]; then
    PAGE_SIZE_RESPONSE=$PAGE_SIZE
  fi

  if (( TOTAL == 0 )); then
    break
  fi

  TOTAL_PAGES=$(( (TOTAL + PAGE_SIZE_RESPONSE - 1) / PAGE_SIZE_RESPONSE ))

  if (( CURRENT_PAGE >= TOTAL_PAGES )); then
    break
  fi

  ((PAGE++))
done
