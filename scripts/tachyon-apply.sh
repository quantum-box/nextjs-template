#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_TENANT_ID="tn_01hjjn348rn3t49zz6hvmfq67p"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPOSITORY_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly TEMPLATE_PATH="${REPOSITORY_ROOT}/tachyon.yml"

TACHYON_BIN="${TACHYON_BIN:-tachyon}"
TENANT_ID="${TACHYON_TENANT_ID:-${DEFAULT_TENANT_ID}}"
DEFAULT_BRANCH="${TACHYON_DEFAULT_BRANCH:-main}"

remote_url="${TACHYON_REPOSITORY_URL:-$(git -C "${REPOSITORY_ROOT}" remote get-url origin)}"
remote_url="${remote_url%/}"
remote_url="${remote_url%.git}"

case "${remote_url}" in
  https://github.com/*) repository_slug="${remote_url#https://github.com/}" ;;
  http://github.com/*) repository_slug="${remote_url#http://github.com/}" ;;
  git@github.com:*) repository_slug="${remote_url#git@github.com:}" ;;
  ssh://git@github.com/*) repository_slug="${remote_url#ssh://git@github.com/}" ;;
  *)
    echo "Unsupported origin URL: expected a GitHub HTTPS or SSH remote." >&2
    exit 1
    ;;
esac

REPOSITORY_OWNER="${repository_slug%%/*}"
REPOSITORY_NAME="${repository_slug#*/}"
APP_NAME="${TACHYON_APP_NAME:-${REPOSITORY_NAME}}"

for value in "${REPOSITORY_OWNER}" "${REPOSITORY_NAME}" "${APP_NAME}" "${TENANT_ID}"; do
  if [[ ! "${value}" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Derived configuration contains unsupported characters." >&2
    exit 1
  fi
done

if [[ ! "${DEFAULT_BRANCH}" =~ ^[A-Za-z0-9._/-]+$ ]]; then
  echo "Default branch contains unsupported characters." >&2
  exit 1
fi

if [[ -z "${REPOSITORY_OWNER}" || -z "${REPOSITORY_NAME}" || "${REPOSITORY_NAME}" == */* ]]; then
  echo "Could not derive GitHub owner and repository from origin." >&2
  exit 1
fi

if ! command -v "${TACHYON_BIN}" >/dev/null 2>&1; then
  echo "tachyon CLI was not found; set TACHYON_BIN to its executable path." >&2
  exit 1
fi

rendered_manifest="$(mktemp)"
trap 'rm -f "${rendered_manifest}"' EXIT

# Only render the leading consumer template; later documents belong to this repository.
sed -n \
  -e '/^---[[:space:]]*$/q' \
  -e "s|__APP_NAME__|${APP_NAME}|g" \
  -e "s|__TENANT_ID__|${TENANT_ID}|g" \
  -e "s|__REPOSITORY_OWNER__|${REPOSITORY_OWNER}|g" \
  -e "s|__REPOSITORY_NAME__|${REPOSITORY_NAME}|g" \
  -e "s|__DEFAULT_BRANCH__|${DEFAULT_BRANCH}|g" \
  -e p \
  "${TEMPLATE_PATH}" >"${rendered_manifest}"

echo "Applying Cloud App ${APP_NAME} from ${REPOSITORY_OWNER}/${REPOSITORY_NAME} to ${TENANT_ID}."
"${TACHYON_BIN}" compute apps apply \
  --file "${rendered_manifest}" \
  --app "${APP_NAME}" \
  --tenant-id "${TENANT_ID}" \
  "$@"
