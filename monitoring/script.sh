#!/bin/bash

# Install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

kubectl create namespace default
kubectl create namespace prometheus

# Setup prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus -f ./prometheus/values.yaml --set alertmanager.persistentVolume.storageClass="gp2" --set server.persistentVolume.storageClass="gp2"
# kubectl port-forward deployment/prometheus-server 9090:9090 -n prometheus

# Setup grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace grafana
helm install grafana grafana/grafana --values ./grafana/grafana.yaml


kubectl get pods --all-namespaces