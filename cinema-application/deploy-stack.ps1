# API
kubectl apply -f api.configmap.yaml
kubectl apply -f api.deployment.yaml
kubectl apply -f api.service.yaml

# DB
kubectl create secret generic db-secret --from-env-file db/db.secret
kubectl create cm db-env --from-env-file db/db.env
kubectl apply -f db.deployment.yaml