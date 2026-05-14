# Apache Data Service Helm chart

Minimal chart to deploy Apache using a [Docker Hardened Image](https://hub.docker.com/hardened-images/catalog/dhi/httpd). The service deployed by this chart is responsible for serving up static content from a mounted ceph subvolume, and making it accessible at a specified URL (e.g. the data files at https://arcticdata.io/data).

> [!NOTE]
> This chart is intended to be a simple, maintainable solution for serving static files at <hostname>/data for sites like arcticdata.io, test.arcticdata.io and knb.ecoinformatics.org. It therefore contains some hard-coded values by design, and is not intended to be a generic chart that is re-usable in other contexts (but can be used as a starting point if needed).

## Upgrade policy

> [!IMPORTANT]
> After upgrading, ALWAYS update the CHANGELOG.md file in our private GitHub Enterprise `k8s-cluster-config` repo!

- To upgrade, simply change the image version manually and run `helm upgrade` when a new version of the 3rd party software is released.
- Avoid using "`latest`" tags, to avoid unexpected breaking changes when new versions are released!
- Check the [official image tags](https://hub.docker.com/hardened-images/catalog/dhi/httpd/images) and [release/upgrade notes](https://httpd.apache.org/docs/current/upgrading.html), for any specific upgrade gotchas.
- Always test upgrades on the dev cluster before deploying to production, to catch any potential issues with the new version.

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
helm upgrade --install datasvcbrooke oci://ghcr.io/dataoneorg/charts/dataone-apache-data-svc \
    -f <my-values-overrides-yaml> -n brooke
```

## Troubleshooting

Docker Hardened Images do not include a shell, so you cannot exec into the pod to troubleshoot. 

However, there should be a "dev" version of the image available that includes a shell, which you can use to troubleshoot by changing the image tag in the deployment to the "dev" version, and redeploying. For example, if the current image tag is `2.4.67-debian13`, the dev version would be `2.4.67-debian13-dev` (check [tags on dockerhub](https://hub.docker.com/hardened-images/catalog/dhi/httpd/images) to confirm).

```yaml
image:
  # Example hardened image for production deployments
  #
  #  tag: "2.4.67-debian13"

  # Example dev image for debugging
  # DO NOT USE FOR PRODUCTION DEPLOYMENTS!
  #
  tag: "2.4.67-debian13-dev"
```

You can also check the logs for the apache container(s) to see any error messages:

```shell
kubectl logs -n brooke -l app.kubernetes.io/name=apache-data-svc -c apache
``` 
