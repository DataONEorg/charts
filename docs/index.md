# The DataONE Charts Repository

DataONE uses GitHub Container Registry ([GHCR](https://ghcr.io)) as an
[OCI-compliant](https://opencontainers.org/) repository, for Helm Charts that can be used to deploy
various DataONE services on a Kubernetes cluster.

As a side-effect, it is not currently possible to `helm repository add` and search the dataone helm
repo from your local environment, since Helm's `index.yaml` does
[not yet support OCI references (as of November 2023)](https://github.com/helm/helm/issues/12322).

You can, however, search the available charts by searching the
[packages page](https://github.com/orgs/DataONEorg/packages?tab=packages&q=charts)
on GitHub. They are prepended with `charts/` (for example: charts/dataone-indexer`), in order to 
distinguish them from docker images and other packages.

