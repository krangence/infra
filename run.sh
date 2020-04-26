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
	eksctl create iamidentitymapping -f cluster.yaml --arn arn:aws:iam::521397258504:role/admin --group system:masters --username admin
else
	set -e
	EKSCTL_EXPERIMENTAL=true
	eksctl enable repo -f cluster.yaml --git-url=git@github.com:HRZNStudio/playhrzn-k8s.git --git-email=accounts@hrznstudio.com
fi

exit $?
