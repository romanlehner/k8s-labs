# Cilium lab

## Crate a kind cluster

    kind create cluster --name cilium --config ../kind/config-no-cni.yaml

## Install cilium with API Gateway enabled
Install CRDs:

    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.5.1/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.5.1/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.5.1/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.5.1/config/crd/experimental/gateway.networking.k8s.io_referencegrants.yaml


Check CRD installations:

    kubectl get crd gatewayclasses.gateway.networking.k8s.io
    kubectl get crd gateways.gateway.networking.k8s.io
    kubectl get crd httproutes.gateway.networking.k8s.io
    kubectl get crd referencegrants.gateway.networking.k8s.io

Install cilium:

    helm install cilium cilium/cilium --version 1.13.0 \
  --namespace kube-system \
  --set gatewayAPI.enabled=true \
  --set kubeProxyReplacement=strict

Check the gatewayclass cilium is available:

    kubectl get gatewayclass

Deploy the API Gateway and routes for the test services. Make sure you specify a valid ip address cidr in the [address pool resource](http-gateway.yaml#L7):

    kubectl apply -f http-gateway.yaml

Check the gatway ip address:

    kubectl get gateway
    NAME         CLASS    ADDRESS          READY   AGE
    my-gateway   cilium   172.18.255.114   True    12s

# Resources
- [API Gateway support for Cilium](https://docs.cilium.io/en/v1.13/network/servicemesh/gateway-api/gateway-api/)