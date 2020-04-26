# IaaC stack for PlayHRZN EKS

### [Google Cloud Build](https://cloud.google.com/cloud-build) is used by this repository to deploy and make architectural changes to the [Amazon EKS](https://aws.amazon.com/eks/) cluster.

Any change to the master branch triggers a build job defined in [`cloudbuild.yaml`](./cloudbuild.yaml). In this file, the build depends on a [Cloud KMS](https://cloud.google.com/kms) key configured at `secrets[0].kmsKeyName`.
The `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are both encrypted by the configured KMS key, encoded as base64, and set as `key: value` pairs in `secrets[0].secretEnv`.

### Encrypting secrets required during builds

The following example snippet demonstrates how encrypt a string with an existing KMS key _(bar)_ from keyring _(foo)_:

```bash
$ echo -n AKIAIOSFODNN7EXAMPLE | gcloud kms encrypt --plaintext-file=- --ciphertext-file=- --location=global --keyring=foo --key=bar | base64 -w 0
CiQA/t63gUNmRrHILiXp9RAVq0I2WT2vCXL1OxYNCjHBZjUcYDYSPQA2yBtTr73utO9qZ6iIQAjFVdf/1sl+yXMhGF2RqPHPA7z+bz6PLfRMik4KPnqRw6ZUdtyMtZ0CfY+4Ew8=
```

The output of the above command is an encrypted and base64 encoded string. Only the same KMS key can decrypt this string; therefore, it is safe to be committed to source control.

**The `Cloud KMS CryptoKey Decrypter` [Cloud IAM](https://cloud.google.com/iam) role must be granted to the [Cloud Build service account](https://cloud.google.com/cloud-build/docs/securing-builds/use-encrypted-secrets-credentials#encrypt_credentials) to allow decryption of this material during the build job.**

### GitOps - Flux Deployment

During the initial cluster deployment, we deploy [Flux](https://github.com/fluxcd/flux). Flux automatically ensures that the state of a cluster matches the config in git.

> Flux believes in [the GitOps implementation](https://www.gitops.tech/) of Continuous Delivery. You declaratively describe the entire desired state of your system in git, including the apps, config, dashboards, monitoring and everything else.  It uses an operator in the cluster to trigger deployments inside Kubernetes, which means you don't need a separate CD tool. It monitors all relevant image repositories, detects new images, triggers deployments and updates the desired running configuration.
>
> The benefits are: you don't need to grant your CI access to the cluster, every change is atomic and transactional, git has your audit log. Each transaction either fails or succeeds cleanly. You're entirely code-centric and don't need new infrastructure.

The configuration repo used by Flux as the single source of truth for this cluster is here: [hrznstudio/playhrzn-k8s](https://github.com/HRZNStudio/playhrzn-k8s). To provide a different source of truth, configure the variables in [`run.sh`](./run.sh). To change the source of truth after the initial deployment; ensure the values set at `spec.template.spec.containers[0].args` are updated in [`flux/flux-deployment.yaml`](https://github.com/HRZNStudio/playhrzn-k8s/blob/master/flux/flux-deployment.yaml), found in the configuration repo.

During the initial deployment, the end of the build output will look like this:

```text
[ℹ]  Flux will only operate properly once it has write-access to the Git repository
[ℹ]  please configure git@github.com:weaveworks/cluster-1-gitops.git  so that the following Flux SSH public key has write access to it
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYYsPuHzo1L29u3zhr4uAOF29HNyMcS8zJmOTDNZC4EiIwa5BXgg/IBDKudxQ+NBJ7mknPlNv17cqo4ncEq1xiQidfaUawwx3xxtDkZWam5nCBMXEJwkr4VXx/6QQ9Z1QGXpaFwdoVRcY/kM4NaxM54pEh5m43yeqkcpRMKraE0EgbdqFNNARN8rIEHY/giDorCrXp7e6AbzBgZSvc/in7Ul9FQhJ6K4+7QuMFpJt3O/N8KDumoTG0e5ssJGp5L1ugIqhzqvbHdmHVfnXsEvq6cR1SJtYKi2GLCscypoF3XahfjK+xGV/92a1E7X+6fHXSq+bdOKfBc4Z3f9NBwz0v
```

The SSH public key provided to you here should be used to provide Flux with write-access to the configuration repo.
If the configuration repo is hosted on GitHub, this can be added to `Deploy keys` under the repo's `Settings` tab.
