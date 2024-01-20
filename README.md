<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/gaianetes/kubula">
    <img src="images/logo.png" alt="Logo" width="380" height="380">
  </a>

<h3 align="center">Kubula</h3>

  <p align="center">
    Kubula is a tool that helps you bootstrap your Kubernetes cluster using [Flux](https://fluxcd.io/). It is a wrapper around Flux that helps you get started with Flux and Kubernetes.
    <br />
    <a href="https://github.com/gaianetes/kubula"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/gaianetes/kubula">View Demo</a>
    ·
    <a href="https://github.com/gaianetes/kubula/issues">Report Bug</a>
    ·
    <a href="https://github.com/gaianetes/kubula/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

Kubula is a tool that helps you bootstrap your Kubernetes cluster using [Flux](https://fluxcd.io/). It is a wrapper around Flux that helps you get started with Flux and Kubernetes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

* [![RockyLinux][RockyLinuxBadge]][RockyLinux-url]
* [![Ansible][AnsibleBadge]][Ansible-url]
* [![Terraform][TerraformBadge]][Terraform-url]
* [![Packer][PackerBadge]][Packer-url]
* [![ArgoCD][ArgoCDBadge]][ArgoCD-url]
* [![Flux][FluxBadge]][Flux-url]
* [![Kubernetes][KubernetesBadge]][Kubernetes-url]
* [![Rancher][RancherBadge]][Rancher-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Prerequisites

- [oVirt](https://www.ovirt.org/download/)
- A Kubernetes [cluster](https://mitchmurphy.io/cilium-rke2/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [flux CLI](https://fluxcd.io/flux/installation/)
- [flamingo CLI](https://flux-subsystem-argo.github.io/website/)
- [argocd cli](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
- [terraform cli](https://www.terraform.io/downloads.html)
- [packer cli](https://www.packer.io/downloads)
- [ansible cli](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

### Bootstrap

This repository will serve as the source of truth for your cluster. You can clone this repository, change the remote, make changes to it and commit. The changes will be applied to your cluster.

1. Install flux CLI. Follow these instructions: https://fluxcd.io/docs/installation/
2. Create PAT (Personal Access Token) with `repo` scope from [GitHub](https://github.com/settings/tokens)
3. Bootstrap

```console
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
export GITHUB_REPO=<your-repo>
export CLUSTER_NAME=<your-cluster-name>
kubectl config use-context $CLUSTER_NAME
flux bootstrap github \
    --owner=$GITHUB_USER \
    --repository=$GITHUB_REPO \
    —-path="applications/flux/clusters/$CLUSTER_NAME" \
    --token-auth \
    --personal \
    --branch=main
```

4. Wait for the bootstrap to complete. You can check the status using `flux get sources git`. It should look like this:

```bash
$ flux get sources git
NAME            REVISION                SUSPENDED       READY   MESSAGE
flux-system     main@sha1:2e619003      False           True    stored artifact for revision 'main@sha1:2e619003'
```

5. Check the pods in `flux-system` namespace. It should look like this:

```bash
$ kubectl get pods -n flux-system
NAME                                       READY   STATUS    RESTARTS   AGE
helm-controller-5f9f9f6f8f-4q9qz           1/1     Running   0          2m
kustomize-controller-7f9f9f6f8f-2q9qz      1/1     Running   0          2m
notification-controller-7f9f9f6f8f-2q9qz   1/1     Running   0          2m
source-controller-7f9f9f6f8f-2q9qz         1/1     Running   0          2m
```

6. Install Flamingo

```bash
flamingo install
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Install Cilium

We can use Flamingo to install Cilium. The Cilium Helm chart is defined in `clusters/$CLUSTER_NAME/cilium/01-cilium-helmrelease.yaml`. You can change the values in `clusters/$CLUSTER_NAME/cilium/01-cilium-helmrelease.yaml` to customize the installation. Once you are done, commit the changes and push them to the repository. Flux will apply the changes to your cluster.

```bash
$ git add .
$ git commit -m "Install Cilium"
$ git push origin main
```

_Note_ - We have set `serviceMonitor.enabled` to `false` as the Prometheus CRDs need to be installed before we can enable this, and since we are replaing `kube-proxy` with `cilium`, we need to install Cilium first. After installing Prometheus, you can set this to `true` and commit the changes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Install Argo CD

We can now use Flux to install Argo CD. We will use a HelmRelease to install Argo CD. The HelmRelease is defined in `clusters/$CLUSTER_NAME/argo-cd/argocd-helmrelease.yaml`. You can change the values in `clusters/$CLUSTER_NAME/argo-cd/02-argo-cd-helmrelease.yaml` to customize the installation. Once you are done, commit the changes and push them to the repository. Flux will apply the changes to your cluster.

```bash
$ git add .
$ git commit -m "Install Argo CD"
$ git push origin main
```

You can check the status of the HelmRelease using `flux get helmrelease --all-namespaces`. It should look like this:

```bash
$ flux get helmrelease --all-namespaces
NAMESPACE       NAME    REVISION        SUSPENDED       READY   MESSAGE
argocd          argocd  5.51.0          False           True    Helm install succeeded for release argocd/argocd-argocd.v1 with chart argo-cd@5.51.0
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Install Prometheus

Similar to Argo CD, we can use a `HelmRelease` to install the Prometheus Kube Stack. The `HelmRelease` is defined in `clusters/$CLUSTER_NAME/prometheus/03-prom-helmrelease.yaml`. You can change the values in `clusters/$CLUSTER_NAME/prometheus/03-prome-helmrelease.yaml` to customize the installation. Once you are done, commit the changes and push them to the repository. Flux will apply the changes to your cluster.

```bash
$ git add .
$ git commit -m "Install Prometheus"
$ git push origin main
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage

Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources.

_For more examples, please refer to the [Documentation](https://example.com)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [x] Flux Bootstrap
  - [x] kube-prometheus-stack
  - [x] Longhorn
  - [x] MetalLB
  - [x] ArgoCD
- [ ] ArgoCD Applications
  - [ ] MinIO
  - [ ] PLG Applicationset
    - [ ] Loki
    - [ ] Grafana
  - [ ] Core Security Applications
    - [ ] Falco
    - [ ] Gatekeeper
    - [ ] Kyverno
    - [ ] Trivy
    - [ ] Coroot
    - [ ] Aqua
      - [ ] Tracee
      - [ ] Falco
  - [ ] Keycloak
  - [ ] Harbor
  - [ ] Velero
  - [ ] KubeVirt
  - [ ] Argo Workflows
  - [ ] Argo Events
  - [ ] MediaServer
    - [ ] Plex
    - [ ] Sonarr
    - [ ] Radarr
    - [ ] Prowlarr
    - [ ] OpenVPN
    - [ ] Transmission
    - [ ] Jackett
    - [ ] Bazarr
- [ ] Infrastructure
    - [ ] Ansible
      - [ ] GlusterFS
      - [ ] RKE2
    - [ ] Terraform
      - [ ] oVirt
      - [ ] AWS
      - [ ] GCP

See the [open issues](https://github.com/gaianetes/kubula/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See [LICENSE](./LICENSE.md) for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Mitchell Murphy - [@kubula](https://twitter.com/kubula) - mitch@smigula.io

Project Link: [https://github.com/gaianetes/kubula](https://github.com/gaianetes/kubula)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* []()
* []()
* []()

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/gaianetes/kubula.svg?style=for-the-badge
[contributors-url]: https://github.com/gaianetes/kubula/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/gaianetes/kubula.svg?style=for-the-badge
[forks-url]: https://github.com/gaianetes/kubula/network/members
[stars-shield]: https://img.shields.io/github/stars/gaianetes/kubula.svg?style=for-the-badge
[stars-url]: https://github.com/gaianetes/kubula/stargazers
[issues-shield]: https://img.shields.io/github/issues/gaianetes/kubula.svg?style=for-the-badge
[issues-url]: https://github.com/gaianetes/kubula/issues
[license-shield]: https://img.shields.io/github/license/gaianetes/kubula.svg?style=for-the-badge
[license-url]: https://github.com/gaianetes/kubula/blob/master/LICENSE.md
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/mitchellmurphy/
[product-screenshot]: images/screenshot.png
[Ansible-url]: https://www.ansible.com/
[AnsibleBadge]: https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white
[RockyLinuxBadge]: https://img.shields.io/badge/Rocky%20Linux-8.4-blue?style=for-the-badge&logo=rocky%20linux
[RockyLinux-url]: https://www.rockylinux.org/
[TerraformBadge]: https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white
[Terraform-url]: https://www.terraform.io/
[Packer-url]: https://www.packer.io/
[PackerBadge]: https://img.shields.io/badge/packer-%23E7EEF0.svg?style=for-the-badge&logo=packer&logoColor=%2302A8EF
[ArgoCDBadge]: https://img.shields.io/badge/Argo-EF7B4D?logo=argo&logoColor=fff&style=for-the-badge
[ArgoCD-url]: https://argo-cd.readthedocs.io/
[FluxBadge]: https://img.shields.io/badge/flux-%2300BEBB.svg?style=for-the-badge&logo=flux&logoColor=white
[Flux-url]: https://fluxcd.io/
[KubernetesBadge]: https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white
[Kubernetes-url]: https://svelte.dev/
[RancherBadge]: https://img.shields.io/badge/rancher-%230075A8.svg?style=for-the-badge&logo=rancher&logoColor=white
[Rancher-url]: https://laravel.com