# Vault Ansible Operator

Vault Ansible Operator implements the [vault operator](https://github.com/coreos/vault-operator) with Ansible playbooks via the [Ansible Operator](https://github.com/water-hole/ansible-operator)


## Quickstart

1. Start [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) (e.g. `minikube start`)
1. Create `rbac.yml` as described in the vault operator's [RBAC guide](https://github.com/coreos/vault-operator/blob/master/doc/user/rbac.md)
1. Deploy the etcd operator as described [here](https://github.com/coreos/vault-operator#deploying-the-etcd-operator)
1. Create the Vault Ansible Operator RBAC

    ```bash
    kubectl create -f deploy/rbac.yaml
    ```

1. Create the Vault Ansible Operator CRD

    ```bash
    kubectl create -f deploy/crd.yaml
    ```

1. Deploy the Vault Ansible Operator

    ```bash
    kubectl create -f deploy/operator.yaml
    ```

1. Create the Vault CR

    ```bash
    kubectl create -f deploy/cr.yaml
    ```


## Verify Vault Deployment

### Check pods

Issue the `kubectl get pods` command, and verify that you have the following pods

```bash
ansible-operator    // Vault Ansible Operator

etc-operator (3)    // ETCD Operator

example-etcd (3)    // ETCD Cluster Pods

example (2)         // Vault Cluster Pods
```

### Verify Vault

The following steps are derived from the verification steps describe in the [Vault Usage Guide](https://github.com/coreos/vault-operator/blob/master/doc/user/vault.md#vault-usage-guide)

1. In a new/separate terminal window issue the following command

    ```bash
    kubectl port-forward pod/example-<one of the Vault Cluster pods> 8200
    ```

1. In another terminal window set the following environment variables

    ```bash
    export VAULT_ADDR='https://localhost:8200'
    export VAULT_SKIP_VERIFY="true"
    ```

1. Verify that the Vault server is accessible with the `vault status` command

    The below is the expected output for an uninitialized Vault:

    ```bash
    $ vault status

    Error checking seal status: Error making API request.

    URL: GET https://localhost:8200/v1/sys/seal-status
    Code: 400. Errors:

    * server is not yet initialized
    ```

1. Initialize the Vault the `vault operator init` command

    ```bash
    $ vault operator init
    Unseal Key 1: <key value>
    Unseal Key 2: <key value>
    Unseal Key 3: <key value>
    Unseal Key 4: <key value>
    Unseal Key 5: <key value>

    Initial Root Token: <token value>

    Vault initialized with 5 key shares and a key threshold of 3. Please securely
    distribute the key shares printed above. When the Vault is re-sealed,
    restarted, or stopped, you must supply at least 3 of these keys to unseal it
    before it can start servicing requests.

    Vault does not store the generated master key. Without at least 3 key to
    reconstruct the master key, Vault will remain permanently sealed!

    It is possible to generate new unseal keys, provided you have a quorum of
    existing unseal keys shares. See "vault operator rekey" for more information.
    ```

1. Verify that the Vault is initialized

    ```bash
    $ vault status
    Key                Value
    ---                -----
    Seal Type          shamir
    Sealed             true
    Total Shares       5
    Threshold          3
    Unseal Progress    0/3
    Unseal Nonce       n/a
    Version            0.9.1
    HA Enabled         true
    ```
### Verify Vault Cluster Recovery

The deployment will create a Vault cluster with the number of pods defined by the `vault_replica_size` variable in the [`deploy/cr.yaml`](https://github.com/johnkim76/vault-ansible-operator/blob/master/deploy/cr.yaml#L6) file (default is 2). Therefore, if a pod is down (or deleted), a new pod should be created.

To test this feature, issue the following command in a terminal window:

```bash
watch kubectl get pods
```

Identify one of the Vault pod and manually delete it.  For example, in a new terminal window do the following:

```bash
kubectl delete pod example-99bcb876-iwkdv
```

Verify that the pod above is being terminated, and a new pod is created in its place. Also, verify the Vault's operational status (i.e. `vault status`) after the replacement pod is in `Running` state.

## Update Deployment

As stated earlier, the deployment can be updated with a different number of pods for the Vault Cluster (minimum 1).

In order to change the number of pods in your Vault cluster, simply edit the  `vault_replica_size` variable in the [`deploy/cr.yaml`](https://github.com/johnkim76/vault-ansible-operator/blob/master/deploy/cr.yaml#L6) file to the desired pod number.  Then run the following command:

```bash
kubectl apply -f deploy/cr.yaml
```

Note: You must `apply` the changes since a deployment already exists.  Issuing the `create` command will error.

Verify that the number of pods are created/terminated to match the new `vault_replica_size` value, and the your Vault cluster is still operational afterwards.

## Uninstall Vault Ansible Operator Deployment

To uninstall the Vault Deployment and the Operator, run the following commands

1. Uninstall Vault
    ```bash
    kubectl delete -f deploy/cr.yaml
    ```
1. Uninstall Vault Ansible Operator
    ```bash
    kubectl delete -f deploy/operator.yaml
    ```

Verify that the all pods created with the deployment are being `terminated` and are deleted
