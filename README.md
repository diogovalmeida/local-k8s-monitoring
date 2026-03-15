# Local Kubernetes Monitoring Stack

A production-like Kubernetes setup running locally on macOS or Linux, with full observability via Prometheus and Grafana. Built as part of a university project at ISTEC Lisboa.

Don't forget to leave a **star ⭐!**

---

## About

The goal of this project is to simulate a real company Kubernetes environment on a local machine — with separate dev and prod namespaces, a FastAPI application connected to PostgreSQL, and a full monitoring stack using Prometheus and Grafana.

Everything runs on your machine. No cloud costs.

> ⚠️ **Windows is not supported.** Kubernetes tooling is native to Unix systems. Use macOS or Linux for the best experience.

---

## Stack

- **Kind** — local Kubernetes cluster
- **Docker** — container runtime
- **FastAPI** — application API
- **PostgreSQL** — database, deployed via Helm (Bitnami)
- **Prometheus + Grafana** — metrics collection and visualisation
- **NGINX Ingress** — traffic routing
- **Helm** — Kubernetes package manager

---

## Getting Started

### 1. Install Prerequisites

```bash
chmod +x install-prerequisites.sh
./install-prerequisites.sh
```

Installs automatically on macOS (via Homebrew) and Linux (via apt/dnf/pacman): Docker, Kind, kubectl, Helm.

### 2. Clone the repository

```bash
git clone https://github.com/your_username/local-k8s-monitoring.git
cd local-k8s-monitoring
```

### 3. Run the setup script

```bash
chmod +x setup.sh
./setup.sh
```

That's it. The script handles everything — cluster creation, Docker image build, namespaces, app deployment, NGINX Ingress, PostgreSQL, Prometheus and Grafana.

> ⏳ **Note:** After the script finishes, the services may take a minute or two to be fully ready. If `http://dev.local` or `http://grafana.local` don't load immediately, wait 60–90 seconds and try again.

At the end of the script you'll see:

```
=============================================
✅ Setup complete!
=============================================

  API (dev)     →  http://dev.local
  API (prod)    →  http://prod.local
  Grafana       →  http://grafana.local
  Grafana user  →  admin
  Grafana pass  →  <generated>
```

### Teardown

To delete everything — cluster, namespaces, Helm releases and DNS entries:

```bash
./delete.sh
```

---

## Accessing the Services

| Service | URL |
|---------|-----|
| API (dev) | http://dev.local |
| API (prod) | http://prod.local |
| Grafana | http://grafana.local |
| Health check | http://dev.local/health |
| DB health | http://dev.local/db-health |
| Metrics | http://dev.local/metrics |

---

## Simulations

### Crash Loop

Simulate a crash loop by breaking the liveness probe:

```bash
kubectl patch deployment fastapi-deployment -n dev \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/path","value":"/non-existent"}]'

# Watch pods restart
kubectl get pods -n dev -w
```

Resolve by restoring the correct path:

```bash
kubectl patch deployment fastapi-deployment -n dev \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/path","value":"/health"}]'
```

### CPU Stress

Exec into a pod and run a stress loop:

```bash
kubectl exec -it -n dev \
  $(kubectl get pods -n dev -l app=fastapi -o jsonpath='{.items[0].metadata.name}') \
  -- sh -c "while true; do echo 'stress' > /dev/null; done"
```

Watch the CPU spike in Grafana under **Dashboards → Kubernetes / Compute Resources / Namespace (Pods)**.

Stop with `Ctrl+C`.

---

## Built With

- **[FastAPI](https://fastapi.tiangolo.com/)** — modern Python web framework
- **[Kind](https://kind.sigs.k8s.io/)** — Kubernetes in Docker
- **[Helm](https://helm.sh/)** — Kubernetes package manager
- **[Prometheus](https://prometheus.io/)** — metrics collection
- **[Grafana](https://grafana.com/)** — metrics visualisation
- **[Bitnami PostgreSQL](https://bitnami.com/stack/postgresql/helm)** — Helm chart for PostgreSQL

---

## License

MIT
