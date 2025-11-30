# kubectl-migrate: Kubernetes Pod Live Migration Plugin

**`kubectl-migrate`** is an experimental `kubectl` plugin that performs "live migration" of stateful Pods between Kubernetes nodes. 

It leverages the [Kubelet Checkpoint API](https://kubernetes.io/docs/reference/node/kubelet-checkpoint-api/) (CRIU) to freeze a running process, export its memory state, package it into an OCI container image, and restore it on a different node—preserving in-memory variables and established TCP connections.

## 🚀 Features

* **Zero-Config Auth**: Uses existing `kubectl` credentials to trigger checkpoints via the API Server proxy.
* **Optimistic Scheduling**: Starts scheduling the new Pod on the destination node *while* the memory image is still uploading, minimizing downtime.
* **Checkpoint-as-Image**: Packages memory dumps into standard OCI images using `buildah`, allowing standard container runtimes (containerd/CRI-O) to perform the restore without custom node agents.
* **Multi-Container Support**: Allows selecting a specific stateful container to migrate while restarting sidecars (e.g., service meshes) fresh.

---

## 📋 Prerequisites

### Client-Side
* **`kubectl`**: Authenticated to your cluster.
* **`jq`**: Required for JSON parsing in the script.
    * *install via `apt install jq` or `brew install jq`*

### Cluster-Side
The Kubernetes cluster must be configured to allow checkpointing:
1.  **Kubernetes Version**: v1.25+ (Beta in v1.30).
2.  **Feature Gate**: The Kubelet must run with `--feature-gates=ContainerCheckpoint=true`.
3.  **CRIU**: The underlying nodes must have `criu` installed (or use a distro like Ubuntu/Fedora where it is available).

---

## 🛠️ Installation

1.  Download the plugin script (save the optimized script from previous steps as `kubectl-migrate`).
2.  Make it executable:
    ```bash
    chmod +x ./kubectl-migrate
    ```
3.  Move it to your `$PATH`:
    ```bash
    sudo mv ./kubectl-migrate /usr/local/bin/kubectl-migrate
    ```
4.  Verify installation:
    ```bash
    kubectl plugin list | grep migrate
    # Output: /usr/local/bin/kubectl-migrate
    ```

---

## 📖 Usage

### Basic Migration
Migrate a pod named `my-job` to a new node. The memory state will be pushed to the specified registry.

```bash
kubectl migrate my-job [my-registry.com/checkpoints/my-job:v1](https://my-registry.com/checkpoints/my-job:v1)
```

### Advanced Options

Select specific container & target node type: If your pod has multiple containers (e.g., a sidecar), specify which one holds the state. You can also use a node selector to influence where the new pod lands.

```sh
kubectl migrate postgres-0 ttl.sh/postgres-ckpt:v1 \
  --container postgres-db \
  --selector disktype=ssd \
  --keep-old

Arguments:

-n, --namespace: Specify namespace (default: default).

-c, --container: The container name to checkpoint.

-s, --selector: key=value node selector for the new pod.

--keep-old: Do not delete the original pod (useful for debugging, but keeps PVCs locked).
```

### References

- [Kubelet Checkpoint API: Official Documentation](https://kubernetes.io/docs/reference/node/kubelet-checkpoint-api/)
- [CRIU (Checkpoint/Restore In Userspace): Project Homepage](https://criu.org/Main_Page)
- [Containerd Restore Handling: Containerd Checkpoint/Restore Support](https://github.com/containerd/containerd/blob/main/docs/cri/checkpoint-restore.md)
- [Buildah: Official Documentation](https://buildah.io/)
- [Kind (Kubernetes in Docker): User Guide](https://kind.sigs.k8s.io/docs/user/quick-start/)