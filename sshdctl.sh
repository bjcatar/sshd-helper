#!/bin/bash

set -e

function create_ssh_secret {
  # List the keys from SSH agent and create a Kubernetes secret from it
  KEYS=$(ssh-add -L)
  if [ "$KEYS" == "The agent has no identities." ]; then
    echo "No keys found in SSH agent. Please add your SSH keys using ssh-add."
    exit 1
  else
    # Creating the Kubernetes secret from your SSH public keys
    echo "Creating Kubernetes secret from SSH agent keys..."
    kubectl create secret generic sshdhelper-key-secret --from-literal=ssh-publickey="$KEYS"
  fi
}

# Function to check SSH service
check_ssh_service() {
  for i in {1..10}; do
    if kubectl exec ssh-pod -- pgrep sshd > /dev/null; then
      echo "SSH service is running."
      return
    else
      echo "SSH service is not running, retrying ($i/10)..."
      kubectl exec ssh-pod -- /usr/sbin/sshd -D &
      sleep 3
    fi
  done
  echo "Failed to ensure SSH service is running after 10 attempts."
  exit 1
}

# Function to check port forwarding
check_port_forward() {
  for i in {1..10}; do
    if ps -o pid,ppid,command -ax | grep "[k]ubectl port-forward"; then
      echo "Port forwarding is running."
      return
    else
      echo "Port forwarding is not running, retrying ($i/10)..."
      kubectl port-forward ssh-pod 8080:22 &
      sleep 5
    fi
  done
  echo "Failed to establish port forwarding after 10 attempts."
  exit 1
}

function start_tunnel {
  local network="${1:-10.0.0.0/8}"
  local kubeconfig="${KUBECONFIG}"

  if [[ -z "$kubeconfig" ]]; then
    echo "KUBECONFIG environment variable is not set. Please set it before running the script."
    exit 1
  fi

  if [[ -n "$2" ]]; then
    kubeconfig="$2"
  fi

  echo "Using KUBECONFIG: $kubeconfig"

  # Set the KUBECONFIG environment variable
  export KUBECONFIG="$kubeconfig"

  # Call the function to create SSH key secret
  create_ssh_secret

  # Apply the SSH Pod manifest
  if ! kubectl apply -f ssh-pod.yaml; then
    echo "Failed to apply SSH Pod manifest."
    exit 1
  fi

  echo "Waiting for the pod to become ready..."
  while [[ $(kubectl get pods ssh-pod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    sleep 2;
  done

  # Check SSH service
  check_ssh_service

  # Set up port forwarding and check it
  check_port_forward

  # Start sshuttle
  if ! sshuttle --dns -vr root@localhost:8080 $network -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"; then
    echo "Failed to start sshuttle."
    exit 1
  fi
}

function stop_tunnel {
  set +e

  # Stop sshuttle
  pkill sshuttle

  # Stop the port-forward
  pkill -f "kubectl port-forward ssh-pod 8080:22"

  # Delete the SSH Pod
  if ! kubectl delete -f ssh-pod.yaml; then
    echo "Failed to delete SSH Pod."
  fi

  # Delete the secret
  if ! kubectl delete secret sshdhelper-key-secret; then
    echo "Failed to delete secret."
  fi

  echo "Tunnel and resources have been cleaned up"
}

if [[ "$1" == "start" ]]; then
  shift
  start_tunnel "$@"
elif [[ "$1" == "stop" ]]; then
  stop_tunnel
else
  echo "Usage: $0 {start|stop} [network CIDR] [kubeconfig path]"
fi
