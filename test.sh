#!/bin/bash

set -e

for cmd in kubectl helm; {
    if ! command -v $cmd &> /dev/null
    then
        echo "$cmd not found"
        exit 1
    fi
}

function finish {
  kubectl delete namespace plone-helm
}
trap finish EXIT

kubectl create namespace plone-helm

for helm_name in plone6-volto-zeo plone6-classic-pg plone6-volto-pg plone6-volto-pg-nginx-varnish; {
    echo Testing $helm_name
    helm dependency update ./$helm_name
    helm dependency list ./$helm_name
    helm install -n plone-helm dummy ./$helm_name && sleep 10 && \
    helm uninstall -n plone-helm dummy
}
