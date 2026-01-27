#!/bin/bash

APP_DIR="${APP_DIR:-/app}"

exit_with_err() {
  local msg="${1?}"
  echo "ERROR: ${msg}"
  exit 1
}

function run_orca_sast_scan() {
  cd "${GITHUB_WORKSPACE}" || exit_with_err "could not find GITHUB_WORKSPACE: ${GITHUB_WORKSPACE}"
  git config --global --add safe.directory "$PWD"
  echo "Running Orca SAST scan:"
  echo orca-cli "${GLOBAL_FLAGS[@]}" sast scan "${SCAN_FLAGS[@]}" --containerized-mode
  orca-cli "${GLOBAL_FLAGS[@]}" sast scan "${SCAN_FLAGS[@]}" --containerized-mode
  export ORCA_EXIT_CODE=$?

  # save exit code on output
  echo "exit_code=${ORCA_EXIT_CODE}" >>"$GITHUB_OUTPUT"
}

function set_global_flags() {
  GLOBAL_FLAGS=()
  if [ "${INPUT_EXIT_CODE}" ]; then
    GLOBAL_FLAGS+=(--exit-code "${INPUT_EXIT_CODE}")
  fi
  if [ "${INPUT_NO_COLOR}" == "true" ]; then
    GLOBAL_FLAGS+=(--no-color)
  fi
  if [ "${INPUT_PROJECT_KEY}" ]; then
    GLOBAL_FLAGS+=(--project-key "${INPUT_PROJECT_KEY}")
  fi
  if [ "${INPUT_SILENT}" == "true" ]; then
    GLOBAL_FLAGS+=(--silent)
  fi
  if [ "${INPUT_CONFIG}" ]; then
    GLOBAL_FLAGS+=(--config "${INPUT_CONFIG}")
  fi
  if [ "${INPUT_DISABLE_ERR_REPORT}" == "true" ]; then
    GLOBAL_FLAGS+=(--disable-err-report)
  fi
  if [ "${INPUT_DISPLAY_NAME}" ]; then
    GLOBAL_FLAGS+=(--display-name "${INPUT_DISPLAY_NAME}")
  fi
  if [ "${INPUT_DEBUG}" == "true" ]; then
    GLOBAL_FLAGS+=(--debug)
  fi
  if [ "${INPUT_LOG_PATH}" ]; then
    GLOBAL_FLAGS+=(--log-path "${INPUT_LOG_PATH}")
  fi
  if [ "${INPUT_CUSTOM_SAST_CONTROLS}" ]; then
    GLOBAL_FLAGS+=(--custom-sast-controls "${INPUT_CUSTOM_SAST_CONTROLS}")
  fi
  if [ "${INPUT_STRICT_MODE}" == "true" ]; then
    GLOBAL_FLAGS+=(--strict-mode)
  fi
}

# Json format must be reported and be stored in a file for github annotations
function prepare_json_to_file_flags() {
  # Output directory must be provided to store the json results
  OUTPUT_FOR_JSON="${INPUT_OUTPUT}"
  CONSOLE_OUTPUT_FOR_JSON="${INPUT_CONSOLE_OUTPUT}"
  if [[ -z "${INPUT_OUTPUT}" ]]; then
    # Results should be printed to console in the selected format
    CONSOLE_OUTPUT_FOR_JSON="${INPUT_FORMAT:-cli}"
    # Results should also be stored in a directory
    OUTPUT_FOR_JSON="orca_results/"
  fi

  if [[ -z "${INPUT_FORMAT}" ]]; then
    # The default format should be provided together with the one we are adding
    FORMATS_FOR_JSON="cli,json"
  else
    if [[ "${INPUT_FORMAT}" == *"json"* ]]; then
      FORMATS_FOR_JSON="${INPUT_FORMAT}"
    else
      FORMATS_FOR_JSON="${INPUT_FORMAT},json"
    fi
  fi

  # Used during the annotation process
  export OUTPUT_FOR_JSON CONSOLE_OUTPUT_FOR_JSON FORMATS_FOR_JSON
}

function set_sast_scan_flags() {
  SCAN_FLAGS=()
  if [ "${INPUT_PATH}" ]; then
    SCAN_FLAGS+=(--path "${INPUT_PATH}")
  fi
  if [ "${INPUT_EXCLUDE_PATHS}" ]; then
    SCAN_FLAGS+=(--exclude-paths "${INPUT_EXCLUDE_PATHS}")
  fi
  if [ "${INPUT_TIMEOUT}" ]; then
    SCAN_FLAGS+=(--timeout "${INPUT_TIMEOUT}")
  fi
  if [ "${INPUT_PREVIEW_LINES}" ]; then
    SCAN_FLAGS+=(--preview-lines "${INPUT_PREVIEW_LINES}")
  fi
  if [ "${FORMATS_FOR_JSON}" ]; then
    SCAN_FLAGS+=(--format "${FORMATS_FOR_JSON}")
  fi
  if [ "${OUTPUT_FOR_JSON}" ]; then
    SCAN_FLAGS+=(--output "${OUTPUT_FOR_JSON}")
  fi
  if [ "${CONSOLE_OUTPUT_FOR_JSON}" ]; then
    SCAN_FLAGS+=(--console-output="${CONSOLE_OUTPUT_FOR_JSON}")
  fi
  if [ "${INPUT_MAX_FILE_SIZE}" ]; then
    SCAN_FLAGS+=(--max-file-size "${INPUT_MAX_FILE_SIZE}")
  fi
}

function set_env_vars() {
  if [ "${INPUT_API_TOKEN}" ]; then
    export ORCA_SECURITY_API_TOKEN="${INPUT_API_TOKEN}"
  fi
}

function validate_flags() {
  [[ -n "${INPUT_PATH}" ]] || exit_with_err "Path must be provided"
  [[ "${INPUT_PATH}" != /* ]] || exit_with_err "Path shouldn't be absolute. Please provide a relative path within the repository. Use '.' to scan the entire repository"
  [[ -n "${INPUT_API_TOKEN}" ]] || exit_with_err "api_token must be provided"
  [[ -n "${INPUT_PROJECT_KEY}" ]] || exit_with_err "project_key must be provided"
  [[ -z "${INPUT_OUTPUT}" ]] || [[ "${INPUT_OUTPUT}" == */ ]] || [[ -d "${INPUT_OUTPUT}" ]] || exit_with_err "Output must be a folder (end with /)"
}

annotate() {
  if [ "${INPUT_SHOW_ANNOTATIONS}" == "false" ]; then
    exit "${ORCA_EXIT_CODE}"
  fi
  mkdir -p "${APP_DIR}/${OUTPUT_FOR_JSON}"
  cp "${OUTPUT_FOR_JSON}/sast.json" "${APP_DIR}/${OUTPUT_FOR_JSON}/" || exit_with_err "error during annotations initiation"
  cd "${APP_DIR}" || exit 1
  npm run build --if-present
  node dist/index.js
}

function main() {
  validate_flags
  set_env_vars
  set_global_flags
  prepare_json_to_file_flags
  set_sast_scan_flags
  run_orca_sast_scan
  annotate
}

main "${@}"
