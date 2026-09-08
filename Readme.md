# Kubernetes (k8s)

## Minikube
Installation: https://minikube.sigs.k8s.io/

Commandes minikube principales
```
minikube start|stop|status

minikube docker-env  # dind

minikube dashboard
minikube addons enable metrics-server  # addon pour le dashboard et autres composants
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

### 1er pod - standalone

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


### 2ème pod - standalone
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

## Déploiements - CLI
Solution de gestion de pod avec scaling (replicas) en mode stateless.

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

## Déploiements - YAML
```
cd echo-server-application
kubectl apply -f echo.deployment.yml
kubectl get deploy,po --show-labels

# modify spec: labels, replicas, ...
kubectl apply -f echo.deployment.yml
kubectl get deploy,po --show-labels
```

## Application cinema (fil rouge)
### Déploiement API
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

## Replicat Set
1 replica set par deploiement (même cycle de vie)

```
kubectl get replicaset
kubectl get replicasets
kubectl get rs
kubectl get rs -l app=movieapi     # hérité du déploiement
kubectl get rs/movieapi-744869579f
```

## Mise à jour et retour arrière
```
cd cinema-application
docker build -t movieapi:2.0 api/api-v2.0

# passage à la V2
kubectl get deploy,rs,po -l app=movieapi
kubectl apply -f api.deployment.yaml  
kubectl get deploy,rs,po -l app=movieapi

minikube ssh curl 10.244.0.49:8080/movies/
minikube ssh curl 10.244.0.49:8080/persons/

# Rollback
kubectl rollout status deploy/movieapi
kubectl rollout history deploy/movieapi
kubectl rollout undo deploy/movieapi

kubectl rollout history deploy/movieapi --revision 5   # pour voir l'image

# passage à la v3
docker build -t movieapi:3.0 api/api-v3.0
kubectl apply -f api.deployment.yaml
kubectl rollout pause deploy/movieapi
kubectl rollout status deploy/movieapi  # en attente
kubectl get deploy,rs,po -l app=movieapi -o wide

kubectl rollout resume deploy/movieapi
kubectl rollout status deploy/movieapi
kubectl get deploy,rs,po -l app=movieapi -o wide

minikube ssh curl 10.244.0.58:8080/movies/
minikube ssh curl 10.244.0.58:8080/persons/
minikube ssh curl 10.244.0.58:8080/alive
minikube ssh curl 10.244.0.58:8080/ready

# V3 + config 2 probes
kubectl apply -f api.deployment.yaml
kubectl get deploy,rs,po -l app=movieapi -o wide
```

## Services
Voir présentation pour les types de services.


```
kubectl apply -f api.service.yaml

kubectl get services
kubectl get service
kubectl get svc
kubectl get svc movieapi
kubectl get svc/movieapi

kubectl get svc,deploy,rs,po -l app=movieapi

minikube ssh curl 10.108.177.27:8080/movies/
kubectl run -it --rm --restart=Never --image=busybox -- bash
    wget --header "Content-Type: application/json" \
    --post-data='{"title": "The Odyssey", "year": 2026, "duration": 180}' \
    -O - http://10.108.177.27:8080/movies/
    
    wget -O - http://10.244.0.44:8080/movies/
```

Pour exposer les services à l'extérieur:
- LoadBalancer : minikube tunnel
- NodePort : port forward

Client externe de l'api:
- Navigateur : http://localhost:8080/docs
- CLI:

```
curl -X 'POST' \
  'http://localhost:8080/movies/' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "title": "Spiderman: Brand New Day",
  "year": 2026,
  "duration": 120
}'
```

```
curl -X 'POST' `
  'http://localhost:8080/movies/' `
  -H 'accept: application/json' `
  -H 'Content-Type: application/json' `
  -d '{  "title": "Spiderman: Brand New Day",   "year": 2026,  "duration": 120 }'
```

## Base de données
1ère version naïve (deployment + configmap avec les passwords)
```
kubectl create cm db-env --from-env-file db/db.env
kubectl get cm db-env -o jsonpath='{.data}'

