# DataONE Helm Charts

> [!NOTE]
> This repo contains miscellaneous Helm charts for deploying 3rd-party software (such as Apache HTTP Server, WordPress etc.) that is needed to support DataONE services. The goal is to be able to deploy these services and keep them up to date as simply as possible, without needing new chart releases or other maintenance overhead. Because of this:
> - The image version is not hard-coded in the chart - see the Upgrade Policy, below
> - The charts may contain some hard-coded values by design, and are not intended to be generic or re-usable in other contexts (but can be used as a starting point if needed)

## Upgrade policy

> [!IMPORTANT]
> After upgrading, ALWAYS update the CHANGELOG.md file in our private GitHub Enterprise `k8s-cluster-config` repo!

- To upgrade, simply change the image version manually and run `helm upgrade` when a new version of the 3rd party software is released.
- Avoid using "`latest`" tags, to avoid unexpected breaking changes when new versions are released!
- Check the README in each specific chart, for links to the official image tags and release notes, and any specific upgrade notes or gotchas.

## Production Deployment

When deploying these charts in the production cluster:
  - Values overrides should be added to our private GitHub Enterprise `k8s-cluster-config` repo 
  - Encrypted copies of Secrets should be added to our internal GitHub Enterprise security repo.

## Adding New Charts

> [!IMPORTANT]
> First ensure that the software you want to deploy does not already have an existing officially-maintained Helm Chart or Kubernetes Cluster Operator that we can use!
> Places to check for an existing officially-maintained Helm Chart:
> - the official site/documentation for the software you want to deploy (e.g. https://www.apache.org/)
> - [Docker Hardened Images Helm Charts](https://hub.docker.com/hardened-images/catalog?types=helmChart)
> - Artifact Hub (https://artifacthub.io/)

Please follow existing patterns in this repo when adding new charts, and add documentation to the README for the new chart, including links to official image tags and release notes, and any specific upgrade notes or gotchas.

If possible, try to use [Docker Hardened Images](https://hub.docker.com/hardened-images/catalog) for production deployments, to improve security. If a hardened image is not available, use the official image from the software vendor.

---

## Historical Note

This repo was originally intended for use as the DataONE chart repository for software releases, via GitHub Pages and the charts.dataone.org CNAME.

However, since we're using GHCR as our repo, and it's not currently possible to use an `index.yaml` to link to OCI resources (see https://github.com/helm/helm/issues/12322), this repo currently cannot be used for that purpose. The GitHub Pages site and CNAME are therefore disabled for now.

It may be useful in future, if `index.yaml` files start to support `oci://` urls, for instance.

(Also see [./docs/index.md](./docs/index.md) for hints on how to search dataone helm charts)
