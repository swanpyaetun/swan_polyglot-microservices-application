# Instructions to set up the project

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

To add IAM permissions for "swan_githubactions_ecr" IAM Role, in AWS Management Console, go to "IAM" -> Access Management -> Roles -> swan_githubactions_ecr -> Permissions -> Add permissions. Click "Create inline policy". Go to "Policy editor" -> JSON. Copy and paste the following json. Click "Next". Enter "swan_githubactions_ecr" in "Policy name" under "Policy details". Click "Create policy".
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

## 2. GitHub Actions

### 2.1. Create repository secret

In swanpyaetun/swan_polyglot-microservices-application repository, go to "Settings" -> Secrets and variables -> Actions.

Create a new repository secret:<br>
Name: SWAN_CI_IAM_ROLE_ARN<br>
Secret: swan_githubactions_ecr IAM Role arn from [1.1. Create IAM Role for GitHub Actions to authenticate to AWS](#11-create-iam-role-for-github-actions-to-authenticate-to-aws)

### 2.2. Set inputs

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

### 2.3. How to run CI/CD pipelines for microservices

CI/CD pipelines for microservices can be triggered in 3 ways:
1. The CI/CD pipelines run when a pull request is opened against the main branch.
2. The CI/CD pipelines run when a direct push is made to the main branch.
3. In swanpyaetun/swan_polyglot-microservices-application repository, go to "Actions". Choose a microservice that you want to run CI/CD pipeline for. Click "Run workflow", and click "Run workflow" to run the CI/CD pipeline for the selected microservice.

## 3. Karpenter

### 3.1. swan_kubernetes/swan_karpenter/ec2nodeclass.yaml

Private subnets, EKS node IAM role, and default cluster security group are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

Run this command before running the next command.
```bash
aws configure
```

The following command can be used to determine the alias version in a specific region.
```bash
export K8S_VERSION="1.35"
aws ssm get-parameter --name "/aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id" --query Parameter.Value | xargs aws ec2 describe-images --query 'Images[0].Name' --image-ids | sed -r 's/^.*(v[[:digit:]]+).*$/\1/'
```

In swan_kubernetes/swan_karpenter/ec2nodeclass.yaml, set the following fields: spec.role, spec.amiSelectorTerms, spec.subnetSelectorTerms, and spec.securityGroupSelectorTerms.

### 3.2. swan_kubernetes/swan_karpenter/nodepool.yaml

In swan_kubernetes/swan_karpenter/nodepool.yaml, set the following fields: spec.template, spec.limits, and spec.disruption.

## 4. Helm

### 4.1. swan_kubernetes/swan_helm/swan_platform/

In swan_kubernetes/swan_helm/swan_platform/, set the following value:
```yaml
namespace: otel-demo
```

### 4.2. swan_kubernetes/swan_helm/swan_microservices/

Private ECR repositories are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

For accounting microservice, in swan_kubernetes/swan_helm/swan_microservices/accounting/, set the following values:
```yaml
namespace: otel-demo
image:
  repository: 655355946217.dkr.ecr.ap-southeast-1.amazonaws.com/swan_polyglot-microservices-application/accounting
  tag: 
```

Do the same for other microservices, except frontend-proxy, postgresql, and valkey-cart.

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

For postgresql and valkey-cart microservice, set only the following value:
```yaml
namespace: otel-demo
```

### 4.3. swan_kubernetes/swan_argocd_root_app/

ssh-keygen -t ed25519 -C “swanpyaetun/swan_polyglot-microservices-application” -f ~/.ssh/swan_polyglot-microservices-application_argocd_ed25519

kubeseal --controller-name sealed-secrets --controller-namespace kube-system <~/Desktop/swan_git_repository_secret.yaml >~/Desktop/swan_polyglot-microservices-application/swan_kubernetes/swan_argocd_root_app/swan_git_repository_sealed_secret.yaml

cd ~/Desktop/swan_polyglot-microservices-application/swan_kubernetes/swan_argocd_root_app/
git add swan_git_repository_sealed_secret.yaml
git commit -m "Update swan_git_repository_sealed_secret.yaml [skip ci]"
git push origin main
cd

In swan_kubernetes/swan_argocd_root_app/root-app.yaml, set the following fields: spec.project, spec.source, spec.destination, and spec.syncPolicy.

### 4.4. swan_kubernetes/swan_argocd_apps/

In swan_kubernetes/swan_argocd_apps/platform-app.yaml, set the following fields: spec.project, spec.source, spec.destination, and spec.syncPolicy.

In swan_kubernetes/swan_argocd_apps/microservices-applicationset.yaml, set the following fields: spec.generators and spec.template.

Private ECR repositories are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

In swan_kubernetes/swan_argocd_apps/image-updater.yaml, set the following fields: spec.namespace, spec.commonUpdateSettings, spec.writeBackConfig, and spec.applicationRefs. 

For accounting microservice, in swan_kubernetes/swan_argocd_apps/image-updater.yaml, set the following under spec.applicationRefs:
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