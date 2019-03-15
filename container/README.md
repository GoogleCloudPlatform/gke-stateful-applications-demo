# Cassandra Container for Kubernetes

This project provides a container optimized to run Apache Cassandra on Kubernetes.
Two containers are hosted; one without cqlsh or python, and another with cqlsh and python.

The containers are available via:

```console
docker pull gcr.io/pso-examples/cassandra:3.11.4-v22
```
Or
```console
docker pull gcr.io/pso-examples/cassandra:3.11.4-cqlsh-v22
```

## Building via Makefile

The projects Makefile contains various targets for building and pushing both
the production container and the development container.

### Container without cqlsh or python

Use the default target. The example below also sets the docker repository name
and the Cassandra version. See the top of the Makefile for other variables that
can be set.

```console
PROJECT=registry-url make
```

### Container with cqlsh and python

The following command builds the container which includes a working
version of `cqlsh`.

```console
make build-cqlsh
```

## Configuring Cassandra

The `run.sh` bash script in the [files](files) folder has many options that allow
the container to run in and outside of Kubernetes. The setting of  Configuration
values are driven off of Environment Variables key value combination. For example
`CASSANDRA_BROADCAST_ADDRESS` default to the value of `hostname -i`, but can
be overriden.  Please refer to [run.sh](files/runs.sh) for the full list of values.
These values are either added to such things a the cassandra.yaml file, logging
setup or GC values in jvm.options.  These files are bundled and versioned in the
files folder as well.

Besides the base values one can pass in Environment Variables that named with
the prefix `CASSANDRA_YAML_`.  Any env var with that prefix is parsed and the value
sets the corresponding YAML value in the `cassandra.yaml` configuration file.

For example:

1. set an env var `CASSANDRA_YAML_phi_convict_threshold=10`
1. run.sh replaces the line `# phi_convict_threshold: 8" with "phi_convict_threshold: 10`

## Ready Probe

The [ready probe](files/ready-probe.sh) file is used by Kubernetes to check the
readiness of the container.
