#!/usr/bin/env bash
set -e
source ../.env
# shellcheck disable=SC2046
export $(cut -d= -f1 ../.env)

while [ $# -gt 0 ]; do
  case "${1}" in
    --codepipeline-name=*)
      codepipeline_name="${1#*=}"
    ;;
    *)
      echo "Unsupported argument: '${1}'"
      exit 1
    ;;
  esac
  shift
done

if [ -z "${codepipeline_name}" ]; then
  echo "You must specify a --codepipeline-name=[name here]"
  exit 1
fi

aws codepipeline start-pipeline-execution --name "${codepipeline_name}"
