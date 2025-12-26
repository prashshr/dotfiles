# ============================================================
# Minimal kubectl / Kubernetes Bash Add-on
# Author: <your-github-username>
# Usage:
#   curl -fsSL <RAW_GITHUB_URL> >> ~/.bashrc
# ============================================================

# ------------------------------------------------------------
# Guard: prevent duplicate loading
# ------------------------------------------------------------
if [[ -n "${__KUBECTL_BASH_ADDON_LOADED:-}" ]]; then
  return 0
fi
export __KUBECTL_BASH_ADDON_LOADED=1

# ------------------------------------------------------------
# Core kubectl environment
# ------------------------------------------------------------
export KUBE_EDITOR=${KUBE_EDITOR:-vi}

# ------------------------------------------------------------
# kubectl shortcut + completion
# ------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
  source <(kubectl completion bash)
  complete -F __start_kubectl k
fi

# ------------------------------------------------------------
# Context & namespace helpers (low noise, high value)
# ------------------------------------------------------------
alias kctx='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'

# Usage:
#   kns my-namespace

# ------------------------------------------------------------
# Node labels (cleaned output)
# ------------------------------------------------------------
alias kubectl-node-labels='kubectl get nodes -o wide --show-labels \
  | sed "s/[a-zA-Z0-9\.\-]*kubernetes\.io[^,]*,//g"'

# ------------------------------------------------------------
# Search across core resources + CRDs
# ------------------------------------------------------------
k8s-search() {
  local term="$1"
  [[ -z "$term" ]] && echo "Usage: k8s-search <pattern>" && return 1

  for r in pods deployments services configmaps secrets statefulsets daemonsets jobs cronjobs ingress; do
    kubectl get "$r" -A 2>/dev/null | grep -i --color=auto "$term" && echo "---"
  done

  for crd in $(kubectl get crds -o name 2>/dev/null | cut -d/ -f2); do
    kubectl get "$crd" -A 2>/dev/null | grep -i --color=auto "$term" && echo "---"
  done
}

# ------------------------------------------------------------
# Generate namespace aliases dynamically
# Creates:
#   k-<namespace> → kubectl -n <namespace>
# ------------------------------------------------------------
generate_kubectl_namespace_aliases() {
  local outfile="$HOME/.kubectl_aliases"
  : > "$outfile"

  kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null \
    | tr ' ' '\n' \
    | grep -v '^default$' \
    | while read -r ns; do
        echo "alias k-$ns='kubectl -n $ns'" >> "$outfile"
      done

  source "$outfile"
}

# Auto-generate namespace aliases in interactive shells
if [[ $- == *i* ]] && [[ -n "${KUBECONFIG:-}" ]] && command -v kubectl >/dev/null 2>&1; then
  generate_kubectl_namespace_aliases
fi

# ------------------------------------------------------------
# Diagnostics helpers (no aliases, explicit intent)
# ------------------------------------------------------------
k-events() {
  kubectl get events -A --sort-by=.metadata.creationTimestamp
}

k-api-health() {
  kubectl get --raw=/healthz && echo
}

# ============================================================
# End of kubectl bash add-on
# ============================================================
