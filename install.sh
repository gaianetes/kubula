#!/bin/sh

# preflight check function
preflight_check() {
  local passed=true
  # check if the script is running as root
  if [ "$(id -u)" != "0" ]; then
      echo "This script must be run as root" 1>&2
      passed=false
  fi

  # check if flux is installed
  if ! [ -x "$(command -v flux)" ]; then
      echo "flux is not installed. Please install flux first." 1>&2
      passed=false
  fi

  # check that argocd is installed
  if ! [ -x "$(command -v argocd)" ]; then
      echo "argocd is not installed. Please install argocd first." 1>&2
      passed=false
  fi

  # check that kubectl is installed
  if ! [ -x "$(command -v kubectl)" ]; then
      echo "kubectl is not installed. Please install kubectl first." 1>&2
      passed=false
  fi

  # check that kustomize is installed
  if ! [ -x "$(command -v kustomize)" ]; then
      echo "kustomize is not installed. Please install kustomize first." 1>&2
      passed=false
  fi

  # check that helm is installed
  if ! [ -x "$(command -v helm)" ]; then
      echo "helm is not installed. Please install helm first." 1>&2
      passed=false
  fi

  # check passed variable
  if [ "$passed" = false ]; then
    echo "preflight check failed"
    exit 1
  fi

  echo "preflight check passed"
}

# setup function to initialize variables
# Usage: setup
setup() {
  local arch=$(uname -m)
  case $arch in
    x86_64) arch=amd64;;
    aarch64) arch=arm64;;
    armv7l) arch=armv7;;
    *) echo "unsupported architecture"; exit 1 ;;
  esac
  export OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  export ARCHITECTURE=$arch
}

# function to download and install flux
# Usage: install_flux
install_flux() {
  # ensure all arguments are passed
  # if [ $# -ne 1 ]; then
  #     echo "Usage: install_flux <flux_version>"
  #     exit 1
  # fi

  # download flux
  curl -s https://fluxcd.io/install.sh | sudo bash -s --
}

# function to download and install argocd
# Usage: install_argocd
install_argocd() {
  # ensure global variables are set
  if [ -z "$OS" ] || [ -z "$ARCHITECTURE" ]; then
    echo "Please run setup first"
    exit 1
  fi
  curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-$OS-$ARCHITECTURE"
  chmod a+x argocd
  sudo install -m 555 argocd /usr/local/bin/argocd
  rm argocd
}

# function to download and install kustomize
# Usage: install_kustomize
install_kustomize() {
  # ensure global variables are set
  if [ -z "$OS" ] || [ -z "$ARCHITECTURE" ]; then
    echo "Please run setup first"
    exit 1
  fi
  curl -sSL -o kustomize "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.2.3/kustomize_kustomize.v3.2.3_$OS_$ARCHITECTURE"
  chmod a+x kustomize
  sudo install -m 555 kustomize /usr/local/bin/kustomize
  rm kustomize
}
    

# function to add a cluster to argocd
# Usage: add_cluster <cluster_name> <cluster_context>
add_cluster() {
  # ensure all arguments are passed
  if [ $# -ne 2 ]; then
    echo "Usage: add_cluster <cluster_name> <cluster_server> <cluster_context>"
    exit 1
  fi

  # add cluster to argocd
  argocd cluster add --name $1 $2 
}

# function to add a repo to argocd
# Usage: add_repo <repo_url> <username> <password> [<project> (optional)]
add_repo() {
  # ensure all arguments are passed
  if [ $# -lt 3 ]; then
    echo "Usage: add_repo <repo_name> <repo_url> <username> <password> [<project> (optional)]"
    exit 1
  fi
  # was a project name passed? (last argument not empty)
  if [ ! -z "$4" ]; then
    # add repo to argocd
    argocd repo add $1 --username $2 --password $3 --project $4 --insecure-skip-server-verification
    return
  fi

  # add repo to argocd
  argocd repo add $1 --username $2 --password $3 --insecure-skip-server-verification
}

# call prefight check
preflight_check