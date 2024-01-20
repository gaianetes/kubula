# Kubula: ArgoCD

![Gaia Logo](media/gaianetes.png)

## What is Gaia?

_todo_

## Components

_todo_

## Prerequisites

### Hardware

_todo_

### Software

_todo_

## Installation

_todo_

## Usage

_todo_

## ArgoCD

ArgoCD is a widely used declarative, GitOps continuous delivery tool for Kubernetes. It is used to deploy and manage the state of applications running in Kubernetes clusters. It is a declarative tool, meaning that it uses a Git repository as the source of truth for the desired state of the cluster. It then compares the desired state with the actual state of the cluster and makes any necessary changes to the cluster to make the actual state match the desired state.

### ArgoCD Installation

ArgoCD can be installed via multiple methods. The most common method is to install it as a Kubernetes application using the ArgoCD Helm chart. This method is the most flexible and allows for the most customization. It is also the most complex method. The other method is to install ArgoCD as a standalone application. This method is the simplest and quickest method, but it is also the least flexible and customizable. `gaianetes` is a full, self-service platform that bootstraps a Kubernetes cluster and installs ArgoCD on `n` number of Kubernetes clusters using `flux-cd`. Please see the [Gaia](https://github.com/gaianetes/kubula/tree/main/clusters/mgmt/03-argo-cd) module for more information.

### ArgoCD Configuration

While you can configure ArgoCD solely using the UI, we will be using the CLI to configure ArgoCD so it will be easily reproducible. The ArgoCD CLI is called `argocd`. It is a powerful tool that allows you to configure ArgoCD in a declarative manner. This means that you can configure ArgoCD using a Git repository as the source of truth for the desired state of ArgoCD. This is the same way that ArgoCD manages the state of applications running in Kubernetes clusters. This is a powerful feature because it allows you to manage the state of ArgoCD in the same way that you manage the state of applications running in Kubernetes clusters. This means that you can use the same tools and processes to manage the state of ArgoCD that you use to manage the state of applications running in Kubernetes clusters. See the [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) documentation for more information.

#### ArgoCD Private Repository

The first thing that we will configure is the private repository that ArgoCD will use to store its state. This is the same repository that ArgoCD will use to store the state of applications running in Kubernetes clusters. We will use the `argocd` CLI to configure the private repository. _Note_ you need to create a personal access token (PAT) in GitHub (with proper scope) and store it in the `GAIANETES_PAT` environment variable.

```bash
# first port forward to the ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443
# login to ArgoCD
# first get the admin password and set it as an environment variable
export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# it is good practice to delete this password and set your own. You can do this by running the following command
argocd account update-password --current-password $ARGOCD_PASSWORD --new-password <your-new-password>
# then make sure to update the ARGOCD_PASSWORD environment variable
export ARGOCD_PASSWORD=<your-new-password> >> ~/.zshrc
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD
# now configure the private repository
argocd repo add https://github.com/gaianetes/gaia.git \
  --project monitoring \
  --username git \
  --password $GAIANETES_PAT \
  --insecure-skip-server-verification \
  --upsert
```

#### ArgoCD Project

Projects in ArgoCD are used to group applications together. The first project that we will configure will be for `monitoring` applications. We will use the `argocd` CLI to create the `monitoring` project.

```bash
# first port forward to the ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443
# login
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD
# now create a project
ADDFLAGS="--upsert"
argocd proj create monitoring \
  --allow-namespaced-resource '*' \
  --allow-cluster-resource '*' \
  $ADDFLAGS \
  --dest https://kubernetes.default.svc,monitoring
```

## References

- https://fluxcd.io/docs/get-started/
- https://argoproj.github.io/cd/
- https://docs.rke2.io/helm

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Credits

Lead Developer - [Mitchell Murphy](mitch.murphy@gmail.com)

## License

The MIT License (MIT)

Copyright (c) 2023 Mitchell Murphy

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
