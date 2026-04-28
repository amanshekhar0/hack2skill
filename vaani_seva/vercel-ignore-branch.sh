#!/usr/bin/env bash
# Vercel: exit 0 = skip deployment, non-zero = proceed with build.
# Only deploy when the triggering ref is abhishek/dashboard.
set -euo pipefail
if [ "${VERCEL_GIT_COMMIT_REF:-}" = "abhishek/dashboard" ]; then
  exit 1
else
  exit 0
fi
