---
title: "Managing multi-env deployments with ArgoCD ApplicationSets"
date: 2025-03-18
tag: gitops
---

We have five environments: dev, staging, preprod, prod-eu, prod-us. For a
while we maintained one ArgoCD Application per service per environment —
which meant around 80 Application manifests to keep in sync. It was fine
until it wasn't.

### The problem

Updating a Helm values path required touching 16 files. Drift between
environments was subtle and hard to catch. New services got inconsistent
Application definitions depending on who set them up.

### ApplicationSets to the rescue

ApplicationSets are a controller that generates ArgoCD Applications from a
template plus a list of parameters. The `List` generator is the simplest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-service
spec:
  generators:
    - list:
        elements:
          - env: dev
            cluster: dev-cluster
            valuesFile: values-dev.yaml
          - env: prod-eu
            cluster: prod-eu-cluster
            valuesFile: values-prod.yaml
  template:
    metadata:
      name: "my-service-{{env}}"
    spec:
      project: default
      source:
        repoURL: https://github.com/org/helm-charts
        targetRevision: HEAD
        path: charts/my-service
        helm:
          valueFiles:
            - "{{valuesFile}}"
      destination:
        server: "{{cluster}}"
        namespace: my-service
```

### What changed

One ApplicationSet per service. Adding a new environment is one line in the
`elements` list. Structural changes to Application definitions happen in one
place.

The `Matrix` generator is next on my list — combining cluster and app lists
to generate the full cross-product automatically.
