---
config:
  registries:
  - name: ECR
    api_url: https://655355946217.dkr.ecr.ap-southeast-1.amazonaws.com
    prefix: 655355946217.dkr.ecr.ap-southeast-1.amazonaws.com
    ping: yes
    insecure: no
    credentials: ext:/scripts/auth1.sh
    credsexpire: 10h

authScripts:
  enabled: true
  scripts:
    auth1.sh: |
      #!/bin/sh
      aws ecr --region ap-southeast-1 get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d

serviceAccount:
  name: argocd-image-updater

nodeSelector:
  workload-type: "system"

tolerations:
- key: "workload-type"
  operator: "Equal"
  value: "system"
  effect: "NoSchedule"