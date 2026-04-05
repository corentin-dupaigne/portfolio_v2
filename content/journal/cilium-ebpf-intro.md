---
title: "Getting started with Cilium and eBPF"
date: 2025-04-01
tag: networking
---

I've been meaning to dig into Cilium for a while. Our clusters still run
Calico and it works fine, but eBPF-based networking has been on my radar
ever since I watched a talk on bypassing iptables entirely.

### Why Cilium

The pitch is straightforward: Cilium replaces kube-proxy with an eBPF
data plane that runs directly in the kernel. No more iptables chains
growing with every new Service. The performance improvements at scale
are real, but what actually sold me was the observability story.

Hubble — Cilium's observability layer — gives you L3/L4/L7 flow visibility
without any sidecar proxies. You can see exactly which pods are talking to
which, with latency and drop reasons, all from the kernel.

### Getting started locally

I used `kind` to spin up a local cluster with Cilium:

```bash
kind create cluster --config kind-config.yaml
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.15.0 \
  --namespace kube-system \
  --set kubeProxyReplacement=true
```

The `kind-config.yaml` needs `disableDefaultCNI: true` and the right
`podSubnet` to avoid conflicts.

### First impressions

The Hubble UI is genuinely useful for debugging connection issues. I spent
an afternoon tracing a DNS resolution problem that would have taken days
with tcpdump and iptables-save output.

The documentation is dense but thorough. I'll write more as I get deeper
into NetworkPolicy and the Tetragon security observability layer.
