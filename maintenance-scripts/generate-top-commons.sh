#!/usr/bin/env bash

# -----------------------------------------------------------------------------
#
# This file is part of the xPack project (http://xpack.github.io).
# Copyright (c) 2024 Liviu Ionescu.  All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
#
# If a copy of the license was not distributed with this file, it can
# be obtained from https://opensource.org/licenses/mit/.
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Identify the script location, to reach, for example, the helper scripts.

script_path="$0"
if [[ "${script_path}" != /* ]]
then
  # Make relative path absolute.
  script_path="$(pwd)/$0"
fi

script_name="$(basename "${script_path}")"

script_folder_path="$(dirname "${script_path}")"
script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

# set -x

# The script is invoked via the following npm script:
# "generate-commons": "bash node_modules/@xpack/node-modules-helper/scripts/generate-commons.sh"

project_folder_path="$(dirname $(dirname $(dirname $(dirname "${script_folder_path}"))))"
helper_folder_path="$(dirname "${script_folder_path}")"

source "${script_folder_path}/compute-context.sh"

tmp_script_file="$(mktemp -t script)"

# -----------------------------------------------------------------------------

echo
echo "Generate top package.json..."

liquidjs --context "${context}" --template "@${helper_folder_path}/templates/package-liquid.json" --output "${tmp_script_file}"

# https://trentm.com/json
cat "${project_folder_path}/package.json" "${tmp_script_file}" | json --deep-merge >"${project_folder_path}/package-new.json"
rm "${project_folder_path}/package.json"
mv -v "${project_folder_path}/package-new.json" "${project_folder_path}/package.json"

echo
echo "Generating workflows..."

echo liquidjs -> "${project_folder_path}/.github/workflows/test-ci.yml"
liquidjs --context "${context}" --template "@${helper_folder_path}/templates/test-ci-liquid.yml" --output "${project_folder_path}/.github/workflows/test-ci.yml"

cp -v "${helper_folder_path}/templates/publish-github-pages.yml" "${project_folder_path}/.github/workflows"

echo
echo "Copying other..."

cp -v "${helper_folder_path}/templates/.gitignore" "${project_folder_path}"
cp -v "${helper_folder_path}/templates/.npmignore" "${project_folder_path}"

# -----------------------------------------------------------------------------

rm -rf "${tmp_script_file}"

echo
echo "${script_name} done"

# Completed successfully.
exit 0
