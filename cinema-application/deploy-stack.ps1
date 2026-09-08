$KUBETCL_NAMESPACE='movie'

kubectl create namespace "$KUBETCL_NAMESPACE"
kubectl config set-context --current --namespace "$KUBETCL_NAMESPACE"

# API
kubectl apply -f api.deployment.yaml
kubectl apply -f api.service.yaml

# DB
kubectl create secret generic db-secret --from-env-file db/db.secret
kubectl create cm db-env --from-env-file db/db.env
kubectl apply -f db-init.configmap.yaml
kubectl apply -f db.statefulset.yaml
kubectl apply -f db.service.yaml
