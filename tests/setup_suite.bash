#!/bin/bash

set -eu

function setup_suite {
  export BATS_TEST_TIMEOUT=120
  # Define the name of the kind cluster
  export CLUSTER_NAME="ccm-kind"

  export ARTIFACTS_DIR="$BATS_TEST_DIRNAME"/../_artifacts
  mkdir -p "$ARTIFACTS_DIR"
  rm -rf "$ARTIFACTS_DIR"/*

  # create cluster
  kind create cluster --name $CLUSTER_NAME -v7 --wait 1m --retain --config="$BATS_TEST_DIRNAME/kind.yaml"

  for node in $(kind get nodes --name $CLUSTER_NAME); do
    docker exec "$node" sh -c 'apt-get update && apt-get install -y criu'
  done

  # test depend on external connectivity that can be very flaky
  sleep 5
}

function teardown_suite {
    kill "$CCM_PID"
    kind export logs "$ARTIFACTS_DIR" --name "$CLUSTER_NAME"
    kind delete cluster --name "$CLUSTER_NAME"
}