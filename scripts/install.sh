#!/bin/bash

set -eo pipefail

GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PINK=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
NC=$(tput sgr0)

FLUX_VERSION=2.2.3
ARGO_VERSION=v2.11.7
KUSTOMIZE_VERSION=v5.4.3
K9S_VERSION=0.32.5
HELM_VERSION=3.6.3
SOPS_VERSION=3.7.1


# declare associative array to store the installation status of each tool
declare -A installed_tools
installed_tools["flux"]=false
installed_tools["argocd"]=false
installed_tools["kubectl"]=false
installed_tools["kustomize"]=true
installed_tools["helm"]=false
installed_tools["k9s"]=false


info() {
  echo "${GREEN}INFO: $1${NC}"
}
debug() {
  echo "${YELLOW}DEBUG: $1${NC}"
}
warning() {
  echo "${BLUE}WARNING: $1${NC}"
}
error() {
  echo "${RED}ERROR: $1${NC}"
  exit 1
}

# function to print logo with proper color
# Usage: print_logo
print_logo() {
  echo "                                                                                     "
  echo "${GREEN}      ___      ${YELLOW}     ___      ${BLUE}              ${PINK}     ___      ${CYAN}              ${RED}     ___      "
  echo "${GREEN}     /__/|     ${YELLOW}    /__/\     ${BLUE}    _____     ${PINK}    /__/\     ${CYAN}              ${RED}    /  /\     "
  echo "${GREEN}    |  |:|     ${YELLOW}    \  \:\    ${BLUE}   /  /::\    ${PINK}    \  \:\    ${CYAN}              ${RED}   /  /::\    "
  echo "${GREEN}    |  |:|     ${YELLOW}     \  \:\   ${BLUE}  /  /:/\:\   ${PINK}     \  \:\   ${CYAN} ___     ___  ${RED}  /  /:/\:\   "
  echo "${GREEN}  __|  |:|     ${YELLOW} ___  \  \:\  ${BLUE} /  /:/~/::\  ${PINK} ___  \  \:\  ${CYAN}/__/\   /  /\ ${RED} /  /:/~/::\  "
  echo "${GREEN} /__/\_|:|____ ${YELLOW}/__/\  \__\:\ ${BLUE}/__/:/ /:/\:| ${PINK}/__/\  \__\:\ ${CYAN}\  \:\ /  /:/ ${RED}/__/:/ /:/\:\ "
  echo "${GREEN} \  \:\/:::::/ ${YELLOW}\  \:\ /  /:/ ${BLUE}\  \:\/:/~/:/ ${PINK}\  \:\ /  /:/ ${CYAN} \  \:\  /:/  ${RED}\  \:\/:/__\/ "
  echo "${GREEN}  \  \::/~~~~  ${YELLOW} \  \:\  /:/  ${BLUE} \  \::/ /:/  ${PINK} \  \:\  /:/  ${CYAN}  \  \:\/:/   ${RED} \  \::/      "
  echo "${GREEN}   \  \:\      ${YELLOW}  \  \:\/:/   ${BLUE}  \  \:\/:/   ${PINK}  \  \:\/:/   ${CYAN}   \  \::/    ${RED}  \  \:\      "
  echo "${GREEN}    \  \:\     ${YELLOW}   \  \::/    ${BLUE}   \  \::/    ${PINK}   \  \::/    ${CYAN}    \__\/     ${RED}   \  \:\     "
  echo "${GREEN}     \__\/     ${YELLOW}    \__\/     ${BLUE}    \__\/     ${PINK}    \__\/     ${CYAN}              ${RED}    \__\/     "
  echo "                                                                                     "
}

