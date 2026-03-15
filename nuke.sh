#!/usr/bin/env bash
set -eu

export DISABLE_TELEMETRY=true

cloud-nuke inspect-aws --region us-east-1
