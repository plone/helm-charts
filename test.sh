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
  kubectl delete namespace plone-helm-test
}
trap finish EXIT

kubectl create namespace plone-helm-test

for helm_name in plone6-volto-zeo plone6-classic-pg plone6-volto-pg plone6-volto-pg-nginx-varnish; {
    echo Testing $helm_name;
    helm install -n plone-helm-test plone-helm-$helm_name ./$helm_name && sleep 30 && \
    helm uninstall -n plone-helm-test plone-helm-$helm_name
}
