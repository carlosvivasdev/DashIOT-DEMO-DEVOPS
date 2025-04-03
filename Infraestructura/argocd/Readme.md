

helm delete argocd -n argocd
helm uninstall argocd -n argocd

helm delete ingress-nginx -n ingress-nginx
helm uninstall ingress-nginx -n ingress-nginx

#############################################################

---------------- Encriptar PASSWORD ----------------------

htpasswd -nbBC 10 "" AQUIPASSWORD | tr -d ':\n' | sed 's/$2y/$2a/'

#############################################################

---------------- Agregar PASSWORD ----------------------

argocdServerAdminPassword: "$2a$10$sTPh5sJJafZvxb1WG8D6h.seMOewbZKgE/GFTyHcTvgyHF5tboKWm"

---------------- Cambios en el archivo values ----------------------
//Cambio del servicio de ClusterIp a NodePort//
  server:
    service:
      type: NodePort
