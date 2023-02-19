## Install Istio

Download istio:

    ISTIO_VERSION=1.17.1
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

Within the release folder you can add istioctl to `PATH`:

    export PATH=$PWD/istio-$ISTIO_VERSION/bin:$PATH

Install istio with istioctl and istio-operator:

    istioctl install -f istio-operator.yaml

## Deploy bookinfo app

    kubectl label namespace default istio-injection=enabled
    kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml
    kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
    kubectl apply -f istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo-versions.yaml

    GATEWAY_IP=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[*].value}')
    GATEWAY_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')

    GATEWAY_URL=$GATEWAY_IP:$GATEWAY_PORT

Test connectivity to bookinfo api gateway:

    docker run --network kind -it curlimages/curl http://$GATEWAY_URL/productpage -I


