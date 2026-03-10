# swanpyaetun/swan_polyglot-microservices-application

# Deploying 22 Microservices Application to EKS with GitHub Actions and Argo CD

- Tools used: GitHub Actions, AWS, ECR, EKS, Helm, Argo CD, Argo CD Image Updater, AWS Load Balancer Controller, External DNS, Karpenter
- Deploy 22 microservices application to EKS with GitHub Actions and Argo CD
- Set up GitHub Actions reusable workflow for building and pushing Docker images to ECR
- Set up 20 GitHub Actions CI/CD pipelines for microservices, which use reusable workflow to build and push Docker images to private ECR repositories
- Use GitHub Actions repository secret to store sensitive values
- Use GitHub App, so that Argo CD Image Updater can push to GitHub
- Use CI IAM role which only allows a specific GitHub repository in a specific GitHub organization authenticate to AWS using GitHub OIDC provider
- Secure GitHub Actions authentication to AWS by using short-lived OIDC tokens with automatic expiration, instead of storing long-lived IAM user credentials in GitHub
- Use private ECR Repositories to store container images
- Create ec2nodeclass and nodepool for Karpenter to scale EKS nodes
- Prioritize spot capacity type with fallback option to on-demand in Karpenter to optimize cost
- Remove EKS nodes that are idle or underutilized, and replace with cheaper node to optimize cost
- Use Helm to package Kubernetes manifests into Helm charts
- Create namespace, service account, "default-deny" network policy, and "allow-dns-access" network policy in "platform" Helm chart
- Deny all ingress and egress traffic in the namespace with "default-deny" network policy
- Allow the pods in the namespace to access coredns pods with "allow-dns-access" network policy
- Create deployments, services, and network policies in microservices Helm charts
- Secure the application by creating least privilege network policies
- Create ingress in "frontend-proxy" Helm chart
- Create internet-facing ALB for Kubernetes ingress with AWS Load Balancer Controller
- Use ip mode in ingress to route traffic directly to pod ip addresses
- Use ACM certificate in ingress to enable https
- Redirect http to https in ingress
- Create DNS records in Route 53 public hosted zone with External DNS
- Use Argo CD App-of-Apps pattern
- Deploy "platform" application, "microservices" applicationset, and "microservices" imageupdater with "root" application in Argo CD
- Deploy "platform" Helm chart with "platform" application in Argo CD
- Generate multiple Argo CD applications for each microservice Helm chart with "microservices" applicationset
- Enable Argo CD to automatically synchronize with git
- Validate the manifests before applying in Argo CD
- Create new resources first before pruning old resources in Argo CD
- Monitor ECR for new container image tags, and update the container image tags in the git repository with Argo CD Image Updater

## Table of Contents

- [1. Prerequisites](#1-see-prerequisites)
- [2. Technical Details](#2-see-technical-details)
- [3. Instructions](#3-instructions)
- [4. Additional Information](#4-additional-information)

## 1. See [Prerequisites](swan_docs/swan_docs/swan_prerequisites.md)

## 2. See [Technical Details](swan_docs/swan_docs/swan_technical_details.md)

## 3. Instructions

Run "Provision AWS Infrastructure using Terraform" pipeline in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure) to create EKS infrastructure.
<br><br>

Run CI/CD pipelines for microservices to build and push Docker images to private ECR repositories.<br>
CI/CD pipelines for microservices can be triggered in 3 ways:
1. The CI/CD pipelines run when a pull request is opened against the main branch.
2. The CI/CD pipelines run when a direct push is made to the main branch.
3. The CI/CD pipelines run when a user manually triggers them.

To view ECR basic scanning results, in AWS Management Console, go to ap-southeast-1 region -> Elastic Container Registry -> Private registry -> Repositories. Choose a repository that has container image that you want to view ECR basic scanning result for. Choose an image that you want to view ECR basic scanning result for. Under "Scanning and vulnerabilities", you will see ECR basic scanning result for that image.
<br><br>

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name swan_production_eks_cluster --role-arn arn:aws:iam::655355946217:role/swan_production_eks_cluster-swan_eks_cluster_admin_iam_role
```
This command updates ~/.kube/config so that "swan_production_eks_cluster" EKS cluster can be accessed using kubectl, assuming "swan_production_eks_cluster-swan_eks_cluster_admin_iam_role" IAM role.
<br><br>

```bash
cd ~/Desktop/
git clone git@github.com:swanpyaetun/swan_polyglot-microservices-application.git
```
Go to ~/Desktop/ and clone the [https://github.com/swanpyaetun/swan_polyglot-microservices-application](https://github.com/swanpyaetun/swan_polyglot-microservices-application) repository.
<br><br>

```bash
kubectl apply -f ~/Desktop/swan_polyglot-microservices-application/swan_kubernetes/swan_karpenter/
```
This command creates "default" ec2nodeclass and "default" nodepool.
<br><br>

Go to "Settings" -> Developer settings -> GitHub Apps. Select "swan-argocd-image-updater" GitHub App. Go to "General". You will see "githubAppID".<br>
Go to "Settings" -> Integrations -> Applications -> Installed GitHub Apps. Select "swan-argocd-image-updater" GitHub App by clicking "Configure". Look at the URL. The number behind https://github.com/settings/installations/ is "githubAppInstallationID".<br>
Go to "Settings" -> Developer settings -> GitHub Apps. Select "swan-argocd-image-updater" GitHub App. Go to "General" -> Private keys. Click "Generate a private key". The private key will be downloaded to your work station.<br>
```bash
kubectl -n argocd create secret generic git-creds \
  --from-literal=githubAppID=applicationid \
  --from-literal=githubAppInstallationID=installationid \
  --from-literal=githubAppPrivateKey='-----BEGIN RSA PRIVATE KEY-----PRIVATEKEYDATA-----END RSA PRIVATE KEY-----'
```
This command creates "git-creds" secret in "argocd" namespace.
<br><br>

OPTIONAL (Accessing Argo CD ui):
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```
This command will generate "argocd-initial-admin-secret". Copy the secret.
```bash
kubectl port-forward service/argocd-server 8080:80 -n argocd
```
This command makes Argo CD ui accessible at http://localhost:8080.<br>
To access Argo CD ui, go to http://localhost:8080. Enter "admin" in Username field and secret that you copied in Password field. Click "SIGN IN".
<br><br>

```bash
kubectl apply -f ~/Desktop/swan_polyglot-microservices-application/swan_kubernetes/swan_argocd/root-app.yaml
```
This command creates "root" application, which will then create child resources.
<br><br>

Go to www.swanpyaetun.com to access the application.
<br><br>

```bash
kubectl delete -f ~/Desktop/swan_polyglot-microservices-application/swan_kubernetes/swan_argocd/root-app.yaml
```
This command deletes Argo CD resources.

After Argo CD resources are deleted, wait for 1 minute. After 1 minute, Karpenter will terminate empty nodes. Check in AWS Management Console or use "kubectl get node" to make sure only system EKS node group nodes are left.
<br><br>

Run "Terraform Destroy" pipeline in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure) to destroy EKS infrastructure.

## 4. Additional Information

Terraform code for EKS infrastructure, and GitHub Actions CI/CD pipelines for Terraform: [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure)

This repository is a fork of [https://github.com/open-telemetry/opentelemetry-demo](https://github.com/open-telemetry/opentelemetry-demo).