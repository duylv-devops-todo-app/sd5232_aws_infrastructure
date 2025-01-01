#!/bin/bash

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=”{.data.password}”

kubectl port-forward svc/argocd-server -n argocd 8081:443

# use id: admin
# password: <base64 decoded password>

kubectl create namespace app-argocd