kubectl apply -f db.deployment.yaml
kubectl get deploy,rs,po -l app=dbmovie

kubectl exec -it dbmovie-5876f984c5-krncp -- bash
    mysql -u root -p
        show databases;
        select host, user from mysql.user;
    mysql -u umovie -p dbmovie
        show tables;
```

### Secrets
K8s propose 8 types de secrets natifs + tiers

8 types natifs :
1. `Opaque`
2. `kubernetes.io/service-account-token`
3. `kubernetes.io/dockercfg`
4. `kubernetes.io/dockerconfigjson`
5. `kubernetes.io/basic-auth`
6. `kubernetes.io/ssh-auth`
7. `kubernetes.io/tls`
8. `bootstrap.kubernetes.io/token`

Exemple de tiers: HashiCorp Vault

```
kubectl create secret generic db-secret --from-env-file db/db.secret  # type Opaque
kubectl get secret db-secret -o jsonpath='{.data}'                    # mdp cryptés

# recreate cm without passwords
kubectl delete cm db-env 
kubectl create cm db-env --from-env-file db/db.env
kubectl apply -f db.deployment.yaml   

# si erreur de config/start
kubectl logs pod/dbmovie-687988bbb5-4nbhr      # error while starting
kubectl describe pod/dbmovie-687988bbb5-4nbhr  # early error (config k8s)
```

### Volumes
Article: https://kubernetes.io/docs/concepts/storage/volumes/

Plusieurs types de volumes:
- PV/PVC: modèle le plus classique pour les bases de données
    * PV : PersistentVolume = disque virtuel utilisé par un pod (storageclass + reclaim policy)
    * PVC : PersistentVolumeClaim : description du disque

Note: 
- storageclass=standard => provisionnement dynamqique
- reclaim policy=delete => delete pvc => delete pv


### StatefulSet
Avantages:
- nommage déterministe : dbmovie-0 non dépendant des déploiements (dbmovie-687988bbb5-4nbhr)
- passage à l'échelle : chaque pod peut être associé à un PV permanent et de nom fixe


```
# delete first version (deployment)
kubectl delete deploy dbmovie  
kubectl get deploy,rs,po -l app=dbmovie

# recreate as a statefulset
kubectl apply -f db.statefulset.yaml
kubectl get statefulsets
kubectl get statefulset
kubectl get sts 

kubectl get sts,po -l app=dbmovie  # pod = fixed name
kubectl get pv,pvc

kubectl exec -it dbmovie-0 -- bash
    mysql -u root -p
        show databases;
        select host, user from mysql.user;
    mysql -u umovie -p dbmovie
        show tables;
kubectl logs dbmovie-0
```

### Scripts SQL initialization
Solution 1:
```
# kubectl delete cm db-init
kubectl create cm db-init --from-file db/sql-init
kubectl get cm db-init -o yaml
kubectl get cm db-init -o jsonpath='{.data}'
```

Solution 2:
```
kubectl apply -f db-init.configmap.yaml
kubectl get cm db-init -o jsonpath='{.data}'
```

Intégration dans la base
```
kubectl delete sts dbmovie
kubectl delete pvc dbmovie-data-dbmovie-0
kubectl apply -f db.statefulset.yaml

kubectl logs dbmovie-0
kubectl exec -it dbmovie-0 -- bash
    cd /docker-entrypoint-initdb.d
    ls
    cat 01-tables.sql
    mysql -u root -p
        show databases;
        select host, user from mysql.user;
    mysql -u umovie -p dbmovie
        show tables;


kubectl delete sts dbmovie 
kubectl apply -f db.statefulset.yaml
kubectl logs dbmovie-0     # les scripts ne sont pas rejoués
```

## Namespaces
```
kubectl get svc,deploy,rs,sts,po,pv,pvc,cm
kubectl delete all --all       # current namespace
kubectl delete all --all -n default
kubectl get svc,deploy,rs,sts,po,pv,pvc,cm
```

```
kubectl create namespace movie
kubectl get namespaces
kubectl get namespace
kubectl get ns
kubectl delete ns movie

