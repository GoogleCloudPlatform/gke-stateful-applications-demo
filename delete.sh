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
# "-  Delete uninstalls Cassandra and deletes              -"
# "-  the GKE cluster                                      -"
# "-                                                       -"
# "---------------------------------------------------------"

# Do not set errexit as it makes partial deletes impossible
set -o nounset
set -o pipefail

ROOT=$(dirname "${BASH_SOURCE[0]}")
CLUSTER_NAME=""
ZONE=""

# shellcheck disable=SC1090
source "$ROOT"/common.sh

# Get credentials for the k8s cluster
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"

# Delete cassandra
echo "Deleting Cassandra"
kubectl --namespace=default delete -f "$ROOT"/manifests
# You have to wait the default pod grace period before you can delete the pvcs
echo "Sleeping 60 seconds before deleting PVCs. The default pod grace period."
sleep 60
# delete the pvcs
kubectl --namespace=default delete pvc -l app=cassandra

# Cleanup the cluster
echo "Deleting cluster"
gcloud container clusters delete "$CLUSTER_NAME" --zone "$ZONE" --async --quiet
