#!/usr/bin/env bash

# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# "------------------------------------------------------------------------"
# "-                                                                      -"
# "-  This script generates the cassandra-statefulset.yaml with new tag   -"
# "-                                                                      -"
# "------------------------------------------------------------------------"

set -o errexit
set -o nounset
set -o pipefail

PROJECT_ID=$1
APP_NAME=$2
IMAGE_TAG=$3
MANIFEST_FILE=$4
sed -i -e "s#gcr.io/${PROJECT_ID}/${APP_NAME}:.*#gcr.io/${PROJECT_ID}/${APP_NAME}:${IMAGE_TAG}#" \
"${MANIFEST_FILE}"
