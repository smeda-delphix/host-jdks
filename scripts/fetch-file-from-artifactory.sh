#!/bin/bash
#
# Copyright 2021 Delphix
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function die() {
	echo "$(basename "$0"): $*" >&2
	exit 1
}

function usage() {
	echo "$(basename "$0"): $*" >&2
	echo "Usage: $(basename "$0") <url> <checksum> <output directory>"
	exit 2
}

function cleanup() {
	[[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

[[ $# -gt 3 ]] && usage "too many arguments specified"
[[ $# -lt 3 ]] && usage "too few arguments specified"

ARTIFACTORY_PATH="$1"
EXPECTED_CKSUM="$2"
OUTPUT_PATH="$3"

PREFIX="https://artifactory.delphix.com/artifactory/delphix-java-packages"
FILENAME="$(basename "$ARTIFACTORY_PATH")"

trap cleanup EXIT

TEMP_DIR="$(mktemp -d -t fetch-file.XXXXXXX)"
[[ -d "$TEMP_DIR" ]] || die "failed to create temporary directory '$TEMP_DIR'"
pushd "$TEMP_DIR" &>/dev/null || die "'pushd $TEMP_DIR' failed"

wget -nv "$PREFIX/$ARTIFACTORY_PATH" -O "$FILENAME"

ACTUAL_CKSUM="$(sha256sum "$FILENAME" | awk '{print $1}')"
[[ "$ACTUAL_CKSUM" == "$EXPECTED_CKSUM" ]] ||
	die "checksum mismatch; " \
		"expected '$EXPECTED_CKSUM', actual '$ACTUAL_CKSUM'"

popd &>/dev/null || dir "'popd' failed"

mkdir -p "$(dirname "$OUTPUT_PATH")" || die "failed to create output directory"
mv "$TEMP_DIR/$FILENAME" "$OUTPUT_PATH" ||
	die "failed to copy file into output directory"
