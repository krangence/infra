#!/usr/bin/env bash

set -x
set -o pipefail

ADMIN_IAM_ROLE="arn:aws:iam::474108156746:role/admin"
FLUX_GIT_URL="https://github.com/krangence/k8s-flux.git"
FLUX_GIT_EMAIL="matt@matt-white.co.uk"

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
else
	set -e
	apk add git openssh
	git clone "${FLUX_GIT_URL}"
	kubectl apply -k "k8s-flux/flux"
fi

eksctl create iamidentitymapping -f cluster.yaml --arn "${ADMIN_IAM_ROLE}" --group system:masters --username admin

exit $?
