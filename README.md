# swanpyaetun/swan_polyglot-microservices-application

# Deploying 22 Microservices Application to EKS with GitHub Actions and Argo CD

## Table of Contents

- [1. Prerequisites](#1-see-prerequisites)
- [2. Technical Details](#2-see-technical-details)
- [3. Instructions](#3-instructions)
- [4. Additional Information](#4-additional-information)

## 1. See [Prerequisites](swan_docs/swan_prerequisites.md)

## 2. See [Technical Details](swan_docs/swan_technical_details.md)

## 3. Instructions

Run "Provision AWS Infrastructure using Terraform" pipeline in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure) to create EKS infrastructure.<br>
Run CI/CD pipelines for microservices to build and push Docker images to private ECR repositories.<br>
CI/CD pipelines for microservices can be triggered in 3 ways:
1. The CI/CD pipelines run when a pull request is opened against the main branch.
2. The CI/CD pipelines run when a direct push is made to the main branch.
3. In swanpyaetun/swan_polyglot-microservices-application repository, go to "Actions". Choose a microservice that you want to run CI/CD pipeline for. Click "Run workflow", and click "Run workflow" to run the CI/CD pipeline for the selected microservice.

To view ECR basic scanning results, in AWS Management Console, go to ap-southeast-1 region -> Elastic Container Registry -> Private registry -> Repositories. Choose a repository that has container image that you want to view ECR basic scanning result for. Choose an image that you want to view ECR basic scanning result for. Under "Scanning and vulnerabilities", you will see ECR basic scanning result for that image.
<br><br>

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name swan_production_eks_cluster --role-arn arn:aws:iam::655355946217:role/swan_production_eks_cluster-swan_eks_cluster_admin_iam_role
```
This command updates ~/.kube/config so "swan_production_eks_cluster" EKS cluster can be accessed using kubectl, assuming "swan_production_eks_cluster-swan_eks_cluster_admin_iam_role" IAM role.
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