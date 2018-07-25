#!/bin/bash

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

set -e

# Base variables for Cassandra install
CASSANDRA_HOME=/usr/local/apache-cassandra
CASSANDRA_BIN=$CASSANDRA_HOME/bin/cassandra
CASSANDRA_CONF_DIR=/etc/cassandra
CASSANDRA_CFG=$CASSANDRA_CONF_DIR/cassandra.yaml
CASSANDRA_CONF_DIR=/etc/cassandra

# Get the pod ip address
# This is used in a number of configurations and passed in the k8s manifest
if [ -z "$POD_IP" ]; then
  POD_IP=$(hostname -I| awk '{print $1}')
fi

# Add the hostname to hosts file
if hostname -i;
then
  # fix for host networking
  echo "$POD_IP $HOSTNAME" >> /etc/hosts
fi

# we are doing StatefulSet or just setting our seeds
if [ -z "$CASSANDRA_SEEDS" ]; then
  CASSANDRA_SEEDS=$POD_IP
fi

# The following vars relate to their counterparts in $CASSANDRA_CFG
# for instance rpc_address
CASSANDRA_AUTO_BOOTSTRAP="${CASSANDRA_AUTO_BOOTSTRAP:-true}"
CASSANDRA_BROADCAST_ADDRESS=${POD_IP:-$HOSTNAME}
CASSANDRA_BROADCAST_RPC_ADDRESS=${POD_IP:-$HOSTNAME}
CASSANDRA_CLUSTER_NAME="${CASSANDRA_CLUSTER_NAME:='Test Cluster'}"
CASSANDRA_DC="${CASSANDRA_DC}"
CASSANDRA_DISK_OPTIMIZATION_STRATEGY="${CASSANDRA_DISK_OPTIMIZATION_STRATEGY:-ssd}"
CASSANDRA_ENDPOINT_SNITCH="${CASSANDRA_ENDPOINT_SNITCH:-SimpleSnitch}"
CASSANDRA_INTERNODE_COMPRESSION="${CASSANDRA_INTERNODE_COMPRESSION:-dc}"
CASSANDRA_LISTEN_ADDRESS=${POD_IP:-$HOSTNAME}
CASSANDRA_LOG_GC="${CASSANDRA_LOG_GC:-false}"
CASSANDRA_LOG_GC_VERBOSE="${CASSANDRA_GC_VERBOSE:-false}"
CASSANDRA_LOG_JSON="${CASSANDRA_LOG_JSON:-false}"
CASSANDRA_LOG_PATH="${CASSANDRA_LOG_PATH:-/var/log/cassandra}"
CASSANDRA_LOG_TO_FILES="${CASSANDRA_LOG_TO_FILES:-false}"
CASSANDRA_MIGRATION_WAIT="${CASSANDRA_MIGRATION_WAIT:-1}"
CASSANDRA_NUM_TOKENS="${CASSANDRA_NUM_TOKENS:-32}"
CASSANDRA_RACK="${CASSANDRA_RACK}"
CASSANDRA_RING_DELAY="${CASSANDRA_RING_DELAY:-30000}"
CASSANDRA_RPC_ADDRESS="${CASSANDRA_RPC_ADDRESS:-0.0.0.0}"
CASSANDRA_SEEDS="${CASSANDRA_SEEDS:false}"
CASSANDRA_SEED_PROVIDER="${CASSANDRA_SEED_PROVIDER:-org.apache.cassandra.locator.SimpleSeedProvider}"
CASSANDRA_TRICKLE_FSYNC="${CASSANDRA_TRICKLE_FSYNC:-false}"

# Turn off JMX auth
CASSANDRA_OPEN_JMX="${CASSANDRA_OPEN_JMX:-true}"

