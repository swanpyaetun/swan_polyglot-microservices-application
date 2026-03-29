---
serviceAccount:
  name: karpenter

nodeSelector:
  workload-type: "system"

tolerations:
- key: "workload-type"
  operator: "Equal"
  value: "system"
  effect: "NoSchedule"

settings:
  clusterName: ${swan_eks_cluster_name}
  clusterEndpoint: ${swan_eks_cluster_endpoint}
  interruptionQueue: ${swan_karpenter_interruption_sqs_queue_name}