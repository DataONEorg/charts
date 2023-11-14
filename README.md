# charts
This repo was intended for use as the DataONE chart repository for software releases, via GitHub Pages and the charts.dataone.org CNAME.

However, since we're using GHCR as our repo, and it's not currently possible to use an `index.yaml` to link to OCI resources (see https://github.com/helm/helm/issues/12322), this repo is currently of limited use. The GitHub Pages site and CNAME are therefore disabled for now.

It may be useful in future, if `index.yaml` files start to support `oci://` urls, for instance.

(Also see [./docs/index.md](./docs/index.md) for hints on how to search dataone helm charts)
