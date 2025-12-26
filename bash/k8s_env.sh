# ============================================================
# Minimal kubectl / Kubernetes Bash Add-on
# Author: prashshr
# Usage:
#   mkdir -p $HOME/.dotfiles/bash
#   curl -fsSL https://raw.githubusercontent.com/prashshr/dotfiles/main/bash/k8s_env.sh -o "$HOME/.dotfiles/bash/k8s_env.sh"
#   chmod 644 $HOME/.dotfiles/bash/k8s_env.sh
#   grep -qxF '[ -r "$HOME/.dotfiles/bash/k8s_env.sh" ] && source "$HOME/.dotfiles/bash/k8s_env.sh"' "$HOME/.bashrc" || printf '\n%s\n\n' '[ -r "$HOME/.dotfiles/bash/k8s_env.sh" ]
#   source "$HOME/.dotfiles/bash/k8s_env.sh"' >> "$HOME/.bashrc"
# ============================================================

# ------------------------------------------------------------
# Core kubectl environment
# ------------------------------------------------------------
export KUBE_EDITOR=${KUBE_EDITOR:-vi}

# ------------------------------------------------------------
# kubectl shortcut + completion
# ------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1 \
   && [[ -n "${KUBECONFIG:-}" ]] \
   && [[ -r "$KUBECONFIG" ]]; then
  alias k='kubectl'
  source <(kubectl completion bash)
  complete -F __start_kubectl k
fi

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
# Generate + source namespace aliases
# ------------------------------------------------------------
generate_kubectl_namespace_aliases() {
  local outfile="$HOME/.kubectl_aliases"
  : > "$outfile"

  kubectl get namespaces --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null \
    | grep -v '^default$' \
    | while read -r ns; do
        [[ -n "$ns" ]] && echo "alias k-${ns}='kubectl -n ${ns}'" >> "$outfile"
      done

  grep -q "^alias ksys=" "$outfile" || echo "alias ksys='kubectl -n kube-system'" >> "$outfile"

  [[ -r "$outfile" ]] && source "$outfile"
}

# Manual reload command
alias k-reload-ns='generate_kubectl_namespace_aliases && echo "Namespace aliases reloaded ($(wc -l < "$HOME/.kubectl_aliases") aliases loaded)"'

# ------------------------------------------------------------
# Always run for interactive shells (SAFE)
# ------------------------------------------------------------
if [[ $- == *i* ]] \
   && command -v kubectl >/dev/null 2>&1 \
   && [[ -n "${KUBECONFIG:-}" ]] \
   && [[ -r "$KUBECONFIG" ]]; then
  generate_kubectl_namespace_aliases
fi

# ------------------------------------------------------------
# Diagnostics helpers
# ------------------------------------------------------------
k-events() {
  kubectl get events -A --sort-by=.metadata.creationTimestamp
}

k-api-health() {
  kubectl get --raw=/healthz && echo
}

# ============================================================
# End of kubectl environment
# ============================================================
