# Overview

The practical part of the work where testing rollback strategies of stateless and stateful applications on a Kubernetes setup, can be found in this repository. The experiments were done on the AWS cluster and tested using Helm, ArgoCD, and FluxCD to compare the deployment processes and rollback effectiveness.The overall goal is to examine the possibility of using a single rollback strategy when using both stateless and stateful applications in a GitOps-based environment.

### 1. Cluster Setup: 

 *   The Kubernetes cluster deployed on AWS via CLI.
 *   Stateless workload: NGINX with a LoadBalancer Service.
 *   Stateful workload: MySQL with a Headless Service.
 *   First deployments were done on raw Kubernetes manifests.
 *   Below is the code snippet for cluster creation for testing.
```
 export CLUSTER=mysql-eks
 export AWS_REGION=eu-west-1

    eksctl create cluster \
    --name $CLUSTER \
    --region $AWS_REGION \
    --version 1.29 \
    --managed \
    --node-type t3.medium \
    --nodes 2 \
    --with-oidc
```

This allows the CSI driver to provision EBS volumes dynamically:
```
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $CLUSTER \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve
```
```
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster $CLUSTER \
  --region $AWS_REGION \
  --force
```


### 2. Helm Integration:

 *   Transform raw manifests to Helm charts.
 *   Modified chart folder structures and values for custom parameters.
 *   Used Helm to operate both stateless and stateful apps deployments.
 *   The rollback duration in both cases was measured using implemented rollback scripts.

### 3. ArgoCD Integration:

 *   Configured ArgoCD for declarative GitOps-driven deployments.
 *   Synced both NGINX and MySQL applications directly from Git.
 *   Rollback behavior in the Git repository when re-reverting commit.
 *   Measured rollback time and measured workload variation.

### 4. FluxCD Integration:

 *   Set up FluxCD alongside ArgoCD for comparison.
 *   Git manifest reconciliation pipelines with FluxCD.
 *   Performance on stateless and stateful tested rollback with identical workloads.
 *   Comparisons with ArgoCD Compared to rollback efficiency and speed of reconciliation.

### 5. Rollback Evaluation:

 *   Rollback experiments were written so as to provide repeatable testing.
 *   The duration to re-establish applications to a prior stable status was recorded.
 *   Clear differences observed between stateless and statefull application.


The repository is structured into three major folders which represent 3 different deployment methods: Helm, argo and FluxCD.
Within each folder contains both the stateless and stateful workload configurations, and specific rollback scripts, which are used to measure rollback time.
