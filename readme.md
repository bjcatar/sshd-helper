# 

```shell
export KUBECONFIG=~/.kube/zero-reactive-eks-qa2
```

# Create the pod by running:

```shell
kubectl apply -f ssh-pod.yaml
```

# Test

```shell
kubectl get pods
kubectl logs ssh-pod -c ssh-key-dir
kubectl describe pod ssh-pod
kubectl exec -it ssh-pod -- /bin/bash
```

# Set up port forwarding

```shell
kubectl port-forward ssh-pod 8080:22
```

# Establish the SSH tunnel

```shell
ssh -D 9090 -q -C -N -p 8080 root@localhost
```

# Delete
kubectl delete -f ssh-pod.yaml
