# aws-platform-starter

A small, explainable AWS platform you can build, demo, and destroy in an afternoon.
Built for interview prep: every piece maps to a topic on the interview checklist.

```
bootstrap/          S3 bucket for remote state (local state, applied once)
modules/
  vpc/              hand-written VPC: public/private subnets, IGW, NAT, S3 endpoint
  eks/              wrapper over the community EKS module (IRSA + Pod Identity ready)
  github-oidc/      GitHub Actions -> AWS via OIDC, no static keys
envs/dev/           the environment that wires the modules together
.github/workflows/  terraform fmt + validate + plan on every PR
```

## Prerequisites

Terraform (or OpenTofu) >= 1.10, AWS CLI, kubectl, Helm, Git.
Authenticate first and confirm with `aws sts get-caller-identity`.
Use a personal sandbox account with a budget alarm. Never use employer credentials.

## Cost warning

The EKS control plane, the NAT gateway, and the 2 nodes all bill per hour. Roughly a few
dollars a day while running. **Destroy when you finish each session** (see below), and
check the Billing console before bed.

EKS versions that fall out of standard support are billed at a higher "extended support"
rate. Pick a current standard-support version:

```bash
aws eks describe-cluster-versions --region ap-south-1 \
  --query 'clusterVersions[].[clusterVersion,status]' --output table
```

Then set `cluster_version` in `envs/dev/variables.tf` (the default is `1.34`).

## Quick start

### 1. Bootstrap remote state (once)

```bash
cd bootstrap
terraform init
terraform apply
# note the output: state_bucket
```

### 2. Configure the dev environment

```bash
cd ../envs/dev
cp backend.hcl.example backend.hcl            # fill in your account ID
cp terraform.tfvars.example terraform.tfvars  # fill in repo, bucket, your IP
terraform init -backend-config=backend.hcl
```

### 3. Build in stages (recommended: explain each stage as you go)

```bash
terraform plan  -target=module.vpc
terraform apply -target=module.vpc          # VPC first, look at it in the console
terraform apply                              # then EKS + OIDC (EKS takes ~10-15 min)
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

Targeted applies are fine for learning; in real pipelines you apply the whole plan.

### 4. Deploy something with Helm

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install web bitnami/nginx
kubectl get pods,svc
```

### 5. Tear down (do not skip)

```bash
# Delete anything that created AWS resources outside Terraform first,
# otherwise load balancers can block the VPC from deleting.
helm uninstall web
terraform destroy
```

The state bucket in `bootstrap/` costs almost nothing; leave it.

## GitHub OIDC setup

1. Push this repo to GitHub.
2. After `apply`, copy the `github_actions_role_arn` output into a repo secret named `AWS_ROLE_ARN`.
3. Add a repo variable `TF_STATE_BUCKET` with your bucket name.
4. Open a PR: the workflow plans using short-lived credentials.

## Break-things drills (the best interview prep)

| Break this | Expected symptom | How to find it |
|---|---|---|
| Delete the private route to the NAT in the console | Pods can't pull images, `ImagePullBackOff` | Route tables, then `kubectl describe pod` |
| Change the OIDC `sub` condition to another repo | Workflow fails with `Not authorized to perform sts:AssumeRoleWithWebIdentity` | IAM trust policy vs token claims |
| Set `public_access_cidrs` to a wrong IP | `kubectl` times out | EKS endpoint access config |
| `helm install` with a bad image tag | `ErrImagePull` / `ImagePullBackOff` | `kubectl describe pod` events |
| Change a resource in the console, then `terraform plan` | Drift shown in the plan | Read the diff, then decide: import, revert, or accept |
| Kill a `terraform apply` midway | State lock left behind | Lock file in S3, `terraform force-unlock` |

Troubleshooting loop: **symptom, what changed, isolate the layer (DNS, network, IAM, app),
hypothesis, test, fix, document.**

## Interview talking points

- **Why a hand-written VPC but a community EKS module?** Networking is core to explain;
  EKS has many moving parts that are low value to hand-roll and are well maintained upstream.
- **Single NAT vs one per AZ:** cost vs availability. Flip `single_nat_gateway` to show you
  know the trade-off.
- **Why OIDC instead of access keys?** Short-lived credentials, nothing to leak or rotate,
  and the trust policy pins the exact repo and branch.
- **IRSA vs Pod Identity:** both give pods their own IAM role instead of using the node role.
  Pod Identity is simpler to configure; IRSA works everywhere and has more existing material.
- **Remote state:** S3 versioning for recovery, encryption since state holds secrets, locking so
  two applies can't collide.
- **What's missing for production** (say this proactively): multi-account landing zone,
  separate apply role with approval gates, private cluster endpoint, VPC flow logs,
  CloudTrail/GuardDuty, GitOps for app delivery, and observability (CloudWatch +
  Prometheus/Grafana).
