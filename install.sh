#!/bin/sh

# function to print logo with proper color
# Usage: print_logo
print_logo() {
  echo "${GREEN}"
  echo "                                                                                     "
  echo "      ___           ___                         ___                         ___      "
  echo "     /__/|         /__/\         _____         /__/\                       /  /\     "
  echo "    |  |:|         \  \:\       /  /::\        \  \:\                     /  /::\    "
  echo "    |  |:|          \  \:\     /  /:/\:\        \  \:\    ___     ___    /  /:/\:\   "
  echo "  __|  |:|      ___  \  \:\   /  /:/~/::\   ___  \  \:\  /__/\   /  /\  /  /:/~/::\  "
  echo " /__/\_|:|____ /__/\  \__\:\ /__/:/ /:/\:| /__/\  \__\:\ \  \:\ /  /:/ /__/:/ /:/\:\ "
  echo " \  \:\/:::::/ \  \:\ /  /:/ \  \:\/:/~/:/ \  \:\ /  /:/  \  \:\  /:/  \  \:\/:/__\/ "
  echo "  \  \::/~~~~   \  \:\  /:/   \  \::/ /:/   \  \:\  /:/    \  \:\/:/    \  \::/      "
  echo "   \  \:\        \  \:\/:/     \  \:\/:/     \  \:\/:/      \  \::/      \  \:\      "
  echo "    \  \:\        \  \::/       \  \::/       \  \::/        \__\/        \  \:\     "
  echo "     \__\/         \__\/         \__\/         \__\/                       \__\/     "
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
      echo "${RED}flux is not installed.${NC} ${WHITE}Please install flux first.${NC}" 1>&2
      passed=false
  fi

  # check that argocd is installed
  if ! [ -x "$(command -v argocd)" ]; then
      echo "${RED}argocd is not installed.${NC} ${WHITE}Please install argocd first.{NC}" 1>&2
      passed=false
  fi

  # check that kubectl is installed
  if ! [ -x "$(command -v kubectl)" ]; then
      echo "${RED}kubectl is not installed.${NC} ${WHITE}Please install kubectl first.${NC}" 1>&2
      passed=false
  fi

  # check that kustomize is installed
  if ! [ -x "$(command -v kustomize)" ]; then
      echo "${RED}kustomize is not installed.${NC} ${WHITE} Please install kustomize first.${NC}" 1>&2
      passed=false
  fi

  # check that helm is installed
  if ! [ -x "$(command -v helm)" ]; then
      echo "${RED}helm is not installed.${NC} ${WHITE} Please install helm first.${NC}" 1>&2
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
# Usage: setup
setup() {
  export GREEN=$(tput setaf 2)
  export RED=$(tput setaf 1)
  export YELLOW=$(tput setaf 3)
  export BLUE=$(tput setaf 4)
  export PINK=$(tput setaf 5)
  export CYAN=$(tput setaf 6)
  export WHITE=$(tput setaf 7)
  export NC='\e[0m'
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

echo Welcome to Kubula!
setup
print_logo
echo "${YELLOW}Running preflight checks${NC}"
echo
preflight_check