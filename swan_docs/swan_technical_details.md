# Technical Details

## 1. AWS

### 1.1. IAM Role for GitHub Actions to authenticate to AWS

IAM Role is configured to trust GitHub OIDC provider, swanpyaetun organization, and swan_polyglot-microservices-application repository. An inline policy which has ECR permissions for selected ECR repositories is attached to IAM role.

GitHub Actions can now assume IAM Role.

GitHub Actions authentication to AWS is secured by implementing the following practices:
1. Not storing long-lived IAM User credentials in GitHub
2. Using short-lived OIDC tokens with automatic expiration

### 1.2. ACM certificate for Kubernetes ingress

ACM certificate is used to encrypt the data in transit for the application.

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
3. configure aws credentials using oidc
4. login to ECR
5. set up docker in the runner
6. build and push docker image

### 3.2. CI/CD pipelines for microservices

CI/CD pipelines for microservices can be triggered in 3 ways:
1. The CI/CD pipelines run when a pull request is opened against the main branch.
2. The CI/CD pipelines run when a direct push is made to the main branch.
3. In swanpyaetun/swan_polyglot-microservices-application repository, go to "Actions". Choose a microservice that you want to run CI/CD pipeline for. Click "Run workflow", and click "Run workflow" to run the CI/CD pipeline for the selected microservice.

In CI/CD pipelines for microservices, swan_docker job uses [./.github/workflows/swan_docker.yml reusable workflow](#31-githubworkflowsswan_dockeryml).

There is no CI/CD pipeline for postgresql and valkey-cart microservices.

## 4. Karpenter

### 4.1. swan_kubernetes/swan_karpenter/ec2nodeclass.yaml

In ec2nodeclass called "default",
1. EKS node IAM Role is attached to Karpenter managed nodes.
2. Latest EKS-optimized Amazon Linux 2023 x86_64 AMI is used to create Karpenter managed nodes. 
3. Karpenter managed nodes are deployed in private subnets with tag "karpenter.sh/discovery" = "swan_production_eks_cluster". 
4. Default cluster security group is attached to Karpenter managed nodes.

### 4.1. swan_kubernetes/swan_karpenter/nodepool.yaml

In nodepool called "default", Karpenter only creates the nodes with
1. amd64 cpu architecture
2. linux os
3. spot and on-demand capacity type
4. "c" -> compute optimized, "m" -> general purpose, "r" -> memory optimized instance category
5. instance generation greater than 2

This nodepool references ec2nodeclass called "default".

In this nodepool, Karpenter managed nodes will expire after 720 hours (30 days).

In this nodepool, Karpenter can allocate up to 1000 cpu and 1000Gi memory.

In this nodepool, Karpenter automatically removes nodes if they are empty or underutilized. Karpenter waits 1 minute before consolidating the nodes.