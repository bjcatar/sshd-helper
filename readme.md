# SSH Tunneling with Kubernetes

This setup allows you to create an SSH tunnel into your internal network using a Kubernetes pod, facilitating access to internal resources without requiring a VPN.

## Prerequisites

Ensure you have the following prerequisites installed and configured:

- `kubectl`
- `nc` (netcat)
- `sshuttle`
- SSH keys configured and added to your SSH agent

On macOS, you can install `nc` and `sshuttle` using Homebrew with the commands:

```sh
brew install netcat
brew install sshuttle
```

Ensure that your KUBECONFIG environment variable is correctly set to point to your Kubernetes cluster.

# Setup

1. Replace the SSH keys in the ssh-pod.yaml file with your own keys.
2. Set your KUBECONFIG environment variable to point to the correct cluster:

```sh
export KUBECONFIG=~/.kube/my_cluster_config
```

3. Add your SSH public keys to your SSH agent (replace with your actual SSH key path):

```sh
ssh-add -K ~/.ssh/your-ssh-key
```

# Using the sshdctl Script

We have a shell script named sshdctl that facilitates starting and stopping the SSH tunnel. Below is how you can use it:

## Starting the Tunnel

To start the tunnel with the default network (10.0.0.0/8) and the KUBECONFIG from the environment variable:

Follow the commands below to set up and utilize your SSH tunnel:

```sh
./sshdctl start
```

To start the tunnel with a custom network and a custom KUBECONFIG file:

```sh
./sshdctl start 10.152.0.0/16 /path/to/your/kubeconfig
```

## Stopping the Tunnel

To stop the tunnel and clean up the Kubernetes resources:

```sh
./sshdctl stop
```

## Troubleshooting

If you encounter issues while using the script, ensure the following:

. Your KUBECONFIG environment variable is set correctly.
. Your SSH keys are correctly added to the SSH agent.
. The ssh-pod.yaml file is correctly configured with your SSH keys.

For detailed logs, you can check the logs of the SSH Pod using the following command:

```sh
kubectl logs ssh-pod -c ssh-key-dir
```

# Accessing Resources

After establishing the SSH tunnel, configure your applications to use the SOCKS proxy at localhost:9090 to direct their traffic through the SSH tunnel. Note that port numbers 9090 and 8080 are just examples and can be changed as long as they are free on your machine.

For a setup that doesn't rely on a SOCKS proxy, consider using a tool like sshuttle.

To SSH into an internal server through the tunnel, use the following command (replace x.x.x.x with the internal IP and myuser with your username):

```sh
ssh -o ProxyCommand='nc -x localhost:9090 %h %p' myuser@x.x.x.x
```
