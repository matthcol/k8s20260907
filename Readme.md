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

## Application cinema
```
cd cinema-application
docker build -t movieapi:1.0 api/api-v1.0

# note: transfert image hote => minikube
minikube image load movieapi:1.0

kubectl apply api.deployment.yml
kubectl get deploy,po --show-labels         # 2 pods in error mode
kubectl logs pod/movieapi-57547bbc89-b76nn  # consult logs => error
```

### Utilisation d'une config map pour paramétrer l'API
Variable d'environnement: `DB_URL=sqlite:///./movie.db`

A partir d'un fichier YAML
```
kubectl apply -f api.configmap.yaml
kubectl get configmaps
kubectl get configmap
kubectl get cm

kubectl get deploy,po,cm --show-labels -l app=movieapi

# edit api.deployment.yml using cm
kubectl apply -f api.deployment.yaml        
kubectl get deploy,po,cm --show-labels -l app=movieapi

kubectl get po -o wide -l app=movieapi 
minikube ssh curl 10.244.0.44:8080/movies/ 

kubectl run -it --rm --restart=Never --image=busybox -- bash
    wget --header "Content-Type: application/json" --post-data='{"title": "The Odyssey", "year": 2026, "duration": 180}' -O - http://10.244.0.44:8080/movies/
    wget -O - http://10.244.0.44:8080/movies/

kubectl exec -it movieapi-744869579f-bjzwq  -- bash
    ls -l   # file movie.db
    python
        import sqlite3

        with sqlite3.connect("movie.db") as conn:
            conn.row_factory = sqlite3.Row
            for row in conn.execute("SELECT * FROM movie"):
                print(dict(row))
```

### Gestion directe d'un config map en CLI
```
kubectl create configmap dummy-env --from-literal HOST=www.dummy.org --from-literal PORT=8080
kubectl get cm
kubectl get cm/dummy-env -o yaml
kubectl get cm/dummy-env -o json
kubectl get cm/dummy-env -o jsonpath='{.data}'
```

```
cd misc
kubectl create configmap dummy-env2 --from-env-file dummy.env
kubectl get cm/dummy-env2 -o jsonpath='{.data}'
```

```
kubectl create cm table-ddl --from-file tables.sql
kubectl get cm/table-ddl -o jsonpath='{.data}'
kubectl apply -f montage-tables.deployment.yml
kubectl get po   # montage-table-5f64d795f8-snjch 
kubectl exec -it montage-table-5f64d795f8-snjch -- sh
    ls -l /opt/sql
    cat /opt/sql/tables.sql
```

