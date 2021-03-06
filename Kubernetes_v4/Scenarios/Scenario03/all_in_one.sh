#!/bin/bash

cd ~/LabNetApp/Kubernetes_v4/Scenarios/Scenario03

if [ $(kubectl get sc | grep "(default)" | wc -l) = 0 ]
  then
    echo "#######################################################################################################"
    echo "Assign a default storage class"
    echo "#######################################################################################################"

    kubectl patch storageclass storage-class-nas -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi

echo "#######################################################################################################"
echo "Upgrade Prometheus Operator with Helm"
echo "#######################################################################################################"

helm upgrade prom-operator stable/prometheus-operator --namespace monitoring --set prometheusOperator.createCustomResource=false,grafana.persistence.enabled=true

echo "==POD:"
kubectl get -n monitoring pod -l app.kubernetes.io/name=grafana --output=name
echo "==NB:"
kubectl get -n monitoring pod -l app.kubernetes.io/name=grafana --field-selector=status.phase=Running | wc -l
echo "LOOP:"
while [ $(kubectl get -n monitoring pod -l app.kubernetes.io/name=grafana --field-selector=status.phase=Running | wc -l) -ne 2 ]
do
  echo "sleep a bit ..."
  sleep 10
done
echo "END LOOP"
echo "==POD:"
kubectl get -n monitoring pod -l app.kubernetes.io/name=grafana --output=name

echo "#######################################################################################################"
echo "Install Pie Chart Plugin in Grafana"
echo "#######################################################################################################"

kubectl exec -n monitoring -it $(kubectl get -n monitoring pod -l app.kubernetes.io/name=grafana --output=name) -c grafana -- grafana-cli plugins install grafana-piechart-panel
echo "==POD:"
kubectl get -n monitoring pod -l app.kubernetes.io/name=grafana --output=name
echo "==SCALE DOWN:"
kubectl scale -n monitoring deploy prom-operator-grafana --replicas=0
sleep 15s
echo "==POD:"
kubectl get -n monitoring pod -l app.kubernetes.io/name=grafana --output=name
echo "==SCALE UP:"
kubectl scale -n monitoring deploy prom-operator-grafana --replicas=1
sleep 15s

echo "#######################################################################################################"
echo "Create ConfigMap for Dashboards"
echo "#######################################################################################################"

kubectl create configmap -n monitoring cm-trident-dashboard --from-file=3_Grafana/Dashboards/
kubectl label configmap -n monitoring cm-trident-dashboard grafana_dashboard=1