# preflight check function
preflight_check() {
  local passed=true
  # check if flux is installed
  if [ -x "$(command -v flux)" ]; then
    INSTALLED_VERSION=$(flux --version | grep -oP '\d+\.\d+\.\d+' | head -n 1)
    # Compare versions
    if [[ $(echo -e "$INSTALLED_VERSION\n$FLUX_VERSION" | sort -V | head -n 1) = "$FLUX_VERSION" ]]; then
        info "Flux: Installed version ($INSTALLED_VERSION) meets the minimum requirement ($FLUX_VERSION)."
        installed_tools["flux"]=$ARGO_VERSION
    else
        error "Flux: Installed version ($INSTALLED_VERSION) does not meet the minimum requirement ($FLUX_VERSION)."
        installed_tools["flux"]=false
    fi
  fi

  # check that argocd is installed
  if ! [ -x "$(command -v argocd)" ]; then
      error "argocd is not installed"
  else
    installed_tools["argocd"]=$ARGO_VERSION
  fi

  # check that kubectl is installed
  if ! [ -x "$(command -v kubectl)" ]; then
      error "kubectl is not installed"
  else
    installed_tools["kubectl"]=$(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')
  fi

  # check that kustomize is installed
  if ! [ -x "$(command -v kustomize)" ]; then
      error "kustomize is not installed"
  else
    installed_tools["kustomize"]=$KUSTOMIZE_VERSION
  fi

  # check that k9s is installed
  if [ -x "$(command -v k9s)" ]; then
    INSTALLED_VERSION=$(k9s version | grep -oP '\d+\.\d+\.\d+' | head -n 1)
    # Compare versions
    if [[ $(echo -e "$INSTALLED_VERSION\n$K9S_VERSION" | sort -V | head -n 1) = "$K9S_VERSION" ]]; then
        info "K9s: Installed version ($INSTALLED_VERSION) meets the minimum requirement ($K9S_VERSION)."
        installed_tools["k9s"]=$K9S_VERSION
    else
        error "K9s: Installed version ($INSTALLED_VERSION) does not meet the minimum requirement ($K9S_VERSION)."
        installed_tools["k9s"]=false
    fi
  fi

  # check that helm is installed
  if ! [ -x "$(command -v helm)" ]; then
      error "helm is not installed"
  else
    installed_tools["helm"]=$HELM_VERSION
  fi

  echo
  # check passed variable
  if [ "$passed" = false ]; then
    error "preflight check failed"
  else
    info "preflight check passed"
  fi

  # print out the status of all installed tools
  for tool in "${!installed_tools[@]}"; do
    if [ "${installed_tools[$tool]}" != false ]; then
      info "$tool: ${installed_tools[$tool]}"
    else
      warning "$tool is installed"
    fi
  done
}

# setup function to initialize variables
# Usage: setup <github_repo> <github_user> <github_token>
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

check_git_credentials() {
  if [ -z "$GITHUB_USER" ]; then
    warning "GITHUB_USER is not set"
    read -p "${WHITE}Please enter your GitHub username: " GITHUB_USER
    export GITHUB_USER
  else
    debug "GITHUB_USER is currently set to '$GITHUB_TOKEN'"
    read -p "Do you want to specify a different GitHub user? (y/n): " answer
    case $answer in
      [Yy]* ) read -p "${WHITE}Please enter the GitHub user you want to use: " GITHUB_USER;;
      * ) info "${GREEN}Using existing GITHUB_USER: $GITHUB_USER";;
    esac
  fi
  if [ -z "$GITHUB_TOKEN" ]; then
    warning "GITHUB_TOKEN is not set" 1>&2
    read -p "${WHITE}Please enter your GitHub Token: " GITHUB_TOKEN
    export GITHUB_TOKEN
  else
    echo "${YELLOW}GITHUB_TOKEN is currently set to '$GITHUB_TOKEN'."
    read -p "${WHITE}Would you like to use this? (y/n): " answer
    case $answer in
      [Nn]* ) read -p "${WHITE}Please enter the GitHub token you want to use: " GITHUB_TOKEN;;
      * ) info "Using existing GITHUB_TOKEN: $GITHUB_TOKEN";;
    esac
  fi
  # do same for GITHUB_REPO
  if [ -z "$GITHUB_REPO" ]; then
    warning "GITHUB_REPO is not set"
    read -p "${WHITE}Please enter the name of the GitHub repository you want to use: " GITHUB_REPO
    export GITHUB_REPO
  else
    debug "GITHUB_REPO is currently set to '$GITHUB_REPO'."
    
    read -p "${WHITE}Do you want to specify a different GitHub repository? (y/n): " answer
    case $answer in
      [Yy]* ) read -p "{WHITE}Please enter the name of the GitHub repository you want to use:{NC} " GITHUB_REPO;;
      * ) info "Using existing GITHUB_REPO: $GITHUB_REPO";;
    esac
  fi
}

# function to download and install flux
# Usage: install_flux
install_flux() {
  # Check if the correct version of flux is installed
  if [ -x "$(command -v flux)" ]; then
    if [ "$(flux --version)" == "flux version $FLUX_VERSION" ]; then
      echo "Flux $FLUX_VERSION is already installed"
      return
    fi
  fi

  # download flux
  curl -s https://fluxcd.io/install.sh | sudo bash -s --
}

# function to download and install argocd
# Usage: install_argocd
install_argocd() {
  # ensure global variables are set
  if [ -z "$OS" ] || [ -z "$ARCHITECTURE" ]; then
    error "Please run setup first"
    exit 1
  fi
  # if ARGO_VERSION is not set use latest
  if [ -z "$ARGO_VERSION" ]; then
    ARGO_VERSION=latest
  fi
  # Check to see if the corrent version of argocd is installed
  if [ -x "$(command -v argocd)" ]; then
    if [ "$(argocd version --client)" == "argocd version $ARGO_VERSION" ]; then
      debug "ArgoCD $ARGO_VERSION is already installed"
      return
    fi
  fi
  info Installing ArgoCD CLI $ARGO_VERSION
  echo "Download ArgoCD from: https://github.com/argoproj/argo-cd/releases/download/$ARGO_VERSION/argocd-$OS-$ARCHITECTURE"
  # https://github.com/argoproj/argo-cd/releases/2.11.7/download/argocd-linux-amd64
  curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/$ARGO_VERSION/argocd-$OS-$ARCHITECTURE"
  # if empty exit
  if [ ! -f argocd ]; then
    error "Failed to download argocd"
  fi
  chmod a+x argocd
  sudo mv argocd /usr/local/bin
  debug Installing ArgoCD on cluster $(kubectl config current-context)
  kubectl create namespace argocd
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v$ARGO_VERSION/manifests/install.yaml
}