echo Starting Cassandra on "${CASSANDRA_LISTEN_ADDRESS}"
echo CASSANDRA_CONF_DIR "${CASSANDRA_CONF_DIR}"
echo CASSANDRA_AUTO_BOOTSTRAP "${CASSANDRA_AUTO_BOOTSTRAP}"
echo CASSANDRA_BROADCAST_ADDRESS "${CASSANDRA_BROADCAST_ADDRESS}"
echo CASSANDRA_BROADCAST_RPC_ADDRESS "${CASSANDRA_BROADCAST_RPC_ADDRESS}"
echo CASSANDRA_CFG "${CASSANDRA_CFG}"
echo CASSANDRA_CLUSTER_NAME "${CASSANDRA_CLUSTER_NAME}"
echo CASSANDRA_COMPACTION_THROUGHPUT_MB_PER_SEC "${CASSANDRA_COMPACTION_THROUGHPUT_MB_PER_SEC}"
echo CASSANDRA_CONCURRENT_COMPACTORS "${CASSANDRA_CONCURRENT_COMPACTORS}"
echo CASSANDRA_CONCURRENT_READS "${CASSANDRA_CONCURRENT_READS}"
echo CASSANDRA_CONCURRENT_WRITES "${CASSANDRA_CONCURRENT_WRITES}"
echo CASSANDRA_COUNTER_CACHE_SIZE_IN_MB "${CASSANDRA_COUNTER_CACHE_SIZE_IN_MB}"
echo CASSANDRA_DC "${CASSANDRA_DC}"
echo CASSANDRA_DISK_OPTIMIZATION_STRATEGY "${CASSANDRA_DISK_OPTIMIZATION_STRATEGY}"
echo CASSANDRA_ENDPOINT_SNITCH "${CASSANDRA_ENDPOINT_SNITCH}"
echo CASSANDRA_GC_WARN_THRESHOLD_IN_MS "${CASSANDRA_GC_WARN_THRESHOLD_IN_MS}"
echo CASSANDRA_INTERNODE_COMPRESSION "${CASSANDRA_INTERNODE_COMPRESSION}"
echo CASSANDRA_KEY_CACHE_SIZE_IN_MB "${CASSANDRA_KEY_CACHE_SIZE_IN_MB}"
echo CASSANDRA_LISTEN_ADDRESS "${CASSANDRA_LISTEN_ADDRESS}"
echo CASSANDRA_LISTEN_INTERFACE "${CASSANDRA_LISTEN_INTERFACE}"
echo CASSANDRA_LOG_JSON "${CASSANDRA_LOG_JSON}"
echo CASSANDRA_LOG_GC "${CASSANDRA_LOG_GC}"
echo CASSANDRA_LOG_GC_VERBOSE "${CASSANDRA_LOG_GC_VERBOSE}"
echo CASSANDRA_LOG_PATH "${CASSANDRA_LOG_PATH}"
echo CASSANDRA_LOG_TO_FILES "${CASSANDRA_LOG_TO_FILES}"
echo CASSANDRA_MEMTABLE_ALLOCATION_TYPE "${CASSANDRA_MEMTABLE_ALLOCATION_TYPE}"
echo CASSANDRA_MEMTABLE_CLEANUP_THRESHOLD "${CASSANDRA_MEMTABLE_CLEANUP_THRESHOLD}"
echo CASSANDRA_MEMTABLE_FLUSH_WRITERS "${CASSANDRA_MEMTABLE_FLUSH_WRITERS}"
echo CASSANDRA_MIGRATION_WAIT "${CASSANDRA_MIGRATION_WAIT}"
echo CASSANDRA_NUM_TOKENS "${CASSANDRA_NUM_TOKENS}"
echo CASSANDRA_OPEN_JMX "${CASSANDRA_OPEN_JMX}"
echo CASSANDRA_RACK "${CASSANDRA_RACK}"
echo CASSANDRA_RING_DELAY "${CASSANDRA_RING_DELAY}"
echo CASSANDRA_RPC_ADDRESS "${CASSANDRA_RPC_ADDRESS}"
echo CASSANDRA_RPC_INTERFACE "${CASSANDRA_RPC_INTERFACE}"
echo CASSANDRA_SEEDS "${CASSANDRA_SEEDS}"
echo CASSANDRA_SEED_PROVIDER "${CASSANDRA_SEED_PROVIDER}"
echo CASSANDRA_TRICKLE_FSYNC "${CASSANDRA_TRICKLE_FSYNC}"

# set the storage directory
# shellcheck disable=SC2016
sed -ri 's/^cassandra_storagedir.*/cassandra_storagedir=$CASSANDRA_DATA/' "$CASSANDRA_HOME/bin/cassandra.in.sh"

# if DC and RACK are set, use GossipingPropertyFileSnitch
if [[ $CASSANDRA_DC && $CASSANDRA_RACK ]]; then
  echo "dc=$CASSANDRA_DC" > $CASSANDRA_CONF_DIR/cassandra-rackdc.properties
  echo "rack=$CASSANDRA_RACK" >> $CASSANDRA_CONF_DIR/cassandra-rackdc.properties
  CASSANDRA_ENDPOINT_SNITCH="GossipingPropertyFileSnitch"
fi

