#!/usr/bin/env bash
set -x
aws sts get-caller-identity --query Account | jq -r '.'
