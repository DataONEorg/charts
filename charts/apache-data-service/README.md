# Apache Data Service Helm chart

> [!NOTE]
> This chart is intended to be a simple, maintainable solution for serving static files at <hostname>/data for sites like arcticdata.io, test.arcticdata.io and knb.ecoinformatics.org. It therefore contains some hard-coded values by design, and is not intended to be a generic chart that is re-usable in other contexts (but can be used as a starting point if needed).

Minimal chart to deploy Apache using Docker Hardened Image - see https://hub.docker.com/hardened-images/catalog/dhi/httpd

## Create PV & PVC

Inspect and edit admin/pv--example-datasvc-cephfs.yaml and pvc--example-datasvc.yaml as needed to point at the data files you want to serve, then apply to create the PV and PVC to be mounted by apache

## Create Image Pull Secret

Dockerhub requires credentials for pulling hardened images. First create a personal access token (PAT) that grants read-only access to dockerhub:
1. Log in to the Docker Hub / DHI Web Portal.
2. Go to Account Settings > Security, and click New Access Token.
3. Give it a name (e.g., "arctic-ghi-access") and set the permissions to Read-only.
5. Copy the Token immediately, and use it to create a k8s Secret using your username and a read-only personal access token (PAT) for dockerhub:

```shell
kubectl create secret docker-registry dhi-pull-secret \
  --docker-server=dhi.io \
  --docker-username=<YOUR_USERNAME> \
  --docker-password=<YOUR_P_A_T> \
  --docker-email=<YOUR_EMAIL>
 ```

## Deploy

```shell
helm upgrade --install datasvcbrooke oci://ghcr.io/dataoneorg/charts/dataone-wordpress-stack \
    -f values-prod-cluster-example.yaml -n brooke
```
