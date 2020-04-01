#!/usr/bin/env bash

set -x
set -o pipefail

touch output.txt
tail -f output.txt &

if [[ "$(eksctl create cluster -f cluster.yaml | tee output.txt)" = *AlreadyExistsException* ]]; then
    set -e
    eksctl update cluster -f cluster.yaml --approve
		eksctl create nodegroup -f cluster.yaml
		eksctl delete nodegroup -f cluster.yaml --only-missing --approve
		eksctl utils update-kube-proxy -f cluster.yaml --approve
		eksctl utils update-aws-node -f cluster.yaml --approve
		eksctl utils update-coredns -f cluster.yaml --approve
fi

exit $?
