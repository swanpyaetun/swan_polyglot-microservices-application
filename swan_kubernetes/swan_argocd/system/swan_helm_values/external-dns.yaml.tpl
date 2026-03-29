---
serviceAccount:
  name: external-dns

nodeSelector:
  workload-type: "system"

tolerations:
- key: "workload-type"
  operator: "Equal"
  value: "system"
  effect: "NoSchedule"

policy: sync

txtOwnerId: ${swan_eks_cluster_name}

domainFilters:
- ${swan_domain_name}