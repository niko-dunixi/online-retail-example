#!/usr/bin/env bash

env_file=".env"
echo '' > "${env_file}"
# These will be different for everyone
if [ -z "${AWS_PROFILE}" ]; then
	read -rp "Enter AWS_PROFILE: " AWS_PROFILE
fi
echo "AWS_PROFILE=${AWS_PROFILE}" >> "${env_file}"
if [ -z "${AWS_REGION}" ]; then
  read -rp "Enter AWS_REGION: " AWS_REGION
fi
echo "AWS_REGION=${AWS_REGION}" >> "${env_file}"
# This keeps non-interactive use of AWS cli (EG in shellscripts)
# fairly sane
echo "AWS_PAGER=" >> ${env_file}
