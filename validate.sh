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

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Validation script checks if Cassandra                -"
# "-  deployed successfully.                               -"
# "-                                                       -"
# "---------------------------------------------------------"

# Do no set exit on error, since the rollout status command may fail
set -o nounset
set -o pipefail

ROOT=$(dirname "${BASH_SOURCE[0]}")
CLUSTER_NAME=""
ZONE=""

# shellcheck disable=SC1090
source "$ROOT"/common.sh

# Get credentials for the k8s cluster
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"

# Get rollout status for the statefulset and grep for the complete message
MESSAGE="statefulset rolling update complete"
ROLLOUT=$(kubectl --namespace=default rollout status --timeout="10m" -f \
  "$ROOT"/manifests/cassandra-statefulset.yaml)

# Test the ROLLOUT variable to see if the grep has returned the expected value.
# Depending on the test print success or failure messages.
if [[ $ROLLOUT = *"$MESSAGE"* ]]; then
  echo "Validation Passed: the Statefulset has been deployed"
else
  echo "Validation Failed: Statefulset has not been deployed"
  exit 1
fi