kubectl config get-contexts
kubectl config set-context --current --namespace default
kubectl config view --minify  # current
kubectl config view -o jsonpath='{..namespace}' 

kubectl delete ns movie # !!!!! BE CAREFUL

.\deploy-stack.ps1
kubectl config view -o jsonpath='{..namespace}'   
kubectl get svc,deploy,rs,sts,po,pv,pvc,cm  
```

Test service DB
```
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- bash
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h 10.108.169.146 -u umovie -p dbmovie
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h dbmovie -u umovie -p dbmovie  # même NS
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h dbmovie.movie.svc.cluster.local -u umovie -p dbmovie  # nom absolu

kubectl config set-context --current --namespace default   
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h 10.108.169.146 -u umovie -p dbmovie       # OK
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h dbmovie -u umovie -p dbmovie              # ECHEC DNS
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h dbmovie.movie.svc.cluster.local -u umovie -p dbmovie  # OK resolution DNS

kubectl config set-context --current --namespace movie  
```

## Connecter l'API à la DB
Connexion via le service

```
docker build -t movieapi:4.0 api/api-v4.0     # create tables optionnel (default false)
kubectl apply -f .\api.deployment.yaml 
kubectl get svc,deploy,rs,po -l app=movieapi

$POD_API="movieapi-74fc47cd68-sb6x6"
kubectl exec -it $POD_API -- bash     

# play with API via swagger
$POD_DB="dbmovie-0"
kubectl exec -it $POD_DB -- mysql -u umovie -p dbmovie     
```

## NetworkPolicy

```
minikube delete
minikube start --cni=calico

kubectl apply -f db.networkpolicy.yaml
kubectl get networkpolicies
kubectl get networkpolicy
kubectl get netpol
# TODO: test depuis api
# TODO: test depuis pod client
```

## Service Headless
Exposition de chaque replica d'un statefulset. 
Avantage, cabler un service sur le replica en lecture/ecriture, un autre sur le replica synchronisé en lecture seule.

```
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h dbmovie -u umovie -p dbmovie # service choose pod
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h dbmovie-0.dbmovie -u umovie -p dbmovie
kubectl run db-client --rm --restart=Never -it --image=mysql:8 -- mysql -h dbmovie-0.dbmovie.movie.svc.cluster.local -u umovie -p dbmovie
```

## Tout refaire
```
kubectl config set-context --current --namespace default   
kubectl delete ns movie
./deploy-stack.ps1
kubectl get svc,deploy,rs,sts,po,pv,pvc,cm  
```

Note: 2 probes ajoutées dans le pod db

## Migration, Backup et jobs
Penser: job ou cronjob

Appliquer les migrations
- Solution 1 : kubectl cp (copy SQL) + kuebctl exec (play SQL)
- Solution 2 : 1 migration + 1 job

```
kubectl apply -f db-migration-01.configmap.yaml
kubectl apply -f db-migration-01.job.yaml
kubectl get job         # apparait jusqu'à commplétion + ttlSecondsAfterFinished
kubectl get job -l job-name=db-migration-01
kubectl logs -n movie -l job-name=db-migration-01
```

```
kubectl apply -f db-migration-02.configmap.yaml
kubectl apply -f db-migration-02.job.yaml
kubectl get job         # apparait jusqu'à commplétion + ttlSecondsAfterFinished
kubectl get job -l job-name=db-migration-02
kubectl logs -n movie -l job-name=db-migration-02 -f
```

Bonus endslice:
```
kubectl get endpointslices 
kubectl get endpointslice -l app=movieapi
```

## Perspectives
- pre/post install container sur 1 pod (initContainer)
- endpointslices: récuperer les IPs de chaque pod (lié à chaque service)
- gestion de configuration Helm (template + env)
- daemonset : monitoring, proxy, logging, sécurité, stockage
- monitoring
- autoscaling: HPA, VPA, Autoscaler, ...
- multi-nodes

