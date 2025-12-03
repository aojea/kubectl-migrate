#!/bin/bash

set -eu

function setup_suite {
  export BATS_TEST_TIMEOUT=120
  # Define the name of the kind cluster
  export CLUSTER_NAME="kind-migrate"

  export ARTIFACTS_DIR="$BATS_TEST_DIRNAME"/../_artifacts
  mkdir -p "$ARTIFACTS_DIR"
  rm -rf "$ARTIFACTS_DIR"/*

  # create cluster
  kind create cluster --name $CLUSTER_NAME -v7 --wait 1m --retain --config="$BATS_TEST_DIRNAME/kind.yaml"

  # build and load builder image
  export BUILDER_IMAGE="kubectl-migrate:test"
  docker build -t "$BUILDER_IMAGE" "$BATS_TEST_DIRNAME/.."
  kind load docker-image "$BUILDER_IMAGE" --name "$CLUSTER_NAME"

  # test depend on external connectivity that can be very flaky
  sleep 5
}

function teardown_suite {
    kind export logs "$ARTIFACTS_DIR" --name "$CLUSTER_NAME"
    kind delete cluster --name "$CLUSTER_NAME"
}