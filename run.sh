#!/usr/bin/env bash

set -x
set -o pipefail

ADMIN_IAM_ROLE="arn:aws:iam::474108156746:role/admin"
FLUX_GIT_URL="git@github.com:krangence/k8s-flux.git"
FLUX_GIT_EMAIL="matt@matt-white.co.uk"

touch output.txt
tail -f output.txt &

if [[ "$(eksctl create cluster -f cluster.yaml | tee output.txt)" != *AlreadyExistsException* ]]; then
    set -e
    eksctl update cluster -f cluster.yaml --approve
	eksctl create nodegroup -f cluster.yaml
	eksctl delete nodegroup -f cluster.yaml --only-missing --approve
	eksctl utils update-kube-proxy -f cluster.yaml --approve
	eksctl utils update-aws-node -f cluster.yaml --approve
	eksctl utils update-coredns -f cluster.yaml --approve
	eksctl create iamidentitymapping -f cluster.yaml --arn "${ADMIN_IAM_ROLE}" --group system:masters --username admin
else
	set -e
	apk add git
	EKSCTL_EXPERIMENTAL=true eksctl enable repo -f cluster.yaml --git-url="${FLUX_GIT_URL}" --git-email="${FLUX_GIT_EMAIL}"
fi

exit $?
