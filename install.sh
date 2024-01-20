#!/bin/sh

set -euo pipefail

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
  echo "${NC}"
}

# preflight check function
preflight_check() {
  local passed=true
  # check if the script is running as root
  if [ "$(id -u)" != "0" ]; then
      echo "${RED}This script must be run as root${NC}" 1>&2
      passed=false
  fi

  # check if flux is installed
  if ! [ -x "$(command -v flux)" ]; then
      echo "${RED}flux is not installed. ${WHITE}Please install flux first.${NC}" 1>&2
      passed=false
  fi

  # check that argocd is installed
  if ! [ -x "$(command -v argocd)" ]; then
      echo "${RED}argocd is not installed. ${WHITE}Please install argocd first.{NC}" 1>&2
      passed=false
  fi

  # check that kubectl is installed
  if ! [ -x "$(command -v kubectl)" ]; then
      echo "${RED}kubectl is not installed. ${WHITE}Please install kubectl first.${NC}" 1>&2
      passed=false
  fi

  # check that kustomize is installed
  if ! [ -x "$(command -v kustomize)" ]; then
      echo "${RED}kustomize is not installed. ${WHITE} Please install kustomize first.${NC}" 1>&2
      passed=false
  fi

  # check that helm is installed
  if ! [ -x "$(command -v helm)" ]; then
      echo "${RED}helm is not installed. ${WHITE} Please install helm first.${NC}" 1>&2
      passed=false
  fi

  echo
  # check passed variable
  if [ "$passed" = false ]; then
    echo "${RED}preflight check failed${NC}" 1>&2
    exit 1
  fi

  echo "${GREEN}preflight check passed${NC}" 1>&2
}

# setup function to initialize variables
# Usage: setup <github_repo> <github_user> <github_token>
setup() {
  # ensure all arguments are passed
  if [ $# -ne 3 ]; then
      echo "Usage: setup <github_repo> <github_user> <github_token>"
      exit 1
  fi
  export GREEN=$(tput setaf 2)
  export RED=$(tput setaf 1)
  export YELLOW=$(tput setaf 3)
  export BLUE=$(tput setaf 4)
  export PINK=$(tput setaf 5)
  export CYAN=$(tput setaf 6)
  export WHITE=$(tput setaf 7)
  export NC='\e[0m'
  export GITHUB_TOKEN=$3
  export GITHUB_USER=$2
  export GITHUB_REPO=$1
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

# echo "Welcome to Kubula!" 1>&2
setup "https://github.com/gaianetes/kubula.git" $GITHUB_USER $GITHUB_TOKEN
print_logo
echo "${YELLOW}Running preflight checks${NC}" 1>&2
echo
preflight_check
echo
echo "${YELLOW}Bootstrapping mgmt cluster with flux${NC}" 1>&2
echo
bootstrap "mgmt"