# Instructions to set up the project

## 1. AWS

### 1.1. Create IAM Role for GitHub Actions to authenticate to AWS

IAM identity provider called "token.actions.githubusercontent.com" is already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

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

In AWS Management Console, go to "IAM" -> Access Management -> Roles -> swan_githubactions_ecr -> Permissions -> Add permissions. Click "Create inline policy". Go to "Policy editor" -> JSON. Copy and paste the following json. Click "Next". Enter "swan_githubactions_ecr" in "Policy name" under "Policy details". Click "Create policy".
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

## 2. GitHub Actions

### 2.1. Create repository secret

In swanpyaetun/swan_polyglot-microservices-application repository, go to "Settings" -> Secrets and variables -> Actions.

Create a new repository secret:<br>
Name: SWAN_CI_IAM_ROLE_ARN<br>
Secret: swan_githubactions_ecr IAM Role arn from [1.1. Create IAM Role for GitHub Actions to authenticate to AWS](#11-create-iam-role-for-github-actions-to-authenticate-to-aws)

### 2.2. Set inputs

Private ECR repositories are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

For accounting microservice, in .github/workflows/accounting.yml, set the following inputs: swan_aws_region, and swan_ecr_repository.
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

Do the same for other microservices.

### 2.3. How to run CI/CD pipelines for microservices

CI/CD pipelines for microservices can be triggered in 3 ways:
1. The CI/CD pipelines run when a pull request is opened against the main branch.
2. The CI/CD pipelines run when a direct push is made to the main branch.
3. In swanpyaetun/swan_polyglot-microservices-application repository, go to "Actions". Choose a microservice that you want to run CI/CD pipeline for. Click "Run workflow", and click "Run workflow" to run the CI/CD pipeline for the selected microservice.

## 3. Karpenter

### 3.1. swan_karpenter/ec2nodeclass.yaml

Private subnets, EKS node IAM role, and default cluster security group are already created in [https://github.com/swanpyaetun/swan_eks-infrastructure](https://github.com/swanpyaetun/swan_eks-infrastructure).

The following command can be used to determine the alias version in a specific region.
```bash
export K8S_VERSION="1.35"
aws ssm get-parameter --name "/aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id" --query Parameter.Value | xargs aws ec2 describe-images --query 'Images[0].Name' --image-ids | sed -r 's/^.*(v[[:digit:]]+).*$/\1/'
```

In swan_karpenter/ec2nodeclass.yaml, set the following fields: spec.role, spec.amiSelectorTerms, spec.subnetSelectorTerms, and spec.securityGroupSelectorTerms.
```yaml
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  role: "swan_production_eks_cluster-swan_eks_node_iam_role"
  amiSelectorTerms:
    - alias: "al2023@v20260209"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "swan_production_eks_cluster"
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/swan_production_eks_cluster: "owned"
```

### 3.2. swan_karpenter/nodepool.yaml

In swan_karpenter/nodepool.yaml, set the following fields: spec.template, spec.limits, and spec.disruption.
```yaml
---
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["2"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      expireAfter: 720h # 30 * 24h = 720h
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
```

## 4. Helm