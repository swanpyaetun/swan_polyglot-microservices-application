# Technical Details

## Table of Contents

- [1. AWS](#1-aws)
  - [1.1. IAM Role for GitHub Actions to authenticate to AWS](#11-iam-role-for-github-actions-to-authenticate-to-aws)
  - [1.2. ACM certificate for Kubernetes ingress](#12-acm-certificate-for-kubernetes-ingress)
- [2. GitHub](#2-github)
  - [2.1. GitHub App for Argo CD Image Updater](#21-github-app-for-argo-cd-image-updater)
- [3. GitHub Actions](#3-github-actions)
  - [3.1. .github/workflows/swan_docker.yml](#31-githubworkflowsswan_dockeryml)
  - [3.2. CI/CD pipelines for microservices](#32-cicd-pipelines-for-microservices)
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

### 1.1. IAM Role for GitHub Actions to authenticate to AWS

IAM role is configured to trust GitHub OIDC provider, swanpyaetun organization, and swan_polyglot-microservices-application repository. An inline policy which has ECR permissions for selected ECR repositories is attached to IAM role.

GitHub Actions can now assume IAM role.

GitHub Actions authentication to AWS is secured by implementing the following practices:
1. Not storing long-lived IAM user credentials in GitHub
2. Using short-lived OIDC tokens with automatic expiration

### 1.2. ACM certificate for Kubernetes ingress

ACM certificate is used to enable https for the application.

## 2. GitHub

### 2.1. GitHub App for Argo CD Image Updater

Argo CD Image Updater authentication to GitHub is secured by implementing the following practices:
1. Using GitHub App for fine grained control over permissions and repositories
2. GitHub App uses short lived tokens

## 3. GitHub Actions

### 3.1. .github/workflows/swan_docker.yml

.github/workflows/swan_docker.yml is a reusable workflow for building and pushing Docker images to ECR.

swan_docker job does the following steps:
1. checkout repository
2. load environment variables from .env file
3. configure AWS credentials using OIDC
4. login to ECR
5. set up Docker in the runner
6. build and push Docker image

### 3.2. CI/CD pipelines for microservices

There are 20 CI/CD pipelines which build and push Docker images to private ECR repositories. Each microservice has 1 CI/CD pipeline, except postgresql and valkey-cart.

CI/CD pipelines for microservices can be triggered in 3 ways:
1. The CI/CD pipelines run when a pull request is opened against the main branch.
2. The CI/CD pipelines run when a direct push is made to the main branch.
3. The CI/CD pipelines run when a user manually triggers them.

In CI/CD pipelines for microservices, swan_docker job uses [./.github/workflows/swan_docker.yml reusable workflow](#31-githubworkflowsswan_dockeryml).

## 4. Karpenter

### 4.1. swan_kubernetes/swan_karpenter/ec2nodeclass.yaml

In "default" ec2nodeclass,
1. EKS node IAM role is attached to Karpenter managed nodes.
2. Latest EKS-optimized Amazon Linux 2023 x86_64 AMI is used to create Karpenter managed nodes. 
3. Karpenter managed nodes are deployed in private subnets with tag "karpenter.sh/discovery" = "swan_production_eks_cluster". 
4. Default cluster security group is attached to Karpenter managed nodes.

### 4.2. swan_kubernetes/swan_karpenter/nodepool.yaml

In "default" nodepool, Karpenter only creates the nodes with
1. amd64 CPU architecture
2. linux OS
3. spot and on-demand capacity type
4. "c" -> compute optimized, "m" -> general purpose, "r" -> memory optimized instance category
5. instance generation greater than 2

In this nodepool, Karpenter will prioritize spot capacity type. If spot capacity is unavailable, Karpenter will fallback to on-demand. This nodepool references "default" ec2nodeclass. Karpenter managed nodes will expire after 720 hours (30 days). Karpenter can allocate up to 1000 CPU and 1000Gi memory. Karpenter consolidates nodes that are idle or underutilized. Karpenter waits 1 minute before consolidating the nodes.

Karpenter does cost-optimization by implementing the following practices:
1. Prioritizing spot capacity over on-demand
2. Consolidating nodes that are idle or underutilized
3. Replacing with cheaper node

## 5. Helm

Helm is used to package Kubernetes manifest files into Helm charts.

### 5.1. swan_kubernetes/swan_helm/platform/

In "platform" Helm chart, a namespace and service account for the application is created. "default-deny" network policy denies all ingress and egress traffic in the namespace. "allow-dns-access" network policy allows the pods in the namespace to access coredns pods.

Security in namespace "otel-demo" is achieved by implementing the following practices:
1. "default-deny" network policy to deny all ingress and egress traffic in the namespace
2. Creating least privilege network policies

### 5.2. swan_kubernetes/swan_helm/swan_microservices/

swan_kubernetes/swan_helm/swan_microservices/ contains 22 Helm charts. Most Helm charts contain deployment, service, and network policy.

"frontend-proxy" Helm chart contains deployment, service, ingress and network policy.
"accounting" and "fraud-detection" Helm charts only contain deployment and network policy.<br>
"flagd" and "postgresql" Helm charts contain configmap, deployment, service, and network policy.

High availibility in deployments is achieved by implementing the following practices:
1. Having 2 replicas in deployment

In "frontend-proxy" Helm chart, there is an ingress called "frontend-proxy". AWS Load Balancer Controller in EKS will create internet-facing ALB. "frontend-proxy" ingress uses ip mode to route traffic directly to pod ip addresses. ACM certificate is attached to ALB to enable https. The ingress is configured to redirect http to https. External DNS in EKS will create DNS records in "swanpyaetun.com" Route 53 public hosted zone.

![](swan_docs/architecture.png)
Network policies are created according to traffic flows in the diagram.

When creating network policies, these traffic flows are excluded since they are not needed for application to function:
1. kafka to accounting
2. kafka to fraud-detection
3. llm to product-reviews

When creating network policies, these traffic flows are included since they are needed for application to function:
1. load-generator to flagd
2. frontend-proxy to load-generator
3. frontend to flagd
4. checkout to flagd
5. kafka to kafka on port 9093
6. accounting to kafka
7. fraud-detection to kafka
8. email to flagd
9. product-catalog to postgresql
10. product-catalog to flagd

Application is secured by implementing the following practices:
1. https is enabled by using ACM certificate in "frontend-proxy" ingress
2. "frontend-proxy" ingress redirecting http to https
3. Creating least privilege network policies

## 6. Argo CD

Argo CD App-of-Apps pattern is used.

```yaml
metadata:
  finalizers:
  - resources-finalizer.argocd.argoproj.io/foreground
```
This ensures Argo CD will delete child resources first before deleting the application itself.

```yaml
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - Validate=true
    - CreateNamespace=false
    - PrunePropagationPolicy=foreground
    - PruneLast=true
```
This enables Argo CD to automatically synchronize with git. Argo CD validates the manifests before applying. New resources are created first before old resources are pruned.

### 6.1. swan_kubernetes/swan_argocd/root-app.yaml

The "root" application deploys child resources.

### 6.2. swan_kubernetes/swan_argocd/swan_argocd_apps/

The "platform" application deploys "platform" Helm chart.

The "microservices" applicationset generates multiple Argo CD applications for each microservice Helm chart.
```yaml
spec:
  template:
    metadata:
      annotations:
        argocd.argoproj.io/depends-on: platform
```
This ensures "microservices" applications are deployed only after "platform" application is fully deployed.

Argo CD Image Updater monitors ECR for new container image tags for "microservices" applications, except "postgresql" and "valkey-cart", since there is no private ECR repository for "postgresql" and "valkey-cart". Argo CD Image Updater automatically updates the container image tags defined in the Helm values files in the git repository for each "microservices" application. Argo CD Image Updater uses "git-creds" secret in "argocd" namespace, to be able to push to the git repository.