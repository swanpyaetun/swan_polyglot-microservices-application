# Prerequisites

## Table of Contents

- [1. AWS](#1-aws)
  - [1.1. Create IAM Role for GitHub Actions to authenticate to AWS](#11-create-iam-role-for-github-actions-to-authenticate-to-aws)
  - [1.2. Create ACM certificate for Kubernetes ingress](#12-create-acm-certificate-for-kubernetes-ingress)
- [2. GitHub](#2-github)
  - [2.1. Create GitHub App for Argo CD Image Updater](#21-create-github-app-for-argo-cd-image-updater)
- [3. GitHub Actions](#3-github-actions)
  - [3.1. Create repository secret](#31-create-repository-secret)
  - [3.2. Set inputs](#32-set-inputs)
- [4. Karpenter](#4-karpenter)
  - [4.1. swan_kubernetes/swan_karpenter/ec2nodeclass.yaml](#41-swan_kubernetesswan_karpenterec2nodeclassyaml)
  - [4.2. swan_kubernetes/swan_karpenter/nodepool.yaml](#42-swan_kubernetesswan_karpenternodepoolyaml)
- [5. Helm](#5-helm)
  - [5.1. swan_kubernetes/swan_helm/platform/](#51-swan_kubernetesswan_helmplatform)
  - [5.2. swan_kubernetes/swan_helm/swan_microservices/](#52-swan_kubernetesswan_helmswan_microservices)
- [6. Argo CD](#6-argo-cd)
  - [6.1. swan_kubernetes/swan_argocd/root-app.yaml](#61-swan_kubernetesswan_argocdroot-appyaml)
  - [6.2. swan_kubernetes/swan_argocd/swan_argocd_apps/](#62-swan_kubernetesswan_argocdswan_argocd_apps)

## 1. AWS

### 1.1. Create IAM Role for GitHub Actions to authenticate to AWS

IAM Identity provider called "token.actions.githubusercontent.com" is already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

In AWS Management Console, create an IAM Role with the following configurations:<br>
Trusted entity type:<br>
&nbsp;&nbsp;&nbsp;&nbsp;Web identity<br>
Web identity:<br>
&nbsp;&nbsp;&nbsp;&nbsp;Identity provider: token.actions.githubusercontent.com<br>
&nbsp;&nbsp;&nbsp;&nbsp;Audience: sts.amazonaws.com<br>
&nbsp;&nbsp;&nbsp;&nbsp;GitHub organization: swanpyaetun<br>
&nbsp;&nbsp;&nbsp;&nbsp;GitHub repository: swan_polyglot-microservices-application<br>
Role details:<br>
&nbsp;&nbsp;&nbsp;&nbsp;Role name: swan_githubactions_ecr<br>
Tags:<br>
&nbsp;&nbsp;&nbsp;&nbsp;Project: swan_polyglot-microservices-application<br>
&nbsp;&nbsp;&nbsp;&nbsp;Environment: Production

To add IAM permissions for "swan_githubactions_ecr" IAM role, in AWS Management Console, go to "IAM" -> Access Management -> Roles -> swan_githubactions_ecr -> Permissions -> Add permissions. Click "Create inline policy". Go to "Policy editor" -> JSON. Copy and paste the following json. Click "Next". Enter "swan_githubactions_ecr" in "Policy name" under "Policy details". Click "Create policy".
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Statement2",
            "Effect": "Allow",
            "Action": [
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            ],
            "Resource": [
                "arn:aws:ecr:ap-southeast-1:655355946217:repository/swan_polyglot-microservices-application/*"
            ]
        }
    ]
}
```

### 1.2. Create ACM certificate for Kubernetes ingress

Route 53 domain and public hosted zone are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

In AWS Management Console, request an ACM certificate in ap-southeast-1 region with the following configurations:<br>
Certificate type:<br> 
&nbsp;&nbsp;&nbsp;&nbsp;Request a public certificate<br>
Domian names:<br>
&nbsp;&nbsp;&nbsp;&nbsp;Fully qualified domain name:<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- swanpyaetun.com<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- *.swanpyaetun.com<br>
Allow export:<br> 
&nbsp;&nbsp;&nbsp;&nbsp;Disable export<br>
Validation method:<br> 
&nbsp;&nbsp;&nbsp;&nbsp;DNS validation - recommended<br>
Key algorithm:<br> 
&nbsp;&nbsp;&nbsp;&nbsp;RSA 2048<br>
Tags:<br>
&nbsp;&nbsp;&nbsp;&nbsp;Project: swan_polyglot-microservices-application<br>
&nbsp;&nbsp;&nbsp;&nbsp;Environment: Production

To validate the domain for above ACM certificate, in AWS Management Console, go to ap-southeast-1 region -> Certificate Manager -> List certificates. Choose the certificate that you want to validate the domain for. Under Domains, click "Create records in Route 53". Click "Create records". Then, the status of the ACM certificate will change to "Issued".

## 2. GitHub

### 2.1. Create GitHub App for Argo CD Image Updater

Go to GitHub -> Settings -> Developer settings -> GitHub Apps. Create a GitHub App with the following settings:<br>
GitHub App name: swan-argocd-image-updater<br>
Homepage URL: https://github.com/swanpyaetun/swan_polyglot-microservices-application<br>
Disable Webhook<br>
Permissions:<br>
&nbsp;&nbsp;&nbsp;&nbsp;Repository permissions:<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Contents: Read and write<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Metadata: Read-only<br>
Where can this GitHub App be installed?: Only on this account<br>

Go to "Settings" -> Developer settings -> GitHub Apps. Select "swan-argocd-image-updater" GitHub App. Go to "Install App". Click "Install". Choose "Only select repositories", click "Select repositories", and select "swanpyaetun/swan_polyglot-microservices-application". Click "Install".

## 3. GitHub Actions

### 3.1. Create repository secret

In swanpyaetun/swan_polyglot-microservices-application repository, go to "Settings" -> Secrets and variables -> Actions.<br>
Create a new repository secret:<br>
Name: SWAN_CI_IAM_ROLE_ARN<br>
Secret: swan_githubactions_ecr IAM role arn from [1.1. Create IAM Role for GitHub Actions to authenticate to AWS](#11-create-iam-role-for-github-actions-to-authenticate-to-aws)

### 3.2. Set inputs

Private ECR repositories are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

For accounting microservice, in .github/workflows/accounting.yml, set the following inputs:<br>
swan_aws_region: "ap-southeast-1"<br>
swan_ecr_repository: "swan_polyglot-microservices-application/accounting"
```yaml
jobs:
  swan_docker:
    uses: ./.github/workflows/swan_docker.yml
    with:
      swan_aws_region: "ap-southeast-1"
      swan_ecr_repository: "swan_polyglot-microservices-application/accounting"
      swan_dockerfile_path: "src/accounting/Dockerfile"
    secrets:
      SWAN_CI_IAM_ROLE_ARN: ${{ secrets.SWAN_CI_IAM_ROLE_ARN }}
```

Do the same for other microservices, except postgresql and valkey-cart. There is no CI/CD pipeline and private ECR repository for postgresql and valkey-cart microservices.

## 4. Karpenter

### 4.1. swan_kubernetes/swan_karpenter/ec2nodeclass.yaml

Private subnets, EKS node IAM role, and default cluster security group are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

Run this command before running the next command. Enter AWS Access Key ID and AWS Secret Access Key of the IAM user, and ap-southeast-1 as Default region name.
```bash
aws configure
```
<br>

The following command can be used to determine the alias version in a specific region.
```bash
export K8S_VERSION="1.35"
aws ssm get-parameter --name "/aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id" --query Parameter.Value | xargs aws ec2 describe-images --query 'Images[0].Name' --image-ids | sed -r 's/^.*(v[[:digit:]]+).*$/\1/'
```
<br>

In swan_kubernetes/swan_karpenter/ec2nodeclass.yaml, set the following fields: spec.role, spec.amiSelectorTerms, spec.subnetSelectorTerms, and spec.securityGroupSelectorTerms.

### 4.2. swan_kubernetes/swan_karpenter/nodepool.yaml

In swan_kubernetes/swan_karpenter/nodepool.yaml, set the following fields: spec.template, spec.limits, and spec.disruption.

## 5. Helm

### 5.1. swan_kubernetes/swan_helm/platform/

In swan_kubernetes/swan_helm/platform/values.yaml, set the following value:
```yaml
namespace: otel-demo
```

### 5.2. swan_kubernetes/swan_helm/swan_microservices/

Private ECR repositories are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

For accounting microservice, in swan_kubernetes/swan_helm/swan_microservices/accounting/, set the following values:
```yaml
namespace: otel-demo
image:
  repository: 655355946217.dkr.ecr.ap-southeast-1.amazonaws.com/swan_polyglot-microservices-application/accounting
  tag: 
```

Do the same for other microservices, except frontend-proxy, postgresql, and valkey-cart.
<br><br>

Get ACM certificate arn from ACM certificate created in [1.2. Create ACM certificate for Kubernetes ingress](#12-create-acm-certificate-for-kubernetes-ingress).

For frontend-proxy microservice, in swan_kubernetes/swan_helm/swan_microservices/frontend-proxy/, set the following values:
```yaml
namespace: otel-demo
image:
  repository: 655355946217.dkr.ecr.ap-southeast-1.amazonaws.com/swan_polyglot-microservices-application/frontend-proxy
  tag:
swan_ingress:
  swan_host: www.swanpyaetun.com
  swan_acm_certificate_arn: arn:aws:acm:ap-southeast-1:655355946217:certificate/2d6443ef-1f10-4f46-8fb5-fb318b7de611
```
<br>

For postgresql and valkey-cart microservice, set only the following value:
```yaml
namespace: otel-demo
```

## 6. Argo CD

### 6.1. swan_kubernetes/swan_argocd/root-app.yaml

In swan_kubernetes/swan_argocd/root-app.yaml, set the following fields: spec.project, spec.source, spec.destination, and spec.syncPolicy.

### 6.2. swan_kubernetes/swan_argocd/swan_argocd_apps/

In swan_kubernetes/swan_argocd/swan_argocd_apps/platform-app.yaml, set the following fields: spec.project, spec.source, spec.destination, and spec.syncPolicy.
<br><br>

In swan_kubernetes/swan_argocd/swan_argocd_apps/microservices-applicationset.yaml, set the following fields: spec.generators and spec.template.
<br><br>

Private ECR repositories are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

In swan_kubernetes/swan_argocd/swan_argocd_apps/image-updater.yaml, set the following fields: spec.namespace, spec.commonUpdateSettings, spec.writeBackConfig, and spec.applicationRefs. 

For accounting microservice, in swan_kubernetes/swan_argocd/swan_argocd_apps/image-updater.yaml, set the following under spec.applicationRefs:
```yaml
- namePattern: accounting
  images:
    - alias: accounting
      imageName: 655355946217.dkr.ecr.ap-southeast-1.amazonaws.com/swan_polyglot-microservices-application/accounting
      manifestTargets:
        helm:
          name: image.repository
          tag: image.tag
```

Do the same for other microservices, except postgresql and valkey-cart. There is no private ECR repository for postgresql and valkey-cart microservices.