#!/usr/bin/env bash
set -e
source ../.env
# shellcheck disable=SC2046
export $(cut -d= -f1 ../.env)

while [ $# -gt 0 ]; do
  case "${1}" in
    --direction=*)
      direction="${1#*=}"
      if [ "${direction}" != "up" ] && [ "${direction}" != "down" ]; then
        echo "Unsupported value for --direction. Only [up|down], but '${direction}' was specified"
        exit 1
      fi
    ;;
    *)
      echo "Unsupported argument: '${1}'"
      exit 1
    ;;
  esac
  shift
done

if [ -z "${direction}" ]; then
  echo "You must set --direction=[up|down]"
  exit 1
fi

bucket_arn=$(aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=meta_tier,Values=bootstrap \
  --resource-type-filters s3 --query 'ResourceTagMappingList[0].ResourceARN' | jq -r)
bucket_name="${bucket_arn#*:::}"

if [ -z "${bucket_name}" ]; then
  echo "No bucket found (probably first deploy) will not sync tfstate."
  exit 0
fi

unmanaged_terraform_s3_state_key="s3://${bucket_name}/tfstate/unmanaged/boostrap.tf"

if [ "${direction}" == "down" ]; then
  if ! aws s3 ls "${unmanaged_terraform_s3_state_key}"; then
    echo "Remote tfstate doesn't exist, this is (probably) okay. It means we have yet to sync it up."
    exit 0
  fi
  aws s3 cp "${unmanaged_terraform_s3_state_key}" "terraform.tfstate"
elif [ "${direction}" == "up" ]; then
  aws s3 cp "terraform.tfstate" "${unmanaged_terraform_s3_state_key}"
fi