# Set the heap options in jvm.options
if [ -n "$CASSANDRA_MAX_HEAP" ]; then
  sed -ri "s/^(#)?-Xmx[0-9]+.*/-Xmx$CASSANDRA_MAX_HEAP/" "$CASSANDRA_CONF_DIR/jvm.options"
  sed -ri "s/^(#)?-Xms[0-9]+.*/-Xms$CASSANDRA_MAX_HEAP/" "$CASSANDRA_CONF_DIR/jvm.options"
fi

# If replacing a node
# This is not fully functional and should be improved
if [ -n "$CASSANDRA_REPLACE_NODE" ]; then
   echo "-Dcassandra.replace_address=$CASSANDRA_REPLACE_NODE/" >> "$CASSANDRA_CONF_DIR/jvm.options"
fi

# Setup C* racks
# Add rack
# TODO need to test this
for rackdc in dc rack; do
  var="CASSANDRA_${rackdc^^}"
  val="${!var}"
  if [ "$val" ]; then
	sed -ri 's/^('"$rackdc"'=).*/\1 '"$val"'/' "$CASSANDRA_CONF_DIR/cassandra-rackdc.properties"
  fi
done

# Replace various values in the  $CASSANDRA_CFG config file
# These values map directly to the cassandra.yaml file that is vendorred
# In this directory
for yaml in \
  broadcast_address \
  broadcast_rpc_address \
  cluster_name \
  disk_optimization_strategy \
  endpoint_snitch \
  listen_address \
  num_tokens \
  rpc_address \
  start_rpc \
  key_cache_size_in_mb \
  concurrent_reads \
  concurrent_writes \
  memtable_cleanup_threshold \
  memtable_allocation_type \
  memtable_flush_writers \
  concurrent_compactors \
  compaction_throughput_mb_per_sec \
  counter_cache_size_in_mb \
  internode_compression \
  endpoint_snitch \
  gc_warn_threshold_in_ms \
  listen_interface \
  rpc_interface \
  trickle_fsync \
  ; do
  var="CASSANDRA_${yaml^^}"
  val="${!var}"
  if [ "$val" ]; then
    sed -ri 's/^(#\s*)?('"$yaml"':).*/\2 '"$val"'/' "$CASSANDRA_CFG"
  fi
done

# Loop through the containers environment variables search for a VAR prefixed
# with CASSANDRA_YAML_
# When a correctly name var is found such as CASSANDRA_YAML_FOO, then replace the
# 'foo' yaml key's value with the value set in the env var.
# For example
# CASSANDRA_YAML_phi_convict_threshold=10 is set the StatefulSet manifest
# "# phi_convict_threshold: 8" line in the C* config file will be modified to
# "phi_convict_threshold: 10".
# TODO: do a to lower on the $yaml value to ensure that CASSANDRA_YAML_FOO and
# TODO: CASSANDRA_YAML_foo both work.
while IFS='=' read -r name ; do
  if [[ $name == 'CASSANDRA_YAML_'* ]]; then
    val="${!name}"
    yaml=$(echo "${name,,}" | cut -c 16-)
    echo "FOUND $name $yaml $val"
    sed -ri 's/^(#\s*)?('"$yaml"':).*/\2 '"$val"'/' "$CASSANDRA_CFG"
  fi
done < <(env)

# setting auto bootstrap for starting nodes
echo "auto_bootstrap: ${CASSANDRA_AUTO_BOOTSTRAP}" >> $CASSANDRA_CFG

# set the seed to itself.  This is only for the first pod, otherwise
# it will be able to get seeds from the seed provider
if [[ $CASSANDRA_SEEDS == 'false' ]]; then
  sed -ri 's/- seeds:.*/- seeds: "'"$POD_IP"'"/' $CASSANDRA_CFG
else # if we have seeds set them.  Probably StatefulSet
  sed -ri 's/- seeds:.*/- seeds: "'"$CASSANDRA_SEEDS"'"/' $CASSANDRA_CFG
fi

# Set the seed provider in the CASSANDRA_CFG
sed -ri 's/- class_name: SEED_PROVIDER/- class_name: '"$CASSANDRA_SEED_PROVIDER"'/' $CASSANDRA_CFG

# setup JVM options in cassandra-env
sed -ri 's/JVM_OPTS.*Xloggc.*//' $CASSANDRA_CONF_DIR/cassandra-env.sh

