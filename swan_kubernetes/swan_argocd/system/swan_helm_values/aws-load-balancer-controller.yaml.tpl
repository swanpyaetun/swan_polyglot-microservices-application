---
serviceAccount:
  name: aws-load-balancer-controller

nodeSelector:
  workload-type: "system"

tolerations:
- key: "workload-type"
  operator: "Equal"
  value: "system"
  effect: "NoSchedule"

clusterName: ${swan_eks_cluster_name}

vpcId: ${swan_vpc_id}