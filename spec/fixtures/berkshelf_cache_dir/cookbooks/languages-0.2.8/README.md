# languages

Resources to install compilers and other support for various languages.

# Using Test Kitchen with Docker

The following assumes you are on a Mac OS X workstation and have installed and
started [Kitematic](https://kitematic.com/).

* Install [kitchen-docker](https://github.com/portertech/kitchen-docker) into your local ChefDK install:
```
$ chef gem install kitchen-docker
Successfully installed kitchen-docker-2.3.0
1 gem installed
```

* Set environment variables to point kitchen-docker at your local Kitematic instance:
```
# Bash
export DOCKER_HOST=tcp://192.168.99.100:2376
export DOCKER_CERT_PATH=$HOME/.docker/machine/certs
export DOCKER_TLS_VERIFY=1

# Fish
set -gx DOCKER_HOST "tcp://192.168.99.100:2376"
set -gx DOCKER_CERT_PATH "$HOME/.docker/machine/certs"
set -gx DOCKER_TLS_VERIFY 1
```

* Run Test Kitchen with the provided `.kitchen.docker.yml`:
```
KITCHEN_LOCAL_YAML=.kitchen.docker.yml kitchen verify languages-ruby-ubuntu-1204
```