# Turn on JVM Garbage Collection logging
if [[ $CASSANDRA_LOG_GC == 'true' ]]; then
  {
    echo "-XX:+PrintGCDetails";
    echo "-XX:+PrintGCDateStamps";
    echo "-XX:+PrintHeapAtGC";
    echo "-XX:+PrintTenuringDistribution";
    echo "-XX:+PrintGCApplicationStoppedTime";
    echo "-XX:+PrintPromotionFailure"; } >> $CASSANDRA_CONF_DIR/jvm.options

  if [[ $CASSANDRA_LOG_GC_VERBOSE == 'true' ]]; then
    echo "-XX:PrintFLSStatistics=1" >> $CASSANDRA_CONF_DIR/jvm.options
  fi

  if [[ $CASSANDRA_LOG_TO_FILES == 'true' ]]; then
    {
      echo "-Xloggc:${CASSANDRA_LOG_PATH}/gc.log";
      echo "-XX:+UseGCLogFileRotation";
      echo "-XX:NumberOfGCLogFiles=10";
      echo "-XX:GCLogFileSize=10M"; } >> $CASSANDRA_CONF_DIR/jvm.options
  fi
fi

# configure logging
sed -ri 's/.*cassandra_parms=.*-Dlogback.configurationFile.*//' $CASSANDRA_BIN
sed -ri 's/.*cassandra_parms=.*-Dcassandra.logdir.*//' $CASSANDRA_BIN
echo "-Dcassandra.logdir=${CASSANDRA_LOG_PATH}" >> $CASSANDRA_CONF_DIR/jvm.options
if [[ $CASSANDRA_LOG_TO_FILES == 'true' ]]; then
  if [[ $CASSANDRA_LOG_JSON == 'true' ]]; then
    echo "-Dlogback.configurationFile=${CASSANDRA_CONF_DIR}/logback-json-files.xml" >> $CASSANDRA_CONF_DIR/jvm.options
  else
    echo "-Dlogback.configurationFile=${CASSANDRA_CONF_DIR}/logback-files.xml" >> $CASSANDRA_CONF_DIR/jvm.options
  fi
else
  # TODO can we clean this up??
  if [[ $CASSANDRA_LOG_JSON == 'true' ]]; then
    echo "-Dlogback.configurationFile=${CASSANDRA_CONF_DIR}/logback-json-stdout.xml" >> $CASSANDRA_CONF_DIR/jvm.options
  else
    echo "-Dlogback.configurationFile=${CASSANDRA_CONF_DIR}/logback-stdout.xml" >> $CASSANDRA_CONF_DIR/jvm.options
  fi
fi

# getting WARNING messages with Migration Service
# Setting -D options with jvm for migration and ring delay
echo "-Dcassandra.migration_task_wait_in_seconds=${CASSANDRA_MIGRATION_WAIT}" >> $CASSANDRA_CONF_DIR/jvm.options
# Setting ring delay can speed up the deployment of C* pods
echo "-Dcassandra.ring_delay_ms=${CASSANDRA_RING_DELAY}" >> $CASSANDRA_CONF_DIR/jvm.options

# Enable jmx
if [[ $CASSANDRA_OPEN_JMX == 'true' ]]; then
  export LOCAL_JMX=no
  sed -ri 's/ -Dcom\.sun\.management\.jmxremote\.authenticate=true/ -Dcom\.sun\.management\.jmxremote\.authenticate=false/' $CASSANDRA_CONF_DIR/cassandra-env.sh
  sed -ri 's/ -Dcom\.sun\.management\.jmxremote\.password\.file=\/etc\/cassandra\/jmxremote\.password//' $CASSANDRA_CONF_DIR/cassandra-env.sh

  {
    echo "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote\"";
    echo "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.ssl=false\"";
    echo "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.local.only=false\"";
    echo "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.port=7199\"";
    echo "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote.rmi.port=7199\"";
    echo "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=$POD_IP\""; } >> $CASSANDRA_CONF_DIR/cassandra-env.sh
fi

# setup perms on the PVC and log drives
# TODO can we do this in one line?
chmod 700 "${CASSANDRA_DATA}"
chmod 700 "${CASSANDRA_LOG_PATH}"

# set owner on various paths
chown -c -R cassandra: "${CASSANDRA_DATA}" "${CASSANDRA_CONF_DIR}" "${CASSANDRA_LOG_PATH}"

# TODO setup a DEBUG env var on these echos
# Can be a lot of logging
echo "/etc/resolv.conf"
cat /etc/resolv.conf

echo "$CASSANDRA_CFG"
cat $CASSANDRA_CFG

# start cassandra
su cassandra -c "$CASSANDRA_BIN -f"
