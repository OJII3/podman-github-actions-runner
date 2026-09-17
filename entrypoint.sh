#!/usr/bin/env bash
set -euo pipefail

runner_root="${RUNNER_ROOT:-/srv/gha-runner}"
cd "$runner_root"

if [[ ! -x ./config.sh || ! -x ./run.sh ]]; then
  echo "GitHub Actions runner is not installed in ${runner_root}" >&2
  exit 1
fi

if [[ ! -f .runner ]]; then
  : "${RUNNER_URL:?RUNNER_URL is required for the first start}"
  : "${RUNNER_TOKEN:?RUNNER_TOKEN is required for the first start}"

  ./config.sh \
    --unattended \
    --url "$RUNNER_URL" \
    --token "$RUNNER_TOKEN" \
    --name "${RUNNER_NAME:-podman-ubuntu-runner}" \
    --labels "${RUNNER_LABELS:-podman}" \
    --work _work
fi

exec ./run.sh