# function to download and install kustomize
# Usage: install_kustomize
install_kustomize() {
  # ensure global variables are set
  if [ -z "$KUSTOMIZE_VERSION" ]; then
    error "KUSTOMIZE_VERSION is not set"
  fi
  # Check to see if the corrent version of argocd is installed
  if [ -x "$(command -v kustomize)" ]; then
    if [ "$(kustomize version)" == "argocd version $ARGO_VERSION" ]; then
      debug "Kustomize $KUSTOMIZE_VERSION is already installed"
      return
    fi
  fi
  url="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F$KUSTOMIZE_VERSION/kustomize_${KUSTOMIZE_VERSION}_${OS}_$ARCHITECTURE.tar.gz"
  debug "Install Kustomize $KUSTOMIZE_VERSION"
  curl -sSL "$url" | sudo tar -xz -C /usr/local/bin
}

upgrade_k9s() {
  # ensure global variables are set
  if [ -z "$OS" ] || [ -z "$ARCHITECTURE" ]; then
    echo "Please run setup first"
    exit 1
  fi
  curl -sSL -o k9s.tar.gz "https://github.com/derailed/k9s/releases/download/v$K9S_VERSION/k9s_Linux_amd64.tar.gz"
  tar -xzf k9s.tar.gz
  chmod a+x k9s
  # overwrite the existing k9s binary
  sudo rm -f /usr/local/bin/k9s
  sudo mv k9s /usr/local/bin/k9s
}

install_k9s() {
  # check if k9s is installed, if not exist
  if [ -x "$(command -v k9s)" ]; then
    INSTALLED_VERSION=$(k9s version | grep -oP '\d+\.\d+\.\d+' | head -n 1)
    # Compare versions
    if [[ $(echo -e "$INSTALLED_VERSION\n$K9S_VERSION" | sort -V | head -n 1) = "$K9S_VERSION" ]]; then
        info "Installed version ($INSTALLED_VERSION) meets the minimum requirement ($K9S_VERSION)."
    else
        error "Installed version ($INSTALLED_VERSION) does not meet the minimum requirement ($K9S_VERSION)."
        # prompt user to install the correct version
        read -p "Do you want to install k9s version $K9S_VERSION? (y/n): " answer
        case $answer in
          [Yy]* ) upgrade_k9s;;
          * ) info "installing k9s";;
        esac
    fi
  fi
  read -p "Do you want to install k9s version $K9S_VERSION? (y/n): " answer
  case $answer in
    [Yy]* ) upgrade_k9s;;
    * ) error "Exiting";;
  esac
}

# function to bootstrap a cluster using flux
# Usage: bootstrap <cluster_name>
bootstrap() {
  # ensure all arguments are passed
  if [ $# -ne 1 ]; then
    echo "Usage: bootstrap <cluster_name>"
    exit 1
  fi
  flux bootstrap github \
      --owner=$GITHUB_USER \
      --repository=$GITHUB_REPO \
      --path="flux/clusters/$1" \
      --token-auth \
      --personal \
      --branch=main
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

# function to install ApplicationSets to argocd
# Usage: install_appset <application_set> <cluster_name>
install_appset() {
  # ensure all arguments are passed
  if [ $# -ne 2 ]; then
    echo "Usage: install_appset <application_set> <cluster_name>"
    exit 1
  fi
  # check that <cluster_name> is a valid cluster
  $clusters=$(kubectl config get-contexts -o name)
  if [[ ! $clusters =~ $2 ]]; then
    echo "Cluster $2 does not exist"
    exit 1
  fi

  # install ApplicationSet to argocd
  echo "${GREEN}Installing $1 ApplicationSet to cluster $2 ${NC}"
  argocd app create $1 --repo $GITHUB_USER/$GITHUB_REPO \
    --path "argocd/applicationsets/$1.yaml" \
    --dest-name $2 \
    --dest-namespace argocd --sync-policy automated \
    --auto-prune --self-heal --directory-recurse --upsert
}

setup
print_logo
info "Checking Git credentials"
check_git_credentials

echo "${YELLOW}Running preflight checks${NC}" 1>&2
echo
preflight_check
# echo
# # echo "${YELLOW}Bootstrapping mgmt cluster with flux${NC}" 1>&2
# # echo