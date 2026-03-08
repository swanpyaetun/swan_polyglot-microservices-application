# Prerequisites

## Table of Contents

- [1. AWS](#1-aws)
  - [1.1. AWS resources required for swanpyaetun/swan_polyglot-microservices-application Project](#11-aws-resources-required-for-swanpyaetunswan_polyglot-microservices-application-project)
- [2. GitHub Actions](#2-github-actions)
  - [2.1. Create repository secret](#21-create-repository-secret)
- [3. GitHub](#3-github)
  - [3.1. Create GitHub App for Argo CD Image Updater](#31-create-github-app-for-argo-cd-image-updater)
- [4. Helm](#4-helm)
  - [4.1. swan_kubernetes/swan_helm/swan_microservices/frontend-proxy/](#41-swan_kubernetesswan_helmswan_microservicesfrontend-proxy)

## 1. AWS

### 1.1. AWS resources required for swanpyaetun/swan_polyglot-microservices-application Project

Make sure you have created AWS resources required for swanpyaetun/swan_polyglot-microservices-application Project in [https://github.com/swanpyaetun/swan_eks-infrastructure/blob/main/swan_docs/swan_docs/swan_prerequisites.md#12-create-aws-resources-required-for-swanpyaetunswan_eks-infrastructure-project-and-swanpyaetunswan_polyglot-microservices-application-project](https://github.com/swanpyaetun/swan_eks-infrastructure/blob/main/swan_docs/swan_docs/swan_prerequisites.md#12-create-aws-resources-required-for-swanpyaetunswan_eks-infrastructure-project-and-swanpyaetunswan_polyglot-microservices-application-project)

CI IAM role, Private ECR Repositories, and ACM Certificate are created for swanpyaetun/swan_polyglot-microservices-application project.

## 2. GitHub Actions

### 2.1. Create repository secret

```bash
aws iam get-role --role-name swan_githubactions_ecr_iam_role --query 'Role.Arn' --output text
```
Run this command to get "swan_githubactions_ecr_iam_role" arn.

In swanpyaetun/swan_polyglot-microservices-application repository, go to "Settings" -> Secrets and variables -> Actions.<br>
Create a new repository secret:<br>
Name: SWAN_CI_IAM_ROLE_ARN<br>
Secret: "swan_githubactions_ecr_iam_role" arn

## 3. GitHub

### 3.1. Create GitHub App for Argo CD Image Updater

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

## 4. Helm

### 4.1. swan_kubernetes/swan_helm/swan_microservices/frontend-proxy/

```bash
aws acm list-certificates --certificate-statuses ISSUED --query "CertificateSummaryList[?contains(DomainName, 'swanpyaetun.com')].CertificateArn" --output text
```
Run this command to get ACM certificate arn.

In swan_kubernetes/swan_helm/swan_microservices/frontend-proxy/values.yaml, set the ACM certificate arn.
```yaml
swan_ingress:
  swan_host: www.swanpyaetun.com
  swan_acm_certificate_arn: arn:aws:acm:ap-southeast-1:655355946217:certificate/314cbcc5-340d-4a7a-8d2d-82e7b596662d
```