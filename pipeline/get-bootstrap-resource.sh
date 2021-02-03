#!/usr/bin/env bash
set -e
if [ -f ../.env ]; then
  source ../.env
  # shellcheck disable=SC2046
  export $(cut -d= -f1 ../.env)
fi

while [ $# -gt 0 ]; do
  case "${1}" in
    --resource=*)
      resource="${1#*=}"
    ;;
    *)
      echo "Unsupported argument: '${1}'"
      exit 1
    ;;
  esac
  shift
done

resource_arn=$(aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=meta_tier,Values=bootstrap \
  --resource-type-filters "${resource}" --query 'ResourceTagMappingList[0].ResourceARN' | jq -r '.')

if [ "${resource}" == "s3" ]; then
  resource_name="${resource_arn#*:::}"
elif [ "${resource}" == "dynamodb" ]; then
  resource_name="${resource_arn#*/}"
else
  resource_name="${resource_arn#*:}"
fi
echo "${resource_name}"
