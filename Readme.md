# Kubernetes (k8s)

## Minikube
Installation: https://minikube.sigs.k8s.io/

Commandes minikube principales
```
minikube start|stop|status

minikube docker-env  # dind

minikube dashboard
```

Gestion des contextes avec kubectl (can be stored in ~/.kube/config)
```
kubectl config get-contexts
kubectl config current-context
kubectl config use-context <name_of_context>
```

## Gestion des Pods
Lister les pods
```
# default namespace
kubectl get pod
kubectl get pods
kubectl get po

# all namespaces
kubectl get po -A

# one namespace
kubectl get po -n kube-system
```

Deployer un pod
```
kubectl run echo --image=kicbase/echo-server:1.0
kubectl get po
kubectl get pod/echo
kubectl delete po echo
kubectl delete pod/echo
```

Formats d'output
```
kubectl get pod/echo -o wide
kubectl get pod/echo -o yaml
kubectl get pod/echo -o json

kubectl get pod/echo -o jsonpath='{.status.podIP}'
kubectl get pod/echo -o jsonpath='{.spec.containers[0].image}'
kubectl get pods -o jsonpath='{.items[*].status.podIP}'
```

Description (équivalent docker inspect)
```
kubectl describe pod echo
kubectl describe pod/echo
```

Client echo server
```
minikube ssh # interactive mode
    curl '10.244.0.12:8080/toto?p=toto&q=123'
minikube ssh "curl '10.244.0.12:8080/toto?p=toto&q=123'"
```


### Un 2e pod
```
kubectl run nginx --image=nginx:alpine-slim
kubectl get po -o wide
minikube ssh "curl 10.244.0.13"
kubectl exec -it nginx -- sh
kubectl exec -it nginx -- ps -aef
```

### Cleanup
```
kubectl delete po echo nginx
```

## Deploiement CLI
En mode CLI
```
kubectl create deployment echo --image=kicbase/echo-server:1.0 --replicas=2

kubectl get po

kubectl get deployments
kubectl get deployment
kubectl get deploy
kubectl get deployment/echo
kubectl get deployment/echo -o wide

kubectl get deploy,po

kubectl get po -o jsonpath='{.items[*].status.podIP}'
kubectl get po -o wide
minikube ssh "curl 10.244.0.15:8080"
minikube ssh "curl 10.244.0.14:8080"

kubectl scale deploy echo --replicas=5   # upscale
kubectl get deploy,po
kubectl scale deploy echo --replicas=2   # downscale
kubectl scale deploy echo --replicas=0   # stop
kubectl scale deploy echo --replicas=2   # start
```

## Labels
```
kubectl get deploy,po --show-labels
kubectl get deploy,po -l app=echo  
kubectl get po -l app=echo --show-labels
kubectl delete po -l app=echo     # delete all replicas => recreate auto
kubectl get po -l app=echo --show-labels

kubectl label deploy echo environnement=test
kubectl get deploy --show-labels 

kubectl label pod -l app=echo environnement=test
kubectl get deploy,po --show-labels

# overwrite label
kubectl label deploy,po -l app=echo --overwrite environnement=preprod   
kubectl get deploy,po --show-labels

# unlabel
kubectl label deploy,po -l app=echo environnement-         

# cleanup
kubectl delete deploy,po -l app=echo  
```

## Deploiement YAML
```
cd echo-server-application
kubectl apply -f echo.deployment.yml
kubectl get deploy,po --show-labels

# modify spec: labels, replicas, ...
kubectl apply -f echo.deployment.yml
kubectl get deploy,po --show-labels
```


